# Real World Examples

## Easy local directories
I setup all my science projects using DrWatson's suggested setup, using [`initialize_project`](@ref). Then, every file in every project has a start that looks like this:
```julia
using DrWatson
@quickactivate "MagneticBilliardsLyapunovs"
using DynamicalBilliards, GLMakie, LinearAlgebra

include(srcdir("plot_perturbationgrowth.jl"))
include(srcdir("unitcells.jl"))
```
In all projects I save data/plots using `datadir/plotsdir`:
```julia
@tagsave(datadir("mushrooms", "Λ_N=$N.jld2"), (@strdict(Λ, Λσ, ws, hs, description)))
```
The advantage of this approach is that it will always work regardless of if I move the specific file to a different subfolder (which is very often necessary) or whether I move the entire project folder somewhere else!
**Please be sure you have understood the caveat of using [`quickactivate`](@ref)!**

Here is an example from another project. You will notice that another advantage is that I can use identical syntax to access the data or source folders even though I have different projects!
```julia
using DrWatson
@quickactivate "EmbeddingResearch"
using Parameters
using TimeseriesPrediction, LinearAlgebra, Statistics

include(srcdir("systems", "barkley.jl"))
include(srcdir("nrmse.jl"))

# stuff...

save(datadir("sim", "barkley", "astonishing_results.jld2"), data)
```

## Making your project a usable module
For some projects, it is often the case that some packages and files from the source folder are loaded at the beginning of _every file of the project_.
For example, I have a project that I know that for _any_ script I will write, the first five lines will be:
```julia
using DrWatson
@quickactivate "AlbedoProperties"
using Dates, Statistics, NCDatasets
include(srcdir("core.jl"))
include(srcdir("style.jl"))
```
It would be quite convenient to group all of these commands into one file and instead load that file, for example do `include(srcdir("everything.jl"))` and all commands are in there.

We can do even better though! Because of the way Julia handles project and module paths, it is in fact possible to transform the currently active project into a usable module. If one defines inside the `src` folder a file `AlbedoProperties.jl` and in that file define a module `AlbedoProperties` (notice that these names must match _exactly_ the project name), then upon doing `using AlbedoProperties` Julia will in fact just bring this module into scope.

So what I end up doing (for some projects where this makes sense) is creating the aforementioned file and putting inside things like
```julia
module AlbedoProperties

using Reexport
@reexport using Dates, Statistics
using NCDatasets: NCDataset, dimnames, NCDatasets
export NCDataset, dimnames
include("core.jl") # this file now also has export statements
include("style.jl")

end
```
and then the header of all my files is transformed to
```julia
using DrWatson
@quickactivate :AlbedoProperties
```
which takes advantage of [`@quickactivate`](@ref)'s feature to essentially combine the commands `@quickactivate "AlbedoProperties"` and `using AlbedoProperties` into one.

## `savename` and tagging
The combination of using [`savename`](@ref) and [`tagsave`](@ref) makes it easy and fast to save output in a way that is consistent, robust and reproducible. Here is an example from a project:
```julia
using DrWatson
quickactivate(@__DIR__, "EmbeddingResearch")
using TimeseriesPrediction, LinearAlgebra, Statistics
include(srcdir("systems", "barkley.jl"))

ΔTs = [1.0, 0.5, 0.1] # resolution of the saved data
Ns = [50, 150] # spatial extent
for N ∈ Ns, ΔT ∈ ΔTs
    T = 10050 # we can offset up to 1000 units
    every = round(Int, ΔT/barkley_Δt)
    seed = 1111

    simulation = @ntuple T N ΔT seed
    U, V = barkley(T, N, every; seed = seed)

    @tagsave(
        datadir("sim", "bk", savename(simulation, "jld2")),
        @strdict U V simulation
    )
end
```
This saves files that look like:
```
path/to/project/data/sim/bk_N=50_T=10050_seed=1111_ΔT=1.jld2
```
and each file is a dictionary that has my data fields: `:U, :V, :simulation`, but also `:gitcommit, :script`. When I read this file I know exactly what was the source code that produced it (provided that I am not sloppy and commit code changes regularly :P).

