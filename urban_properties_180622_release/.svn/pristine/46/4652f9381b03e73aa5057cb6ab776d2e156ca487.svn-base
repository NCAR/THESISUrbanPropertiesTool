#! /bin/tcsh -f
#===============================================================================
# SVN $Id: urban_prop_scen_1_Roof_Albedo_P.csh 202 2017-08-10 21:17:59Z kauff $
# SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/Scenarios_Feddema_2017/Scenario_1_Roof_Albedo/urban_prop_scen_1_Roof_Albedo_P.csh $#
#===============================================================================
# run all urban property tools
#===============================================================================
set echo ON

set LID = "`date +%y%m%d-%H%M%S`"
set SHORTLINE = "####################"
set LINE = "$SHORTLINE $SHORTLINE $SHORTLINE $SHORTLINE"
set EXP = "Scen_1_Roof_Albedo_P"

#---- input files created by user prior to code execution ----
set FN_MAT_PROP   = mat_prop_scen.csv
set FN_LAM_SPEC   = lam_spec_scen.csv
set FN_CITY_SPEC  = city_spec_$EXP.csv
set FN_REG_SPEC   = region_spec.csv

#---- output/input files created by code during execution ----
set FN_LAM_PROP   = lam_prop_$EXP.$LID.csv
set FN_CITY_PROP  = city_prop_$EXP.$LID.csv
set FN_REG_PROP   = region_prop_$EXP.$LID.csv


echo $LINE
echo $LID
echo $LINE #--- form surfaces consisting of layered materials
ncl fn_in_mat=\"$FN_MAT_PROP\"    fn_in_lam=\"$FN_LAM_SPEC\"    fn_out=\"$FN_LAM_PROP\"   gen_lam.ncl  

echo $LINE #--- create all possible city types
ncl fn_in_surf=\"$FN_LAM_PROP\"   fn_in_spec=\"$FN_CITY_SPEC\"  fn_out=\"$FN_CITY_PROP\"  gen_city.ncl

echo $LINE # ---select desired city types for each region/category
ncl fn_in_city=\"$FN_CITY_PROP\"  fn_in_spec=\"$FN_REG_SPEC\"   fn_out=\"$FN_REG_PROP\"   gen_region.ncl 

echo $LINE

