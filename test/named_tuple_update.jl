using Logging, Test
errorlogger = ConsoleLogger(stderr, Logging.Error)
with_logger(errorlogger) do
    base = (a=5, b=(d=6, f=7), c=(to="be", or="not to be"))
    my_tuple = @update NamedTuple() begin
        a = 5 # Adding a new nested field
        b.d = 6
        b.f = 7
        c.to = "be"
        c.or = "not to be"
    end
    # ("Tuples are not equal")
    @test my_tuple == base 

    new_config = @update base begin
        b.e = (new="field", m=66) # Adding a new nested field
        b.g.nested = (;new ="field") # Adding a deeper nested field
        b.a = "This is changed" # Changing 
        c = "to be changed" # Changing an existing field
    end

    @update! base begin
        b.e = (new="field", m=66) # Adding a new nested field
        b.g.nested = (;new ="field") # Adding a deeper nested field
        b.a = "This is changed" # Changing 
        c = "to be changed" # Changing an existing field
    end

    # "In-place update failed"
    @test base == new_config

    a = 10
    for a in 1:3
        @update! base begin
            a = a # Adding a new nested field
            b.g.first = "Nested" # Adding a deeper nested field
            b.a = "This is changed" # Changing 
            c = "to be changed" # Changing an existing field
        end

        # "Local scope variable a not assigned correctly"
        @assert base.a == a 
    end

    base = @update base a = "inline" 
    @update! base b = "inline with !" 

    #"Inline update failed"
    @test base.a  == "inline"
    # "Inline update! failed"
    @test base.b  == "inline with !" 
end


# ## Example usage:
# base = (a=5, b=(d=6, f=7), c=(to="be", or="not to be"))

# new_config = @update base begin
#     b.e = (new="field", m=66) # Adding a new nested field
#     b.g.nested = (;new ="field") # Adding a deeper nested field
#     b.a = "This is changed" # Changing 
#     c = "to be changed" # Changing an existing field
# end

# println("Base configuration:")
# pretty_nt_print(base)

# println("\nUpdated configuration:")
# pretty_nt_print(new_config)

# @update! base begin
#     b.e = (l=65, m=66) # Adding a new nested field
#     b.g.first = "Nested" # Adding a deeper nested field
#     b.a = "This is changed" # Changing 
#     c = "to be changed" # Changing an existing field
# end

# # @assert base == new_config

# base = @update base a = "inline" 
# @update! base b = "inline with !" 
