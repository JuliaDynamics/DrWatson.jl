# Saving Tools
This page discusses numerous tools that can significantly improve process of saving & loading files, always in a scientific context.

These tools are also used in the examples demonstrated in the [Real World Examples](@ref) page. After reading the proper documentation here it might be worth it to have a look there as well!

!!! info "We use `FileIO`"
    For saving and loading files we use `FileIO.save` and `FileIO.load`. This means that you have to install yourself whatever saving backend you want to use. `FileIO` by itself does _not_ install a package that saves data, it only provides the interface!

    In addition, DrWatson re-exports `FileIO.save` and `FileIO.load` for convenience!

!!! info "We always call `mkpath`"
    All functions of DrWatson that save things, e.g. [`tagsave`](@ref), [`safesave`](@ref), [`tmpsave`](@ref) etc. always call `mkpath` first on the directory the file needs to be saved at. This is not the case for the standard `save` function, as it comes from `FileIO`.

## Converting a struct to a dictionary
[`savename`](@ref) gives great support for getting a name out of any Julia composite type. To save something though, one needs a dictionary. So the following function can be conveniently used to directly save a struct using any saving function:
```@docs
struct2dict
```

## Safely saving data
Almost all packages that save data by default overwrite existing files (if given a save name of an existing file). This is the default behavior because often it is desired.

Sometimes it is not though! And the consequences of overwritten data can range from irrelevant to catastrophic. To avoid such an event we provide an alternative way to save data that will never overwrite existing files:
```@docs
safesave
```

## Tagging a run using Git
For reproducibility reasons (and also to not go insane when asking "HOW DID I GET THOSE RESUUUULTS") it is useful to "tag" any simulation/result/process using the Git status of the repository.

To this end we have some functions that can be used to ensure reproducibility:
```@docs
tagsave
@tagsave
```
The functions also incorporate [`safesave`](@ref) if need be.

### Low level functions
[`@tagsave`](@ref) internally uses the following low level functions:
```@docs
tag!
@tag!
gitdescribe
DrWatson.gitpatch
```

Please notice that `tag!` will operate in place only when possible. If not possible then a new dictionary is returned. Also (importantly) these functions will **never error** as they are most commonly used when saving simulations and this could risk data not being saved!


## Produce or Load

`produce_or_load` is a function that very conveniently integrates with [`savename`](@ref) to either load a file if it exists, or if it doesn't to produce it, save it and then return it!

This saves you the effort of checking if a file exists and then loading, or then running some code and saving, or writing a bunch of `if` clauses in your code! `produce_or_load` really shines when used in interactive sessions where some results require a couple of minutes to complete.

```@docs
produce_or_load
```