## [Customizing `savename`](@id customizing_savename)
Here is a simple example for customizing [`savename`](@ref). We are using a common struct `Experiment` across different experiments with cats and mice.

We first define the relevant types.
```@example customizing
using DrWatson, Dates
using Base: @kwdef # for defining structs with keyword values

# Define a type hierarchy we use at experiments
abstract type Species end
struct Mouse <: Species end
struct Cat <: Species end

# @with_kw comes from Parameters.jl
@kwdef struct Experiment{S<:Species}
    n::Int = 50
    c::Float64 = 10.0
    x::Float64 = 0.2
    date::Date = Date(Dates.now())
    species::S = Mouse()
    scientist::String = "George"
end

e1 = Experiment()
e2 = Experiment(species = Cat())
```

For analyzing our experiments we need information about the species used, and to use multiple dispatch later on we decided to make this information associated with a Type. This is why we defined `Species`.

Now, we want to customize [`savename`](@ref). We start by extending [`DrWatson.default_prefix`](@ref):
```@example customizing
DrWatson.default_prefix(e::Experiment) = "Experiment_"*string(e.date)

savename(e1)
```
However this is not good enough for us, as the information about the species is not contained in [`savename`](@ref) and also the date information is duplicated.
We have to extend [`DrWatson.default_allowed`](@ref) to specify which data types should be extended in `savename`:
```@example customizing
DrWatson.default_allowed(::Experiment) = (Real, String, Species)

savename(e1)
```
To make printing of `Species` better we can extend `Base.string`, which is what DrWatson uses internally in [`savename`](@ref) to display values.
```@example customizing
Base.string(::Mouse) = "mouse"
Base.string(::Cat) = "cat"
savename(e1)
```

Lastly, let's say that the information of which scientist performed the experiment is not really relevant for `savename`. We can extend the last method, [`DrWatson.allaccess`](@ref):
```@example customizing
DrWatson.allaccess(::Experiment) = (:n, :c, :x, :species)
```
so that only those four fields will be used (notice that the `date` field is already used in `default_prefix`). We finally have:
```@example customizing
println( savename(e1) )
println( savename(e2) )
```

## `savename` and nested containers
In the case of user-defined structs and projects of significant complexity, it is often necessary that your "main" container has other containers as subfields.
`savename` can adapt to these situations as well.
Consider the following example, where I need a core struct that represents a spatiotemporal system, and its simulation:
```@example customizing
struct SpatioTemporalSystem
    model::String # system codeword
    N        # Integer or Tuple of integers: spatial extent
    Δt::Real # sampling time in real time units
    p        # parameters. nothing or Dict{Symbol}
end
const STS = SpatioTemporalSystem

struct SpatioTemporalTimeseries
    sts::STS
    T::Int       # total frame amount
    ic           # initial condition (matrix, string, seed)
    fields::Dict # resulting timeseries, dictionary of string to vector
end
const STT = SpatioTemporalTimeseries
```
For my use case, `p` can be `nothing` or it can be a dictionary itself, containing the possible parameters the spatiotemporal systems can have.
To adapt `savename` to situations like this, we use the functionality surrounding [`DrWatson.default_expand`](@ref).

Expanding the necessary methods allows me to do:
```@example customizing
DrWatson.allaccess(c::STS) = (:N, :Δt, :p)
DrWatson.default_prefix(c::STS) = c.model
DrWatson.default_allowed(c::STS) = (Real, Tuple, Dict, String)
DrWatson.default_expand(c::STS) = ["p"]

bk = STS("barkley", 60, 0.1, nothing)
savename(bk)
```
and when I do want to use different parameters than the default:
```@example customizing
a = 0.3; b = 0.5
bk = STS("barkley", 60, 0.1, @dict a b)
savename(bk)
```

