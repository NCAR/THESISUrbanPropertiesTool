;===============================================================================
; SVN $Id: gen_data_clm.ncl 208 2017-11-10 19:56:28Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_data_clm.ncl $
;===============================================================================
; NCL script
; create_CLM50_tbuildmax_streams_file.ncl
; This script reads in the maximum building temperature file from a surface
; dataset and creates a maximum building temperature streams file for CLM50.
; Keith Oleson, Aug 2017
;**************************************

load "./keyword_values.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;================================================================================
; Main code
;================================================================================
begin 

   subName = "(gen_data_clm) " 
;  LID = systemfunc("date +%y%m%d-%H%M%S")   ; get Log ID from command line
   print(subName+"Log ID = " + LID)
   systemfunc_date = systemfunc ("date")
   create_file = True

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Input namelist variables")
print(subName+"-----------------------------------------------------------------")

   ;----- case-specific output -----
   nml_variable = "output_dir"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   output_dir = temp_str

   nml_variable = "output_fn_1km" 
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   temp_str = str_sub_str(temp_str,"LID",LID)
   print(subName + nml_variable + "  = " + temp_str)
   output_fn_1km = temp_str

   nml_variable = "template_dir"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   template_dir = temp_str

   nml_variable = "template_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   template_fn = temp_str

   nml_variable = "mksrf_dir"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   mksrf_dir = temp_str

   nml_variable = "mksrf_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   mksrf_fn = temp_str

   nml_variable = "output_fn_clm" 
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   temp_str = str_sub_str(temp_str,"LID",LID)
   print(subName + nml_variable + "  = " + temp_str)
   output_fn_clm = temp_str

   nml_variable = "metadata_title"
   temp_stra = keyword_values(nml_fn,nml_variable,"string")
   temp_str = ""
   n = dimsizes(temp_stra)
   do i = 0,n-1
      temp_str = temp_str + temp_stra(i) + " "  ; BUG in keyword_values, must reconstruct string
   end do
   delete(temp_stra)
   print(subName + nml_variable + "  = " + temp_str)
   metadata_title = temp_str

   nml_variable = "metadata_source"
   temp_stra = keyword_values(nml_fn,nml_variable,"string")
   temp_str = ""
   n = dimsizes(temp_stra)
   do i = 0,n-1
      temp_str = temp_str + temp_stra(i) + " "  ; BUG in keyword_values, must reconstruct string
   end do
   delete(temp_stra)
   print(subName + nml_variable + "  = " + temp_str)
   metadata_source = temp_str

   nml_variable = "metadata_caseID"
   temp_stra = keyword_values(nml_fn,nml_variable,"string")
   temp_str = ""
   n = dimsizes(temp_stra)
   do i = 0,n-1
      temp_str = temp_str + temp_stra(i) + " "  ; BUG in keyword_values, must reconstruct string
   end do
   delete(temp_stra)
   print(subName + nml_variable + "  = " + temp_str)
   metadata_caseID = temp_str

;-------------------------------------------------------------
; USER MODS
;-------------------------------------------------------------
; Note that the infile and srffile must be consistent, i.e, both with the same set of control 
; or scenario parameters 
; This file was generated from generate_netcdf_1km_urbanparam_file.ncl
;
;  infile = "mksrf_urban_1km_simyr2000.c170724.nc"
;  output from gen_data_1km.ncl 
;
;  srffile = "/glade/p/work/oleson/clm4_5_16_r251/components/clm/tools/mksurfdata_map/surfdata_0.9x1.25_16pfts_CMIP6_simyr1850_c170724.nc"
;  srffile is a previously created output file used as a template file
;
;  outfile = "CLM50_tbuildmax_V2_0.9x1.25_simyr1849-2106_c170804.nc"
;-------------------------------------------------------------

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Input clm template netcdf file")
print(subName+"-----------------------------------------------------------------")

; Get some grid fields from latest CLM50 urbantv_streams file
;in1 = addfile("/glade/p/cesmdata/cseg/inputdata/lnd/clm2/urbandata/CLM50_tbuildmax_Oleson_2016_0.9x1.25_simyr1849-2106_c160923.nc","r")
   fn = template_dir+template_fn
   print(subName+"addfile = " + fn)
   in1 = addfile(fn,"r")
 area               = in1->area
 area!0             = "lat"
 area!1             = "lon"
 longxy             = in1->LONGXY
 longxy!0           = "lat"
 longxy!1           = "lon"
 latixy             = in1->LATIXY
 latixy!0           = "lat"
 latixy!1           = "lon"
 lat                = in1->lat
 nlat               = dimsizes(lat)
 lon                = in1->lon
 nlon               = dimsizes(lon)
 landmask           = in1->LANDMASK
