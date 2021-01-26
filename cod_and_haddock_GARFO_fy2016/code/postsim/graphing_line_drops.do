use cod_line_drops.dta, clear
label var cpdf "Probability Distribution"
label var ccdf "Cumulative Distribution"

label var clinedrops "Cod Catch"

line cpdf cline
graph save "clinedrops", replace
graph export "clinedrops.tif", replace as(tif)

line ccdf cline
graph save "ccdf", replace
graph export "ccdf.tif", replace as(tif)




use haddock_line_drops.dta, clear
label var hpdf "Probability Distribution"
label var hlinedrops "Haddock Catch"
label var hcdf "Cumulative Distribution"


line hpdf hline
graph save "hlinedrops", replace
graph export "hlinedrops.tif", replace as(tif)
line hcdf hline
graph save "hcdf", replace
graph export "hcdf.tif", replace as(tif)
