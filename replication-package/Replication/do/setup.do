* Initialize paths from the current Replication package root.
* Run once before standalone scripts; do/main.do calls this automatically.
* This file validates paths only: it does not create directories or outputs.

* Clear any earlier root before checking the newly selected directory.
global path ""
local _ls_path_root = subinstr("`c(pwd)'", char(92), "/", .)
foreach _ls_path_marker in "do/main.do" "do/setup.do" "do/data_cleaning/model_inputs.do" "quant_model/main.jl" {
    capture confirm file "`_ls_path_marker'"
    if _rc {
        display as error "Change to the complete Replication package root and rerun do/setup.do."
        display as error "Missing required file: `_ls_path_marker'"
        exit 601
    }
}
global path "`_ls_path_root'"
