#! /bin/tcsh -f
#===============================================================================
# SVN $Id: urban_prop.csh 233 2018-06-22 20:49:05Z kauff $
# SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/urban_prop.csh $#
#===============================================================================
# run all urban property tools
#===============================================================================
# set echo ON

set LID = "`date +%y%m%d-%H%M%S`"
set SHORTLINE = "####################"
set LINE = "$SHORTLINE $SHORTLINE $SHORTLINE $SHORTLINE"

#---- input files created by user prior to code execution ----
set FN_MAT_PROP   = mat_prop.csv
set FN_LAM_SPEC   = lam_spec.csv
set FN_CITY_SPEC  = city_spec.csv
set FN_REG_SPEC   = region_spec.csv
set FN_MKSRF_NML  = gen_data.nml

#---- output/input files created by code during execution ----
set FN_LAM_PROP   = lam_prop.$LID.csv
set FN_CITY_PROP  = city_prop.$LID.csv
set FN_REG_PROP   = region_prop.$LID.csv


echo $LINE
echo $LID

set echo ON

echo $LINE #--- form surfaces consisting of layered materials
ncl fn_in_mat=\"$FN_MAT_PROP\"    fn_in_lam=\"$FN_LAM_SPEC\"    fn_out=\"$FN_LAM_PROP\"   gen_lam.ncl  

echo $LINE #--- create all possible city types
ncl fn_in_surf=\"$FN_LAM_PROP\"   fn_in_spec=\"$FN_CITY_SPEC\"  fn_out=\"$FN_CITY_PROP\"  gen_city.ncl

echo $LINE # ---select desired city types for each region/category
ncl fn_in_city=\"$FN_CITY_PROP\"  fn_in_spec=\"$FN_REG_SPEC\"   fn_out=\"$FN_REG_PROP\"   gen_region.ncl 

echo $LINE

ncl gen_data_1km.ncl LID=\"$LID\" nml_fn=\"$FN_MKSRF_NML\"

ncl gen_data_05deg.ncl LID=\"$LID\" nml_fn=\"$FN_MKSRF_NML\"

#----- must run mksrf code (not provided) after gen_data_05deg.ncl and before gen_data_clm.ncl -----

# ncl gen_data_clm.ncl LID=\"$LID\" nml_fn=\"$FN_MKSRF_NML\"
