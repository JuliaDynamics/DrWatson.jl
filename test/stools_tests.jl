using DrWatson, Test

# Test commit function
com = gitdescribe(@__DIR__)
@test com === nothing

com = gitdescribe(dirname(@__DIR__))
@test com !== nothing
@test typeof(com) <: String
@test com[1] == 'v' # test that it has a version tag
# tag!
d1 = Dict(:x => 3, :y => 4)
d2 = Dict("x" => 3, "y" => 4)
for d in (d1, d2)
    d = tag!(d, dirname(@__DIR__))

    @test haskey(d, keytype(d)(:gitcommit))
    @test d[keytype(d)(:gitcommit)] |> typeof <: String
end

# @tag!
for d in (d1, d2)
    d = @tag!(d, @__DIR__)
    @test !haskey(d, keytype(d)(:gitcommit))

    d = @tag!(d, dirname(@__DIR__))
    @test d[keytype(d)(:gitcommit)] |> typeof <: String
    @test d[keytype(d)(:script)][1:4] == "test"
end

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
