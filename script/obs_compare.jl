# Helper functions for comparing FSM point simulations against observed snow depth.

using CSV
using DataFrames
using NaNStatistics
using Dates
using Statistics
using CairoMakie
CairoMakie.activate!()

# function load_mdw_data(filepath::String, layer::Int = 1)
#     if !isfile(filepath)
#         error("File not found: $filepath")
#     end

#     mdw = matread(filepath)

#     time = datenum2datetime.(mdw["MDW"]["MDW_data"][layer]["dobj"]["time"])
#     acro = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["acro"]
#     x = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["x"]
#     y = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["y"]
#     z = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["z"]
#     data = mdw["MDW"]["MDW_data"][layer]["dobj"]["data"][:, :, 1]
#     sel_stats = mdw["MDW"]["MDW_settings"][layer]["stats"]
#     nodata_value = mdw["MDW"]["MDW_data"][layer]["dobj"]["data_info"]["nan_value"]

#     attributes = Dict(
#         "acro" => acro,
#         "sel_stats" => sel_stats,
#         "x" => x,
#         "y" => y,
#         "z" => z,
#         "nodata_value" => nodata_value,
#     )

#     return (time = time, data = data, attributes = attributes)
# end

function load_csv_data(filepath::String)
    obs = CSV.read(filepath, DataFrame; header =[:id, :time, :HTN, :type_nivo], dateformat = "yyyy-mm-dd-HH-MM")
    return obs
end

function daily_mean(sim)
    uniq_time = .!nonunique(DataFrame(t = sim.time)) 
    sim_time = sim.time[uniq_time]
    sim_data = sim.data[uniq_time, :]

    days = unique(Date.(sim_time))
    i_days = indexin(days, Date.(sim_time))

    daily_data = Matrix{Union{Missing, Float64}}(missing, length(i_days), length(sim_data[1,:])) 
    for d in eachindex(i_days)
        if d != length(i_days)
            daily_data[d, :] = mean(sim_data[i_days[d]:i_days[d+1]-1, :]; dims = 1)
        else
            daily_data[d, :] = mean(sim_data[i_days[d]:end, :]; dims = 1)
        end
    end

    sim_daily = merge(sim, (time = Union{Missing, DateTime}[DateTime(d) + Hour(6) for d in days], data = daily_data,))
    return sim_daily
end

function align_data(obs, sim)

    # match stations
    id = sort(intersect(obs.id, sim.id))
    i_sim = indexin(id, sim.id)
    i_dict = Dict(i => k for (k, i) in enumerate(id))

    # match time
    times = sort(intersect(obs.time, collect(skipmissing(vec(sim.time)))))
    t_sim = indexin(times, vec(sim.time))
    t_dict = Dict(t => k for (k, t) in enumerate(times))

    obs_sub = subset(obs,
           :id   => ByRow(in(id)),
           :time => ByRow(in(times)))

    # final rows 
    if isempty(obs_sub)
        error("No observations available")
    end

    # align data
    obs_aligned = Matrix{Union{Missing, Float64}}(missing, length(times), length(id))
    for r in eachrow(obs_sub)
        obs_aligned[t_dict[r.time], i_dict[r.id]] = r.HTN
    end

    obs_aligned = coalesce.(obs_aligned, NaN)
    sim_aligned = sim.data[t_sim, i_sim]
    # sim_aligned = sim.data

    altitudes = vec(sim.alt)[i_sim]

    return (times = times, obs_aligned = obs_aligned, sim_aligned = sim_aligned, altitudes = altitudes)

end

bias(sim, obs) = nanmean(sim .- obs)
rmse(sim, obs) = sqrt(nanmean((sim .- obs) .^ 2))
r2(sim, obs) = nancor(obs, sim)^2

function plot_band_time_series(obs, sim)

    times, obs_aligned, sim_aligned, altitudes = align_data(obs, daily_mean(sim))

    # altitude data
    altitude_bands = [(0, 3000), (0, 500), (500, 1000), (1000, 1500), (1500, 2000), (2000, 2500), (2500, 3000)]

    # plot data

    f = Figure(size = (1200, 2000))
    band_axes = Axis[]
    for (b, (lo, hi)) in enumerate(altitude_bands)
        mask = lo .<= altitudes .<= hi
        obs_band = obs_aligned[:, mask]
        sim_band = sim_aligned[:, mask]
        # obs is reported in cm, sim in m — convert obs to m for comparison
        obs_mean_b = vec(nanmean(obs_band; dims = 2)) / 100
        sim_mean_b = Float64.(vec(nanmean(sim_band; dims = 2)))

        ax = Axis(f[b, 1]; ylabel = "HS [m]", title = "$(lo)–$(hi) m (n=$(count(mask)))")
        lines!(ax, times, obs_mean_b; label = "obs", color = :black, linewidth = 2.5)
        lines!(ax, times, sim_mean_b; label = "sim", color = :red)
        axislegend(ax; position = :rt)
        push!(band_axes, ax)

        bias_val = bias(sim_mean_b, obs_mean_b)
        rmse_val = rmse(sim_mean_b, obs_mean_b)
        r2_val = r2(sim_mean_b, obs_mean_b)
        stat_text = "RMSE: $(round(rmse_val, digits = 3)) m\n" *
            "Bias: $(round(bias_val, digits = 3)) m\n" *
            "R²:   $(round(r2_val, digits = 3))"
        Label(f[b, 2], stat_text; halign = :left, justification = :left, tellwidth = false, tellheight = false)
    end

    colsize!(f.layout, 2, Fixed(160))

    linkxaxes!(band_axes...)
    for ax in band_axes[1:(end - 1)]
        hidexdecorations!(ax; ticks = false, grid = false)
    end
    band_axes[end].xlabel = "time"

    return f

end


## Other functions to plot (1 station, ...)
