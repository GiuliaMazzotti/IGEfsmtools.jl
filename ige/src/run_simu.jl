const settings_default = Dict(
    "tile" => "open",
    "config" => Dict("SNFRAC" => 0),
    "params" => Dict("wind_scaling" => 1.0, "dt" => 3600, "zT" => 1.5, "zU" => 5.0, "zRH" => 1.5),
    "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/balises/mask/meteo/FORCING_2000080106_2001080106.nc", # change it
    "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
    "list_id" => "all", # for s2m poste only
    "out_file" => string(@__DIR__, "/../../../Data/outputs/output_test.nc"),
    "output_vars" => ["time", "Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"],
)


"""
    run_grid_simulation(; kwargs...)

Run a grid-based snow model simulation for open, forest or glacier tiles.
"""
function run_grid_simulation(;
    settings::Dict=settings_default,
    Tf::Type=Float32,
    Ti::Type=Int32,
    verbose::Bool=true,
)
    lus, Nx, Ny, time = init_grid(settings)

    fsm = setup(Tf, Ti, lus, Nx, Ny, settings)
    met = MET{Tf,Ti}(Nx=Nx, Ny=Ny)

    # Get output variables from settings
    output_vars = get(settings, "output_vars", ["time", "Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"])

    # Create accumulator and saver functions for storing model results
    output_dicts = make_saver(output_vars, Nx, Ny, length(time))

    # Run model
    for i in eachindex(time)

        t_i = time[i]
        elapsed_time = @elapsed begin # ??

            # Read forcing data
            read_meteo!(met, i, settings)

            # Run model
            step!(fsm, met, t_i)

            # Save results
            fill_saver(fsm, output_dicts, t_i)
        end
        verbose && println(t, ", run time=", elapsed_time, " s")
    end

    grid_saver(output_dicts, settings[out_file], Nx, Ny, length(time))

end

function run_grid_daily_simulation(;
    settings::Dict=settings_default,
    Tf::Type=Float32,
    Ti::Type=Int32,
    verbose::Bool=true,
)
    lus, Nx, Ny, time = init_grid(settings)

    fsm = setup(Tf, Ti, lus, Nx, Ny, settings)
    met = MET{Tf,Ti}(Nx=Nx, Ny=Ny)

    # Get output variables from settings
    output_vars = get(settings, "output_vars", ["time", "Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"])

    # Create accumulator and saver functions for storing model results
    output_dicts = make_saver(output_vars, Nx, Ny, length(time)/24)
    daily_output_dicts =  make_saver(output_vars, Nx, Ny, 24)

    d = 1
    daily = 1

    # Run model
    for i in eachindex(time)

        t_i = time[i]
        elapsed_time = @elapsed begin # ??

            # Read forcing data
            read_meteo!(met, i, settings)

            # Run model
            step!(fsm, met, t_i)

            # Save results
            if daily <= 24            
                fill_saver(fsm, daily_output_dicts, t_i)
                daily += 1
            else
                fill_saver(fsm, output_dicts, d)
                d += 1
                daily = 1
            end
        end
        verbose && println(t, ", run time=", elapsed_time, " s")
    end

    grid_saver(output_dicts, settings[out_file], Nx, Ny, length(time)/24)

end

function run_poste_simulation(;
    settings::Dict=settings_default,
    Tf::Type=Float32,
    Ti::Type=Int32,
    verbose::Bool=true,
)
    lus, Nx, Ny, time = init_poste(settings)

    fsm = setup(Tf, Ti, lus, Nx, Ny, settings)
    met = MET{Tf,Ti}(Nx=Nx, Ny=Ny)

    # Get output variables from settings
    output_vars = get(settings, "output_vars", ["time", "Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"])

    # Create accumulator and saver functions for storing model results
    output_dicts = make_saver(output_vars, Nx, Ny, length(time))

    # Run model
    for i in eachindex(time)

        t_i = time[i]
        elapsed_time = @elapsed begin # ??

            # Read forcing data
            read_meteo!(met, i, settings)

            # Run model
            step!(fsm, met, t_i)

            # Save results
            fill_saver(fsm, output_dicts, i)
        end
        verbose && println(t, ", run time=", elapsed_time, " s")
    end

    pt_saver(output_dicts, settings[out_file], Nx, length(time))

end

function run_point_simulation(;
    settings::Dict=settings_default,
    Tf::Type=Float32,
    Ti::Type=Int32,
    verbose::Bool=true,
)

    lus, Nx, Ny, time = init_point(settings)

    fsm = setup(Tf, Ti, lus, Nx, Ny, settings)
    met = MET{Tf,Ti}(Nx=Nx, Ny=Ny)

    # Get output variables from settings
    output_vars = get(settings, "output_vars", ["time", "Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"])

    # Create accumulator and saver functions for storing model results
    output_dicts = make_saver(output_vars, Nx, Ny, length(time))

    # Run model
    for i in eachindex(time)

        t_i = time[i]
        elapsed_time = @elapsed begin # ??

            # Read forcing data
            read_meteo!(met, i, settings)

            # Run model
            step!(fsm, met, t_i)

            # Save results
            fill_saver(fsm, output_dicts, i)
        end
        verbose && println(t, ", run time=", elapsed_time, " s")
    end

    pt_saver(output_dicts, settings[out_file], Nx, length(time))

end