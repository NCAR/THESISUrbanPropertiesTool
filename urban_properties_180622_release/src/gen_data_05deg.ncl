;===============================================================================
; SVN $Id: gen_data_05deg.ncl 211 2017-11-16 22:59:53Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_data_05deg.ncl $
;===============================================================================
; NCL script
; aggregate_1km_urbanparam_file.ncl
; This program aggregates the 1km urban parameter file to a given
; coarser resolution (e.g., 0.05 degrees). 
; Keith Oleson, Aug 2016
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
   subName = "(gen_05deg_data: main) "

;  LID = systemfunc("date +%y%m%d-%H%M%S")   ; get Log ID from command line
   print(subName+"Log ID = " + LID)
;  systemfunc_date = systemfunc ("date")
   creation_info = systemfunc("whoami")+" "+systemfunc ("date")

   create_file = True

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Input namelist variables")
;rint(subName+                    " Input namelist variables")
print(subName+"-----------------------------------------------------------------")

;-------------------------------------------------
; USER MODS
;-------------------------------------------------

;  res_out = "0.05x0.05"
;  file_creation_date = "170726"
;  output_dir = "/glade/p/cgd/tss/people/oleson/...PROPERTIES_THESIS_TOOL/Urban_Scenarios_Jul_24_2017/"
;  output_fn_1km  = "mksrf_urban_Roof_Albedo_1km_simyr2000.c"+file_creation_date+".nc"
;  output_fn_05deg = "mksrf_urban_Roof_Albedo_"+res_out+"_simyr2000.c"+file_creation_date+".nc"

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

   nml_variable = "output_fn_05deg"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   temp_str = str_sub_str(temp_str,"LID",LID)
   print(subName + nml_variable + "  = " + temp_str)
   output_fn_05deg = temp_str

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

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+" read input data")
print(subName+"-----------------------------------------------------------------")

 ; 6 1km cells per 0.05 degrees
 x_scale = 6
 y_scale = 6

 ; Set some fixed dimensions (should get from 1km file)
 numsolar        = 2
 numrad          = 2
 nlevurb         = 10
 num_regions     = 33
 num_urban_types = 3

; Get 1km data
  fn = output_dir+output_fn_1km
  print(subName+"addfile = " + fn)
  in_file = addfile(fn,"r")
; in_file = addfile(output_fn_1km,"r")

 landmask = in_file->LANDMASK
 lat = in_file->LAT
 lon = in_file->LON
 dens_class = in_file->URBAN_DENSITY_CLASS
 region_id = in_file->REGION_ID
 canyon_hwr = in_file->CANYON_HWR
 wtlunit_roof = in_file->WTLUNIT_ROOF
 wtroad_perv = in_file->WTROAD_PERV
 em_roof = in_file->EM_ROOF
 em_wall = in_file->EM_WALL
 em_improad = in_file->EM_IMPROAD
 em_perroad = in_file->EM_PERROAD
 alb_roof = in_file->ALB_ROOF
 alb_wall = in_file->ALB_WALL
 alb_improad = in_file->ALB_IMPROAD
 alb_perroad = in_file->ALB_PERROAD
 ht_roof = in_file->HT_ROOF
 wind_hgt_canyon = in_file->WIND_HGT_CANYON
 tk_roof = in_file->TK_ROOF
 tk_wall = in_file->TK_WALL
 tk_improad = in_file->TK_IMPROAD
 cv_roof = in_file->CV_ROOF
 cv_wall = in_file->CV_WALL
 cv_improad = in_file->CV_IMPROAD
 nlevimproad = in_file->NLEV_IMPROAD
 thick_roof = in_file->THICK_ROOF
 thick_wall = in_file->THICK_WALL
 t_building_min = in_file->T_BUILDING_MIN
 t_building_max = in_file->T_BUILDING_MAX

 print(subName+"create 0.05 domain data")

 nlat_out = dimsizes(lat)/y_scale
 nlon_out = dimsizes(lon)/x_scale

 lat_out = new(nlat_out,"double","No_FillValue")
 bot = y_scale/2 - 1
 top = y_scale/2
 do j = 0, nlat_out-1
   lat_out(j) = lat(bot) + (lat(top) - lat(bot))/2.d
   bot = bot + y_scale
   top = bot + 1
 end do
 lat_out!0 = "lat"
 lat_out@long_name = "lat"
 lat_out@units = "degrees north"

 lon_out = new(nlon_out,"double","No_FillValue")
 lef = x_scale/2 - 1
 rig = x_scale/2
 do i = 0, nlon_out-1
   lon_out(i) = lon(lef) + (lon(rig) - lon(lef))/2.d
   lef = lef + y_scale
   rig = lef + 1
 end do
 lon_out!0 = "lon"
 lon_out@long_name = "lon"
 lon_out@units = "degrees east"

 latixy = conform_dims((/nlat_out,nlon_out/),(/lat_out/),0)
 latixy_out = (/latixy/)
 latixy_out!0 = "lat"
 latixy_out!1 = "lon"
 latixy_out@long_name = "latitude-2d"
 latixy_out@units = "degrees north"

 longxy = conform_dims((/nlat_out,nlon_out/),(/lon_out/),1)
 longxy_out = (/longxy/)
 longxy_out!0 = "lat"
 longxy_out!1 = "lon"
 longxy_out@long_name = "longitude-2d"
 longxy_out@units = "degrees east"

 print(subName+"create 0.05 data arrays")

 pct_urban_tmp = new((/num_urban_types,nlat_out,nlon_out/),"double")
 region_id_tmp = new((/nlat_out,nlon_out/),"byte")
 landmask_tmp  = new((/nlat_out,nlon_out/),"byte")

 wks = gsn_open_wks("ps","dummy")
 gsn_define_colormap(wks,"BlueRed")
 resh = True
 resh@gsnHistogramDiscreteBinValues = ispan(1,33,1)
 resh@gsnDraw = False
 resh@gsnFrame = False

 opt = True
 opt@bin_min = 1
 opt@bin_max = 33

