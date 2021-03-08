using DrWatson, Test, Parameters, Dates

# Define a type we use at experiments
abstract type Species end
struct Mouse <: Species end
struct Cat <: Species end

@with_kw struct Experiment{S<:Species}
    n::Int = 50
    c::Float64 = 10.0
    x::Float64 = 0.2
    date::Date = Date(1991, 04, 13)
    species::S = Mouse()
    scientist::String = "George"
end
# Make a couple of experiments
e1 = Experiment()
e2 = Experiment(species = Cat())

# Implement defaults
DrWatson.default_prefix(e::Experiment) = "Experiment_"*string(e.date)
DrWatson.allaccess(::Experiment) = (:n, :c, :x, :species)

# Extend `Base.string` for custom types (`savename` uses `string`)
Base.string(::Mouse) = "mouse"
Base.string(::Cat) = "cat"

@test savename(e1) == "Experiment_1991-04-13_c=10.0_n=50_x=0.2"
@test savename(e2) == savename(e1)


# Add the extra type:
DrWatson.default_allowed(::Experiment) = (Real, String, Species)

@test savename(e1) ≠ "Experiment_1991-04-13_c=10.0_n=50_x=0.2"
@test savename(e2) ≠ savename(e1)

@test savename(e1) == "Experiment_1991-04-13_c=10.0_n=50_species=mouse_x=0.2"
@test savename(e2) == "Experiment_1991-04-13_c=10.0_n=50_species=cat_x=0.2"

d = struct2dict(e1)
@test keytype(d) == Symbol
for x in fieldnames(typeof(e1))
    @test d[x] == getfield(e1, x)
end

nt = struct2ntuple(e1)
@test isa(nt, NamedTuple)
for x in fieldnames(typeof(e1))
    @test nt[x] == getfield(e1, x)
end

# Test extra dir and default_prefix:
s = savename(joinpath("path", "to", "data"), e1)
@test s[1:4] == "path"
@test occursin("Experiment", s)
@test s == joinpath("path", "to", "data", "Experiment_1991-04-13_c=10.0_n=50_species=mouse_x=0.2")
