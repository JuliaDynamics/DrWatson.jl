#Update macro and functions for handling named tuples

# Simple update macro for handling multiple updates in a block
macro update(base, update_expr)
    # Verify if the expr is a block or a line
    if update_expr.head == :block
        # if a block, extract the expressions
        updates = update_expr.args

        # Start with the base configuration
        # The :($(esc(base))) is used to ensure the base is evaluated in the correct context (the macro's context)
        current_config = :($(esc(base)))

        # Process each update expression in the block
        for update_expr in updates
            isa(update_expr, LineNumberNode) && continue  # Ensure it's an expression

            # Extract the left-hand side and right-hand side, the left-hand side is the field to update, the right hand side is the new value
            lhs, rhs = update_expr.args

            # Escape the value to ensure it's evaluated in the correct context
            value = :($(esc(rhs)))

            # Assert the left-hand side has the correct structure
            # if isa(lhs, Symbol)
            #     pushfirst!(fields, lhs)  # Add the first part
            # else
            # @assert lhs.head == Symbol(".")
            fields = []
            while !isa(lhs, Symbol)
                pushfirst!(fields, lhs.args[2].value)  # Collect the field names
                lhs = lhs.args[1]  # Move to the next part of the path
            end
            pushfirst!(fields, lhs)  # Add the first part

            # Convert the field names into symbols
            field_syms = [Symbol(f) for f in fields]

            # Apply the update to the current config using the helper function
            current_config = :(update_with_merge($current_config, $field_syms, $value))
        end
        return current_config
    else
        lhs, rhs = update_expr.args  # Extract the left-hand side and right-hand side


        # @assert lhs.head == Symbol(".")
        fields = []
        while !isa(lhs, Symbol)
            pushfirst!(fields, lhs.args[2].value)  # Collect the field names
            lhs = lhs.args[1]  # Move to the next part of the path
        end
        pushfirst!(fields, lhs)  # Add the first part

        # Convert the field names into symbols
        field_syms = [Symbol(f) for f in fields]

        # Return the updated expression with deep merge
        return :(update_with_merge($base, $field_syms, $rhs))
    end
    # end
end

# Deep merge function for named tuples
function update_with_merge(base_config::NamedTuple, path::Vector{Symbol}, value, full_path=nothing)
    full_path = isnothing(full_path) ? path : full_path
    if length(path) == 1
        # If it's the final field, update the value
        @debug "Updating field $(join(full_path,".")) to $value"
        return merge(base_config, (path[1] => value,))
    else
        key = path[1]
        if !haskey(base_config, key) 
            @warn("Field $key in $(join(full_path,".")) does not exist, assign it to an empty NamedTuple")
            base_config = merge(base_config, (key => NamedTuple(),))
            # updated_sub = update_with_merge(base_config, path, value)
            # sub = (;tmp=nothing)
        end
        sub = getfield(base_config, key)
        if isa(sub, NamedTuple)
            # Recursively update the nested subfield
            updated_sub = update_with_merge(sub, path[2:end], value, full_path)
        else
            @warn("Field $key in $(join(full_path,".")) is not a NamedTuple. Overwriting $key with a new NamedTuple.")
            updated_sub = update_with_merge(NamedTuple(), path[2:end], value, full_path)
        end

        # Merge the updated subfield back into the base
        return merge(base_config, (key => updated_sub,))
    end
end

macro update!(base, update_expr)
    if update_expr.head == :block
        updates = update_expr.args
        current_config = :($(esc(base)))

        # Process each update expression in the block
        for update_expr in updates
            isa(update_expr, LineNumberNode) && continue  # Ensure it's an expression
            lhs, rhs = update_expr.args
            value = :($(esc(rhs)))
            fields = []
            while !isa(lhs, Symbol)
                pushfirst!(fields, lhs.args[2].value)  # Collect the field names
                lhs = lhs.args[1]  # Move to the next part of the path
            end
            pushfirst!(fields, lhs)  # Add the first part
            field_syms = [Symbol(f) for f in fields]
            current_config = :(update_with_merge($current_config, $field_syms, $value))
        end
        # return current_config
    else
        lhs, rhs = update_expr.args  # Extract the left-hand side and right-hand side
        fields = []
        while !isa(lhs, Symbol)
            pushfirst!(fields, lhs.args[2].value)  # Collect the field names
            lhs = lhs.args[1]  # Move to the next part of the path
        end
        pushfirst!(fields, lhs)  # Add the first part
        field_syms = [Symbol(f) for f in fields]
        current_config =  :(update_with_merge($base, $field_syms, $rhs))
    end
    return Expr(:(=), esc(base), :($current_config))
end



function pretty_nt_print(value, indent=0)
    if isa(value, NamedTuple)
        println("{")
        for (subfield, subvalue) in pairs(value)
            print(" " ^ (indent + 2))
            print("  $subfield := ")
            pretty_nt_print(subvalue, indent + 2)
        end
        println(" " ^ (indent+2) * " " * "}")
    else
        println(value)
    end
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
