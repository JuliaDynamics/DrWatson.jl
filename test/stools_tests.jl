using DrWatson, Test
using DataStructures
using JLD2
using LibGit2

# Test commit function
com = gitdescribe(@__DIR__)
@test com isa String

com = gitdescribe(dirname(@__DIR__))
@test com !== nothing
@test typeof(com) <: String
# TODO: why?
# @test com[1] == 'v' # test that it has a version tag

# Set up a clean and a dirty repo.
function _setup_repo(dirty)
    path = mktempdir(cleanup=true) # delete path on process exit
    repo = LibGit2.init(path)
    john = LibGit2.Signature("Dr. John H. Watson", "snail mail only")
    write(joinpath(path, "foo.txt"), "bar\n")
    LibGit2.add!(repo, "foo.txt")
    LibGit2.commit(repo, "tmp repo commit", author=john, committer=john)
    dirty && write(joinpath(path, "foo.txt"), "baz\n")
    return path
end
dpath = _setup_repo(true) # dirty
cpath = _setup_repo(false) # clean

@test isdirty(dpath)
@test endswith(gitdescribe(dpath), "-dirty")
@test endswith(gitdescribe(dpath, dirty_suffix="-verydirty"), "-verydirty")
@test !endswith(gitdescribe(dpath, dirty_suffix=""), "-dirty")
@test !isdirty(cpath)
@test !endswith(gitdescribe(cpath), "-dirty")

# tag!
function _test_tag!(d, path, haspatch, DRWATSON_STOREPATCH)
    d = copy(d)
    withenv("DRWATSON_STOREPATCH" => DRWATSON_STOREPATCH) do
        d = tag!(d, gitpath=path)
        commitname = keytype(d)(:gitcommit)
        @test haskey(d, commitname)
        @test d[commitname] isa String
        if haspatch
            patchname = keytype(d)(:gitpatch)
            @test haskey(d, patchname)
            @test d[patchname] isa String
            @test d[patchname] != ""
        end
    end
end

d1 = Dict(:x => 3, :y => 4)
d2 = Dict("x" => 3, "y" => 4)
@testset "tag! ($(keytype(d)))" for d in (d1, d2)
    @testset "no patch ($(dirty ? "dirty" : "clean"))" for dirty in (true, false)
        path = dirty ? dpath : cpath
        _test_tag!(d, path, false, nothing) # variable unset
        _test_tag!(d, path, false, "") # variable set but empty
        _test_tag!(d, path, false, "false") # variable parses as false
        _test_tag!(d, path, false, "0") # variable parses as false
        _test_tag!(d, path, false, "rubbish") # variable not a Bool
    end
    @testset "patch" begin
        _test_tag!(d, dpath, true, "true") # variable parses as true
        _test_tag!(d, dpath, true, "1") # variable parses as true
    end
    @testset "message" begin
        d = copy(d1)
        path = cpath
        d = tag!(d; gitpath=path, commit_message = true)
                    message_name = keytype(d)(:gitmessage)
                    @test haskey(d, message_name)
                    @test d[message_name] == "tmp repo commit"
    end
end

# Ensure that above tests operated out-of-place.
@test d1 == Dict(:x => 3, :y => 4)
@test d2 == Dict("x" => 3, "y" => 4)

# Test assertion error when the data has a incompatible key type
@test_throws AssertionError("We only know how to tag dictionaries that have keys that are strings or symbols") tag!(Dict{Int64,Any}(1 => 2))
@test_throws AssertionError("We only know how to tag dictionaries that have keys that are strings or symbols") DrWatson.scripttag!(Dict{Int64,Any}(1 => 2), "foo")


# @tag!
@testset "@tag! ($(keytype(d)))" for d in (d1, d2)
    d = @tag!(d, gitpath=@__DIR__)
    @test haskey(d, keytype(d)(:gitcommit))
    @test d[keytype(d)(:gitcommit)] |> typeof <: String
    @test split(d[keytype(d)(:script)], '#')[1] == basename(@__FILE__)
end

# Tag kw-functions

d = Dict(:x => 3, :y => 4)

d_new = tag!(d,gitpath=@__DIR__,source="foo")
@test endswith(d_new[:script],"foo")

