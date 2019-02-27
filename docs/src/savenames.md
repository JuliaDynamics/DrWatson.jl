# Naming & Saving Simulations

This page discusses numerous tools that make life easier for handling simulations. Most (if not all) of these tools are also used in the examples demonstrated in the [`Real World Examples`](@ref) page. After reading the proper documentation here it might be worth it to have a look there as well!

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

## Tagging a run using Git
For reproducibility reasons (and also to not go insane when asking "HOW DID I GET THOSE RESUUUULTS") it is useful to "tag!" any simulation/result/process with the Git commit of the repository.

To this end there are two functions that can be used to ensure reproducibility:

```@docs
current_commit
tag!
```

Please notice that `tag!` will operate in place only when possible. If not possible then a new dictionary is returned. Also (importantly) these functions will **never error** as they are most commonly used when saving simulations and this could risk data not being saved.

### Automatic Tagging during Saving

WIP. (adding the `tag!` functionality automatically with a `save` call)

## Produce or Load
WIP. (loading a simulation or producing it if it doesn't exist)