Expanding to the second struct is also fine:
```@example customizing
DrWatson.default_prefix(c::STT) = savename(c.sts)
stt = STT(bk, 1000, nothing, Dict("U"=>rand(100), "V"=>rand(100)))
savename(stt)
```



## Stopping "Did I run this?"
It can become very tedious to have a piece of code that you may or may not have run and may or may not have saved the produced data. You then constantly ask yourself "Did I run this?". Depending on how costly running the code is, having a good framework to answer this question can become very important!

This is the role of [`produce_or_load`](@ref). You can wrap your code in a function and then [`produce_or_load`](@ref) will take care of the rest for you! I found it especially useful in scripts that generate figures for a publication.

Here is an example; originally I had this piece of code:
```julia
HTEST = 0.1:0.1:2.0
WS = [0.5, 1.0, 1.5]
N = 10000; T = 10000.0

toypar_h = [[] for l in WS]
for (wi, w) in enumerate(WS)
    println("w = $w")
    for h in HTEST
        toyp = toyparameters(h, w, N, T)
        push!(toypar_h[wi], toyp)
    end
end
```
that was taking some minutes to run. To use the function [`produce_or_load`](@ref) I first have to wrap this code in a high level function like so:
```julia
function simulation(config)
    HTEST = 0.1:0.1:2.0
    WS = [0.5, 1.0, 1.5]
    @unpack N, T = config
    toypar_h = [[] for _ in WS]

    for (wi, w) in enumerate(WS)
        println("w = $w")
        for h in HTEST
            toyp = toyparameters(h, w, N, T)
            push!(toypar_h[wi], toyp)
        end
    end
    return @strdict toypar_h
end

N = 2000; T = 2000.0
data, file = produce_or_load(
    datadir("mushrooms", "toy"), # path
    @dict(N, T), # container
    simulation; # function
    prefix = "fig5_toyparams" # prefix for savename
)
@unpack toypar_h = data
```
Now, every time I run this code block the function tests automatically whether the file exists. Only if it does not, then the code is run while the new result is saved to ensure I won't have to run it again.

The extra step is that I have to extract the useful data I need from the container `file`. Thankfully the [`@unpack`](@ref) macro, or if your are using Julia v1.5 or later, the named decomposition syntax, `(; a, b) = config`, makes unpacking super easy.

## `produce_or_load` with hash codes
As displayed above, the default setting of [`produce_or_load`](@ref) uses [`savename`](@ref) to extract the filename from the configuration input. This file name is used to check whether the program has run and its output has been saved or not. However, in some situations you may too many parameters, or complicated nested structs, and encoding these simply using [`savename`](@ref) is not possible or simply inconvenient.

Thankfully, instead of [`savename`](@ref) we can use base Julia's `hash` function as we will illustrate in the following example.

```@example customizing
using DrWatson
using Random

function sim_large_c(config)
    @unpack x, f = config
    r = sum(x)*f.a + f.t.b + f.t.c
    return @strdict(r)
end

## Some nested structs
f1 = (a = 1, t = (b = 2, c = 3))
f2 = (a = 2, t = (b = 4, c = 5))
## some containers with too many parameters
rng = Random.MersenneTwister(1234)
x1 = rand(Random.MersenneTwister(1234), 1000)
x2 = randn(Random.MersenneTwister(1234), 20)

preconfigs = Dict("x" => [x1, x2], "f" => [f1, f2])
configs = dict_list(preconfigs)

path = mktempdir()
pol_kwargs = (prefix = "sim_large_c", verbose = false, tag = false)

for config in configs
    produce_or_load(sim_large_c, config, path; pol_kwargs...)
end

readdir(path)
```
as you can see this is obviously useless :D `savename` didn't return
anything from the given `config` containers so all data had the same name.
Let's use `hash` instead:

