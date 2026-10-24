## Function section
# include("../src/IGEfsmtools.jl")
using IGEfsmtools
using FlexibleSnowModelOSHD
using Infiltrator
using NCDatasets
using ProgressMeter
using ArchGDAL
using DataFrames
using MAT


"""
    preload_forcing(times, run_id, settings_domain, settings_common,
                    prec_multi, dt, met_host, keep, Tf, verbose = true)

Run the operational meteo reader (`read_input!`) once over all time steps and snapshot the
fully-processed forcing for the selected stations `keep`.
"""
function get_station_name(list_id, shapefile_path)
    station_shapefile = ArchGDAL.read(shapefile_path)
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame 
    shp = shapefile[in.(shapefile.ID, Ref(list_id)),:]
    sort!(shp, [:ID])
    return vec(shp.Name)
end

function get_station_massif(list_id, shapefile_path)
    station_shapefile = ArchGDAL.read(shapefile_path)
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame 
    shp = shapefile[in.(shapefile.ID, Ref(list_id)),:]
    sort!(shp, [:ID])
    return vec(shp.massif_num)
end

const METRIC_COLS = ["config", "run_id", "id", "altitude", "massif", "band_lo", "n_days", "rmse", "bias", "r2"]

function append_metrics(path, new)
    new = select(new, METRIC_COLS)

    # new or empty file: write with header
    if !isfile(path) || filesize(path) == 0
        CSV.write(path, new)
        return new
    end

    # a file without a header line would have its first data row read as column names
    first_line = readline(path)
    if first_line != join(METRIC_COLS, ",")
        error("$path has no valid header line (first line: \"$first_line\"). " *
              "Add the header or delete the file.")
    end

    old = CSV.read(path, DataFrame; types = Dict(:run_id => String))
    new = filter(:run_id => id -> id ∉ Set(old.run_id), new)      # skip runs already in the file
    if nrow(new) == 0
        @info "All runs already in $(basename(path)), nothing appended"
        return old
    end
    CSV.write(path, new; append = true, writeheader = false)
    return vcat(old, new)
end

function preload_forcing(settings, Tf)

    meteo_file = Dataset(settings["file_path"]) 
    begin_t = findfirst(>=(DateTime(settings["period"][1], 8, 1)), meteo_file["time"][:])
    end_t = findlast(<(DateTime(settings["period"][2], 8, 1)), meteo_file["time"][:])
    stations = meteo_file["station"][:]
    time = meteo_file["time"][begin_t:end_t]

    ntimes = length(time)
    if  ! (settings["list_id"] == "all") 
        nstations = length(settings["list_id"])
        mask = indexin(sort(settings["list_id"]), meteo_file["station"][:])
        mask = Int64.(filter(!isnothing, mask))

        DIR_SW    = meteo_file["DIR_SWdown"][begin_t:end_t,mask]           
        SCA_SW    = meteo_file["SCA_SWdown"][begin_t:end_t,mask]
        LWdown    = meteo_file["LWdown"][begin_t:end_t,mask]
        Snowf     = meteo_file["Snowf"][begin_t:end_t,mask]
        Rainf     = meteo_file["Rainf"][begin_t:end_t,mask]
        Tair      = meteo_file["Tair"][begin_t:end_t,mask]
        Qair      = meteo_file["Qair"][begin_t:end_t,mask]
        Wind      = meteo_file["Wind"][begin_t:end_t,mask]
        PSurf     = meteo_file["PSurf"][begin_t:end_t,mask]
        Alt       = meteo_file["ZS"][mask]

        settings["list_id"] = sort(settings["list_id"])

    else 
        settings["list_id"] = stations
        nstations = length(stations)

        DIR_SW    = meteo_file["DIR_SWdown"][begin_t:end_t,:]         
        SCA_SW    = meteo_file["SCA_SWdown"][begin_t:end_t,:]
        LWdown    = meteo_file["LWdown"][begin_t:end_t,:]
        Snowf     = meteo_file["Snowf"][begin_t:end_t,:]
        Rainf     = meteo_file["Rainf"][begin_t:end_t,:]
        Tair      = meteo_file["Tair"][begin_t:end_t,:]
        Qair      = meteo_file["Qair"][begin_t:end_t,:]
        Wind      = meteo_file["Wind"][begin_t:end_t,:]
        PSurf     = meteo_file["PSurf"][begin_t:end_t,:]
        Alt       = meteo_file["ZS"]
    end

    settings["alt"] = vec(Alt)
    settings["name"] = get_station_name(sort(settings["list_id"]), settings["shapefile"])
    settings["massif"] = get_station_massif(sort(settings["list_id"]), settings["shapefile"])

    alloc() = zeros(Tf, nstations, ntimes)
    forcing = (
        Sdir = alloc(), Sdif = alloc(), Sdird = alloc(), LW = alloc(),
        Rf = alloc(), Sf = alloc(), Ta = alloc(), RH = alloc(),
        Ua = alloc(), Ps = alloc(), Sf24h = alloc(),
    )

    forcing.Sdir[:, :] = permutedims(DIR_SW[:,:], [2 1])
    forcing.Sdif[:, :] = permutedims(SCA_SW[:,:], [2 1])
    forcing.Sdird[:, :] = permutedims(DIR_SW[:,:], [2 1])
    forcing.LW[:, :] = permutedims(LWdown[:,:], [2 1])
    forcing.Rf[:, :] = permutedims(Rainf[:,:], [2 1]) 
    forcing.Sf[:, :] = permutedims(Snowf[:,:], [2 1]) 
    forcing.Ta[:, :] = permutedims(Tair[:,:], [2 1])
    forcing.RH[:, :] = permutedims(Qair[:,:], [2 1])
    forcing.Ua[:, :] = permutedims(Wind[:,:], [2 1])
    forcing.Ps[:, :] = permutedims(PSurf[:,:], [2 1])
    forcing.Sf24h[:, :] = (c = cumsum(permutedims(Snowf[:,:], [2 1]) .* 3600, dims=2); c .- [zeros(size(c,1), 24) c[:, 1:end-24]])  

    return forcing, time
