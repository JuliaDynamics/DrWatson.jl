using DrWatson, Test

d = (a = 0.153456453, b = 5.0, mode = "double")
@test savename(d; digits = 4) == "a=0.1535_b=5_mode=double"
@test savename("n", d) == "n_a=0.153_b=5_mode=double"
@test savename("n/", d) == "n/a=0.153_b=5_mode=double"
@test savename("n/", d; connector = "-") == "n/a=0.153-b=5-mode=double"
@test savename("n\\", d) == "n\\a=0.153_b=5_mode=double"
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

z = "lala"
d2 = Dict(:x => x, :y => y, :z => z)
n2 = (x = x, y = y, z= z)

@test d2 == @dict x y z
@test n2 == @ntuple x y z

@test savename(@dict x y) == "x=3_y=5"
@test savename(@ntuple x y) == "x=3_y=5"
w = rand(50)
@test savename(@dict x y w) == savename(@dict x y)
@test savename(@ntuple x y w) == savename(@dict x y)

@test ntuple2dict(@ntuple x y) == @dict x y
@test sort(collect(keys(dict2ntuple(@dict x y)))) == sort(collect(keys(@ntuple x y)))

a = 3; b = 4
c = @ntuple a b
d = 5; e = @dict c d

@test DrWatson.access(e, :c, :a) == a
f = dict2ntuple(e)
@test DrWatson.access(f, :c, :a) == a
@test f.c.a == a 
