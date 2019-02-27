# Running & Listing Simulations

## Preparing Simulation Runs
It is very often the case that you want to run "batch simulations", i.e. just submit a bunch of different simulations, all using same algorithms and code but just different parameters. This scenario always requires the user to prepare a set of simulation parameter containers which are then passed into some kind of "main" function that starts the simulation.

To make the preparation part simpler we provide the following functionality:
```@docs
dict_list
dict_list_count
```

Using the above function means that you can write your "preparation" step into a single dictionary and then let it automatically expand into many parameter containers. This keeps the code cleaner but also consistent, provided that it follows one rule: **Anything that is a `Vector` has many parameters, otherwise it is one parameter**. [`dict_list`](@ref) considers this true irrespectively of what the `Vector` contains. This allows users to use any iterable custom type as a single "parameter" of a simulation.

See the [`Real World Examples`](@ref) for a very convenient application!

## Simulation Tables

WIP. (Adding simulation runs to a table/csv/dataframe)
