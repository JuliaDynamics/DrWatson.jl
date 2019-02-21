using DrWatson, Test

# Test commit function
com = current_commit(dirname(@__DIR__))
@test com !== nothing
@test typeof(com) == String

# Test dictionary expansion
c = Dict(:a => [1, 2], :b => 4);
c1 = [ Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)]

v1 = dict_list(c)
for el in c1
    @test el ∈ v1
end

c[:c] = "test"; c[:d] = ["lala", "lulu"];
c2 = [ Dict(:a=>1,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:c=>"test")]

v2 = dict_list(c)
for el in c2
    @test el ∈ v2
end


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

# tag!
d1 = Dict(:x => 3, :y => 4)
d2 = Dict("x" => 3, "y" => 4)
for d in (d1, d2)
    d = tag!(d, dirname(@__DIR__))

    @test haskey(d, keytype(d)(:commit))
    @test d[keytype(d)(:commit)] |> typeof == String
end