```@example customizing
rm(joinpath(path, "sim_large_c.jld2"))
for config in configs
    produce_or_load(sim_large_c, config, path; filename = hash, pol_kwargs...)
end
readdir(path)
```
Lovely. But, just to be on the safe side, if we use a different input `x`
but of same type and size would we get a different file name (as desired)?

```@example customizing
config = Dict("x" => rand(Random.MersenneTwister(4321)), "f" => f1)
produce_or_load(sim_large_c, config, path; filename = hash, pol_kwargs...)
readdir(path)
```
yes.
But, if we used exactly the same numbers and function, would it yield exactly the
same hash code, and hence, not rerun the simulation (as desired)?

```@example customizing
config = Dict("x" => rand(Random.MersenneTwister(1234), 1000), "f" => f1)
produce_or_load(sim_large_c, config, path; filename = hash, pol_kwargs...)
readdir(path)
```
Perfect!

!!! warning "Be careful of using `hash`."
    The limitations of the `hash` function apply here. For example, custom types should implement `==` to ensure `hash` will work as intended.
    In general using functions with `hash` should be avoided. Hashing of functions happens on the function name, and hence it doesn't capture information about the actual code of the function or its methods. So this should only be used if the functions are well-established names coming from e.g. Base Julia such as `sin, cos, ...`. You also cannot use anonymous functions _at all_, as they do not have the same `hash` even when defined in the the same way but in different Julia sessions.



## Preparing & running jobs
### Preparing the dictionaries
Here is a shortened script from a project that uses [`dict_list`](@ref):
```@example customizing
using DrWatson

general_args = Dict(
    "model" => ["barkley", "kuramoto"],
    "noise" => 0.075,
    "noisy_training" => [true, false],
    "N" => [100],
    "embedding" => [ #(γ, τ, r, c)
    (4, 5, 1, 0.34), (4, 6, 1, 0.28)]
)
```

```@example customizing
dicts = dict_list(general_args)
println("Total dictionaries made: ", length(dicts))
dicts[1]
```
Also, using the type [`Derived`](@ref), we can have parameters that are computed depending on the value of other parameters:
```@example customizing
using DrWatson

general_args2 = Dict(
    "model" => "barkley",
    "noise" => [0.075, 0.050, 0.025],
    "noise2" => [1.0, Derived(["noise", "N"], (x,y) -> 2x + y)],
    "noisy_training" => true,
    "N" => 100,
)
```
```@example customizing
dicts2 = dict_list(general_args2)
println("Total dictionaries made: ", length(dicts2))
dicts2[1]
```

Now, how you use these dictionaries is up to you. Typically each dictionary is given to a `main`-like Julia function which extracts the necessary data and calls the necessary functions.

Let's say I have written a function that takes in one of these dictionaries and saves the file somewhere locally:
```@example customizing
function cross_estimation(data)
    γ, τ, r, c = data["embedding"]
    N = data["N"]
    # add fake results:
    data["x"] = rand()
    data["error"] = rand(10)
    # Save data:
    prefix = datadir("results", data["model"])
    get(data, "noisy_training", false) && (prefix *= "_noisy")
    get(data, "symmetric_training", false) && (prefix *= "_symmetric")
    sname = savename((@dict γ τ r c N), "jld2")
    mkpath(datadir("results", data["model"]))
    save(datadir("results", data["model"], sname), data)
    return true
end
```

### Using map and pmap

One way to run many simulations is with `map` (identical process for using `pmap`).
To run all my simulations I just do:
```@example customizing
dicts = dict_list(general_args)
map(cross_estimation, dicts) # or pmap

# load one of the files to be sure everything is ok:
filename = readdir(datadir("results", "barkley"))[1]
file = load(datadir("results", "barkley", filename))
```

