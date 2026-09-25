@enum AggregationType INSTANT SUM MEAN

# Variables available for saving to file

const AVAILABLE_OUTPUT_VARS = Dict(
    "time" => Dict(
        "longname" => "datetime",
        "unit" => "",
        "type" => INSTANT
    ),
    "Nb_points" => Dict(
        "longname" => "stations id",
        "unit" => "",
        "type" => INSTANT
    ),
    "Nx" => Dict(
        "longname" => "latitude",
        "unit" => "",
        "type" => INSTANT
    ),
    "Ny" => Dict(
        "longname" => "longitude",
        "unit" => "",
        "type" => INSTANT
    ),
    "Roff" => Dict(
        "longname" => "total runoff",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "Roff_snow" => Dict(
        "longname" => "runoff from snow tile",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "meltflux_out" => Dict(
        "longname" => "runoff from snow",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "Icemlt" => Dict(
        "longname" => "runoff rate from ice",
        "unit" => "mm/s",
        "type" => SUM
    ),
    "Sbsrf" => Dict(
        "longname" => "sublimation from snow",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "fsnow" => Dict(
        "longname" => "snow covered fraction",
        "unit" => "-",
        "type" => INSTANT
    ),
    "Ds" => Dict(
        "longname" => "snow depth",
        "unit" => "m",
        "type" => INSTANT
    ),
    "SWE" => Dict(
        "longname" => "snow water equivalent",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "Tsrf" => Dict(
        "longname" => "surface temperature",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Sliq" => Dict(
        "longname" => "liquid water content",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "Sice" => Dict(
        "longname" => "solid water content",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "Nsnow" => Dict(
        "longname" => "number of snow layers",
        "unit" => "-",
        "type" => INSTANT
    ),
    "albs" => Dict(
        "longname" => "snow albedo",
        "acronymn" => "alse",
        "unit" => "-",
        "type" => INSTANT
    ),
    "G" => Dict(
        "longname" => "heat flux into the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "H" => Dict(
        "longname" => "sensible heat flux",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "LE" => Dict(
        "longname" => "latent heat flux",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Rnet" => Dict(
        "longname" => "net radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "asrf_out" => Dict(
        "longname" => "surface albedo",
        "unit" => "-",
        "type" => INSTANT
    ),
    "Tsnow1" => Dict(
        "longname" => "snow temperatures in layer 1",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsnow2" => Dict(
        "longname" => "snow temperatures in layer 2",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsnow3" => Dict(
        "longname" => "snow temperatures in layer 3",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil1" => Dict(
        "longname" => "soil temperatures in layer 1",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil2" => Dict(
        "longname" => "soil temperatures in layer 2",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil3" => Dict(
        "longname" => "soil temperatures in layer 3",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil4" => Dict(
        "longname" => "soil temperatures in layer 4",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Esrf" => Dict(
        "longname" => "moisture flux from the surface",
        "unit" => "kg/m^2/s",
        "type" => MEAN
    ),
    "Gsoil" => Dict(
        "longname" => "heat flux into soil",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Hsrf" => Dict(
        "longname" => "sensible heat flux from the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "LEsrf" => Dict(
        "longname" => "latent heat flux from the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Rsrf" => Dict(
        "longname" => "net radiation at surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Melt" => Dict(
        "longname" => "surface melt rate",
        "unit" => "kg/m^2/s",
        "type" => MEAN
    ),
)

# Variable access functions

get_variable_value(fsm::FSM, ::Val{:Ds}) = dropdims(sum(fsm.state.Ds, dims=1), dims=1)
# get_variable_value(fsm::FSM, ::Val{:Ds}) = dropdims(sum(fsm.Ds, dims=1), dims=1) .* fsm.fsnow
get_variable_value(fsm::FSM, ::Val{:SWE}) = dropdims(sum(fsm.state.Sice .+ fsm.state.Sliq, dims=1), dims=1)
get_variable_value(fsm::FSM, ::Val{:Sliq}) = dropdims(sum(fsm.state.Sliq, dims=1), dims=1)
get_variable_value(fsm::FSM, ::Val{:Sice}) = dropdims(sum(fsm.state.Sice, dims=1), dims=1)
# get_variable_value(fsm::FSM, var::Int) = In32(var)
get_variable_value(fsm::FSM, ::Val{:Tsnow1}) = getfield(fsm.state, :Tsnow)[1,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsnow2}) = getfield(fsm.state, :Tsnow)[2,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsnow3}) = getfield(fsm.state, :Tsnow)[3,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil1}) = getfield(fsm.state, :Tsoil)[1,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil2}) = getfield(fsm.state, :Tsoil)[2,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil3}) = getfield(fsm.state, :Tsoil)[3,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil4}) = getfield(fsm.state, :Tsoil)[4,:,:]

get_variable_value(fsm::FSM, ::Val{var}) where var = getfield(fsm.diag, var)
get_variable_value(fsm::FSM, var::Symbol) = get_variable_value(fsm.diag, Val(var))


# get_variable_size(fsm::FSM, var::String) = size(getfield(fsm, var))

# Function for creating methods for saving data
# **STEP 1** Create the output_dicts corresponding to the raw tables and info for every output variable "make_saver"
# **STEP 2** At every time step, call "fill_saver" (resp. "fill_daily_saver") to fill the output tables with the corresponding values
# **STEP 3** Create the file.nc and save it "grid_saver" (resp. "pt_saver")

function make_saver(output_vars::Vector{String}, Nx::Int, Ny::Int, period::Int) # for daily simu initialize two output_dicts with make saver : one with period/24 and one with period=24, loop on output_dicts daily (every 24h)
    invalid_vars = setdiff(output_vars, keys(AVAILABLE_OUTPUT_VARS))
    !isempty(invalid_vars) && error("Invalid variables: $(join(invalid_vars, ", "))")

    output_dicts = Dict[]
    for var in output_vars
        if ! (Ny == 1)
            output_dict = Dict(
                "data" => fill(0.0,Nx,Ny,period),
                "shortname" => var,
                "longname" => AVAILABLE_OUTPUT_VARS[var]["longname"],
                "unit" => AVAILABLE_OUTPUT_VARS[var]["unit"]
            )
        else 
            output_dict = Dict(
                "data" => fill(0.0,Nx,period),
                "shortname" => var,
                "longname" => AVAILABLE_OUTPUT_VARS[var]["longname"],
                "unit" => AVAILABLE_OUTPUT_VARS[var]["unit"]
            )
        end
        push!(output_dicts, output_dict)
    end
    return output_dicts
end

function fill_daily_grid_saver(output_dicts::Vector{Dict}, daily_output_dicts::Vector{Dict}, step::Int) # here step is equal to period/24, to call at each time step
    for var in keys(output_dicts)
        output_dicts[var]["data"][:,:,step] = dropdims(mean(daily_output_dicts[var]["data"], dims=3), dims=3)
    end
    return output_dicts
end

function fill_grid_saver(fsm::FSM, output_dicts::Vector{Dict}, step::Int) # to call at each time step
    for var in keys(output_dicts)
        output_dicts[var]["data"][:,:,step] = get_variable_value(fsm, Val(Symbol(output_dicts[var]["shortname"])))
    end
    return output_dicts
end

function fill_pt_saver(fsm::FSM, output_dicts::Vector{Dict}, step::Int) # to call at each time step
    for var in keys(output_dicts)
        output_dicts[var]["data"][:,step] = get_variable_value(fsm, Val(Symbol(output_dicts[var]["shortname"])))
    end
    return output_dicts
end

function grid_saver(output_dicts::Vector{Dict}, settings::Dict, time::Any)
    file = NCDataset(settings["out_file"], "c")
    defDim(file,"time",length(time)) 
    defDim(file,"x",settings["Nx"])
    defDim(file,"y",settings["Ny"])
    defVar(file,"time",time,("time",))
    defVar(file,"x",settings["x"],("x",))
    defVar(file,"y",settings["y"],("y",))

    for var in keys(output_dicts)
        defVar(file,output_dicts[var]["shortname"],output_dicts[var]["data"], ("x","y","time"), attrib = OrderedDict("units" => output_dicts[var]["unit"]))
    end

    for output_dict in output_dicts
        output_dict["data"] .= 0.0
    end
    return nothing
end

function pt_saver(output_dicts::Vector{Dict}, settings::Dict, time::Any)
    file = NCDataset(settings["out_file"], "c")
    defDim(file,"time",length(time)) # Int
    defDim(file,"Number_of_points",settings["Nx"])
    defVar(file,"time",time, ("time",))
    defVar(file,"Number_of_points",settings["id_point"], ("Number_of_points",))

    for var in keys(output_dicts)
        defVar(file,output_dicts[var]["shortname"],output_dicts[var]["data"], ("Number_of_points","time"), attrib = OrderedDict("units" => output_dicts[var]["unit"]))
    end

    for output_dict in output_dicts
        output_dict["data"] .= 0.0
    end
    return nothing
end