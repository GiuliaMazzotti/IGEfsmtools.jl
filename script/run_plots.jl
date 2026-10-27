# ********************************
# Metrics files
# ********************************
# **** Max hs metrics (precip bias factor) ****
# Only for raw sim
all_groups_metrics = group_metrics_runs(obs, sims; groups = groups, tol = 0.0, min_points = 5)
flat_metrics = reduce(vcat, [st for (_, st) in all_groups_metrics])
append_groups_metrics(flat_metrics, settings_path["hs_metrics"])

# ********************************
# Main plots
# ********************************
# **** Bands plot ****
# save(settings_path["plot"]*"snowdepth_band.png", plot_runs(obs, sims; groups = groups))

# **** Scatter plots ****
figs = [label => plot_scatter_run(mtrcs) for (label, mtrcs) in all_groups_metrics]
for (label, f) in figs
    save(settings_path["plot"]*"max_scatter_$(replace(label, r"[^\w.\-]+" => "_")).png", f)
end

# **** Single station plots ****
ids = sort(collect(skipmissing(settings["INIT"]["list_id"])))
for id in ids
    f = plot_runs(obs, sims; groups = station_groups([id], names_of), fsize = (1200, 500))
    save(settings_path["plot"]*"snowdepth_calib_station_$(id).png", f)
end

# **** Single group plots ****
for grp in groups
    f = plot_runs(obs, sims; groups = [grp], fsize = (1200, 500))
    save(settings_path["plot"]*"snowdepth_calib_group_$(grp[1]).png", f)
end

# **** Year group plots ****
period = (DateTime(2018,8,1), DateTime(2024,7,31))
figs = plot_year_runs(obs, sims; groups, period = period, fsize = (1400, 600))
for (label, f) in figs
    save(settings_path["plot"]*"plot_$(replace(label, r"[^A-Za-z0-9]+" => "_"))_$(year(period[1]))-$(year(period[2])).png", f)
end

# **** Period group plots ****
# figs = plot_period_runs(obs, sims; groups, fsize = (1400, 600))
# for (label, f) in figs
#     save(settings_path["period_runs"]*"plot_$(replace(label, r"[^A-Za-z0-9]+" => "_"))_$(y1)-$(y2).png", f)
# end

# ********************************
# Box plots
# ********************************
# **** rmse plots ****
save(settings_path["plot"]*"rmse_boxplot.png", boxplot_metric(settings_path["metrics"], :rmse))
save(settings_path["plot"]*"rmse_boxplot_groups.png", boxplot_metric(settings_path["metrics"], :rmse; groups = groups))
save(settings_path["plot"]*"rmse_heatmap.png", heatmap_metrics(settings_path["hs_metrics"], :rmse)) #--------------------------------------- "metrics" or "hs_metrics"

save(settings_path["plot"]*"bias_boxplot.png", boxplot_metric(settings_path["metrics"], :bias))
save(settings_path["plot"]*"bias_boxplot_groups.png", boxplot_metric(settings_path["metrics"], :bias; groups = groups))
save(settings_path["plot"]*"bias_heatmap.png", heatmap_metrics(settings_path["hs_metrics"], :bias)) #--------------------------------------- "metrics" or "hs_metrics"

# ********************************
# Other plots
# ********************************
# **** Crocus ****
# save(settings_path["group_bands"], plot_runs(obs, sims, cro; groups = groups))