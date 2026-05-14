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