cd(@__DIR__)

using Dates
using CSV
using DataFrames
using FSMOSHD
using NCDatasets
using Base: findall
using ArchGDAL
using GeoDataFrames
# using IGEfsmtools

# initialization function
    # sets parameters (topo, meteo), configuration, variables (format)
    # opens meteo file
function setup_example(massif, alt, asp, slope)

    # read meteo file
    df_meteo = Dataset("C:/Users/elise/Documents/These/Workspace/Data/S2M/meteo/FORCING_1958080106_2024080106_trans.nc")
    massif_shp = ArchGDAL.read("C:/Users/elise/Documents/These/Workspace/Data/S2M/shapefile/massifs_alpes_2154.shp")
    shapefile = ArchGDAL.getlayer(massif_shp, 0) |> DataFrame
    id_massif = shapefile[shapefile.nom .== massif, "massif_num"]
    mask = (df_meteo["ZS"][:] .== alt) .& (df_meteo["massif_number"][:] .== id_massif) .& (df_meteo["slope"][:] .== slope) .& (df_meteo["aspect"][:] .== asp)
    idx = findall(!=(0), mask)

    # set landuse properties
    lus = Dict()
    lus["skyvf"] = Dict("data" => [1.0;;])           
    lus["x"] = Dict("data" => [1.0;;])
    lus["y"] = Dict("data" => [1.0;;])
    lus["dem"] = Dict("data" => [Float32(alt);;])
    lus["slopemu"] = Dict("data" => [1.0;;])
    lus["xi"] = Dict("data" => [1.0;;])
    lus["Ld"] = Dict("data" => [1.0;;])
    lus["prec_multi"] = Dict("data" => [1.0;;])
    
    # define custom settings
    settings = Dict("tile" => "open", "params" => Dict("wind_scaling" => 0.7,
                                                        "dt" => 3600,
                                                        "zT" => 1.5,
                                                        "zU" => 5.0,
                                                        "zRH" => 1.5))
    
    # create fsm struct
    fsm = setup(Float32, Int32, lus, 1, 1, settings)
    
    # define meteo data struct
    met = MET{Float32,Int32}()
    
     return idx, fsm, met, df_meteo

end

#####################################################################################
function run_fsm(idx, fsm, met, df_meteo)

    # allocate output variable-wise
    hs = zeros(size(df_meteo["time"][:])[1])
    Tsnow1 = fill(NaN, size(df_meteo["time"][:])[1])
    Tsnow2 = fill(NaN, size(df_meteo["time"][:])[1])
    Tsnow3 = fill(NaN, size(df_meteo["time"][:])[1])
    Tsrf = zeros(size(df_meteo["time"][:])[1])
    alb = zeros(size(df_meteo["time"][:])[1])
    Sice = zeros(size(df_meteo["time"][:])[1])
    Sliq = zeros(size(df_meteo["time"][:])[1])
    snowdepthmin = zeros(size(df_meteo["time"][:])[1])
    snowdepthmax = zeros(size(df_meteo["time"][:])[1])
    swemin = zeros(size(df_meteo["time"][:])[1])
    swemax = zeros(size(df_meteo["time"][:])[1])

    # time loop
    for i in 1:size(df_meteo["time"][:])[1]

        # assign input
        met.year .= year.(df_meteo["time"][i])
        met.month .= month.(df_meteo["time"][i])
        met.day .= day.(df_meteo["time"][i])
        met.hour .= hour.(df_meteo["time"][i])
        met.Sdir .= df_meteo["DIR_SWdown"][idx, i]
        met.Sdif .= df_meteo["SCA_SWdown"][idx, i]
        met.Sdird .= df_meteo["DIR_SWdown"][idx, i]
        met.LW .= df_meteo["LWdown"][idx, i]
        met.Sf .= df_meteo["Snowf"][idx, i]*Int32(3600)
        met.Rf .= df_meteo["Rainf"][idx, i]*Int32(3600) 
        met.Ta .= df_meteo["Tair"][idx, i]
        met.RH .= df_meteo["Qair"][idx, i] 
        met.Ua .= df_meteo["Wind"][idx, i] 
        met.Ps .= df_meteo["PSurf"][idx, i]
        met.Sf24h .= sum(df_meteo["Snowf"][idx, max(1, i-23):i]) # sf24[i]

        # set time 
        t = df_meteo["time"][i]

        # run model
        println(i)
        step!(fsm, met, t)

        # store outputs (unchanged from your code)
        hs[i] = dropdims(sum(fsm.Ds, dims=1), dims=1)[1]

        if fsm.Nsnow[1,1] == 1
            Tsnow1[i] = fsm.Tsnow[1,1,1]
        elseif fsm.Nsnow[1,1] == 2
            Tsnow1[i] = fsm.Tsnow[1,1,1]
            Tsnow2[i] = fsm.Tsnow[2,1,1]
        elseif fsm.Nsnow[1,1] == 3
            Tsnow1[i] = fsm.Tsnow[1,1,1]
            Tsnow2[i] = fsm.Tsnow[2,1,1]
            Tsnow3[i] = fsm.Tsnow[3,1,1]
        end

        alb[i] = fsm.asrf_out[1,1]
        Tsrf[i] = fsm.Tsrf[1,1]
        Sice[i] = dropdims(sum(fsm.Sice,dims=1), dims=1)[1]
        Sliq[i] = dropdims(sum(fsm.Sliq,dims=1), dims=1)[1]

        snowdepthmin[i] = fsm.snowdepthmin[1,1]
        snowdepthmax[i] = fsm.snowdepthmax[1,1]
        swemin[i]       = fsm.swemin[1,1]
        swemax[i]       = fsm.swemax[1,1]

    end

    alb_snow = copy(alb) 
    alb_snow[alb .< 0.6] .= NaN

    # write results to dataframe
    time = df_meteo["time"]

    df_results = DataFrame(time=time, hs=hs, Tsnow1=Tsnow1, Tsnow2=Tsnow2, Tsnow3=Tsnow3, Ts=Tsrf, albedo=alb_snow, I=Sice, W=Sliq, snow_depth_min=snowdepthmin, snow_depth_max=snowdepthmax, swemin=swemin, swemax=swemax)

    return df_results

end
#####################################################################################
massif = "Grandes-Rousses" # "Grandes-Rousses", "Oisans", "Thabor"
alt = 2100
slope = 0
asp = -1

print("setup")
idx, fsm, met, df_meteo = setup_example(massif, alt, asp, slope) 

print("fsm")
df_results = run_fsm(idx, fsm, met, df_meteo)

#*********************************************************
CSV.write("C:/Users/elise/Documents/These/Workspace/Data/S2M/meteo/output_1958-2024_S2M_grandesrousses_2100_flat.csv", df_results)
#*********************************************************