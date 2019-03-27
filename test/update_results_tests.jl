using DrWatson, Test
using BSON, DataFrames
###############################################################################
#                        Setup Folder structure                               #
###############################################################################
cd(@__DIR__)
isdir("testdir") && rm("testdir", recursive=true)
mkdir("testdir")
initialize_project("testdir"; git = false)
quickactivate("testdir")

###############################################################################
#                           Create Dummy Data                                 #
###############################################################################
mkdir(datadir()*"results")
cd(datadir()*"results")

d = Dict("a" => 1, "b" => "2", "c" => rand(10))
BSON.bson(savename(d)*".bson", d)

d = Dict("a" => 3, "b" => "4", "c" => rand(10), "d" => Float64)
BSON.bson(savename(d)*".bson", d)

mkdir("subfolder")
cd("subfolder/")

d = Dict("a" => 4., "b" => "twenty" , "d" => Int)
BSON.bson(savename(d)*".bson", d)

###############################################################################
#                           Collect Data Into DataFrame                       #
###############################################################################
using Statistics
special_list = [ :lv_mean => data -> mean(data["c"]),
                 :lv_lar  => data -> var(data["c"])]

black_list = ["c"]

folder = datadir()*"results"
defaultname = joinpath(dirname(folder), "results_$(basename(folder)).bson")
isfile(defaultname) && rm(defaultname)
cres = collect_results(folder;
subfolders = true, special_list=special_list, black_list = black_list)

@test size(cres) == (3, 6)
for n in (:a, :b, :lv_mean)
    @test n ∈ names(cres)
end
@test :c ∉ names(cres)

###############################################################################
#                           Add another file in a sub sub folder              #
###############################################################################
mkdir("subsubfolder")
cd("subsubfolder")
d = Dict("a" => 7, "b" => 35. , "d" => Number, "c" => rand(5))
BSON.bson(savename(d)*".bson", d)

cres2 = collect_results(folder;
subfolders = true, special_list=special_list, black_list = black_list)

@test size(cres2) == (4, 6)
@test sort(names(cres)) == sort(names(cres2))

###############################################################################
#                           Load and analyze  DataFrame                       #
###############################################################################

@test isfile(defaultname)
df = BSON.load(defaultname)[:df]
@test size(df) == size(cres2)
@test sort(names(df)) == sort(names(cres2))

###############################################################################
#                                 Delete Folders                              #
###############################################################################

cd(@__DIR__)
rm("testdir", recursive=true)
