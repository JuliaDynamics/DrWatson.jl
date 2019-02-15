# Handling Simulations

## Naming Schemes

A robust naming scheme allows you to create quick names for simulations, create lists of simulations, check existing simulations, etc.

```@docs
savename
@dict
@ntuple
```

Notice that the naming scheme integrates perfectly with Parameters.jl.

### Customizing `savename`
You can customize [`savename`](@ref) for your own Types. For example you could make it so that it only uses some specific keys instead of all of them, or you could make it access data in a different way (maybe even loading files!).

To do that you need to extend the following two functions:
```@docs
DrWatson.allaccess
DrWatson.access
```

## Creating Run Tables

WIP. (Adding simulation runs to a table/csv/dataframe)

## Produce or Load
WIP. (loading a simulation or producing it if it doesn't exist)
