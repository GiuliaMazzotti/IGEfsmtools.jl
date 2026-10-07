# Route a scalar into the immutable Parameters via a functional update.
function set_param!(fsm, sym::Symbol, value)
    v = convert(fieldtype(typeof(fsm.params), sym), value)
    fsm.params = FlexibleSnowModelOSHD.reconstruct(fsm.params; NamedTuple{(sym,)}((v,))...)
    return fsm
end

"""
    apply_params!(fsm, params)

Apply parameter overrides: a `Parameters` scalar is reconstructed onto `fsm.params`;
a `Surface` per-cell array is filled (scalar) or copied (array) in place.
"""
function apply_params!(fsm, params)
    for (key, value) in params
        sym = Symbol(key)
        if hasfield(typeof(fsm.params), sym)
            set_param!(fsm, sym, value)
        elseif hasfield(typeof(fsm.surface), sym)
            arr = getfield(fsm.surface, sym)
            value isa AbstractArray ? (arr .= eltype(arr).(value)) : fill!(arr, eltype(arr)(value))
        else
            throw(ArgumentError("unknown parameter override \"$key\""))
        end
    end
    return fsm
end