end

"""
    run_simulation(forcing, landuse, times, settings, Tf, verbose = true)

Run simulation using cached operational forcing.
"""
function run_simulation(forcing, landuse, times, settings, Tf, verbose = true)

    # Setup model on the selected stations
    nstat = size(landuse["elevation"]["data"], 1)
    grid = Grid(Tf; Nx = nstat, Ny = 1)
    build_physics!(grid, settings, landuse)
    physics = get(settings, "physics", Dict())
    schemes = (; (Symbol(k) => v for (k, v) in physics)...)
    fsm = FSM(grid, landuse; schemes...)
    apply_params!(fsm, settings["params"])
    met = MET{Tf}(Nx = nstat)

    # Pre-allocate results
    snowdepth = zeros(length(times), size(fsm.state.Ds, 2))

    progress_bar = verbose ? Progress(length(times), desc = "Running snow model...") : nothing

    for (i, t) in enumerate(times)

        # Inject pre-processed operational forcing
        met.Sdir[:, :] .= forcing.Sdir[:, i]
        met.Sdif[:, :] .= forcing.Sdif[:, i] .*landuse["skyvf"]["data"]
        met.Sdird[:, :] .= forcing.Sdird[:, i]
        met.LW[:, :] .= forcing.LW[:, i]
        met.Rf[:, :] .= forcing.Rf[:, i]
        met.Sf[:, :] .= forcing.Sf[:, i] .*landuse["prec_multi"]["data"]
        met.Ta[:, :] .= forcing.Ta[:, i]
        met.RH[:, :] .= forcing.RH[:, i]
        met.Ua[:, :] .= forcing.Ua[:, i]
        met.Ps[:, :] .= forcing.Ps[:, i]
        met.Sf24h[:, :] .= forcing.Sf24h[:, i]

        # Run model step
        step!(fsm, met, t)

        # Store results
        snowdepth[i, :] = dropdims(sum(fsm.state.Ds, dims = 1), dims = 3)

        if verbose
            next!(progress_bar)
        end
    end

    return snowdepth
end

function save_sim(sim, path)
    mkpath(dirname(path))
    NCDataset(path, "c") do ds
        defDim(ds, "time", length(sim.time))
        defDim(ds, "Number_of_points", length(sim.id))

        defVar(ds, "time", sim.time, ("time",))
        defVar(ds, "station", Int32.(sim.id), ("Number_of_points",))
        defVar(ds, "ZS", Float32.(sim.alt), ("Number_of_points",);
               attrib = ["units" => "m", "long_name" => "altitude"])
        defVar(ds, "name", String.(sim.name), ("Number_of_points",))
        defVar(ds, "massif", sim.massif, ("Number_of_points",))

        v = defVar(ds, "snowdepth", Float32, ("time", "Number_of_points");
                   fillvalue = -9999f0, deflatelevel = 4,
                   attrib = ["units" => "m"])
        v[:, :] = Float32.(sim.data)
    end
end