### Using a Serial Cluster
In case that I can't store the results of `dict_list` in memory, I have to
change my approach and load them from disk. This is easy with the function [`tmpsave`](@ref).

Instead of using Julia to run all jobs from one process with `map/pmap` one can use Julia to submit many jobs to a cluster que. For our example above, the Julia program that does this would look like this:

```julia
dicts = dict_list(general_args)
res = tmpsave(dicts)
for r in res
    submit = `qsub -q queuename julia runjob.jl $r`
    run(submit)
end
```
Now the file `runjob.jl` would have contents that look like:
```julia
f = ARGS[1]
dict = load(projectdir("_research", "tmp", f), "params")
cross_estimation(dict)
```
i.e. it just loads the `dict` and straightforwardly uses the "main" function `cross_estimation`. Remember to routinely clear the `tmp` directory!
You could do that by e.g. adding a line `rm(projectdir("_research", "tmp", f)`
at the end of the `runjob.jl` script.

## Listing completed runs
Continuing from the [Preparing & running jobs](@ref) section, we now want to collect the results of all these simulations into a single `DataFrame`. We will do that with the function [`collect_results!`](@ref).

It is quite simple actually! But because we don't want to include the error, we have to black-list it:
```@example customizing
using DataFrames # this is necessary to access collect_results!
bl = ["error"]
res = collect_results!(datadir("results"); black_list = bl, subfolders = true)
```

We can take also advantage of the basic processing functionality of [`collect_results!`](@ref) to use the excluded `"error"` column, replacing it with its average value:
```@example customizing
using Statistics: mean
special_list = [:avrg_error => data -> mean(data["error"])]
res = collect_results(
      datadir("results"),
      black_list = bl,
      special_list = special_list,
      subfolders = true
)

select!(res, Not(:path)) # don't show path this time
```

As you see here we used [`collect_results`](@ref) instead of the in-place version, since there already exists a `DataFrame` with all results processed (and thus everything would be skipped).

## Adapting to new data/parameters
We once again continue from the above example. But we now need to run some new simulations with some new parameters that _do not exist_ in the old simulations... Well, DrWatson says "no problem!" :)

Let's save these new parameters in a different subfolder, to have a neatly organized project:
```@example customizing
general_args_new = Dict(
    "model" => ["bocf"],
    "symmetry" => "radial",
    "symmetric_training" => [true, false],
    "N" => [100],
    "embedding" => [ #(γ, τ, r, c)
    (4, 5, 1, 0.34), (4, 6, 1, 0.28)]
)
```
As you can see, there here there are two parameters not existing in previous simulations, namely `"symmetry", "symmetric_training"`. In addition, the parameters `"noise", "noisy_training"` that existed in the _previous_ simulations do not exist in the current one.

No problem though, let's run the new simulations:
```@example customizing
dicts = dict_list(general_args_new)
map(cross_estimation, dicts)

# load one of the files to be sure everything is ok:
filename = readdir(datadir("results", "bocf"))[1]
file = load(datadir("results", "bocf", filename))
```

Alright, now we want to _add_ these new runs to our existing dataframe that has collected all previous results. This is straight-forward:
```@example customizing
res = collect_results!(datadir("results"); black_list = bl, subfolders = true)

select!(res, Not(:path)) # don't show path this time
```
All `missing` entries were adjusted automatically :)

## Defining parameter sets with restrictions

As already demonstrated in the examples above, for functions where the set of input parameters is the same for each simulation run, a basic dictionary can be used to define these parameters.
However, often some of the parameters or values should only be considered if another parameter is also included in the set or has a specific value.
The macro [`@onlyif`](@ref) allows to place such restrictions on values and parameters.
The following dictionary defines values and parameters for a genetic algorithm:

