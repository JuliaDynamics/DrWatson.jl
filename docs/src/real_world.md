# Real World Examples

## Easy local directories
I setup all my science projects using DrWatson's suggested setup, using [`initialize_project`](@ref). Then, every file in every project has a start that looks like this:
```julia
using DrWatson
quickactivate(@__DIR__, "MagneticBilliardsLyapunovs")
using DynamicalBilliards, PyPlot, LinearAlgebra

include(srcdir()*"plot_perturbationgrowth.jl")
include(srcdir()*"unitcells.jl")
```
In all projects I save data using `datadir()`:
```julia
using BSON

bson(datadir()*"mushrooms/Λ_N=$N.bson", (@dict Λ Λσ ws hs description))
```
The advantage of this approach is that it will always work regardless of if I move the specific file to a different subfolder (which is very often necessary) or whether I move the entire project folder somewhere else!

Here is an example from another project. You will notice that another advantage is that I can use identical syntax to access the data or source folders even though I have different projects!
```julia
using DrWatson
quickactivate(@__DIR__, "EmbeddingResearch")
using FileIO, Parameters
using TimeseriesPrediction, LinearAlgebra, Statistics

include(srcdir()*"systems/barkley.jl")
include(srcdir()*"nrmse.jl")
```
that ends with
```julia
FileIO.save(
    savename(datadir()*"sim/bk", simulation, "jld2"),
    @strdict U V simulation
)
```

## `savename` and tagging
The combination of using [`savename`](@ref) and [`tagsave`](@ref) makes it easy and fast to save output in a way that is consistent, robust and reproducible. Here is an example from a project:
```julia
using DrWatson
quickactivate(@__DIR__, "EmbeddingResearch")
using TimeseriesPrediction, LinearAlgebra, Statistics
include(srcdir()*"systems/barkley.jl")

ΔTs = [1.0, 0.5, 0.1] # resolution of the saved data
Ns = [50, 150] # spatial extent
for N ∈ Ns, ΔT ∈ ΔTs
    T = 10050 # we can offset up to 1000 units
    every = round(Int, ΔT/barkley_Δt)
    seed = 1111

    simulation = @ntuple T N ΔT seed
    U, V = barkley(T, N, every; seed = seed)

    tagsave(
        savename(datadir()*"sim/bk", simulation, "bson"),
        @dict U V simulation
    )
end
```
This saves files that look like:
```
path/to/project/data/sim/bk_N=50_T=10050_seed=1111_ΔT=1.bson
```
and each file is a dictionary with four fields: `:U, :V, :simulation, :commit`. When I read this file I know exactly what was the source code that produced it (provided that I am not sloppy and commit code changes regularly :P).

## Customizing `savename`
Here is a simple (but not from a real project) example for customizing [`savename`](@ref). We are using a common struct `Experiment` across different experiments with cats and mice.
In this example we are also using `Parameters` for a convenient default constructor.

We first define the relevant types.
```@example customizing
using DrWatson, Parameters, Dates

# Define a type hierarchy we use at experiments
abstract type Species end
struct Mouse <: Species end
struct Cat <: Species end

@with_kw struct Experiment{S<:Species}
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

For analyzing our experiments we need information about the species used, and to use multiple dispatch latter on we decide to make this information associated with a Type.

Now, we want to customize [`savename`](@ref). We start by extending [`DrWatson.default_prefix`](@ref):
```@example customizing
DrWatson.default_prefix(e::Experiment) = "Experiment_"*string(e.date)

savename(e1)
```
However this is not good enough for us, as the information about the species is not contained in [`savename`](@ref). We have to extend [`DrWatson.default_allowed`](@ref) like so:
```@example customizing
DrWatson.default_allowed(::Experiment) = (Real, String, Species)

savename(e1)
```
To make printing better we can extend `Base.string`, which is what DrWatson uses internally in [`savename`](@ref) to display values.
```@example customizing
Base.string(::Mouse) = "mouse"
Base.string(::Cat) = "cat"
nothing # hide
```

Lastly, let's say that the information of which scientist performed the experiment is not really relevant for `savename`. We can extend the last method, [`DrWatson.allaccess`](@ref):
```@example customizing
DrWatson.allaccess(::Experiment) = (:n, :c, :x, :species)
```
so that only those four fields will be used (notice that the `date` field is anyway used in `default_prefix`). We finally have:
```@example customizing
println( savename(e1) )
println( savename(e2) )
```

## Stopping "Did I run this?"
It can become very tedious to have a piece of code that you may or may not have saved and you constantly ask yourself "Did I run this?". Typically one uses `isfile` and an `if` clause to either load a file or run some code. Especially in the cases where the code takes only a couple of minutes to finish you are left in a dilemma "Is it even worth it to save?".

This is the dilemma that [`produce_or_load`](@ref) resolves. You can wrap your code in a function and then [`produce_or_load`](@ref) will take care of the rest for you! I found it especially useful in scripts that generate figures for a publication.

Here is an example; originally I had this piece of code:
```julia
WTEST = HTEST = 0.1:0.1:2.0
HS = WS = [0.5, 1.0, 1.5]
N = 10000; T = 10000.0

