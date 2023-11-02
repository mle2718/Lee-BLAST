library(here)
library(haven)
library(dplyr)
library(tibble)
# File names
codA<-"gomcod_M02_2021MT"
codB<-"gomcod_MRAMP_2021MT"
haddockA<-"gomhaddock_BASE_2022MT"

infile_codA<-here("cod_haddock_fy2023","source_data","cod agepro","codagepro2021",paste0(codA,".rdat"))
infile_codB<-here("cod_haddock_fy2023","source_data","cod agepro","codagepro2021",paste0(codB,".rdat"))
infile_haddockA<-here("cod_haddock_fy2023","source_data","haddock agepro","2022_HAD_GM",paste0(haddockA,".rdat"))

#read them in 
load(infile_haddockA)
load(infile_codA)
load(infile_codB)

codA_NAA<-as.data.frame(gomcod_M02_2021MT$N.age)
codB_NAA<-as.data.frame(gomcod_MRAMP_2021MT$N.age)
haddockA_NAA<-as.data.frame(gomhaddock_BASE_2022MT$N.age)

#Prepend age to the columns
codA_NAA<-codA_NAA %>% 
  dplyr::rename_with(~ paste0("age", .)) %>%
  tibble::rownames_to_column(var="year")

codB_NAA<-codB_NAA %>% 
  dplyr::rename_with(~ paste0("age", .)) %>%
  tibble::rownames_to_column(var="year")

haddockA_NAA<-haddockA_NAA %>% 
  dplyr::rename_with(~ paste0("age", .)) %>%
  tibble::rownames_to_column(var="year")


write_dta(codA_NAA,here("cod_haddock_fy2023","source_data","cod agepro","codagepro2021", paste0(codA,".dta")))
write_dta(codB_NAA,here("cod_haddock_fy2023","source_data","cod agepro","codagepro2021",paste0(codB,".dta")))
write_dta(haddockA_NAA,here("cod_haddock_fy2023","source_data","haddock agepro","2022_HAD_GM",paste0(haddockA,".dta")))