d_new = @tag!(d,gitpath=@__DIR__)
@test split(d_new[keytype(d_new)(:script)], '#')[1] == basename(@__FILE__)

ex = @macroexpand @tag!(d,gitpath="path")

@test ex.args[1].name == :tag!
@test ex.args[2] == :d
@test ex.args[3].head == :kw
@test ex.args[3].args[1] == :gitpath
@test ex.args[3].args[2] == "path"
@test ex.args[4].head == :kw

# Test force kw

d = Dict(:x => 3, :y => 4, :gitcommit => "")
@test tag!(d,gitpath=@__DIR__)[:gitcommit] == ""
@test tag!(d,gitpath=@__DIR__,force=true)[:gitcommit] == com
d = Dict(:x => 3, :y => 4, :gitcommit => "")
@test (@tag!(d, gitpath=@__DIR__,force=true))[:gitcommit] == com

# Test dictionary expansion
c = Dict(:a => [1, 2], :b => 4);
c1 = [ Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)]

v1 = dict_list(c)
for el in c1
    @test el ∈ v1
end
@test keytype(eltype(v1)) == Symbol

c[:c] = "test"; c[:d] = ["lala", "lulu"];
c2 = [ Dict(:a=>1,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:c=>"test")]

v2 = dict_list(c)
for el in c2
    @test el ∈ v2
end
@test keytype(eltype(v2)) == Symbol

c[:e] = [[1, 2], [3, 5]];
c3 = [
Dict(:a=>1,:b=>4,:d=>"lala",:e=>[1, 2],:c=>"test")
Dict(:a=>2,:b=>4,:d=>"lala",:e=>[1, 2],:c=>"test")
Dict(:a=>1,:b=>4,:d=>"lulu",:e=>[1, 2],:c=>"test")
Dict(:a=>2,:b=>4,:d=>"lulu",:e=>[1, 2],:c=>"test")
Dict(:a=>1,:b=>4,:d=>"lala",:e=>[3, 5],:c=>"test")
Dict(:a=>2,:b=>4,:d=>"lala",:e=>[3, 5],:c=>"test")
Dict(:a=>1,:b=>4,:d=>"lulu",:e=>[3, 5],:c=>"test")
Dict(:a=>2,:b=>4,:d=>"lulu",:e=>[3, 5],:c=>"test")
]

v3 = dict_list(c)
@test dict_list_count(c) == length(c3) == length(v3)
for el in c3
    @test el ∈ v3
end
@test keytype(eltype(v3)) == Symbol

v4 = dict_list(Dict(:a => 1, :b => 2.0)) # both non-iterable
@test keytype(eltype(v4)) == Symbol

v5 = dict_list(Dict(:a => [1], :b => 2.0)) # one non-iterable
@test keytype(eltype(v5)) == Symbol

v6 = dict_list(Dict(:a => [1], :b => [2.0])) # both iterable
@test keytype(eltype(v6)) == Symbol

struct SolverA end
struct SolverB end

# Simple example with no chained dependencies

p = Dict(:α => 1,
         :solver => [SolverA,SolverB],
         :c => @onlyif(:solver == SolverA , [100,200]),
         :d => @onlyif(:solver == SolverB, 1)
        )

@test Set([ Dict(:α => 1, :solver => SolverA, :c => 100),
           Dict(:α => 1, :solver => SolverA, :c => 200),
           Dict(:α => 1, :solver => SolverB, :d => 1),
          ]) == Set(dict_list(p))

# Advanced example with chained dependency. SolverA => :c => :d
p = Dict(:α => 1,
         :solver => [SolverA,SolverB],
         :c => @onlyif(:solver == SolverA , [100,200]),
         :d => @onlyif(:c == 100, 1)
        )

@test Set([
           Dict(:α => 1, :solver => SolverA, :c => 100, :d => 1),
           Dict(:α => 1, :solver => SolverA, :c => 200),
           Dict(:α => 1, :solver => SolverB),
          ]) == Set(dict_list(p))

# Advanced condition definition

test_param = @onlyif(begin
                d = Dict( :f => (conds...)->all(conds) )
                cond1 = :b == :c
                cond2 = :d == :something
                cond3 = "d" == :d
                cond4 = :α^2 == 1
                return d[:f](cond1, cond2, cond3, cond4)
            end, nothing)

