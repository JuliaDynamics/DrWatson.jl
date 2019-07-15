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

# Tests for parse_savename

function test_convert(prefix::AbstractString,c;kwargs...)
    name = savename(prefix,c;kwargs...)
    _prefix, _b, _suffix = DrWatson.parse_savename(name)
    dicts_equal(_b,c) && _prefix == prefix && _suffix == ""
end

function test_convert(c,suffix::AbstractString;kwargs...)
    name = savename(c,suffix;kwargs...)
    _prefix, _b, _suffix = DrWatson.parse_savename(name)
    dicts_equal(_b,c) && _suffix == suffix && _prefix == ""
end

function test_convert(prefix::AbstractString,c,suffix::AbstractString;kwargs...)
    name = savename(prefix,c,suffix;kwargs...)
    _prefix, _b, _suffix = DrWatson.parse_savename(name)
    dicts_equal(_b,c) && _suffix == suffix && _prefix == prefix
end

function test_convert(c;kwargs...)
    name = savename(c;kwargs...)
    _prefix, _b, _suffix = DrWatson.parse_savename(name)
    dicts_equal(_b,c) && _prefix == "" && _suffix == ""
end

function dicts_equal(a,b)
    kA,kB = keys(a), keys(b)
    kA != kB && return false
    for k ∈ kA
        a[k] != b[k] && return false
    end
    return true
end


@test test_convert(
    Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "mode" => "double"),
    digits=4)
@test test_convert("prefix",
                   Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "mode" => "double"),
                   digits=4)
@test test_convert(
    Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "mode" => "double"),
    "suffix",
    digits=4)
@test test_convert("prefix",
                   Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "mode" => "double"),
                   "suffix",
                   digits=4)
@test test_convert("prefix",
                   Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "variable_with_underscore" => "double"),
                   "suffix",
                   digits=4)
@test test_convert(joinpath("a=10_mode=double","prefix"),
                   Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "variable_with_underscore" => "double"),
                   "suffix",
                   digits=4)
@test test_convert(Dict("c" => 0.1534, "u" => 5.1),
                   digits=4)
@test test_convert(Dict("never" => "gonna", "give" => "you", "up" => "!"))
@test test_convert(Dict("c" => 0.1534),
                   digits=4)

b = Dict("c" => 0.1534, "u" => 5.1, "r"=>101, "mo_de" => "double")
name = savename("prefix",b,connector="_",digits=4)
_prefix, _b, _suffix = DrWatson.parse_savename(name,connector="_")
@test dicts_equal(_b,b) && _prefix == "prefix" && _suffix == ""

_prefix, _b, _suffix = DrWatson.parse_savename(joinpath("some_random_path_a=10.0","prefix")*"_a=10_just_a_string=I'm not allowed to use underscores here_my_value=10.1.suffix_with_underscore-but-don't-use-dots")
@test _prefix == joinpath("some_random_path_a=10.0","prefix")
@test _suffix == "suffix_with_underscore-but-don't-use-dots"
@test _b["a"] == 10.0
@test _b["just_a_string"] == "I'm not allowed to use underscores here"
@test _b["my_value"] == 10.1

@test_throws AssertionError DrWatson.parse_savename("a=10",connector="__")
