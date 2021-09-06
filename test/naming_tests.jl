using DrWatson, Test, Dates

ps = DrWatson.PATH_SEPARATOR

d = (a = 0.153456453, b = 5, mode = "double")
@test savename(d; digits = 4) == "a=0.1535_b=5_mode=double"
@test savename("n", d) == "n_a=0.153_b=5_mode=double"
@test savename("n$(ps)", d) == "n$(ps)a=0.153_b=5_mode=double"
@test savename("n$(ps)", d; connector = "-") == joinpath("n", "a=0.153-b=5-mode=double")
@test savename(d, "n") == "a=0.153_b=5_mode=double.n"
@test savename("n", d, "n") == "n_a=0.153_b=5_mode=double.n"
@test savename("n", d, "n"; connector = "-") == "n-a=0.153-b=5-mode=double.n"
@test savename(d, allowedtypes = (String,)) == "mode=double"
@test savename(d, connector=" | ", equals=" = ") == "a = 0.153 | b = 5 | mode = double"

tday = today()
@test savename(@dict(tday)) == "tday=$(string(tday))"

rick = (never = "gonna", give = "you", up = "!");
@test savename(rick) == "give=you_never=gonna_up=!"
@test savename(rick; ignores = ["up"]) == "give=you_never=gonna"
@test savename(rick; sort = false) == "never=gonna_give=you_up=!"

x = 3; y = 5.0;
d = Dict(:x => x, :y => y)
n = (x = x, y = y)

@test d == @dict x y
@test Dict("x" => x, "y" => y) == @strdict x y
@test n == @ntuple x y
@test (@savename x y) == savename(d)

z = "lala"
d2 = Dict(:x => x, :y => y, :z => z)
n2 = (x = x, y = y, z = z)

@test d2 == @dict x y z
@test n2 == @ntuple x y z

@test savename(n2; ignores=(:y,))  == "x=3_z=lala"
@test savename(n2; ignores=("y",)) == "x=3_z=lala"
@test savename(n2; accesses=(:x, :y), ignores=(:y,)) == "x=3"

@test savename(@dict x y) == "x=3_y=5.0"
@test savename(@ntuple x y) == "x=3_y=5.0"
w = rand(50)
@test savename(@dict x y w) == savename(@dict x y)
@test (@savename x y w) == savename(@dict x y)
@test savename(@ntuple x y w) == savename(@dict x y)

@test ntuple2dict(@ntuple x y) == @dict x y
@test sort(collect(keys(dict2ntuple(@dict x y)))) == sort(collect(keys(@ntuple x y)))

@test keytype(tostringdict(d2)) == String
@test keytype(tosymboldict(tostringdict(d2))) == Symbol

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

# automatic string to symbol conversion in accesses of structs
@test savename(x, accesses=("a",)) == "a=5"
# But test that this conversion does not happen for Dicts!
mixed_str_sym_dict = Dict("a" => 1, :b => 2)
@test savename(mixed_str_sym_dict, accesses=("a", :b)) == "a=1_b=2"

# empty container
x = A(5, NamedTuple())
@test !occursin("p", savename(x))

# container with values that are not by default printed in savename
x = A(5, (m = rand(50,50),))
@test !occursin("p", savename(x))

# Scientific notation for savename
a = 1.2345e-7
c = 1
d = "test"
di = @dict a c d

@test savename(di,sigdigits=6) == "a=1.2345e-7_c=1_d=test"
@test savename(di,sigdigits=5) == "a=1.2345e-7_c=1_d=test"
@test savename(di,sigdigits=4) == "a=1.234e-7_c=1_d=test"
@test savename(di,sigdigits=3) == "a=1.23e-7_c=1_d=test"
@test savename(di,sigdigits=2) == "a=1.2e-7_c=1_d=test"
@test savename(di,sigdigits=1) == "a=1e-7_c=1_d=test"
@test savename(di) == "a=1.23e-7_c=1_d=test" # default is sigdigits=3

sn = savename(di,sigdigits=4)
_,parsed,_ = parse_savename(sn)
@test parsed["a"] == 1.234e-7

sn = savename(di,sigdigits=1)
_,parsed,_ = parse_savename(sn)
@test parsed["a"] == 1.0e-7


# Test for NaN and Inf compatibility
let
    a = Inf
    b = NaN
    di = @dict a b
    @test savename(di) == "a=Inf_b=NaN"
end


# Dedicated Macro tests
@testset "Macro Tests" begin
    x = 3; y = 5.0; z = 42;
    
    @test Dict(:x=>x, :y=>y, :z=>z) == @dict x y z
    @test Dict(:x=>x, :b=>y, :z=>z) == @dict x b=y z
    @test Dict(:a=>x, :b=>y, :c=>z) == @dict a=x b=y c=z
    @test Dict(:z=>x, :x=>y, :y=>z) == @dict z=x x=y y=z

    @test Dict("x"=>x, "y"=>y, "z"=>z) == @strdict x y z
    @test Dict("x"=>x, "b"=>y, "z"=>z) == @strdict x b=y z
    @test Dict("a"=>x, "b"=>y, "c"=>z) == @strdict a=x b=y c=z
    @test Dict("z"=>x, "x"=>y, "y"=>z) == @strdict z=x x=y y=z

    @test (x=x, y=y, z=z) == @ntuple x y z
    @test (x=x, b=y, z=z) == @ntuple x b=y z
    @test (a=x, b=y, c=z) == @ntuple a=x b=y c=z
    @test (z=x, x=y, y=z) == @ntuple z=x x=y y=z

    @test savename((; x, y, z)) == @savename x y z
    @test savename((; x, b=y, z)) == @savename x b=y z
    @test savename((; a=x, b=y, c=z)) == @savename a=x b=y c=z
    @test savename((; z=x, x=y, y=z)) == @savename z=x x=y y=z

end

