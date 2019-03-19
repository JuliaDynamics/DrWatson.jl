# Real World Examples


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
