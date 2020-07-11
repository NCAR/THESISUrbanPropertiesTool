;===============================================================================
; SVN $Id: gen_region.ncl 176 2017-02-18 00:57:00Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_region.ncl $
;===============================================================================
; given (1) surface properties and (2) city specifications
; create a list of cities with their appropriate properties
;===============================================================================

procedure region_info(shortName,region,cat,region_id,cat_id,build_id)

;-----------------------------------------------------------------------------------------
; parse string of the form: "Alaska_TBD_1" ~ [region]_[category_ID]_[building_ID]
;-----------------------------------------------------------------------------------------

begin

   strs = str_split(shortName,"_")

   region    = "       "
   region    = strs(0)
   cat       = strs(1)
   build_id  = stringtoint(strs(2))

   region = str_sub_str(region,"-","_")

   region_id = -1      ; Alaska = 1
   cat_id    = -1      ; "TBD = 1"

   ;--- from cat, get corresponding cat_id ---
   cat_id = -99
   if (cat .eq. "TBD") then
     cat_id = 1
   end if
   if (cat .eq. "HD") then
     cat_id = 2
   end if
   if (cat .eq. "MD") then
     cat_id = 3
   end if
   if (cat .eq. "LD") then
     cat_id = 4
   end if
   
   ;--- from region, get corresponding region_id ---
   region_id = -99
   if (region .eq. "Alaska") then
     region_id = 1
   end if
   if (region .eq. "Australia") then
     region_id = 2
   end if
   if (region .eq. "Brazil") then
     region_id = 3
   end if
   if (region .eq. "C_Africa") then
     region_id = 4
   end if
   if (region .eq. "C_Asia") then
     region_id = 5
   end if
   if (region .eq. "Canada") then
     region_id = 6
   end if
   if (region .eq. "Caribbean") then
     region_id = 7
   end if
   if (region .eq. "China") then
     region_id = 8
   end if
   if (region .eq. "E_Africa") then
     region_id = 9
   end if
   if (region .eq. "E_Asia") then
     region_id = 10
   end if
   if (region .eq. "E_Europe") then
     region_id = 11
   end if
   if (region .eq. "Greenland") then
     region_id = 12
   end if
   if (region .eq. "India") then
     region_id = 13
   end if
   if (region .eq. "Middle_Am") then
     region_id = 14
   end if
   if (region .eq. "Mid_East") then
     region_id = 15
   end if
   if (region .eq. "N_Africa") then
     region_id = 16
   end if
   if (region .eq. "NC_USA") then
     region_id = 17
   end if
   if (region .eq. "NE_USA") then
     region_id = 18
   end if
   if (region .eq. "N_Europe") then
     region_id = 19
   end if
   if (region .eq. "NW_USA") then
     region_id = 20
   end if
   if (region .eq. "Oceania") then
     region_id = 21
   end if
   if (region .eq. "Russia") then
     region_id = 22
   end if
   if (region .eq. "S_Africa") then
     region_id = 23
   end if
   if (region .eq. "S_Asia") then
     region_id = 24
   end if
   if (region .eq. "SC_USA") then
     region_id = 25
   end if
   if (region .eq. "SE_USA") then
     region_id = 26
   end if
   if (region .eq. "SE_Asia") then
     region_id = 27
   end if
   if (region .eq. "S_Europe") then
     region_id = 28
   end if
   if (region .eq. "SW_USA") then
     region_id = 29
   end if
   if (region .eq. "Temp_SA") then
     region_id = 30
   end if
   if (region .eq. "Trop_SA") then
     region_id = 31
   end if
   if (region .eq. "W_Africa") then
     region_id = 32
   end if
   if (region .eq. "W_Europe") then
     region_id = 33
   end if
   
   if (1 .eq. 0) then ; debug
      print(region_id + " "+ cat_id + " "+ build_id + " "+ region + " "+ cat)
   end if

end

;=========================================================================================
; main program
;=========================================================================================
begin

   dbug = 0  ; debug level: 0 => no debug output

;-------------------------------------------------------------------------------
; svn keywords to document output data
;-------------------------------------------------------------------------------
   sys_date = systemfunc("date")
   sys_user = systemfunc("whoami")
   svn_id  = "SVN $Id: gen_region.ncl 176 2017-02-18 00:57:00Z kauff $"
   svn_url = "SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_region.ncl $"

   subName = "(gen_region) "

;-------------------------------------------------------------------------------
; set input & output file names  --  must set on command line, eg.
; ncl fn_in_city=\"city_prop.csv\" fn_in_spec=\"region_spec.csv\" fn_out=\"region_prop.csv\" gen_region.ncl
;-------------------------------------------------------------------------------
;  fn_in_region  = "city_prop.csv"
;  fn_in_spec = "region_spec.csv"
;  fn_out     = "region_prop.csv"

   print("file name fn_in_city = " + fn_in_city)
   print("file name fn_in_spec = " + fn_in_spec)
   print("file name fn_out     = " + fn_out    )

   fn_dbug    = "gen_region_dbug.txt"

   spval = 1.0000e32