function run_comparison(settings, obs, runs, Tf; verbose = true)
    all_metrics = DataFrame[]
    sims = Pair{String, Any}[]

    forcing, times = preload_forcing(settings["INIT"], Tf)

    for (name, overrides) in runs
        s = apply_overrides(settings, overrides)
        settings_init, settings_tuning = s["INIT"], s["TUNING"]

        landuse, Nx, Ny = prepare_landuse(settings_init)
        snowdepth = run_simulation(forcing, landuse, times, settings_tuning, Tf, verbose)

        run_id, _ = set_run_id(s)
        log_run("C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/stations/runs_tuning.md", run_id, s)

        sim = (
            time = collect(times), 
            data = snowdepth, 
            id = sort(settings_init["list_id"]),
            alt = settings_init["alt"], 
            name = settings_init["name"],
            massif = settings_init["massif"]
            )
        
        save_sim(sim, joinpath("C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/", "sim_$(run_id).nc")) 

        push!(all_metrics, station_metrics(obs, sim, name, run_id))
        push!(sims, name => sim)
    end

    metrics = reduce(vcat, all_metrics)
    metrics = append_metrics(settings_path["metrics"], metrics)
    return sims, metrics
end


## Setup section

Tf = Float32
verbose = true
include("obs_compare.jl")
include("tuning_track.jl")

# **************************************************************************************************************
# Settings of tuning
# **************************************************************************************************************
# runs = [
#     "raw"    => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0, cst = 1)],
# ********************************
# Precipitation settings
    # "linear1" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0.00014, cst = 0.68)],
    # "linear2" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0.00023, cst = 0.4)],
    # "linear3" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 4.65*10^(-5), cst = 0.96 )],
    # "log"    => [("INIT", "prec_multi") => scheme(LogbisPrecip; mult1 = -0.0156, mult2 = 0.42, cst = 50)],
    # "tanh"   => [("INIT", "prec_multi") => scheme(TanhPrecip;)],

# ********************************
# z0 settings
    # "z0.002" => [],
    # "z0.0002" => [("TUNING", "params", "z0_snow") => 0.0002],
    # "z0.000002" => [("TUNING", "params", "z0_snow") =>  0.000002],
    # "z0.02" => [("TUNING", "params", "z0_snow") =>  0.02],

# ********************************
# Albedo settings
    # "progn" => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo;)],   #ALRADT = false, adm = 130, adc = ElevationTuned((1500, 2300), (3000, 6000))
    # "diagn" => [("TUNING", "physics", "snow_albedo") => scheme(DiagnosticAlbedo;)],
    # "decay" => [("TUNING", "physics", "snow_albedo") => scheme(DecayAlbedo;)],

# ********************************
# Combined settings
    # "lin3 + z0.2" => [
    #     ("INIT", "prec_multi") => scheme(LinearPrecip; mult = 4.65*10^(-5), cst = 0.96 ),
    #     ("TUNING", "params", "z0_snow") =>  0.2,
    # ],
    # "lin3 + z0lin" => [
    #     ("INIT", "prec_multi") => scheme(LinearPrecip; mult = 4.65*10^(-5), cst = 0.96 ),
    #     ("TUNING", "params", "z0_snow") => ElevationTuned((1000, 2500), (0.5, 0.02)),  #scheme(LinearZ0;)
    # ],
# ]