; Get time information
 time               = in1->time
 ntim               = dimsizes(time)
 year               = in1->year
 time_bnds          = in1->time_bnds
 nnv = dimsizes(time_bnds(0,:))
 printVarSummary(time_bnds)
; Get tbuildmax for density types (to be overwritten by infile data)
 t_building_max_1   = in1->tbuildmax_TBD
 t_building_max_2   = in1->tbuildmax_HD
 t_building_max_3   = in1->tbuildmax_MD

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " readt the output from mksrf tool")
print(subName+"-----------------------------------------------------------------")

; Get region_id from surface dataset
;in2 = addfile(srffile,"r")
   fn = mksrf_dir+mksrf_fn
   print(subName+"addfile = " + fn)
 in2 = addfile(fn,"r")
 region_id = in2->URBAN_REGION_ID  ; (lat,lon)
 printVarSummary(region_id)

; Ensure No AC for 1849-1949
 nyears = 1949 - 1849 + 1
 t_building_max_1(0:nyears-1,:,:) = where(conform_dims((/nyears,nlat,nlon/),landmask,(/1,2/)) .eq. 1,380.d,0.d)
 t_building_max_2(0:nyears-1,:,:) = where(conform_dims((/nyears,nlat,nlon/),landmask,(/1,2/)) .eq. 1,380.d,0.d)
 t_building_max_3(0:nyears-1,:,:) = where(conform_dims((/nyears,nlat,nlon/),landmask,(/1,2/)) .eq. 1,380.d,0.d)
; Ensure No AC for 2101-2106
 nyears = 2106 - 2101 + 1
 styrind = 2101 - 1849
 fnyrind = styrind+nyears-1
 t_building_max_1(styrind:fnyrind,:,:) = where(conform_dims((/nyears,nlat,nlon/),landmask,(/1,2/)) .eq. 1,380.d,0.d)
 t_building_max_2(styrind:fnyrind,:,:) = where(conform_dims((/nyears,nlat,nlon/),landmask,(/1,2/)) .eq. 1,380.d,0.d)
 t_building_max_3(styrind:fnyrind,:,:) = where(conform_dims((/nyears,nlat,nlon/),landmask,(/1,2/)) .eq. 1,380.d,0.d)

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " read the output from gen_data_1km")
print(subName+"-----------------------------------------------------------------")

; Read in T_BUILDING_MAX fields from mksrf_urban_1km_simyr2000 file
;in3 = addfile(infile,"r")    (output of 1km data)
   fn = output_dir+output_fn_1km
   print(subName+"addfile = " + fn)
   in3 = addfile(fn,"r")
 t_building_max = in3->T_BUILDING_MAX  ; (region, density class)
 nreg = dimsizes(t_building_max(:,0))
 printVarSummary(t_building_max)

; AC from 1950-2100
 nyears = 2100 - 1950 + 1
 styrind = 1950 - 1849
 fnyrind = styrind+nyears-1
 do i = 1, nreg
   t_building_max_1(styrind:fnyrind,:,:) = conform_dims((/nyears,nlat,nlon/), where(region_id .eq. i,t_building_max(i-1,0),t_building_max_1(styrind,:,:)), (/1,2/))
   t_building_max_2(styrind:fnyrind,:,:) = conform_dims((/nyears,nlat,nlon/), where(region_id .eq. i,t_building_max(i-1,1),t_building_max_2(styrind,:,:)), (/1,2/))
   t_building_max_3(styrind:fnyrind,:,:) = conform_dims((/nyears,nlat,nlon/), where(region_id .eq. i,t_building_max(i-1,2),t_building_max_3(styrind,:,:)), (/1,2/))
 end do

 t_building_max_1!0 = "time"
 t_building_max_1&time = time
 t_building_max_1!1 = "lat"
 t_building_max_1&lat = lat
 t_building_max_1!2 = "lon"
 t_building_max_1&lon = lon
 copy_VarCoords(t_building_max_1,t_building_max_2)
 copy_VarCoords(t_building_max_1,t_building_max_3)
 t_building_max_1@long_name = "maximum interior building temperature for TBD class"
 t_building_max_1@units = "K"
 t_building_max_2@long_name = "maximum interior building temperature for HD class"
 t_building_max_2@units = "K"
 t_building_max_3@long_name = "maximum interior building temperature for MD class"
 t_building_max_3@units = "K"
 delete(t_building_max_1@_FillValue)
 delete(t_building_max_2@_FillValue)
 delete(t_building_max_3@_FillValue)

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ "Output the netcdf file that CLM needs ")
print(subName+"-----------------------------------------------------------------")