print("------------------------------------------------------------------------")
print(" input city property data")
print("------------------------------------------------------------------------")

   ;---Read in file as array of strings so we can parse each line
   lines = asciiread(fn_in_city,-1,"string")
   nEOF  = min ( str_match_ind(lines(:),"EOF") )

   lines_prop = str_match_regex(lines(0:nEOF-1),"prop")
   lines_wall = str_match_regex(lines(0:nEOF-1),"wall")
   lines_roof = str_match_regex(lines(0:nEOF-1),"roof")
   lines_road = str_match_regex(lines(0:nEOF-1),"road")

print("------------------------------------------------------------------------")
print(" input region specification data")
print("------------------------------------------------------------------------")

   ;--- Read in the whole text file ---
   delete(lines)
   temp_lines = asciiread(fn_in_spec,-1,"string")
   nLines = min ( str_match_ind(temp_lines(:),"EOF") )
   lines = temp_lines(0:nLines-1)
   print("file " + fn_in_spec + " : number of input lines = " + nLines )

   ;--- determine how many region cities are indicated by the input data ---
   nSpec = nLines
   print("file " + fn_in_spec + " : number of region cities   = " + nSpec )

   ;--- form 2d array of input data excluding all text after "EOF" ---
;  delete(split_lines)
   split_lines = str_split_csv(lines(:),",",0)

   spec_shortName  = new( (/nSpec/),"string")
   spec_cityType   = new( (/nSpec/),"string")
   spec_notes      = new( (/nSpec/),"string")

   k_spec_shortName  =  0
   k_spec_cityType   =  1
   k_spec_notes      =  2

   spec_shortName  = "unset"
   spec_cityType   = spval
   spec_notes      = "no notes "

   do n=0,nSpec - 1
      spec_shortName(n)  = str_strip  (   split_lines(n,k_spec_shortName) )
      spec_cityType (n)  = str_strip  (   split_lines(n,k_spec_cityType ) )
      spec_notes    (n)  = str_strip  (   split_lines(n,k_spec_notes    ) )
   end do


print("------------------------------------------------------------------------")
print(" output region property data")
print("------------------------------------------------------------------------")

   do n=0,nSpec - 1
      city_region      = "unset" ;
      city_cat         = "unset" ;
      city_region_id   = -1      ;
      city_cat_id      = -1      ;
      city_build_id    = -1      ;

      city_shortName = str_strip(spec_cityType(n))
      m = min ( str_match_ind(lines_prop(:),city_shortName)) ; 1st matching city type
      if (ismissing(m)) then
         print("cant find city type = " + city_shortName)
      end if

      ;--- parse city short name to get additional info: region, category, etc. ----
      region_info(city_shortName,city_region,city_cat,city_region_id,city_cat_id,city_build_id)

      ;--- reformat string for city category, etc. ----
      strs = (/ sprinti("%2i,",city_region_id) ,sprinti("%1i,",city_cat_id) ,sprinti("%1i,",city_build_id) ,city_region ,",",city_cat /)
      new_city_id = str_concat(strs)

      alist = [/ str_sub_str(lines_prop(m),city_shortName,new_city_id) /]
      if (n.eq.0) then
         write_table(fn_out,"w",alist,  "%-160s")
      else
         write_table(fn_out,"a",alist,  "%-160s")
      end if
      alist = [/ str_sub_str(lines_wall(m),city_shortName,new_city_id) /]
      write_table(fn_out,"a",alist,  "%-200s")
      alist = [/ str_sub_str(lines_roof(m),city_shortName,new_city_id) /]
      write_table(fn_out,"a",alist,  "%-200s")
      alist = [/ str_sub_str(lines_road(m),city_shortName,new_city_id) /]
      write_table(fn_out,"a",alist,  "%-200s")

   end do

   delete(alist)
   alist = [/ "EOF" /]
   write_table(fn_out,"a",alist, "%-5s")
   delete(alist)

   ;----- data key -----
   alist = [/"rid,cid,bid,reg,cat,  prop,    f_bld,        h,          h:w,      f_prv,       f_rf,       Tmin,       Tmax,      notes"/]
   write_table(fn_out,"a",alist, "%-50s")
   delete(alist)

   alist = [/"rid,cid,bid,reg,cat,  surf,   albedo,   emmiss,        thick,        tk1,        tk2,        tk3,        tk4,        tk5,        tk6,        tk7,        tk8,        tk9,       tk10,       cv1,       cv2,       cv3,       cv4,       cv5,       cv6,       cv7,       cv8,       cv9,      cv10 " /]
   write_table(fn_out,"a",alist,"%-200s")

   ;----- documentment code used, user, date -----
   delete(alist)
   alist = [/ "-------------------------------------------------------" /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "File created " + sys_date + " by " + sys_user /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ svn_id /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ svn_url /]
   write_table(fn_out,"a",alist,"%-50s")

   alist = [/ "Input file: " + fn_in_city /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "Input file: " + fn_in_spec /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "Ouput file: " + fn_out /]
   write_table(fn_out,"a",alist,"%-50s")

end

