using DrWatson, Test

ps = DrWatson.PATH_SEPARATOR


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

@test_throws ErrorException DrWatson.parse_savename("a=10",connector="__")
@test_throws ErrorException("Savename cannot be parsed. There is a '_' after the last '='. "*
        "Values containing '_' are not allowed when parsing.") DrWatson.parse_savename("a=10_1")

unicode_chars_name="3pb_Gc₁=3_Gc₂=0.1_or=T_α₁=4_α₂=1_β=3.vtu"

@test parse_savename(unicode_chars_name) == ("3pb",Dict(
    "Gc₁"=>3,
    "Gc₂"=>0.1,
    "or"=>"T",
    "α₁"=>4,
    "α₂"=>1,
    "β"=>3),"vtu")
