/* This constructs a matrix which contains the recreational distribution of effort, by wave */
/* These are the initial results based on 2012 Preliminary MRIP */

/* Desired final results are 
1, 0
2, .0567
3, .337
4, .42
5, .164
6, .022
mata:
recreational_effort_waves = (1,0 \ 2,0.10 \ 3,0.29 \ 4,0.43 \ 5, 0.15 \ 6, 0.03)

end
*/



/* This constructs a matrix which contains the recreational distribution of effort, by wave */
/* Desired final results based on the final version of 2012 MRIP data are 
1, 0
2, 7.9%
3, 34.7%
4, 42%
5, 14.7%
6, 0.7%

This is a big increase of effort in wave 


mata:
recreational_effort_waves = (1,0 \ 2,0.10 \ 3,0.29 \ 4,0.43 \ 5, 0.15 \ 6, 0.03)
recreational_effort_waves = (1,0 \ 2,0.01 \ 3,0.32 \ 4,0.40 \ 5, 0.27 \ 6, 0.00)

end
*/




mata:

recreational_effort_waves = (1,0 \ 2,0.0 \ 3,0.41 \ 4,0.525 \ 5, 0.065 \ 6, 0.00)
recreational_effort_waves = (1,0 \ 2,0.0 \ 3,0.31 \ 4,0.60 \ 5, 0.09 \ 6, 0.00)




end

