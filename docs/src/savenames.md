# Handling Simulations

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
ntupled2dict
dict2ntuple
```

### Customizing `savename`
You can customize [`savename`](@ref) for your own Types. For example you could make it so that it only uses some specific keys instead of all of them, or you could make it access data in a different way (maybe even loading files!).

To do that you need to extend the following two functions:
```@docs
DrWatson.allaccess
DrWatson.access
```

## Tagging a run using Git
For reproducibility reasons (and also to not go insane when asking "HOW DID I GET THOSE RESUUUULTS") it is useful to "tag" any simulation/result/process with the Git commit of the repository.

To this end there are two functions that can be used to ensure reproducibility:

```@docs
current_commit
tag
```

Please notice that `tag` will operate in place (if-possible) even if its name does not end with `!`. Also (importantly) these functions will **never error** as they are most commonly used when saving simulations and this could risk data not being saved.

### Automatic Tagging during Saving

WIP. (adding the `tag` functionality automatically with a `save` call)

## Preparing Simulation Runs
It is very often the case that you want to run "batch simulations", i.e. just submit a bunch of different simulations, all using same algorithms and code but just different parameters. This scenario always requires the user to prepare a set of simulation parameter containers which are then passed into some kind of "main" function that starts the simulation.

To make the preparation part simpler we provide the following functionality:
```@docs
dict_list
```

Using the above function means that you can write your "preparation" step into a single dictionary and then let it automatically expand into many parameter containers.

## Simulation Tables

WIP. (Adding simulation runs to a table/csv/dataframe)

## Produce or Load
WIP. (loading a simulation or producing it if it doesn't exist)
