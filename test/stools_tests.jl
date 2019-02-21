using DrWatson, Test

# Test commit function
com = current_commit(dirname(@__DIR__))
@test com !== nothing
@test typeof(com) == String

# Test dictionary expansion
c = Dict(:a => [1, 2], :b => 4);
c1 = [ Dict(:a=>1,:b=>4)
 Dict(:a=>2,:b=>4)]

@test dict_list(c) == c1

c[:c] = "test"; c[:d] = ["lala", "lulu"];
c2 = [ Dict(:a=>1,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lala",:c=>"test")
 Dict(:a=>1,:b=>4,:d=>"lulu",:c=>"test")
 Dict(:a=>2,:b=>4,:d=>"lulu",:c=>"test")]

@test dict_list(c) == c2

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

@test dict_list(c) == c3
