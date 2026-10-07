using SHA, Dates

canon(x::AbstractDict) = "{" * join(("$k=>$(canon(x[k]))" for k in sort!(collect(keys(x)); by = string)), ",") * "}"
canon(x) = repr(x)

function set_run_id(settings)
    config = deepcopy(settings)
    delete!(config["INIT"], "shapefile")
    return bytes2hex(sha1(canon(config)))[1:8], canon(config)
end

function md_config(io, x::AbstractDict, indent = 0)
    for k in sort!(collect(keys(x)); by = string)
        v = x[k]
        if v isa AbstractDict
            println(io, " "^indent, "- ", k, ":")
            md_config(io, v, indent + 2)
        elseif v isa AbstractVector
            println(io, " "^indent, "- ", k, ": [", join(("`$e`" for e in v), ", "), "]")
        else
            println(io, " "^indent, "- ", k, ": `", v, "`")
        end
    end
end

function log_run(md_file, id, settings)
    isfile(md_file) && occursin("## run_$id\n", read(md_file, String)) && return false   # already logged
    open(md_file, "a") do io
        println(io, "## run_$id")
        println(io, "- date: ", now())
        md_config(io, settings)
        println(io)
    end
    return true
end
