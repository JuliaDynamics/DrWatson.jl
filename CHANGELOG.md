# 0.7.0
* New macro `@savename` that is a shortcut for `savename(@dict vars...)`
* New function `gitdiscribe` (see below)
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
