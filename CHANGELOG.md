# 1.16.7
* Fix `dict_list_count` returns wrong number of elements with `@onlyif`. (#223)
* Fix `gitpatch` for git versions not supporting submodules. (#224)
# 1.16.6
* `@onlyif` now doesn't expand vector arguments if it's placed inside another vector. (#209)
* `@onlyif` now supports chaining. See real world examples: "Defining parameter sets with restrictions". (#210)
# 1.16.5
* The patch information for a dirty repository now also contains the diff for submodules.
# 1.16.1
* `dict_list` now retains the value's type from the passed dictionary.
# 1.16.0
* Add a `sort` option to `savename`.
# 1.15.0
* Better default readme file for a new project.
# 1.14.6
* new keyword argument `rpath` for `collect_results!` that allows storing relative paths
# 1.14.0
* New macro `@onlyif` that allows placing restrictions on values in a dictionary used for expansion with `dict_list`
# 1.13.1
* `gitpach` now shows a warning if `git` was not found in PATH
# 1.13.0
* `savename` now includes `TimeType` (dates) in the default allowed types.
# 1.12.0
* `wsave/wload` now support keyword arguments.
# 1.11.0
* Macros `@pack!, @unpack` are re-exported by DrWatson.

# 1.10.0
* New function `struct2ntuple` that converts a struct to a NamedTuple (for saving)

# 1.9.0
* `savename` now has the `ignore` option.

# 1.8.0
* `@quickactivate` was enhanced to allow projects that also represent a module.
* `initialize_project` no resolves the folder name for naming the project if the path is given as "." or ".."

# 1.7.0
* Improve the introductory file created by DrWatson.

# 1.6.2
* `@tag!` and `@tagsave` now support using `;` as keywords separator (#111)

# 1.6.0
* `quickactivate` doesn't do anything anymore if you try to activate to already active project.
* New macro `@quickactivate`

# 1.5.0
* Started to add support for overloading save/load for custom files. See the updated docs around `wsave` and `wload`.

# 1.4.1
* Fix a bug that created incompatible version strings in generated `Project.toml` files on release candidate versions of Julia.

# 1.4.0
* `savename` now supports rounding to significant digits with the keyword argument `scientific`, where `scientific` defines the number of significant digits.
# 1.3.0
* `initialize_project` now adds a Julia version under `compat` in the created `Project.toml` when it is called.
* The functions `tag!, tagsave` and their respective macros now obtain their arguments (besides the first two) as keywords instead of positional arguments. The positional versions are deprecated (#93).
* New keyword `force = false` for `tag!` and co. which replaces the existing `gitcommit` field.

# 1.2.0
* Improved behavior of `savename` with respect to nested containers. If a nested container is empty, it is not printed instead. For example, `T=100_p=()_x=2` now becomes `T=100_x=2`. (if `p` is not empty then it is expanded as usual)

# 1.1.0
* `initialize_project` no longer makes a test directory.

# 1.0.1
* Allow `tag!` and derivatives to handle dictionaries with *key type* `Any`.
# 1.0.0
First major release (no notable change from 0.8.0).

# 0.8.0
* **[BREAKING]** : The `gitpath` argument used among many functions
  can now also point to a subdirectory within a git repository.
  Previously it had to be the top directory (i.e. the one containing
  `.git/`).
* **[BREAKING]** : Slightly changed how `produce_or_load` uses `path` and interacts with `savename`, to better incorporate the changes done in version 0.6.0. `prefix` is now also supported.
* `tag!` and co now also store the git diff patch if the repo is dirty, see `gitpatch` (#80).
* **[BREAKING]** : `tag!` now saves the commit information into a field `gitcommit` instead of just `commit`.

# 0.7.1
* `projectdir()` now warns if no project (other than the standard one) is
  active

# 0.7.0
* New macro `@savename` that is a shortcut for `savename(@dict vars...)`
* New function `gitdescribe` (see below)
* **[DEPRECATED]** `current_commit()` has been deprecated and replaced by
  `gitdescribe()` which now replaces the output of `git describe` if an
  annotated tag exists, otherwise it will return the latest commit hash.

# 0.6.0
* **[BREAKING]** Reworked the way the functions `projectdir` and derivatives work (#47, #64, #66). Now `projectdir(args...)` uses `joinpath` to connect arguments. None of the functions like `projectdir` and derivatives now end in `/` as well, to ensure more stability and motivate users to use `joinpath` or the new functionality of `projectdir(args...)` instead of using string multiplication `*`.
* New function `parse_savename` that attempts to reverse engineer the result of `savename`.

# 0.5.1
* Improvements to `.gitignore` (#55 , #54)
# 0.5.0
This release has **breaking changes**.
* Adjusted return value of `produce_or_load` (#52). It now always return the file and the path it is saved. If `loadfile = false` it returns `nothing, path`.
* The functionality of `default_prefix` has been modified (#51). Now there is a nice interplay between defining a `default_prefix` *and* passing a prefix to `savename`. They are merged like `joinpath(prefix, default_prefix)`. This is valid only when `default_prefix` has a value other than `""` (the default).
# 0.4.0
* Add expand functionality to `savename`, which handles better containers with nested containers (#50)
* `produce_or_load` now allows the possibility of not loading the file
* New function `struct2dict` that converts a struct to a dictionary (for saving)
# 0.3.0
* Added `test` as a directory of the default project (#43)
* Added `tmpsave` functionality: save the result of `dict_list` in temporary files and conveniently work with sequential clusters (#45)
* Now all saving related functions of DrWatson first `mkpath` of the path to save at and then save (#45)
# 0.2.1
* Improve type-stability of return value of `dict_list` (#41)
# 0.2.0
* Changed `path` and `projectpath` arguments of various functions (e.g. `tagsave`, `current_commit`) to `gitpath` universally.
* make keyword arguments of `tagsave` positional arguments instead (to work with the macros)
* Added two new macros: `@tag!` and `@tagsave`: these do the same thing as `tag!, tagsave` but in addition are able to record both the script name that called them as well as the line of code that they were called at.
# 0.1.0
This is the first beta release! Changelog is kept with respect to here!
