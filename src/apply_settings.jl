# Set settings[path[1]][path[2]]...[path[end]] = value
function set_nested!(d::AbstractDict, path, value)
    for key in path[1:end-1]
        d = d[key]                # errors on a typo in an intermediate key
    end
    d[path[end]] = value
    return d
end

function apply_overrides(settings, overrides)
    s = Dict(k => copy(v) for (k, v) in settings)   # one level deep: INIT, TUNING, ...
    for (path, value) in overrides
        # copy each intermediate dict before modifying it
        d = s
        for key in path[1:end-1]
            d[key] = copy(d[key])
            d = d[key]
        end
        d[path[end]] = value
    end
    return s
end