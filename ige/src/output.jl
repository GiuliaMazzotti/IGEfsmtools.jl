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
    "meltflux_out" => Dict(
        "longname" => "runoff from snow",
        "unit" => "mm/tstep",
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
    "snowdepth" => Dict(
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
    "Sdirt" => Dict(
        "longname" => "incoming direct shortwave radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Sdift" => Dict(
        "longname" => "incoming diffuse shortwave radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "LWt" => Dict(
        "longname" => "incoming longwave radiation",
        "unit" => "W/m^2",
        "type" => MEAN
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
    "SWsrf" => Dict(
        "longname" => "net shortwave radiation absorbed by the surface",
        "unit" => "W/m^2",
        "type" => MEAN
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
    "KH" => Dict(
        "longname" => "Eddy diffusivity for heat to the atmosphere",
        "unit" => "m/s",
        "type" => MEAN
    ),
    "KHg" => Dict(
        "longname" => "Eddy diffusivity for heat from the ground",
        "unit" => "m/s",
        "type" => MEAN
    ),
    "KWg" => Dict(
        "longname" => "Eddy diffusivity for water from the ground",
        "unit" => "m/s",
        "type" => MEAN
    ),
    "snowdepthmin" => Dict(
        "longname" => "minimum snow depth at time step of swemin",
        "unit" => "m",
        "type" => INSTANT
    ),
    "snowdepthmax" => Dict(
        "longname" => "maximum snow depth at time stemp of swemax",
        "unit" => "m",
        "type" => INSTANT
    ),
    "snowdepthhist" => Dict(
        "longname" => "history of snow depth during last 14 days (most recent entries first)",
        "unit" => "m",
        "type" => INSTANT
    ),
    "swemin" => Dict(
        "longname" => "minimum swe during the season",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "swemax" => Dict(
        "longname" => "maximum swe during the season",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "swehist" => Dict(
        "longname" => "history of SWE during last 14 days",
        "unit" => "mm",
        "type" => INSTANT
    )
)

# Variable access functions

get_variable_value(fsm::FSM, ::Val{:snowdepth}) = dropdims(sum(fsm.Ds, dims=1), dims=1) .* fsm.fsnow
get_variable_value(fsm::FSM, ::Val{:SWE}) = dropdims(sum(fsm.Sice .+ fsm.Sliq, dims=1), dims=1)
get_variable_value(fsm::FSM, ::Val{:Sliq}) = dropdims(sum(fsm.Sliq, dims=1), dims=1)
get_variable_value(fsm::FSM, ::Val{:Sice}) = dropdims(sum(fsm.Sice, dims=1), dims=1)
get_variable_value(fsm::FSM, ::Val{var}) where var = getfield(fsm, var)
get_variable_value(fsm::FSM, var::Symbol) = get_variable_value(fsm, Val(var))
get_variable_value(fsm::FSM, ::Val{:Tsnow1}) = get_variable_value(fsm, :Tsnow)[1,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsnow2}) = get_variable_value(fsm, :Tsnow)[2,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsnow3}) = get_variable_value(fsm, :Tsnow)[3,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil1}) = get_variable_value(fsm, :Tsoil)[1,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil2}) = get_variable_value(fsm, :Tsoil)[2,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil3}) = get_variable_value(fsm, :Tsoil)[3,:,:]
get_variable_value(fsm::FSM, ::Val{:Tsoil4}) = get_variable_value(fsm, :Tsoil)[4,:,:]

get_variable_size(fsm::FSM, ::Val{:snowdepth}) = (fsm.Nx, fsm.Ny)
get_variable_size(fsm::FSM, ::Val{:SWE}) = (fsm.Nx, fsm.Ny)
get_variable_size(fsm::FSM, ::Val{:Sliq_out}) = (fsm.Nx, fsm.Ny)
get_variable_size(fsm::FSM, ::Val{var}) where var = size(getfield(fsm, var))
get_variable_size(fsm::FSM, var::Symbol) = get_variable_size(fsm, Val(var))

# Function for creating methods for saving data
# **STEP 1** Create the output_dicts corresponding to the raw tables and info for every output variable "make_saver"
# **STEP 2** At every time step, call "fill_saver" (resp. "fill_daily_saver") to fill the output tables with the corresponding values
# **STEP 3** Create the file.nc and save it "grid_saver" (resp. "pt_saver")

function make_saver(output_vars::Vector{String}, Nx::Int32, Ny::Int32, period::Int32) # for daily simu initialize two output_dicts with make saver : one with period/24 and one with period=24, loop on output_dicts daily (every 24h)
    invalid_vars = setdiff(output_vars, keys(AVAILABLE_OUTPUT_VARS))
    !isempty(invalid_vars) && error("Invalid variables: $(join(invalid_vars, ", "))")

    output_dicts = Dict[]
    for var in output_vars
        output_dict = Dict(
            "data" => fill(0.0,Nx,Ny,period),
            "shortname" => var,
            "longname" => AVAILABLE_OUTPUT_VARS[var]["longname"],
            "unit" => AVAILABLE_OUTPUT_VARS[var]["unit"]
        )
        push!(output_dicts, output_dict)
    end
    return output_dicts
end

function fill_daily_saver(output_dicts::Vector{Dict}, daily_output_dicts::Vector{Dict}, step::Int32) # here step is equal to period/24, to call at each time step
    for var in keys(output_dicts)
        output_dicts[var][data][:,:,step] = dropdims(mean(daily_output_dicts[var][data], dims=3), dims=3)
    end
    return output_dicts
end

function fill_saver(fsm::FSM, output_dicts::Vector{Dict}, step::Int32) # to call at each time step
    for var in keys(output_dicts)
        output_dicts[var][data][:,:,step] = get_variable_value(fsm, var)
    end
    return output_dicts
end

function grid_saver(output_dicts::Vector{Dict}, filepath::String, Nx::Int32, Ny::Int32, period::Int32)
    file = NCDataset(filepath, "c")
    defDim(file,"time",period)
    defDim(file,"x",Nx)
    defDim(file,"y",Ny)

    for var in keys(output_dicts)
        defVar(file,var,output_dicts[var][data])
    end

    for output_dict in output_dicts
        output_dict["data"] .= 0.0
    end
    return nothing
end

function pt_saver(output_dicts::Vector{Dict}, filepath::String, Nx::Int32, period::Int32)
    file = NCDataset(filepath, "c")
    defDim(file,"time",period)
    defDim(file,"Nb_points",Nx)

    for var in keys(output_dicts)
        defVar(file,var,output_dicts[var][data])
    end

    for output_dict in output_dicts
        output_dict["data"] .= 0.0
    end
    return nothing
end