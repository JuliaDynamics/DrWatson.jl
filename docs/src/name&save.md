# Naming & Saving Simulations

This page discusses numerous tools that make life easier for handling simulations. Most (if not all) of these tools are also used in the examples demonstrated in the [Real World Examples](@ref) page. After reading the proper documentation here it might be worth it to have a look there as well!

!!! info "We use `FileIO`"
    For saving and loading files we use `FileIO.save` and `FileIO.load`. This means that you have to install yourself whatever saving backend you want to use. `FileIO` by itself does _not_ install a package that saves data, it only provides the interface!

## Naming Schemes

A robust naming scheme allows you to create quick names for simulations, create lists of simulations, check existing simulations, etc. More importantly it allows you to easily read and write simulations using a consistent naming scheme.

```@docs
savename
@dict
@strdict
@ntuple
```

Notice that this naming scheme integrates perfectly with Parameters.jl.

Two convenience functions are also provided to easily switch between named tuples and dictionaries:
```@docs
ntuple2dict
dict2ntuple
```

## Customizing `savename`
You can customize [`savename`](@ref) for your own Types. For example you could make it so that it only uses some specific keys instead of all of them, only specific types, or you could make it access data in a different way (maybe even loading files!). You can even make it have
a custom `prefix`!

To do that you may extend the following functions:
```@docs
DrWatson.allaccess
DrWatson.access
DrWatson.default_allowed
DrWatson.default_prefix
```

See [Real World Examples](@ref) for an example of customizing `savename`.

## Tagging a run using Git
For reproducibility reasons (and also to not go insane when asking "HOW DID I GET THOSE RESUUUULTS") it is useful to "tag!" any simulation/result/process with the Git commit of the repository.

To this end there are two functions that can be used to ensure reproducibility:

```@docs
current_commit
tag!
```

Please notice that `tag!` will operate in place only when possible. If not possible then a new dictionary is returned. Also (importantly) these functions will **never error** as they are most commonly used when saving simulations and this could risk data not being saved.

### Automatic Tagging during Saving

If you don't want to always call `tag!` before saving a file, you can just use the function `tagsave`:
```@docs
tagsave
```

## Produce or Load
`produce_or_load` is a function that very conveniently integrates with [`savename`](@ref) to either load a file if it exists, or if it doesn't to produce it, save it and then return it!

This saves you the effort of checking if a file exists and then loading, or then running some code and saving, or writing a bunch of `if` clauses in your code! `produce_or_load` really shines when used in interactive sessions where some results require a couple of minutes to complete.

```@docs
produce_or_load
```
