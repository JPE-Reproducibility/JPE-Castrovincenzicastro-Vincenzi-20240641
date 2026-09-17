"""Export Stata values to UTF-8 CSV and validate every cell at source precision.

Requires Python 3.12+, pandas 3.0.5 and numpy 2.5.3 (tested versions).
Run from the replication root:
  python do/utilities/export_stata_csv.py --source data/raw --output data/raw_csv_copy
Use --verify-only to check without replacing data files. --existing allows a
separate staging output directory while checking the currently supplied copies.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ProcessPoolExecutor, as_completed
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import time

import numpy as np
import pandas as pd
from pandas.io.stata import StataMissingValue, StataReader

CHUNK = 100_000
NUMERIC_TYPES = {'b': 'int8', 'h': 'int16', 'l': 'int32', 'f': 'float32', 'd': 'float64'}


def sha256(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda: f.read(8 * 1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def reader(path):
    return StataReader(path, convert_dates=False, convert_categoricals=False,
                       convert_missing=True, preserve_dtypes=True, chunksize=CHUNK)


def source_schema(path):
    with reader(path) as r:
        # initialize header metadata without changing or reading the source data
        r.variable_labels()
        schema = [{'name': name, 'stata_storage': storage,
                   'numeric_dtype': NUMERIC_TYPES.get(storage),
                   'display_format': fmt, 'variable_label': label, 'value_label_name': label_name}
                  for name, storage, fmt, label, label_name in zip(r._varlist, r._typlist, r._fmtlist, r._variable_labels, r._lbllist)]
        labels = {group: {str(int(code)): label for code, label in mapping.items()}
                  for group, mapping in r.value_labels().items()}
        return schema, int(r._nobs), labels


def number_text(value):
    if isinstance(value, StataMissingValue):
        return '' if str(value) == '.' else str(value)
    if isinstance(value, (int, np.integer)):
        return str(value)
    return format(float(value), '.17g')


def compare(path, csv_path, schema, strict_double=False):
    """Compare rows/columns, strings, missing codes and exact stored numeric values."""
    if not Path(csv_path).is_file():
        return {'ok': False, 'reason': 'missing_csv'}
    rows = 0
    bad = {}
    try:
        with reader(path) as src, pd.read_csv(csv_path, dtype=str, keep_default_na=False,
                                            na_filter=False, chunksize=CHUNK, encoding='utf-8-sig') as dst:
            for original in src:
                copied = next(dst, None)
                if copied is None or copied.shape != original.shape or list(copied.columns) != list(original.columns):
                    return {'ok': False, 'reason': 'shape_or_columns', 'rows_checked': rows}
                for col in schema:
                    name = col['name']
                    a = original[name]
                    b = copied[name]
                    dtype = col['numeric_dtype']
                    if dtype is None:
                        good = a.to_numpy(dtype=str) == b.to_numpy(dtype=str)
                    else:
                        if pd.api.types.is_numeric_dtype(a.dtype):
                            missing = np.zeros(len(a), dtype=bool)
                            av = a.to_numpy(dtype=np.float64)
                        else:
                            missing = a.map(lambda v: isinstance(v, StataMissingValue)).to_numpy()
                            av = np.empty(len(a), dtype=np.float64)
                            av[~missing] = a.loc[~missing].to_numpy(dtype=np.float64)
                        good = np.ones(len(a), dtype=bool)
                        if missing.any():
                            wanted = a.loc[missing].map(number_text).to_numpy(dtype=str)
                            good[missing] = wanted == b.loc[missing].to_numpy(dtype=str)
                        tokens = b.loc[~missing].to_numpy(dtype=str)
                        try:
                            bv = tokens.astype(np.float64)
                            if not strict_double and dtype == 'float32':
                                bv = bv.astype(np.float32).astype(np.float64)
                            good[~missing] = av[~missing] == bv
                        except (ValueError, OverflowError):
                            good[~missing] = False
                    if not np.all(good):
                        n = int(np.count_nonzero(~good))
                        entry = bad.setdefault(name, {'count': 0, 'first_row': rows+int(np.flatnonzero(~good)[0])+1,
                                                       'source': str(a.iloc[np.flatnonzero(~good)[0]]),
                                                       'csv': str(b.iloc[np.flatnonzero(~good)[0]])})
                        entry['count'] += n
                rows += len(original)
            if next(dst, None) is not None:
                return {'ok': False, 'reason': 'extra_csv_rows', 'rows_checked': rows}
        return {'ok': not bad, 'rows_checked': rows, 'mismatches': bad}
    except Exception as e:
        return {'ok': False, 'reason': repr(e), 'rows_checked': rows}


def write_csv(path, destination, schema):
    destination.parent.mkdir(parents=True, exist_ok=True)
    first = True
    with reader(path) as src, destination.open('w', encoding='utf-8', newline='') as stream:
        for chunk in src:
            for col in schema:
                name = col['name']
                if col['numeric_dtype'] is not None and not pd.api.types.is_numeric_dtype(chunk[name].dtype):
                    chunk[name] = chunk[name].map(number_text)
            chunk.to_csv(stream, index=False, header=first, float_format='%.17g', lineterminator='\n')
            first = False
        if first:
            pd.DataFrame(columns=[s['name'] for s in schema]).to_csv(stream, index=False, lineterminator='\n')


def work(task):
    source_root, existing_root, output_root, relative, verify_only, previous = task
    start = time.time()
    original = Path(source_root)/relative
    existing = Path(existing_root)/Path(relative).with_suffix('.csv')
    destination = Path(output_root)/Path(relative).with_suffix('.csv')
    schema, expected_rows, labels = source_schema(original)
    source_hash = sha256(original)
    before_hash = sha256(existing) if existing.exists() else None
    if previous is not None:
        prior_output = destination if previous['regenerated'] else existing
        if (previous['after']['ok'] and source_hash == previous['source_sha256']
                and before_hash == previous['previous_csv_sha256'] and prior_output.is_file()
                and sha256(prior_output) == previous['csv_sha256']):
            return {**previous, 'schema':schema, 'value_labels':labels,
                    'resumed_from_validated_hashes':True, 'seconds':time.time()-start}
    before = compare(original, existing, schema)
    changed = False
    if before['ok'] or verify_only:
        after = before
        final = existing
    else:
        write_csv(original, destination, schema)
        after = compare(original, destination, schema, strict_double=True)
        final = destination
        changed = True
    if sha256(original) != source_hash:
        raise RuntimeError(f'Source changed during conversion: {original}')
    if not after['ok'] or after['rows_checked'] != expected_rows:
        if not verify_only:
            raise RuntimeError(f'Validation failed: {relative}: {after}')
    return {'source': relative, 'csv': Path(relative).with_suffix('.csv').as_posix(),
            'rows': expected_rows, 'columns': len(schema), 'regenerated': changed,
            'source_sha256': source_hash, 'previous_csv_sha256': before_hash,
            'csv_sha256': sha256(final), 'csv_bytes': final.stat().st_size,
            'before': before, 'after': after, 'schema': schema, 'value_labels': labels,
            'seconds': time.time()-start}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--existing', type=Path)
    parser.add_argument('--report', type=Path)
    parser.add_argument('--jobs', type=int, default=4)
    parser.add_argument('--verify-only', action='store_true')
    parser.add_argument('--resume-report', type=Path,
                        help='Reuse completed validation only when raw, previous CSV and output hashes still match.')
    args = parser.parse_args()
    source = args.source.resolve()
    output = args.output.resolve()
    existing = (args.existing or args.output).resolve()
    previous = {}
    if args.resume_report:
        earlier = json.loads(args.resume_report.read_text(encoding='utf-8'))
        if (Path(earlier['source_root']).resolve()!=source or Path(earlier['existing_root']).resolve()!=existing
                or Path(earlier['output_root']).resolve()!=output or earlier['verify_only']!=args.verify_only):
            parser.error('Resume report roots/mode must match this invocation.')
        previous = {row['source']:row for row in earlier['files']}
    if source == output or source in output.parents or output in source.parents:
        parser.error('Source and output must be separate directories.')
    if args.jobs < 1:
        parser.error('--jobs must be positive')
    if any(part.lower() == 'revision3' for p in [output, args.report or output] for part in p.parts):
        parser.error('Revision3 is protected and cannot be an output location.')
    start = time.time()
    report = {'started_utc': datetime.now(timezone.utc).isoformat(), 'source_root': str(source),
              'existing_root': str(existing), 'output_root': str(output),
              'verify_only': args.verify_only, 'python': platform.python_version(),
              'pandas': pd.__version__, 'numpy': np.__version__, 'jobs': args.jobs,
              'encoding': 'UTF-8', 'float_format': '%.17g',
              'numeric_values': 'Stored values, not display formats or value-label substitutions; dates retain their numeric Stata representation.',
              'missing_values': 'Standard numeric missing is empty; extended .a through .z are literal tokens. Empty strings remain empty.',
              'validation': 'Row/column order, strings and missing codes exactly; numeric values at original float32/float64 storage precision. Newly written files also compare exactly after promotion to float64.',
              'files': []}
    report_path = args.report or output/'stata_csv_validation.json'
    report_path.parent.mkdir(parents=True, exist_ok=True)
    if args.resume_report:
        report['resumed_from_report'] = str(args.resume_report)
        report['original_started_utc'] = earlier.get('original_started_utc',earlier['started_utc'])
    tasks = [(str(source),str(existing),str(output),p.relative_to(source).as_posix(),args.verify_only,
              previous.get(p.relative_to(source).as_posix()))
             for p in sorted(source.rglob('*.dta'))]
    with ProcessPoolExecutor(max_workers=args.jobs) as pool:
        pending = [pool.submit(work, t) for t in tasks]
        for future in as_completed(pending):
            row = future.result()
            report['files'].append(row)
            report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
            print(f"{len(report['files'])}/{len(tasks)} {row['source']}: {'REGENERATED' if row['regenerated'] else 'CHECKED'} {row['after']['ok']}", flush=True)
    report['files'].sort(key=lambda row: row['source'])
    report['finished_utc'] = datetime.now(timezone.utc).isoformat()
    report['seconds'] = time.time()-start
    report['summary'] = {'files_checked': len(tasks), 'files_regenerated': sum(x['regenerated'] for x in report['files']),
                         'rows_checked': sum(x['rows'] for x in report['files']),
                         'all_pass': all(x['after']['ok'] for x in report['files'])}
    report_path.write_text(json.dumps(report, indent=2, ensure_ascii=False), encoding='utf-8')
    print(json.dumps(report['summary']), flush=True)
    if not report['summary']['all_pass']:
        raise SystemExit(1)


if __name__ == '__main__':
    main()
