################################################################################
#                          Backup files before saving                          #
################################################################################

# Implementation inspired by behavior of GROMACS
#take a path of a results file and increment its prefix backup number
function increment_backup_num(filepath)
    path, filename = splitdir(filepath)
    fname, suffix = splitext(filename)
    m = match(r"^(.*)_#([0-9]+)$", fname)
    if m == nothing
        return joinpath(path, "$(fname)_#1$(suffix)")
    end
    newnum = string(parse(Int, m.captures[2]) +1)
    return joinpath(path, "$(m.captures[1])_#$newnum$(suffix)")
end

#recursively move files to increased backup number
function recursively_clear_path(cur_path)
    isfile(cur_path) || return
    new_path=increment_backup_num(cur_path)
    if isfile(new_path)
        recursively_clear_path(new_path)
    end
    mv(cur_path, new_path)
end

"""
    safesave(filename, data)

A wrapper around FileIO.save that ensures no existing files are overwritten.
If a file with name `filename` such as `test.bson` already exists
it will be renamed to `test_#1.bson` before the new data is written
to `test.bson`.
It recursively makes sure that no existing backups are overwritten
by increasing the backup-number:
`test.bson → test_#1.bson → test_#2.bson → ...`
"""
function safesave(f, data)
    recursively_clear_path(f)
    FileIO.save(f,data)
end