print(subName+"-----------------------------------------------------------------")
print(subName+"aggregate 1km data to 0.05 data (% urban,landmask,region id)")
print(subName+"-----------------------------------------------------------------")

 bot = 0
 top = y_scale-1
 do j = 0, nlat_out-1
   if (mod(j,500).eq.0) then
      print(subName+"DEBUG: lat index = "+j+" of "+nlat_out+" -- "+systemfunc("date"))
   end if
   lef = 0
   rig = x_scale-1
   do i = 0, nlon_out-1
     ;--- extract associated 1km cells ----
     landmask1d   = ndtooned(landmask(bot:top,lef:rig))
     region_id1d  = ndtooned(region_id(bot:top,lef:rig))
     dens_class1d = ndtooned(dens_class(bot:top,lef:rig))

     ;--- get number and indices of unmasked 1km cells ---
     indx         = ind(landmask1d .eq. 1b)  ; ? should be (lndmask1d .ne. 0b)
     num_valid    = num(landmask1d .eq. 1b)  ; ? should be (lndmask1d .ne. 0b)

     ;--- aggregate 1km data to 0.05degree grid ----
     if (.not.(all(ismissing(indx)))) then
       landmask_tmp(j,i) = 1b ; non-zero <=> land exists in this cell

       num_tbd = int2dble(num(dens_class1d(indx) .eq. 1b))
       num_hd  = int2dble(num(dens_class1d(indx) .eq. 2b))
       num_md  = int2dble(num(dens_class1d(indx) .eq. 3b))
       pct_urban_tmp(0,j,i) = (num_tbd/num_valid)*100.d
       pct_urban_tmp(1,j,i) = (num_hd/num_valid)*100.d
       pct_urban_tmp(2,j,i) = (num_md/num_valid)*100.d

       if (dimsizes(indx) .gt. 2) then ; > 2 input cells: use region ID that occurs most often
         tmp = pdfx(region_id1d(indx),33,opt)
         maxindx = integertobyte(maxind(tmp))
         region_id_tmp(j,i) = maxindx + 1b
         delete(tmp)
         delete(maxindx)
       else
         region_id_tmp(j,i) = region_id1d(indx(0)) ; 1 or 2 input cells: use region ID of first cell
       end if
     else
       landmask_tmp(j,i) = 0b
       pct_urban_tmp(:,j,i) = 0.d
       region_id_tmp(j,i) = 0b
     end if
     lef = rig + 1
     rig = lef + x_scale - 1
     delete(indx)
   end do
   bot = top + 1
   top = bot + y_scale - 1
 end do

 pct_urban_out = (/pct_urban_tmp/)
 pct_urban_out!0 = "density_class"
 pct_urban_out!1 = "lat"
 pct_urban_out!2 = "lon"
 pct_urban_out@long_name = "percent urban"
 pct_urban_out@units = "%"
 delete(pct_urban_out@_FillValue)

