using DrWatson, Test

d = (a = 0.153456453, b = 5.0, mode = "double")
@test savename(d; digits = 4) == "a=0.1535_b=5_mode=double"
@test savename(d, (String,)) == "mode=double"

rick = (never = "gonna", give = "you", up = "!");
@test savename(rick) == "give=you_never=gonna_up=!"