dummy_dict = Dict(:α=>1, :b=>1, :c=>1, :d=>:something, "d"=>:something)

@test test_param.condition(dummy_dict, Dict(:α=>1, :b=>1, :c=>1, :d=>:something, "d"=>:something))
@test !test_param.condition(dummy_dict, Dict(:α=>2, :b=>1, :c=>1, :d=>:something, "d"=>:something))
@test !test_param.condition(dummy_dict, Dict(:α=>1, :b=>2, :c=>1, :d=>:something, "d"=>:something))
@test !test_param.condition(dummy_dict, Dict(:α=>1, :b=>1, :c=>1, :d=>:foo, "d"=>:something))
@test !test_param.condition(dummy_dict, Dict(:α=>1, :b=>1, :c=>1, :d=>:something, "d"=>:foo))
@test !test_param.condition(dummy_dict, Dict(:b=>1, :c=>1, :d=>:something, "d"=>:something))

module TestMod
    struct Foo end
end

dummy_dict = Dict(:solver => TestMod.Foo)
test_param = @onlyif(:solver == TestMod.Foo,[100,200])

@test test_param[1].condition(dummy_dict,Dict(:solver=>TestMod.Foo))
@test !test_param[1].condition(dummy_dict,Dict(:solver=>:Foo))

# partially restricted and mixed keytypes parameters

p = Dict(
         :a => :a1,
         "b" => [:b1,:b2],
         :c => [:c1,@onlyif("b" == :b2, :c2)],
        )

@test Set(dict_list(p)) == Set([
                          Dict(:a=>:a1, "b"=>:b1, :c=>:c1),
                          Dict(:a=>:a1, "b"=>:b2, :c=>:c1),
                          Dict(:a=>:a1, "b"=>:b2, :c=>:c2),
                         ])

# Every value restriced, but always at least 1 value available

p = Dict(
         :a => [1,2],
         :b => @onlyif(:a==1,[1,2]),
         :c => @onlyif(:a==3,[1,2]),
        )

@test Set(dict_list(p)) == Set([
                                Dict(:a => 2)
                                Dict(:a => 1,:b => 1)
                                Dict(:a => 1,:b => 2)
                               ])

p = Dict(
         :a => [1,2],
         :b => @onlyif(:a==1,[1,2]),
         :c => [@onlyif(:b==1,1), @onlyif(:b==2,2)],
        )

@test Set(dict_list(p)) == Set([
                                Dict(:a => 1,:b => 1,:c => 1)
                                Dict(:a => 1,:b => 2,:c => 2)
                                Dict(:a => 2)
                               ])

p = Dict(
         :a => [1,2],
         :b => @onlyif(:a==1,[1,2]),
         :c => [@onlyif(:b==1,1), @onlyif(:b==1,2)],
        )

@test Set(dict_list(p)) == Set([
                                Dict(:a => 1,:b => 1,:c => 1)
                                Dict(:a => 1,:b => 1,:c => 2)
                                Dict(:a => 2)
                                Dict(:a => 1,:b => 2)
                               ])

@test Set(dict_list(Dict(
   :a => [1,2,3],
   :b => [@onlyif(:a==1, 10), @onlyif(:a==2, [20]), @onlyif(:a==3, [30,30])]))) == Set(
           [Dict(:a => 1,:b => 10),
            Dict{Symbol,Any}(:a => 2,:b => [20]),
            Dict{Symbol,Any}(:a => 3,:b => [30, 30])])

# Testing nested @onlyif calls
@test Set(dict_list(Dict(
                   :a=>[1,2],
                   :b => [3,4],
                   :c => @onlyif( :a == 2, [5, @onlyif(:b == 4, 6)])
                  ))) == Set([Dict(:a => 1,:b => 3),
                              Dict(:a => 2,:b => 3,:c => 5),
                              Dict(:a => 1,:b => 4),
                              Dict(:a => 2,:b => 4,:c => 5),
                              Dict(:a => 2,:b => 4,:c => 6)])

# Test dict_list retaining original types

dlist = dict_list(Dict(
       :n => [1],
       :h => [10, 15, 20],
       :a => 0.01,:d=>0.001))