# ********************************
# Ensemble of tuning
    product_runs(groups...) = vec([
        join(first.(c), " | ") => reduce(vcat, last.(c))
        for c in Iterators.product(groups...)
    ])

    precips = [
        # "raw" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0, cst = 1)],
        # "105%" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0, cst = 1.05)],
        # "95%" => [("INIT", "prec_multi") => scheme(LinearPrecip; mult = 0, cst = 0.95)],
        # "linear" => [("INIT", "prec_multi") => scheme(LinearPrecip; )],
        # "exp" => [("INIT", "prec_multi") => scheme(ExpPrecip; )],
        "bias" => [("INIT", "prec_multi") => scheme(MaxBiasPrecip; )],
        "bias105%" => [("INIT", "prec_multi") => scheme(MaxBiasPrecip; cst = 1.05)],
        "bias95%" => [("INIT", "prec_multi") => scheme(MaxBiasPrecip;  cst = 0.95)],

    ]
    z0 = [
        "z0.002" => [],        
        "z0.001" => [("TUNING", "params", "z0_snow") =>  0.001],
        "z0.01" => [("TUNING", "params", "z0_snow") =>  0.01],
        "z0.05" => [("TUNING", "params", "z0_snow") =>  0.05],
    #     "z0.05" => [("TUNING", "params", "z0_snow") =>  0.05],
    #     "z0.1" => [("TUNING", "params", "z0_snow") =>  0.1],
    ]
    albedo = [
        "alb default" => Pair{Tuple,Any}[],       
        "alb alradt" => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false)],
        "alb amin0.7"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; amin = 0.7)],
        "alb amin0.5"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; amin = 0.5)],
        "alb adm130"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; adm = 130)],
        "alb adm70"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; adm = 70)],
        # "alb alradt+amin0.65"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.65)],
        # "alb alradt+amin0.65+Sfminelev"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.65, Sfmin = ElevationTuned((1500, 2500), (10, 5)))],
        # "alb alradt+amin0.65+adcelev"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.65, adc = ElevationTuned((1500, 2500), (3000, 5000)))],
        # "alb alradt+amin0.7"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.7)],
        # "alb alradt+amin0.7+Sfminelev"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.7, Sfmin = ElevationTuned((1500, 2500), (10, 5)))],
        # "alb alradt+amin0.7+adcelev"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.7, adc = ElevationTuned((1500, 2500), (1000, 5000)))],
        # "alb alradt+afs0.9"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, afs = ElevationTuned((0, 4000), (0.9, 0.9)))],
        # "alb alradt+Sfmin5"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; Sfmin = 5)],
        # "alb alradt+Sfmin15"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; Sfmin = 15)],
        # "adc1200"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; adc = ElevationTuned((0, 4000), (1200, 1200)))],
        # "adc800"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; adc = ElevationTuned((0, 4000), (800, 800)))],
        "alb slf"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; adm = 130, adc = ElevationTuned((1500, 2300), (3000, 6000)))],
        # "alb alradt+amin0.7+adcelev2"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.7, adc = ElevationTuned((1300, 2500), (1000, 5000)))],
        # "alb alradt+amin0.65+adcelev2"    => [("TUNING", "physics", "snow_albedo") => scheme(PrognosticAlbedo; ALRADT = false, amin = 0.65, adc = ElevationTuned((1300, 2500), (1000, 5000)))],
    ]

    runs = product_runs(precips, albedo)   # precips, z0, albedo 

# **************************************************************************************************************
# Load data
# **************************************************************************************************************
# obs = load_csv_data("C:/Users/navarrel/Documents/Workspace/Data/obs/nivo/OBS_1980_2025.csv")
obs = load_mdw_data("C:/Users/navarrel/Documents/Workspace/Data/obs/nivo/OBS_alps_20261014_clean.MDW")
# crocus = Dataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/pro/PRO_1958080106_2024080106.nc")
# t_start = DateTime(2018, 8, 1, 5)
# cro_time_mask = (crocus["time"][:].>t_start)
# cro_station_mask = findall(in(sort(settings["INIT"]["list_id"])), crocus["station"][:]) 
# cro = (
#         time = collect(crocus["time"][cro_time_mask]), 
#         data = permutedims(collect(crocus["DSN_T_ISBA"][cro_station_mask,cro_time_mask])), 
#         id = sort(settings["INIT"]["list_id"]),
#         alt = collect(crocus["ZS"][cro_station_mask]),
#         )

# **************************************************************************************************************
# Run simulation
# **************************************************************************************************************
sims, metrics = run_comparison(settings, obs, runs, Float32)

# altitude bands, as before
ALT_BANDS = [(0, 3000), (0, 500), (500, 1000), (1000, 1500), (1500, 2000), (2000, 2500), (2500, 3000)]
names_of = Dict(Int(i) => n for (i, n) in zip(settings["INIT"]["list_id"], settings["INIT"]["name"])
                     if !ismissing(i))
massif_of     = Dict(Int(i) => m for (i, m) in zip(settings["INIT"]["list_id"], settings["INIT"]["massif"])
                     if !ismissing(i))

# ********************************
# Main plot
# save(settings_path["alt_band"], plot_runs(obs, sims, cro; groups = band_groups(ALT_BANDS)))
# save(settings_path["alt_band"], plot_runs(obs, sims; groups = band_groups(ALT_BANDS)))
# figs = plot_scatter_runs(obs, sims; groups = band_groups(ALT_BANDS))
# for (label, f) in figs
#     save(settings_path["alt_scatter"]*"max_scatter_$(replace(label, r"[^\w.\-]+" => "_")).png", f)
# end

# ********************************
# Other plots
# a few single stations in one figure
# names = station_names(last(first(sims)))
# ids = sort(settings["INIT"]["list_id"])                              # your station ids
# save(settings_path["multi_station"],
#      plot_runs(obs, sims; groups = station_groups(ids, names), fsize = (1200, 300 * length(ids))))

# one figure per station, without rerunning the model
ids = sort(collect(skipmissing(settings["INIT"]["list_id"])))
for id in ids
    f = plot_runs(obs, sims; groups = station_groups([id], names_of), fsize = (1200, 500))
    save(settings_path["single_station"]*"$(id).png", f)
end

# ********************************
# Box plots
# include("config_compare.jl")