;print(max(pct_urban_out(0,:,:)))
;print(min(pct_urban_out(0,:,:)))
;print(max(pct_urban_out(1,:,:)))
;print(min(pct_urban_out(1,:,:)))
;print(max(pct_urban_out(2,:,:)))
;print(min(pct_urban_out(2,:,:)))

 landmask_out = (/landmask_tmp/)
 landmask_out!0 = "lat"
 landmask_out!1 = "lon"
 landmask_out@long_name = "land mask"
 landmask_out@units = "unitless"
 delete(landmask_out@_FillValue)

 region_id_out = (/region_id_tmp/)
 region_id_out!0 = "lat"
 region_id_out!1 = "lon"
 region_id_out@long_name = "Region ID"
 region_id_out@units = "unitless"
 delete(region_id_out@_FillValue)

 if (create_file) then

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+" write output data")
print(subName+"-----------------------------------------------------------------")


; Write new file
;setfileoption("nc","Format","LargeFile") 
 setfileoption("nc","Format","NetCDF4Classic") 

  fn = output_dir+output_fn_05deg
  print(subName+"addfile = " + fn)
  out_file = addfile(fn,"c")

; system("/bin/rm -f " + output_fn_05deg)
; out_file = addfile(output_fn_05deg,"c")
; setfileoption(out_file,"DefineMode",True)

 fAtt = True
 fAtt@title = metadata_title
 fAtt@case_id = metadata_caseID
 fAtt@source = output_fn_1km
