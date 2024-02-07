# Running & Listing Simulations

## Preparing Simulation Runs
It is very often the case that you want to run "batch simulations", i.e. just submit a bunch of different simulations, all using same algorithms and code but just different parameters. This scenario always requires the user to prepare a set of simulation parameter containers which are then passed into some kind of "main" function that starts the simulation.

To make the preparation part simpler we provide the following functionality:

```@docs
dict_list
dict_list_count
@onlyif
Derived
```

Using the above function means that you can write your "preparation" step into a single dictionary and then let it automatically expand into many parameter containers. This keeps the code cleaner but also consistent, provided that it follows one simple rule: **Anything that is a `Vector` has many parameters, otherwise it is one parameter**. [`dict_list`](@ref) considers this true irrespectively of what the `Vector` contains. This allows users to use any iterable custom type as a single "parameter" of a simulation.

See the [Preparing & running jobs](@ref) for a very convenient application!

## Saving Temporary Dictionaries
The functionality of [`dict_list`](@ref) is great, but can fall short in cases of submitting jobs to a computer cluster. For typical clusters that use `qsub` or `slurm`, each run is submitted to a different Julia process and thus one cannot propagate a Julia in-memory `Dict` (in the case of being already on a machine with a connected and massive amount of processors/nodes, simply using `pmap` is fine).

To balance this, we have here some simple functionality that stores the result of [`dict_list`](@ref) (or any other dictionary collection, really) to files with temporary names. The names are returned and can then be propagated into a `main`-like Julia process that can take the temp-name as an input, load the dictionary and then extract the data.
```@docs
tmpsave
```
An example usage is shown in [Using a Serial Cluster](@ref).

## Collecting Results
There are cases where you have saved a bunch of simulation results in a bunch of different files in a folder. It is useful to be able to collect all of these results into a single table, in this case a `DataFrame`. The function [`collect_results!`](@ref) provides this functionality. Importantly, the function is "future-proof" which means that it works nicely even if you add new parameters or remove old parameters from your results as your project progresses!

```@docs
collect_results!
collect_results
```

For an example of using this functionality please have a look at the [Real World Examples](@ref) page!
