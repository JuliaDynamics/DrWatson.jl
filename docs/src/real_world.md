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

Here is an example from another project:
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
Here is an example for customizing [`savename`](@ref). We are using a common struct `Experiment` across different experiments with cats and mice.
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
