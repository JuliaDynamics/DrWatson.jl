using DrWatson, Test

d = (a = 0.153456453, b = 5.0, mode = "double")
@test savename(d; digits = 4) == "a=0.1535_b=5_mode=double"
@test savename(d, (String,)) == "mode=double"

rick = (never = "gonna", give = "you", up = "!");
@test savename(rick) == "give=you_never=gonna_up=!"

x = 3; y = 5.0;
d = Dict("x" => x, "y" => y)

@test d == @dict x y

z = "lala"
d2 = Dict("x" => x, "y" => y, "z" => z)

@test d2 == @dict x y z

@test savename(@dict x y) == "x=3_y=5"
w = rand(50)
@test savename(@dict x y w) == savename(@dict x y)
