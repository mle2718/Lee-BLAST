*do "${code_dir}/sim/read_in_regs.do"
/* code to read in regulations from a csv. */
clear
use"${code_dir}/sim/regulations/${rec_management}.dta" if scenario==$ws, replace



global scenario_name=simname[1] 
global scenario_num=scenario[1]
global closedbehavior=closedbehavior[1]

local matsub |5,1\.,1|
local matexpand 3
putmata haddock_min_vec=haddockmin haddock_max_vec=haddockmax haddock_bag_vec=haddockbag cod_min_vec=codmin cod_max_vec=codmax cod_bag_vec=codbag, replace

/* this bit of code picks off the 5th through end entries using `matsub'. Then it replicates them out 3 (`matexpand') times. Then it sticks those extra years worth of regulations onto the back of the existing regulations vectors. */
/* you need to "conform" and tile out these vectors */
/* this would be far cleaner if you defined a mata function to conform and tile. But whatever.*/

mata:
hminfy=haddock_min_vec[`matsub']
hminfy=J(`matexpand',1,hminfy)
haddock_min_vec=(haddock_min_vec \ hminfy)

hmaxfy=haddock_max_vec[`matsub']
hmaxfy=J(`matexpand',1,hmaxfy)
haddock_max_vec=(haddock_max_vec \ hmaxfy)


hbagfy=haddock_bag_vec[`matsub']
hbagfy=J(`matexpand',1,hbagfy)
haddock_bag_vec=(haddock_bag_vec \ hbagfy)

cmfy=cod_min_vec[`matsub']
cmfy=J(`matexpand',1,cmfy)
cod_min_vec=(cod_min_vec \ cmfy)

cmaxfy=cod_max_vec[`matsub']
cmaxfy=J(`matexpand',1,cmaxfy)
cod_max_vec=(cod_max_vec \ cmaxfy)

cbagfy=cod_bag_vec[`matsub']
cbagfy=J(`matexpand',1,cbagfy)
cod_bag_vec=(cod_bag_vec \ cbagfy)

mata drop cbagfy cmaxfy cmfy hbagfy hmaxfy hminfy
end