```@example customizing
ga_parameters = Dict(
    :population_size => [20,50,100],
    :selection => ["roulette-selection", "SUS", "tournament-selection", "linear ranking"],
    :fitness_scaling => @onlyif(:selection in ("SUS", "roulette-selection"), collect(1.0:20.0)),
    :tournamet_size => @onlyif(:selection == "tournament-selection", collect(2:10)),
    :chromosome => [:A, @onlyif(begin
        size_constr = (:population_size <= 50)
        select_constr = (:selection != "SUS")
        size_constr && select_constr
    end, :B)])
```

```@example customizing
dicts = dict_list(ga_parameters)
length(dicts)
```

```@example customizing
dicts[1]
```
The parameter restriction for the chromosome type shows that one can use arbitrary Julia expressions that return `true` or `false`.
In this case, first the conditions for the population size and for the selection method are evaluated and stored.
The expression then only returns true, if both conditions are met, thus restricting the usage of chromosome type `:B`.

As `@onlyif` is meant to be used with [`dict_list`](@ref), it supports the vector notation used for defining possible parameter values.
This is achieved by automatically broadcasting every `@onlyif` call over `Vector` arguments, which allows chaining those calls to combine conditions.
So in terms of the result, `@onlyif( :a == 2, [5, @onlyif(:b == 4, 6)])` is equivalent to `[@onlyif( :a == 2, 5), @onlyif(:a == 2 && :b == 4, 6)]`.

## Filtering by name with collect_results

