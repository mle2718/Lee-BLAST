/*done 


*/

global project_dir  "C:/Users/Min-Yang.Lee/Documents/BLAST/cod_haddock_fy2022" 

/* setup directories */
global code_dir "${project_dir}/code"


/*ASO at 15 haddock and 19" for cod */
do "$code_dir/sim/cod_haddock_OpenSept.do"
do "$code_dir/sim/cod_haddock_OpenSept5.do"
do "$code_dir/sim/cod_haddock_OpenSept6.do"
