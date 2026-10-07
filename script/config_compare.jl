using CSV, DataFrames, CairoMakie

function boxplot_metric(metrics_path, col::Symbol; by_band = false, verbose=true)
    metrics = CSV.read(metrics_path, DataFrame)

    df = filter(r -> !isnan(r[col]), metrics)
    configs = unique(df.config)                       # keeps the run order
    x = Int.(indexin(df.config, configs))

    f = Figure(size = (1000, 500))
    ax = Axis(f[1, 1]; xticks = (1:length(configs), configs), ylabel = string(col),
              xticklabelrotation = π / 6)

    if by_band
        bands = sort(unique(df.band_lo))
        d = Int.(indexin(df.band_lo, bands))
        cols = cgrad(:viridis, length(bands); categorical = true)
        boxplot!(ax, x, df[!, col]; dodge = d, color = cols[d])
        Legend(f[1, 2], [PolyElement(color = cols[i]) for i in eachindex(bands)],
               ["$(b)–$(b + 500) m" for b in bands], "Altitude")
    else
        boxplot!(ax, x, df[!, col])
    end

    col == :bias && hlines!(ax, 0; color = :black, linestyle = :dash)
    return f
end

save(settings_path["boxplot"],      boxplot_metric(settings_path["metrics"], :rmse))
save(settings_path["boxplot_band"], boxplot_metric(settings_path["metrics"], :rmse; by_band = true))
# save("bias_by_config.png",      boxplot_metric(metrics, :bias; by_band = true))
# save("r2_by_config.png",        boxplot_metric(metrics, :r2))