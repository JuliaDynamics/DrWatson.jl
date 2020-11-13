using DrWatson, Test

# Test commit function
com = gitdescribe(@__DIR__)
@test com isa String

com = gitdescribe(dirname(@__DIR__))
@test com !== nothing
@test typeof(com) <: String
@test com[1] == 'v' # test that it has a version tag
# tag!
d1 = Dict(:x => 3, :y => 4)
d2 = Dict("x" => 3, "y" => 4)
for d in (d1, d2)
    d = tag!(d, gitpath=@__DIR__)

    @test haskey(d, keytype(d)(:gitcommit))
    @test d[keytype(d)(:gitcommit)] |> typeof <: String
end

# @tag!
for d in (d1, d2)
    d = @tag!(d, gitpath=@__DIR__)
    @test haskey(d, keytype(d)(:gitcommit))
    @test d[keytype(d)(:gitcommit)] |> typeof <: String
    @test split(d[keytype(d)(:script)], '#')[1] == basename(@__FILE__)
end

# Tag kw-functions

d = Dict(:x => 3, :y => 4)
d_new = tag!(d)

@test d == d_new

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
    a = load(joinpath(tmpdir, r))
    @test a ∈ v3
end
rm(tmpdir, force = true, recursive = true)
@test !isdir(tmpdir)