;fAtt@date = systemfunc_date
 fAtt@created_by = creation_info
 fileattdef( out_file, fAtt)
 
 dimNames = (/"lat",    "lon",   "numsolar", "numrad", "nlevurb", "region",    "density_class"/)
 dimSizes = (/nlat_out, nlon_out,numsolar,   numrad,   nlevurb,   num_regions, num_urban_types/)
 dimUnlim = (/False,    False,   False,      False,    False,     False,       False/)
 filedimdef(out_file,dimNames,dimSizes,dimUnlim)

 filevardef(out_file, "LANDMASK", typeof(landmask_out), getvardims(landmask_out))
 filevardef(out_file, "LAT", typeof(lat_out), getvardims(lat_out))
 filevardef(out_file, "LON", typeof(lon_out), getvardims(lon_out))
 filevardef(out_file, "LATIXY", typeof(latixy_out), getvardims(latixy_out))
 filevardef(out_file, "LONGXY", typeof(longxy_out), getvardims(longxy_out))
 filevardef(out_file, "PCT_URBAN", typeof(pct_urban_out), getvardims(pct_urban_out))
 filevardef(out_file, "REGION_ID", typeof(region_id_out), getvardims(region_id_out))
 filevardef(out_file, "CANYON_HWR", typeof(canyon_hwr), getvardims(canyon_hwr))
 filevardef(out_file, "WTLUNIT_ROOF", typeof(wtlunit_roof), getvardims(wtlunit_roof))
 filevardef(out_file, "WTROAD_PERV", typeof(wtroad_perv), getvardims(wtroad_perv))
 filevardef(out_file, "EM_ROOF", typeof(em_roof), getvardims(em_roof))
 filevardef(out_file, "EM_WALL", typeof(em_wall), getvardims(em_wall))
 filevardef(out_file, "EM_IMPROAD", typeof(em_improad), getvardims(em_improad))
 filevardef(out_file, "EM_PERROAD", typeof(em_perroad), getvardims(em_perroad))
 filevardef(out_file, "ALB_ROOF", typeof(alb_roof), getvardims(alb_roof))
 filevardef(out_file, "ALB_WALL", typeof(alb_wall), getvardims(alb_wall))
 filevardef(out_file, "ALB_IMPROAD", typeof(alb_improad), getvardims(alb_improad))
 filevardef(out_file, "ALB_PERROAD", typeof(alb_perroad), getvardims(alb_perroad))
 filevardef(out_file, "HT_ROOF", typeof(ht_roof), getvardims(ht_roof))
 filevardef(out_file, "WIND_HGT_CANYON", typeof(wind_hgt_canyon), getvardims(wind_hgt_canyon))
 filevardef(out_file, "TK_ROOF", typeof(tk_roof), getvardims(tk_roof))
 filevardef(out_file, "TK_WALL", typeof(tk_wall), getvardims(tk_wall))
 filevardef(out_file, "TK_IMPROAD", typeof(tk_improad), getvardims(tk_improad))
 filevardef(out_file, "CV_ROOF", typeof(cv_roof), getvardims(cv_roof))
 filevardef(out_file, "CV_WALL", typeof(cv_wall), getvardims(cv_wall))
 filevardef(out_file, "CV_IMPROAD", typeof(cv_improad), getvardims(cv_improad))
 filevardef(out_file, "NLEV_IMPROAD", typeof(nlevimproad), getvardims(nlevimproad))
 filevardef(out_file, "THICK_ROOF", typeof(thick_roof), getvardims(thick_roof))
 filevardef(out_file, "THICK_WALL", typeof(thick_wall), getvardims(thick_wall))
 filevardef(out_file, "T_BUILDING_MIN", typeof(t_building_min), getvardims(t_building_min))
 filevardef(out_file, "T_BUILDING_MAX", typeof(t_building_max), getvardims(t_building_max))

 filevarattdef(out_file, "LANDMASK", landmask_out)
 filevarattdef(out_file, "LAT", lat_out)
 filevarattdef(out_file, "LON", lon_out)
 filevarattdef(out_file, "LATIXY", latixy_out)
 filevarattdef(out_file, "LONGXY", longxy_out)
 filevarattdef(out_file, "PCT_URBAN", pct_urban_out)
 filevarattdef(out_file, "REGION_ID", region_id_out)
 filevarattdef(out_file, "CANYON_HWR", canyon_hwr)
 filevarattdef(out_file, "WTLUNIT_ROOF", wtlunit_roof)
 filevarattdef(out_file, "WTROAD_PERV", wtroad_perv)
 filevarattdef(out_file, "EM_ROOF", em_roof)
 filevarattdef(out_file, "EM_WALL", em_wall)
 filevarattdef(out_file, "EM_IMPROAD", em_improad)
 filevarattdef(out_file, "EM_PERROAD", em_perroad)
 filevarattdef(out_file, "ALB_ROOF", alb_roof)
 filevarattdef(out_file, "ALB_WALL", alb_wall)
 filevarattdef(out_file, "ALB_IMPROAD", alb_improad)
 filevarattdef(out_file, "ALB_PERROAD", alb_perroad)
 filevarattdef(out_file, "HT_ROOF", ht_roof)
 filevarattdef(out_file, "WIND_HGT_CANYON", wind_hgt_canyon)
 filevarattdef(out_file, "TK_ROOF", tk_roof)
 filevarattdef(out_file, "TK_WALL", tk_wall)
 filevarattdef(out_file, "TK_IMPROAD", tk_improad)
 filevarattdef(out_file, "CV_ROOF", cv_roof)
 filevarattdef(out_file, "CV_WALL", cv_wall)
 filevarattdef(out_file, "CV_IMPROAD", cv_improad)
 filevarattdef(out_file, "NLEV_IMPROAD", nlevimproad)
 filevarattdef(out_file, "THICK_ROOF", thick_roof)
 filevarattdef(out_file, "THICK_WALL", thick_wall)
 filevarattdef(out_file, "T_BUILDING_MIN", t_building_min)
 filevarattdef(out_file, "T_BUILDING_MAX", t_building_max)

 setfileoption(out_file,"DefineMode",False)

 out_file->LANDMASK = (/landmask_out/)
 out_file->LAT = (/lat_out/)
 out_file->LON = (/lon_out/)
 out_file->LATIXY = (/latixy_out/)
 out_file->LONGXY = (/longxy_out/)
 out_file->PCT_URBAN = (/pct_urban_out/)
 out_file->REGION_ID = (/region_id_out/)
 out_file->CANYON_HWR = (/canyon_hwr/)
 out_file->WTLUNIT_ROOF = (/wtlunit_roof/)
 out_file->WTROAD_PERV = (/wtroad_perv/)
 out_file->EM_ROOF = (/em_roof/)
 out_file->EM_WALL = (/em_wall/)
 out_file->EM_IMPROAD = (/em_improad/)
 out_file->EM_PERROAD = (/em_perroad/)
 out_file->ALB_ROOF = (/alb_roof/)
 out_file->ALB_WALL = (/alb_wall/)
 out_file->ALB_IMPROAD = (/alb_improad/)
 out_file->ALB_PERROAD = (/alb_perroad/)
 out_file->HT_ROOF = (/ht_roof/)
 out_file->WIND_HGT_CANYON = (/wind_hgt_canyon/)
 out_file->TK_ROOF = (/tk_roof/)
 out_file->TK_WALL = (/tk_wall/)
 out_file->TK_IMPROAD = (/tk_improad/)
 out_file->CV_ROOF = (/cv_roof/)
 out_file->CV_WALL = (/cv_wall/)
 out_file->CV_IMPROAD = (/cv_improad/)
 out_file->NLEV_IMPROAD = (/nlevimproad/)
 out_file->THICK_ROOF = (/thick_roof/)
 out_file->THICK_WALL = (/thick_wall/)
 out_file->T_BUILDING_MIN = (/t_building_min/)
 out_file->T_BUILDING_MAX = (/t_building_max/)
  
 end if

print(subName+"=================================================================")
print(subName+systemfunc("date")+ " Finished.")
print(subName+"=================================================================")

end

