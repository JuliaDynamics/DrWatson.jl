export collect_results, collect_results!

"""
    collect_results!([filename,] folder; kwargs...) -> df

!!! note "Requires `DataFrames`"
    The function `collect_results!` is only available if you do
    `using DataFrames` in your Julia session.

Search the `folder` (and possibly all subfolders) for new result-files and add
them to `df` which is a `DataFrame` containing all the information from
each result-file.
If a result-file is missing keys that are already columns in `df`,
they will be set as `missing`. If on the other hand new keys are encountered,
a new column will be added and filled with `missing` for all previous entries.

If no file exists in `filename`, then `df` will be saved there. If however
`filename` exists, the existing `df` will be first loaded and then reused.
The reused `df` has some results already collected: files already
included in `df` are skipped in subsequent calls to `collect_results!` while
new result-files are simply appended to the dataframe.

`filename` defaults to:
```julia
filename = joinpath(dirname(folder), "results_\$(basename(folder)).jld2")
```

See also [`collect_results`](@ref).

!!! warning "Don't use `:path` as a parameter name."
    `df` contains a column `:path` which is the path where each result-file
    is saved to. This is used to not reload and reprocess files already
    present in `df` when searching for new ones.

## Keyword Arguments
* `subfolders::Bool = false` : If `true` also scan all subfolders of `folder`
  for result-files.
* `valid_filetypes = [".bson", ".jld", ".jld2"]`: Only files that have these
  endings are interpreted as result-files. Other files are skipped.
* `rpath = nothing` : If not `nothing`, then it must be a path to a folder. The `path`
  column of the result-files is then `relpath(file, rpath)`, instead of the absolute
  path, which is used by default.
* `verbose = true` : Print (using `@info`) information about the process.
* `update = false` : Update data from modified files and remove entries for deleted
  files.
* `rinclude = [r\"\"]` : Only include files whose name matches any of these Regex expressions. Default value includes all files.
* `rexclude = [r\"^\\b\$\"]` : Exclude any files whose name matches any of these Regex expressions. Default value does not exclude any files.
* `white_list` : List of keys to use from result file. By default
  uses all keys from all loaded result-files.
* `black_list = [:gitcommit, :gitpatch, :script]`: List of keys not to include from result-file.
* `special_list = []`: List of additional (derived) key-value pairs
  to put in `df` as explained below.
*  `load_function = wload`: Load function. Defaults to `wload`. You may want to specify a custom load function for example if you store results as a struct and you want the fields of the struct to form the columns of the dataframe. The struct is saved to file as a one-element dictionary so the dataframe will only have a single column. To work around this you could convert it to a dictionary by specifying `load_function = (filename) -> struct2dict(wload(filename)["mykey"])`. This way `collect_results` will receive a `Dict` whose keys are the fields of the struct.

`special_list` is a `Vector` where each entry
is a derived quantity to be included in `df`. There are two types of entries.
The first option is of the form `key => func` where the `key` is a symbol
to be used as column name in the DataFrame. The function entry always
takes a single argument, which is the loaded result-file (a dictionary).
The second option is to provide just one function `func`. This function
also takes the single dictionary argument but returns one or more
`key => value` pairs. This second notation may be useful when one wants
to extract values for multiple columns in a single step.
As an example consider that each result-file
contains a field `:longvector` too large to be included in the `df`.
The quantity of interest is the mean and the variance of said field.
To have these values in your results first use `black_list = [:longvector]`
and then define

    special_list = [ :lv_mean => data -> mean(data[:longvector]),
                     :lv_lar  => data -> var(data[:longvector]) ]

In case this operation fails the values will be treated as `missing`.
"""
function collect_results! end

"""
    collect_results(folder; kwargs...) -> df
Do exactly the same as [`collect_results!`](@ref) but don't care to
load (or later save) an existing dataframe. Thus all found results files
are processed.
"""
function collect_results end

struct InvalidResultsCollection <: Exception
    msg::AbstractString
end
Base.showerror(io::IO, e::InvalidResultsCollection) = print(io, e.msg)
