matfile = "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/output_test_mat/202209020600_output.mat"
ncfile ="C:/Users/mazzottg/Documents/10_Data/fsm4glamos/output_test/202209020600_output.mat"

a = matread(matfile)
b = matread(ncfile)

maximum(abs.(a["snowdepth"]["data"] - b["snowdepth"]["data"]))
