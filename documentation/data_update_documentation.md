# How to update the code and whatnot for the BLAST for recreational Cod and Haddock regulations

# Prereqs
You'll have to get updated MRIP data using the code found at https://github.com/mle2718/READ-SSB-Lee-MRIP-BLAST.
Make a new folder for the year. I don't really know why I do this, except to make it slighly easier to go back in time if necessary.

# Presim

The Presim folder contains code to get the simulation set up.  This is mostly contained in the file ``run_this_once.do``
1. Which years and months are being simulated? 
2. Which years we are calibrating to? 
3. Which years are we using for the Age-Length key?
4. Where do we get the historical NAA? These will have 1 vector per year.  These are usually taken from the most recent stock assessment, although sometimes the bridge year numbers have to get filled in with the mean of an AGEPRO projection.
5. Where do we get initial conditions for NAA. These will have many vectors (a bootstrapped population generated from AGEPRO).  Recently, for Cod there have been multiple projections models.