toypar_w = [[] for l in HS]
for (z, h) in enumerate(HS)
    println("h = $h")
    for (i, w) in enumerate(WTEST)
        toyp = toyparameters(h, w, N, T)
        push!(toypar_w[z], toyp)
    end
end
toypar_h = [[] for l in HS]
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
WTEST = HTEST = 0.1:0.1:2.0
HS = WS = [0.5, 1.0, 1.5]

function g(d)
    @unpack N, T = d

    toypar_w = [[] for l in HS]
    for (z, h) in enumerate(HS)
        println("h = $h")
        for (i, w) in enumerate(WTEST)
            toyp = toyparameters(h, w, N, T)
            push!(toypar_w[z], toyp)
        end
    end
    toypar_h = [[] for l in HS]
    for (wi, w) in enumerate(WS)
        println("w = $w")
        for h in HTEST
            toyp = toyparameters(h, w, N, T)
            push!(toypar_h[wi], toyp)
        end
    end

    return @dict toypar_w toypar_h
end

N = 2000; T = 2000.0
file = produce_or_load(
    datadir()*"mushrooms/toy", # prefix
    @dict(N, T), # container
    g # function
)
@unpack toypar_w, toypar_h = file
```
Now every time I run this code block the function tests automatically whether the file exists and only if it does not the code is run.

The extra step is that I have to extract the useful data I need from the container `file`. Thankfully the `@unpack` macro from [Parameters.jl](https://mauro3.github.io/Parameters.jl/stable/manual.html) makes this super easy.

## Preparing runs
Here is a shortened script from a project that uses [`dict_list`](@ref):
```@example customizing
using DrWatson

general_args = Dict(
    "model" => ["barkley", "kuramoto"],
    "noise" => 0.075,
    "noisy_training" => [true, false],
    "N" => [50, 100],
    "embedding" => [ #(γ, τ, r, c)
    (4, 5, 1, 0.34), (4, 6, 1, 0.28), (8, 3, 1, 0.2)]
)
```

```@example customizing
dicts = dict_list(general_args)
println("Total dictionaries made: ", length(dicts))
dicts[1]
```
Now how you use these dictionaries is up to you. Here we will use `map` (identical process for using `pmap`) but in other scenarios you might want to submit many individual jobs to a computer cluster.

Let's say I have written a function that takes in one of these dictionaries and saves the file somewhere locally:
```@example customizing
using BSON
mkpath(datadir()*"results")

function cross_estimation(data)
    γ, τ, r, c = data["embedding"]
    N = data["N"]
    # add fake results:
    data["x"] = rand()
    data["error"] = rand(10)
    # Save data:
    prefix = datadir()*"results/$(data["model"])"
    data["noisy_training"] && (prefix *= "noisy")
    BSON.bson(
        savename(
            prefix,
            (@dict γ τ r c N),
            "bson"
            ),
        data
    )
    return true
end
```

To run all my simulations I just do:
```@example customizing
dicts = dict_list(general_args)
map(cross_estimation, dicts)

# load one of the files to be sure everything is ok:
filename = readdir(datadir()*"results")[1]
file = BSON.load(datadir()*"results/"*filename)
```

## Listing completed runs
Continuing from the above example, we now want to collect the results of all these simulations into a single `DataFrame`. We will do that with the function [`collect_results`](@ref).

It is quite simple actually:
```@example customizing
using DataFrames # this is necessary to access collect_results!
black_list = ["error"]
res = collect_results(datadir()*"results"; black_list = black_list)
```
(unfortunately for now the type of all columns is `Any` due to bugs in `BSON`)
```@example customizing
names(res)
```

The dataframe has the `error` column, each being a vector of numbers. We can take advantage of the basic processing functionality of [`collect_results`](@ref) to replace this column with the average error instead.
```@example customizing
special_list = [:avrg_error => data -> mean(data["error"])]
res = collect_results(
      datadir()*"results",
      black_list = black_list,
      special_list = special_list
)
```
```@example customizing
names(res)
```
