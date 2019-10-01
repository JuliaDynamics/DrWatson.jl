using DrWatson, Test

ps = DrWatson.PATH_SEPARATOR

d = (a = 0.153456453, b = 5.0, mode = "double")
@test savename(d; digits = 4) == "a=0.1535_b=5_mode=double"
@test savename("n", d) == "n_a=0.153_b=5_mode=double"
@test savename("n$(ps)", d) == "n$(ps)a=0.153_b=5_mode=double"
@test savename("n$(ps)", d; connector = "-") == joinpath("n", "a=0.153-b=5-mode=double")
@test savename(d, "n") == "a=0.153_b=5_mode=double.n"
@test savename("n", d, "n") == "n_a=0.153_b=5_mode=double.n"
@test savename("n", d, "n"; connector = "-") == "n-a=0.153-b=5-mode=double.n"
@test savename(d, allowedtypes = (String,)) == "mode=double"

rick = (never = "gonna", give = "you", up = "!");
@test savename(rick) == "give=you_never=gonna_up=!"

x = 3; y = 5.0;
d = Dict(:x => x, :y => y)
n = (x = x, y = y)

@test d == @dict x y
@test Dict("x" => x, "y" => y) == @strdict x y
@test n == @ntuple x y
@test (@savename x y) == savename(d)

z = "lala"
d2 = Dict(:x => x, :y => y, :z => z)
n2 = (x = x, y = y, z= z)

@test d2 == @dict x y z
@test n2 == @ntuple x y z

@test savename(@dict x y) == "x=3_y=5"
@test savename(@ntuple x y) == "x=3_y=5"
w = rand(50)
@test savename(@dict x y w) == savename(@dict x y)
@test (@savename x y w) == savename(@dict x y)
@test savename(@ntuple x y w) == savename(@dict x y)

@test ntuple2dict(@ntuple x y) == @dict x y
@test sort(collect(keys(dict2ntuple(@dict x y)))) == sort(collect(keys(@ntuple x y)))

a = 3; b = 4
c = @ntuple a b
d = 5; e = @dict c d

@test DrWatson.access(e, :c, :a) == a
ff = dict2ntuple(e)
@test DrWatson.access(ff, :c, :a) == a
@test ff.c.a == a

# Expand tests:
a = 3; b = 4
c = @dict a b
d = 5; e = @dict c d

s = savename(e; allowedtypes = (Any,), expand = ["c"])
@test '(' ∈ s
@test ')' ∈ s
@test occursin("a=3", s)
@test occursin("b=4", s)

# More detailed expand tests
struct A
    a
    p
end
DrWatson.default_allowed(::A) = (Any,)
DrWatson.default_expand(::A) = ["p"]

x = A(5, (b = 3, c = 4))

@test savename(x) == "a=5_p=(b=3,c=4)"

# empty container
x = A(5, NamedTuple())
@test !occursin("p", savename(x))

# container with values that are not by default printed in savename
x = A(5, (m = rand(50,50),))
@test !occursin("p", savename(x))
