using FileIO
using DrWatson
using DataFrames
###############################################################################
#                        Setup Folder structure                               #
###############################################################################

cd(@__DIR__)
isdir("testdir") && rm("testdir", recursive=true)
mkdir("testdir")
initialize_project("testdir")
quickactivate("testdir")

###############################################################################
#                           Create Dummy Data                                 #
###############################################################################
mkdir(datadir()*"results")
cd(datadir()*"results")

d = Dict("a" => 1, "b" => "2", "c" => rand(10))
FileIO.save(savename(d)*".jld2",d)

d = Dict("a" => 3, "b" => "4", "c" => rand(10), "d" => Float64)
FileIO.save(savename(d)*".jld2",d)

mkdir("subfolder")
cd("subfolder/")

d = Dict("a" => 4., "b" => "twenty" , "d" => Int)
FileIO.save(savename(d)*".jld2",d)

###############################################################################
#                           Collect Data Into DataFrame                       #
###############################################################################
using Statistics
special_list = [ :lv_mean => data -> mean(data["c"]),
                 :lv_lar  => data -> var(data["c"])]

black_list = ["c"]
collect_results(; special_list=special_list, black_list = black_list)
###############################################################################
#                           Add another file in a sub sub folder              #
###############################################################################
mkdir("subsubfolder")
cd("subsubfolder")
d = Dict("a" => 7, "b" => 35. , "d" => Number, "c" => rand(5))
FileIO.save(savename(d)*".jld2",d)

collect_results(; special_list=special_list, black_list = black_list)

###############################################################################
#                           Load and analyze  DataFrame                       #
###############################################################################

using BSON

df = BSON.load(datadir()*"results_dataframe.bson")[:df]


###############################################################################
#                                 Delete Folders                              #
###############################################################################

# cd("../../../..")
# rm("testdir", recursive=true)
