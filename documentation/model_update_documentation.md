# How to update the code and whatnot for the BLAST for recreational Cod and Haddock regulations

# Prerequistes

# Data

You'll have to get updated MRIP data using the code found at https://github.com/mle2718/READ-SSB-Lee-MRIP-BLAST.
Make a new folder for the year. I don't really know why I do this, except to make it slightly easier to go back in time if necessary.

# Simulations

## Presim

The Presim folder contains code to get the simulation set up.  This is mostly contained in the file ``run_this_once.do``
1. Which years and months are being simulated? 
2. Which years we are calibrating to? 
3. Which years are we using for the Age-Length key?
4. Where do we get the historical NAA? These will have 1 vector per year.  These are usually taken from the most recent stock assessment, although sometimes the bridge year numbers have to get filled in with the mean of an AGEPRO projection.
5. Where do we get initial conditions for NAA. These will have many vectors (a bootstrapped population generated from AGEPRO).  Recently, for Cod there have been multiple projections models.  The stock assesment folks save the NAA and other assessment details in an .rdat file and I've written a R little code to pull out the matrices that I need.
6. Update the recruit helper. Copy/paste in information on Recruits from the AGEPRO input file.
7. Once you have updated projections, update their locations in the ``run_this_once.do`` wrapper.  You should not have to edit the do files that are called by this wrapper.
 

## Sim
This is mostly where the code to simulate the model resides. I use ``cod_haddock_calibrate.do`` to calibrate the model; then construct ``cod_haddock_template.do`` file from it. 

Set the regulations in the ``sim/regulations`` folder and pass names in using the ``rec_management`` global.

The ``/presim/cod_hadd_bio_params.do`` file must be updated with the locations of the input data. That input data is created in the Presim section.  So, all you need to do is copy the globals in from the ``run_this_once.do`` file

## Postsim
You will need to use stata's dyndoc to make outputs. You will have to fiddle with the input files and folders in the ``postsim/calibration_summaries.txt.'' In particular, you'll have to point this file to the updated MRIP data.  