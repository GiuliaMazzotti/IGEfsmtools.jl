cd(@__DIR__)

using Dates
using CSV
using DataFrames
using FSMOSHD
using NCDatasets
using Base: findall
# using IGEfsmtools


# initialization function
    # sets parameters (topo, meteo), configuration, variables (format)
    # opens meteo file
function setup_example(area, station)

    # read meteo file
    df_meteo = Dict("s2m_pt" => Dataset("C:/Users/elise/Documents/These/Workspace/Data/S2M/postes/meteo/FORCING_1958080106_1959080106.nc"))[area]
    shapefile = CSV.read("C:/Users/elise/Documents/These/Workspace/Data/S2M/shapefile/stations_reanalysis_S2M.csv", DataFrame)
    shapefile.Name = strip.(string.(shapefile.Name))
    id_station = Int32(findfirst(shapefile.Name .== station))
    elev = shapefile[shapefile.Name .== station, "Elevation"][1]

    # set landuse properties
    lus = Dict()
    lus["skyvf"] = Dict("data" => [1.0;;])           
    lus["x"] = Dict("data" => [1.0;;])
    lus["y"] = Dict("data" => [1.0;;])
    lus["dem"] = Dict("s2m_pt" => Dict("data" => [Float32(elev);;]))[area] 
    lus["slopemu"] = Dict("data" => [1.0;;])
    lus["xi"] = Dict("data" => [1.0;;])
    lus["Ld"] = Dict("data" => [1.0;;])
    lus["prec_multi"] = Dict("data" => [1.0;;])
    
    # define custom settings
    settings = Dict("tile" => "open", "params" => Dict("s2m_pt" => Dict("wind_scaling" => 0.7,
                                                                          "dt" => 3600,
                                                                          "zT" => 1.5,
                                                                          "zU" => 5.0,
                                                                          "zRH" => 1.5))[area])
    
    # create fsm struct
    fsm = setup(Float32, Int32, lus, 1, 1, settings)
    
    # define meteo data struct
    met = MET{Float32,Int32}()
    
     return id_station, fsm, met, df_meteo

end

#####################################################################################
function run_fsm(id_station, fsm, met, df_meteo)

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
    
    sf24 = [sum(df_meteo["Snowf"][id_station, max(1, i-23):i]) for i in 1:length(df_meteo["Snowf"][id_station,:])]

    # time loop
    for i in 1:size(df_meteo["time"][:])[1]
    
        # assign input
        met.year .= year.(df_meteo["time"][i])
        met.month .= month.(df_meteo["time"][i])
        met.day .= day.(df_meteo["time"][i])
        met.hour .= hour.(df_meteo["time"][i])
        met.Sdir .= df_meteo["DIR_SWdown"][id_station, i]
        met.Sdif .= df_meteo["SCA_SWdown"][id_station, i]
        met.Sdird .= df_meteo["DIR_SWdown"][id_station, i]
        met.LW .= df_meteo["LWdown"][id_station, i]
        met.Sf .= df_meteo["Snowf"][id_station, i]
        met.Rf .= df_meteo["Rainf"][id_station, i] 
        met.Ta .= df_meteo["Tair"][id_station, i]
        met.RH .= df_meteo["Qair"][id_station, i] 
        met.Ua .= df_meteo["Wind"][id_station, i] 
        met.Ps .= df_meteo["PSurf"][id_station, i]
        met.Sf24h .= sf24[i]
    
        # set time 
        t = df_meteo["time"][i]

        # run model and update states
        step!(fsm, met, t)
        
        # write output
        hs[i] = dropdims(sum(fsm.Ds, dims=1), dims=1)[1, 1]
        if fsm.Nsnow[1, 1] == 1
            Tsnow1[i] = fsm.Tsnow[1, 1, 1]
        elseif fsm.Nsnow[1, 1] == 2
            Tsnow1[i], Tsnow2[i] = fsm.Tsnow[1, 1, 1], fsm.Tsnow[2, 1, 1]
        elseif fsm.Nsnow[1, 1] == 3
            Tsnow1[i], Tsnow2[i], Tsnow3[i] = fsm.Tsnow[1, 1, 1], fsm.Tsnow[2, 1, 1], fsm.Tsnow[3, 1, 1]
        end
        alb[i] = fsm.asrf_out[1, 1] # albs
        Tsrf[i] = fsm.Tsrf[1, 1]
        Sice[i] = dropdims(sum(fsm.Sice, dims=1), dims=1)[1, 1]
        Sliq[i] = dropdims(sum(fsm.Sliq, dims=1), dims=1)[1, 1]
        snowdepthmin[i] = fsm.snowdepthmin[1, 1]
        snowdepthmax[i] = fsm.snowdepthmax[1, 1]
        swemin[i] = fsm.swemin[1, 1]
        swemax[i] = fsm.swemax[1, 1]
        
    end

    alb_snow = copy(alb) 
    alb_snow[alb .< 0.6] .= NaN

    # write results to dataframe
    time = df_meteo["time"]

    df_results = DataFrame(time=time, hs=hs, Tsnow1=Tsnow1, Tsnow2=Tsnow2, Tsnow3=Tsnow3, Ts=Tsrf, albedo=alb_snow, I=Sice, W=Sliq, snow_depth_min=snowdepthmin, snow_depth_max=snowdepthmax, swemin=swemin, swemax=swemax)

    return df_results

end
#####################################################################################
area = "s2m_pt"
station = "GALIBIER-NIVOSE"

print("setup")
id_station, fsm, met, df_meteo = setup_example(area, station) 

print("fsm")
df_results = run_fsm(id_station, fsm, met, df_meteo)

#*********************************************************
CSV.write("C:/Users/elise/Documents/These/Workspace/Data/S2M/postes/output_1958-1959_S2M_galibier.csv", df_results)
#*********************************************************