Using [`collect_results`](@ref) on a folder with many (e.g. 1,000) files in it can be noticeably slow. To speed this up, you can use the `rinclude` and `rexclude` keyword arguments, both of which are vectors of [Regex expressions](https://docs.julialang.org/en/v1/manual/strings/#man-regex-literals). The results returned will have a filename which matches **any** of the Regex expressions in `rinclude` and does not match **any** of the Regex expressions in `rexclude`.

```julia
df = collect_results(datadir("results"); rinclude=[r"a=1"])
# Only include results whose filename contains "a=1"

df = collect_results(datadir("results"); rexclude=[r"a=3"])
# Exclude any results whose filename contains "a=3"

df = collect_results(datadir("results"); rinclude=[r"a=1", r"b=5"], rexclude=[r"a=3"])
# Only include results whose filename contains "a=1" OR "b=5" and exclude any which contain "a=3"
```

## Advanced usage of collect_results
At some point in your work you may want to run a single function
that returns multiple fields that you want to include in your
results `DataFrame`.
Depending on the problem you are trying to solve it may just make more sense to use a single function that extracts most or all of the meta-data.
For this case `DrWatson` has another syntax available.
Let us, for the sake of simplicity, assume that your data files
contain a very long array of numbers called `"manynumbers"`
and the information that you care about are the three largest values.

One way to implement this would be to write
```julia
special_list = [
    :first  => data -> sort(data["manynumbers"])[1],
    :second => data -> sort(data["manynumbers"])[2],
    :third  => data -> sort(data["manynumbers"])[3],
    ]
```
which makes very obvious that there should be a better way to do this.
There is no point in sorting the very long vector three times.
A better thing to do is the following
```julia
function largestthree(data)
    sorted = sort(data["manynumbers"])
    return [:first  => sorted[1],
            :second => sorted[2],
            :third  => sorted[3]]
end

special_list = [largestthree,]
```

## Using `savename` to produce logfiles

When your code runs for a long time or even runs on different machines such as a cluster
environment it becomes important to produce logfiles. Logfiles allow you to
view the progress of your program while it is still running, or check later
on if everything went according to plan.

```julia
using Dates

function logmessage(n, error)
    # current time
    time = Dates.format(now(UTC), dateformat"yyyy-mm-dd HH:MM:SS")

    # memory the process is using
    maxrss = "$(round(Sys.maxrss()/1048576, digits=2)) MiB"

    logdata = (;
        n, # iteration n
        error, # some super important progress update
        maxrss) # lastly the amount of memory being used

    println(savename(time, logdata; connector=" | ", equals=" = ", sort=false, digits=2))
end

function expensive_computation(N)

    for n = 1:N
        sleep(1) # heavy computation
        error = rand()/n # some super import progress update
        logmessage(n, error)
    end

end
```

This yields output that is both easy to read *and* machine parseable.
If you ever end up with too many logfiles to read, there is still `parse_savename` to
help you.

```julia
julia> expensive_computation(5)
2021-05-19 19:20:25 | n = 1 | error = 0.65 | maxrss = 326.27 MiB
2021-05-19 19:20:26 | n = 2 | error = 0.48 | maxrss = 326.27 MiB
2021-05-19 19:20:27 | n = 3 | error = 0.08 | maxrss = 326.27 MiB
2021-05-19 19:20:28 | n = 4 | error = 0.11 | maxrss = 326.27 MiB
2021-05-19 19:20:29 | n = 5 | error = 0.15 | maxrss = 326.27 MiB
```

## Taking project input-output automation to 11
The point of this section is to show how far one can take the interplay between [`savename`](@ref) and [`produce_or_load`](@ref) to **automate project input-to-output and eliminate as many duplicate lines of code as possible**. Read [Customizing `savename`](@ref customizing_savename) first, as knowledge of that section is used here.

The key ingredient is that [`produce_or_load`](@ref) was made to work well with [`savename`](@ref). You can use this to automate the input-to-output pipeline of your project by following these steps:
1. Define a custom struct that represents the input configuration for an experiment or a simulation.
2. Extend [`savename`](@ref) appropriately for it.
3. Define a "main" function that takes as input an instance of this configuration type, and returns the output of the experiment or simulation as dictionary (We're not changing here the "default" way to save files in Julia as `.jld2` files. To save files this way you need your data to be in a dictionary with `String` as keys).
4. All your input-output scripts are simply put together by first defining the input configuration type, and then calling [`produce_or_load`](@ref) with your pre-defined "main" function (Alternatively, this function can internally call `produce_or_load` and return something else that is of special interest to your specific case).

An example of where this approach is used in the "real world" is e.g. in our paper [Effortless estimation of basins of attraction](https://arxiv.org/abs/2110.04358). Its codebase is here: https://github.com/Datseris/EffortlessBasinsOfAttraction. Don't worry, you need to know nothing about the topic to follow the rest. The point is that we needed to run some kind of simulations for many different dynamical systems, which have different parameters, different dimensionality, etc. But they did have one thing in common: our output was always coming from the same function, `basins_of_attraction`, which allowed using the pipeline we discuss here using [`produce_or_load`](@ref).

So we defined a struct called `BasinConfig` that stored configuration options and system parameters. Then we extended `savename` for it. We defined some function `produce_basins` that takes this configuration file, initializes a dynamical system accordingly, and then makes the output **using `produce_or_load`**. This ensures that we're not running simulations twice if they exist. And keep in mind when you have so many parameters and different possible systems, it is quite easy to unintentionally run the same simulation twice because you "forgot about it". All of this can be found in this file: https://github.com/Datseris/EffortlessBasinsOfAttraction/blob/master/src/produce_basins.jl

The benefit? All of our scripts that actually produce what we care about are this short:
```julia
using DrWatson
@quickactivate :EffortlessBasinsOfAttraction

a, b = 1.4, 0.3
p = @ntuple a b
system = :henon

basin_kwargs = (horizon_limit=100.0, mx_chk_fnd_att=30, mx_chk_lost=2)
Z = 201
xg = range(-1.5, 1.5; length = Z)
yg = range(-0.5, 0.5; length = Z)
grid = (xg, yg)

config = BasinConfig(; system, p, basin_kwargs, grid)
basins, attractors = produce_basins(config)
```
and more importantly, the only lines that are genuinely "copy-pasted" from script to script are the last two. All other lines are unique for each script. This minimization of copy-pasting duplicate information makes the workflow robust and makes bugs easier to find.
