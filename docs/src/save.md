# Saving Tools
This page discusses numerous tools that can significantly improve process of saving & loading files, always in a scientific context.

These tools are also used in the examples demonstrated in the [Real World Examples](@ref) page. After reading the proper documentation here it might be worth it to have a look there as well!

In DrWatson we save and load files with the functions `wsave(filename, data)` and `wload(filename)`. These functions are further used in the tools below, like e.g. [`tagsave`](@ref) and can be overloaded for your own specific datatype.

In addition, `wsave` **ensures** that `mkpath` is always called on the path you are trying to save your file at. We all know how unpleasant it is to run a 2-hour simulation and save no data because `FileIO.save` complains that the path you are trying to save at does not exist...

To overload the saving part, add a new method to `DrWatson._wsave(filename, ::YourType, args...; kwargs...)` (notice the `_`!). By overloading `_wsave` you get all the extra functionality of [`tagsave`](@ref), [`safesave`](@ref), etc., for free for your own types (`tagsave` requires that you save your data as a dictionary, or extend [`tag!`](@ref) for your own type).

!!! warning "Saving and loading fallback"
    By default we fallback to `FileIO.save` and `FileIO.load` for and types.
    This means that you have to install yourself whatever saving backend you want to use.
    `FileIO` by itself does _not_ install a package that saves data, it only provides the interface!

    The *suffix* of the file name determines which package will be used for actually saving the file. It is **your responsibility** to know how the saving package works and what input it expects!


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
isdirty
```

Please notice that `tag!` will operate in place only when possible. If not possible then a new dictionary is returned. Also (importantly) these functions will **never error** as they are most commonly used when saving simulations and this could risk data not being saved!

## Produce or Load

`produce_or_load` is a function that very conveniently integrates with [`savename`](@ref) to either load a file if it exists, or if it doesn't to produce it, save it and then return it!

This saves you the effort of checking if a file exists and then loading, or then running some code and saving, or writing a bunch of `if` clauses in your code.
In addition, it attempts to minimize computing energy spent on getting a result.

```@docs
produce_or_load
@produce_or_load
istaggable
```

See [Stopping "Did I run this?"](@ref) for an example usage of `produce_or_load`. While `produce_or_load` will try to by default tag your data if possible, you can also use it with other formats. An example is when your simulation function `f` returns a `DataFrame` and the file suffix is `"csv"`. In this case tagging will not happen, but `produce_or_load` will work as expected.


## Converting a struct to a dictionary
[`savename`](@ref) gives great support for getting a name out of any Julia composite type. To save something though, one needs a dictionary. So the following function can be conveniently used to directly save a struct using any saving function:
```@docs
struct2dict
struct2ntuple
```