@test typeof(dlist[1][:a]) == Float64
@test typeof(dlist[1][:n]) == Int
@test typeof(dlist[1][:h]) == Int
@test typeof(dlist[1][:d]) == Float64

### tmpsave ###
tmpdir = joinpath(@__DIR__, "tmp")
ret = tmpsave(v3, tmpdir)
for r in ret
    @test isfile(joinpath(tmpdir, r))
    a = load(joinpath(tmpdir, r), "params")
    @test a ∈ v3
end
rm(tmpdir, force = true, recursive = true)
@test !isdir(tmpdir)
## is taggable
@test DrWatson.istaggable("test.jld2")
@test !DrWatson.istaggable("test.csv")
@test !DrWatson.istaggable(0.5)
@test DrWatson.istaggable(Dict(:a => 0.5))

## Testing OrderedDict usage
@testset "OrderedDict Tests" begin
    cd(@__DIR__)
    struct TestStruct
        z::Float64
        y::Int
        x::String
    end

    struct TestStruct2 #this structure allows for the if statement to be run in checktagtype!, (will promote the valuetype to Any)
        z::Int64
        y::Int64
        x::Int64
    end

    #test struct2dict
    t = TestStruct(2.0,1,"3") #this tests the case where struct2dict will by default not work
    d1 = struct2dict(t)
    d2 = struct2dict(OrderedDict,t)
    @test !all(collect(fieldnames(typeof(t))).==keys(d1)) #the example struct given does not have the keys in the same order when converted to a dict
    @test all(collect(fieldnames(typeof(t))).==keys(d2)) #OrderedDict should have the key in the same order as the struct

    #test struct2dict
    t2 = TestStruct2(1,3,4)
    d3 = struct2dict(t2)
    d4 = struct2dict(OrderedDict,t2)
    @test isa(d3,Dict)
    @test isa(d4,OrderedDict)

    #test tostringdict and tosymboldict
    d10 = tostringdict(OrderedDict,d4)
    @test isa(d10,OrderedDict)
    d11 = tosymboldict(OrderedDict,d10)
    @test isa(d11,OrderedDict)

    #test ntuple2dict
    x = 3; y = 5.0;
    n = @ntuple x y
    @test isa(ntuple2dict(n),Dict)
    @test isa(ntuple2dict(OrderedDict,n),OrderedDict)

    #test checktagtype!
    @test isa(DrWatson.checktagtype!(d3),Dict)
    @test isa(DrWatson.checktagtype!(d11),OrderedDict)

    #check tagsave
    sn = savename(d10,"jld2")
    tagsave(sn,d10,gitpath=findproject())

    file = load(sn)
    display(file)
    @test "gitcommit" in keys(file)
    @test file["gitcommit"] |>typeof ==String
    rm(sn)

## Tests for ComputedParameter

p = Dict(:α => [1, 2],
    :solver => [SolverA,SolverB],
    :β => Derived(:α, x -> x^2),
    )


@test Set([ Dict(:α => 1, :solver => SolverA, :β => 1),
    Dict(:α => 2, :solver => SolverA, :β => 4),
    Dict(:α => 1, :solver => SolverB, :β => 1),
    Dict(:α => 2, :solver => SolverB, :β => 4),
    ]) == Set(dict_list(p))

p2 = Dict(:α => [1, 2],
    :β => [10,100],
    :solver => [SolverA,SolverB],
    :γ => Derived([:α,:β], (x,y) -> x^2 + 2y),
    )

@test Set([ Dict(:α => 1, :solver => SolverA, :β => 10, :γ => 21),
    Dict(:α => 2, :solver => SolverA, :β => 10, :γ => 24),
    Dict(:α => 1, :solver => SolverB, :β => 10, :γ => 21),
    Dict(:α => 2, :solver => SolverB, :β => 10, :γ => 24),
    Dict(:α => 1, :solver => SolverA, :β => 100, :γ => 201),
    Dict(:α => 2, :solver => SolverA, :β => 100, :γ => 204),
    Dict(:α => 1, :solver => SolverB, :β => 100, :γ => 201),
    Dict(:α => 2, :solver => SolverB, :β => 100, :γ => 204),
   ]) == Set(dict_list(p2))

end
