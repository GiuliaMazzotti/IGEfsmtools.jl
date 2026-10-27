using CSV, DataFrames, CairoMakie

bias(sim, obs) = nanmean(sim .- obs)
rmse(sim, obs) = sqrt(nanmean((sim .- obs) .^ 2))
r2(sim, obs) = nancor(obs, sim)^2
factor(sim_max_hs, obs_max_hs) = nanmean(obs_max_hs ./ sim_max_hs)

# **************************************
# Compute metrics
function station_metrics(obs, sim, config, run_id; min_days = 30, tol = 0.0)
    _, obs_aligned, sim_aligned, altitudes, massifs, ids = align_data(obs, daily_mean(sim))

    rows = map(eachindex(ids)) do j
        o = obs_aligned[:, j] ./ 100           
        s = Float64.(sim_aligned[:, j])

        keep = [!isnan(o[i]) && !isnan(s[i]) && !(o[i] <= tol && s[i] <= tol) for i in eachindex(o)]
        o, s = o[keep], s[keep]

        n = length(o)
        ok = n >= min_days
        (config = config, run_id = string(run_id), id = ids[j], altitude = altitudes[j], massif = massifs[j], band_lo = 500 * floor(Int, altitudes[j] / 500), n_days = n,
         rmse = ok ? rmse(s, o) : NaN,
         bias = ok ? bias(s, o) : NaN,
         r2   = ok ? r2(s, o)   : NaN)
    end
    return DataFrame(rows)
end

function group_metrics(obs, label, sim; groups, tol = 0.0, min_points = 5)
    al = align_data(obs, daily_mean(sim))
    obs_max, sim_max, years = max_pairs(al)

    valid = .!isnan.(obs_max) .& .!isnan.(sim_max) .&
            .!((obs_max .<= tol) .& (sim_max .<= tol))

    out = NamedTuple[]
    for (title, sel) in groups
        M  = cell_mask(sel, al.altitudes, al.ids, years)
        ok = M .& valid
        any(M .& .!isnan.(obs_max) .& .!isnan.(sim_max)) || continue   # groupe sans données

        x, y   = obs_max[ok], sim_max[ok]
        enough = length(x) >= min_points
        push!(out, (config = label, group = title, x = x, y = y,
                    n_points = length(x), n_stations = count(vec(any(ok; dims = 1))),
                    rmse   = enough ? rmse(y, x)   : NaN,
                    bias   = enough ? bias(y, x)   : NaN,
                    r2     = enough ? r2(y, x)     : NaN,
                    factor = enough ? factor(y, x) : NaN))
    end
    isempty(out) && error("No data matches the requested groups")
    return out
end

group_metrics_runs(obs, sims; groups, kwargs...) =
    [label => group_metrics(obs, label, sim; groups = groups, kwargs...) for (label, sim) in sims]

# **************************************
# Write metrics
function append_groups_metrics(stats, path; overwrite_config = true)
    new = DataFrame([(; (k => getfield(s, k) for k in (:config, :group, :n_points, :n_stations, :rmse, :bias, :r2, :factor))...) for s in stats])
    mkpath(dirname(path))
    if isfile(path) && filesize(path) > 0
        old = CSV.read(path, DataFrame)
        # remplace les lignes existantes de la même config : pas de doublons au rerun
        overwrite_config && (old = filter(:config => c -> c ∉ Set(new.config), old))
        new = vcat(old, new)
    end
    CSV.write(path, new)
    return new
end