;cdf_filename = outfile
   fn = output_dir+output_fn_clm
   print(subName+"addfile = " + fn)
 cdf_filename = fn
 system("/bin/rm -f " + cdf_filename)
;setfileoption("nc","Format","LargeFile")
 setfileoption("nc","Format","NetCDF4Classic")
 system("/bin/rm -f " + cdf_filename)
 out_file = addfile(cdf_filename,"c")
 setfileoption(out_file,"DefineMode",True)
 fAtt = True
 fAtt@title = metadata_title
 fAtt@source = metadata_source
 fAtt@case_id = metadata_caseID
 fAtt@date = systemfunc_date
 fileattdef( out_file, fAtt)

 dimNames = (/"lat",   "lon",    "nv",    "time"/)
 dimSizes = (/ nlat,    nlon,     nnv,      ntim/)
 dimUnlim = (/False,   False,   False,      True/)
 filedimdef(out_file,dimNames,dimSizes,dimUnlim)

 filevardef(out_file, "lat", typeof(lat), getvardims(lat))
 filevardef(out_file, "lon", typeof(lon), getvardims(lon))
 filevardef(out_file, "LATIXY", typeof(latixy), getvardims(latixy))
 filevardef(out_file, "LONGXY", typeof(longxy), getvardims(longxy))
 filevardef(out_file, "LANDMASK", typeof(landmask), getvardims(landmask))
 filevardef(out_file, "time", typeof(time), getvardims(time))
 filevardef(out_file, "area", typeof(area), getvardims(area))
 filevardef(out_file, "year", typeof(year), getvardims(year))
 filevardef(out_file, "time_bnds", typeof(time_bnds), getvardims(time_bnds))
 filevardef(out_file, "tbuildmax_TBD", typeof(t_building_max_1), getvardims(t_building_max_1))
 filevardef(out_file, "tbuildmax_HD", typeof(t_building_max_2), getvardims(t_building_max_2))
 filevardef(out_file, "tbuildmax_MD", typeof(t_building_max_3), getvardims(t_building_max_3))

 filevarattdef(out_file, "lat", lat)
 filevarattdef(out_file, "lon", lon)
 filevarattdef(out_file, "LATIXY", latixy)
 filevarattdef(out_file, "LONGXY", longxy)
 filevarattdef(out_file, "LANDMASK", landmask)
 filevarattdef(out_file, "time", time)
 filevarattdef(out_file, "year", year)
 filevarattdef(out_file, "area", area)
 filevarattdef(out_file, "time_bnds", time_bnds)
 filevarattdef(out_file, "tbuildmax_TBD", t_building_max_1)
 filevarattdef(out_file, "tbuildmax_HD", t_building_max_2)
 filevarattdef(out_file, "tbuildmax_MD", t_building_max_3)

 setfileoption(out_file,"DefineMode",False)

 out_file->time = (/time/)
 out_file->area = (/area/)
 out_file->LANDMASK = (/landmask/)
 out_file->lat = (/lat/)
 out_file->lon = (/lon/)
 out_file->LATIXY = (/latixy/)
 out_file->LONGXY = (/longxy/)
 out_file->time = (/time/)
 out_file->year = (/year/)
 out_file->time_bnds = (/time_bnds/)
 out_file->tbuildmax_TBD = (/t_building_max_1/)
 out_file->tbuildmax_HD = (/t_building_max_2/)
 out_file->tbuildmax_MD = (/t_building_max_3/)

 print ("=========================================")
 print ("Finish Time: "+systemfunc("date") )
 print ("=========================================")

end
