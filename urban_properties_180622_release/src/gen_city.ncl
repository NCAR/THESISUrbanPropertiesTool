;===============================================================================
; SVN $Id: gen_city.ncl 176 2017-02-18 00:57:00Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_city.ncl $
;===============================================================================
; given (1) surface properties and (2) city specifications
; create a list of cities with their appropriate properties
;===============================================================================

begin

   dbug = 0  ; debug level: 0 => no debug output
   maxLayers = 10

;-------------------------------------------------------------------------------
; svn keywords to document output data
;-------------------------------------------------------------------------------
   sys_date = systemfunc("date")
   sys_user = systemfunc("whoami")
   svn_id  = "SVN $Id: gen_city.ncl 176 2017-02-18 00:57:00Z kauff $"
   svn_url = "SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_city.ncl $"

;-------------------------------------------------------------------------------
; set input & output file names  --  must set on command line, eg.
; ncl fn_in_surf=\"surf_prop_ww.csv\" fn_in_spec=\"city_spec.csv\" fn_out=\"city_prop.csv\" gen_city.ncl
;-------------------------------------------------------------------------------
;  fn_in_surf = "surf_prop_ww.csv"
;  fn_in_spec = "city_spec.csv"
;  fn_out     = "city_prop.csv"

   print("file name fn_in_surf = " + fn_in_surf)
   print("file name fn_in_spec = " + fn_in_spec)
   print("file name fn_out     = " + fn_out    )

   fn_dbug    = "gen_city_dbug.txt"

   spval = 1.0000e32

print("------------------------------------------------------------------------")
print(" input surface property data")
print("------------------------------------------------------------------------")

   ;---Read in file as array of strings so we can parse each line
   lines = asciiread(fn_in_surf,-1,"string")
   split_lines = str_split_csv(lines,",",0)

   nLines  = dimsizes(split_lines(:,0))
   nfields = dimsizes(split_lines(0,:))

   nSurf = min ( str_match_ind(lines(:),"EOF") )
   print("file " + fn_in_surf + " : nLines  =           " + nLines )
   print("file " + fn_in_surf + " : nfields =           " + nfields)
   print("file " + fn_in_surf + " : number of surfaces = " + nSurf  )

   surf_shortName = new( (/nSurf/),"string")
   surf_albedo    = new( (/nSurf/),"double")
   surf_emmiss    = new( (/nSurf/),"double")
   surf_thick     = new( (/nSurf/),"double")
   surf_tk        = new( (/nSurf,maxLayers/),"double")
   surf_cv        = new( (/nSurf,maxLayers/),"double")
 ; surf_longName  = new( (/nSurf/),"string")
   k_surf_shortName = 0
   k_surf_albedo    = 1
   k_surf_emmiss    = 2
   k_surf_thick     = 3
   k_surf_tk        = 4
   k_surf_cv        = 14
 ; k_surf_longName  = 24

   do n=0,nSurf-1
      surf_shortName(n) =                split_lines(n,k_surf_shortName)
      surf_albedo   (n) = stringtodouble( split_lines(n,k_surf_albedo   ) )
      surf_emmiss   (n) = stringtodouble( split_lines(n,k_surf_emmiss   ) )
      surf_thick    (n) = stringtodouble( split_lines(n,k_surf_thick    ) )
      surf_tk       (n,:) = stringtodouble( split_lines(n,k_surf_tk:k_surf_tk+9) )
      surf_cv       (n,:) = stringtodouble( split_lines(n,k_surf_cv:k_surf_cv+9) )
   ;  surf_longName (n) =                split_lines(n,k_surf_longName )
   end do

;  do n=0,nSurf-1
;     print( surf_shortName(n) + " " + surf_tk(n) + " " + surf_cv(n) + " " + surf_albedo(n) + " " + surf_emmiss(n))
;  end do

;  if (dbug .gt. 0) then
   if ( -1  .gt. 0) then
      ;--- echo input to verify it's correct ---

      if (isfilepresent(fn_dbug)) then
         system("/bin/rm -f " + fn_out)
      end if
   
      alist = [/surf_shortName, surf_albedo ,surf_emmiss, surf_thick                \
               ,surf_tk(:,0), surf_tk(:,1), surf_tk(:,2)  ,surf_tk(:,3), surf_tk(:,4), surf_tk(:,5)  ,surf_tk(:,6), surf_tk(:,7), surf_tk(:,8)  ,surf_tk(:,9) \
               ,surf_cv(:,0), surf_cv(:,1), surf_cv(:,2)  ,surf_cv(:,3), surf_cv(:,4), surf_cv(:,5)  ,surf_cv(:,6), surf_cv(:,7), surf_cv(:,8)  ,surf_cv(:,9) \
               /]
      write_table(fn_dbug,"w",alist,"%-32s,%9.6f,%9.6f,%9.6f,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e,%10.3e")

      delete(alist)
      alist = [/ "laminant                        , albedo  , emmiss  , thick   , tk1      , tk2      , tk3      , tk4      , tk5      , tk6      , tk7      , tk8      , tk9      , tk10     , cv1      , cv2      , cv3      , cv4      , cv5      , cv6      , cv7      , cv8      , cv9      , cv10" /]
      write_table(fn_dbug,"a",alist,"%-200s")

      ;----- documentment code used, user, date -----
      delete(alist)
      alist = [/ "-------------------------------------------------------" /]
      write_table(fn_dbug,"a",alist,"%-50s")
      alist = [/ "File created " + sys_date + " by " + sys_user /]
      write_table(fn_dbug,"a",alist,"%-50s")
      alist = [/ svn_id /]
      write_table(fn_dbug,"a",alist,"%-50s")
      alist = [/ svn_url /]
      write_table(fn_dbug,"a",alist,"%-50s")

      alist = [/ "Input file: " + fn_in_surf  /]
      write_table(fn_dbug,"a",alist,"%-50s")
      delete(alist)
   end if

print("------------------------------------------------------------------------")
print(" input surface specification data")
print("------------------------------------------------------------------------")

   ;--- Read in the whole text file ---
   delete(lines)
   temp_lines = asciiread(fn_in_spec,-1,"string")
   nLines = min ( str_match_ind(temp_lines(:),"EOF") )
   lines = temp_lines(0:nLines-1)
   print("file " + fn_in_spec + " : number of input lines = " + nLines )

   ;--- determine how many laminates are indicated by the input data ---
   nSpec = nLines
   print("file " + fn_in_spec + " : number of cities   = " + nSpec )

   ;--- form 2d array of input data excluding all text after "EOF" ---
   delete(split_lines)
   split_lines = str_split_csv(lines(:),",",0)

   spec_shortName  = new( (/nSpec/),"string")
   spec_height     = new( (/nSpec/),"double")
   spec_hwratio    = new( (/nSpec/),"double")
   spec_fracPerv   = new( (/nSpec/),"double" )
   spec_fracRoof   = new( (/nSpec/),"double" )
   spec_typeWall   = new( (/nSpec/),"string")
   spec_typeWind   = new( (/nSpec/),"string")
   spec_fracWind   = new( (/nSpec/),"double" )
   spec_typeRoof   = new( (/nSpec/),"string")
   spec_fracBuild  = new( (/nSpec/),"double" )
   spec_typeRoad   = new( (/nSpec/),"string")
   spec_Tmin       = new( (/nSpec/),"double" )
   spec_Tmax       = new( (/nSpec/),"double" )
   spec_notes      = new( (/nSpec/),"string")

   k_spec_shortName  =  0
   k_spec_fracBuild  =  1
   k_spec_height     =  2
   k_spec_hwratio    =  3
   k_spec_fracPerv   =  4
   k_spec_typeWall   =  5
   k_spec_fracWind   =  6
   k_spec_typeWind   =  7
   k_spec_fracRoof   =  8
   k_spec_typeRoof   =  9
   k_spec_typeRoad   = 10
   k_spec_Tmin       = 11
   k_spec_Tmax       = 12
   k_spec_notes      = 13

   spec_shortName  = "unset"
   spec_fracBuild  = spval
   spec_height     = spval
   spec_hwratio    = spval
   spec_fracPerv   = spval
   spec_fracRoof   = spval
   spec_typeWall   = "unset"
   spec_fracWind   = spval
   spec_typeWind   = "unset"
   spec_typeRoof   = "unset"
   spec_typeRoad   = "unset"
   spec_Tmin       = spval
   spec_Tmax       = spval
   spec_notes      = "no notes "

   print("  <debug> parse spec input")
   do n=0,nSpec - 1
      spec_shortName(n)  = str_strip     ( split_lines(n,k_spec_shortName) )
      spec_fracBuild(n)  = stringtodouble( split_lines(n,k_spec_fracBuild) )
      spec_height   (n)  = stringtodouble( split_lines(n,k_spec_height   ) )
      spec_hwratio  (n)  = stringtodouble( split_lines(n,k_spec_hwratio  ) )
      spec_fracPerv (n)  = stringtodouble( split_lines(n,k_spec_fracPerv ) )
      spec_fracRoof (n)  = stringtodouble( split_lines(n,k_spec_fracRoof ) )
      spec_typeWall (n)  = str_strip     ( split_lines(n,k_spec_typeWall ) )
      spec_typeWind (n)  = str_strip     ( split_lines(n,k_spec_typeWind ) )
      spec_fracWind (n)  = stringtodouble( split_lines(n,k_spec_fracWind ) )
      spec_typeRoof (n)  = str_strip     ( split_lines(n,k_spec_typeRoof ) )
      spec_typeRoad (n)  = str_strip     ( split_lines(n,k_spec_typeRoad ) )
      spec_Tmin     (n)  = stringtodouble( split_lines(n,k_spec_Tmin     ) )
      spec_Tmax     (n)  = stringtodouble( split_lines(n,k_spec_Tmax     ) )
      spec_notes    (n)  = str_strip     ( split_lines(n,k_spec_notes    ) )
   end do

   if (dbug .gt. 0) then
       print("  <debug> echo spec input A")
   do n=0,nSpec - 1
      print(n + " " + spec_shortName(n) + " " + spec_fracBuild(n) )
   end do
      ;--- echo input to verify it's correct ---
      alist = [/ spec_shortName , spec_fracBuild , spec_height    , spec_hwratio   , spec_fracPerv  , spec_fracRoof  , \
                 spec_typeWall  , spec_typeWind  , spec_fracWind  , spec_typeRoof  , spec_typeRoad  , spec_Tmin      , \
                 spec_Tmax      , spec_notes     /]
      write_table(fn_dbug,"a",alist,"%-15s ,%3.2f ,%3.0f   ,%5.3f ,%5.3f, %5.3f, %-30s,%-11s, %4.3f  ,%-25s,%-24s,%3.0f,%3.0f, %-20s")
      a = (/"shortName"/)
      b = (/"frac build"/)
      c = (/"ht"/)
      d = (/"h:w"/)
      e = (/"f perv"/)
      f = (/"f roof"/)
      g = (/"type wall"/)
      h = (/"type wind"/)
      i = (/"f wind"/)
      j = (/"type roof"/)
      k = (/"type road"/)
      l = (/"Tmn"/)
      m = (/"Tmx"/)
      p = (/"Notes"/)
      delete(alist)
      print("  <debug> echo spec input B")
      alist = [/ a, b, c, d, e, f, g, h, i, j, k, l, m, p /]
      write_table(fn_dbug,"a",alist,"%-20s,%3s  , %s   , %s   , %s   , %-30s, %-20s, %s   %-30s,%s   , %s   ,%s   ,%s   , %-30s")
      delete(alist)

      delete(i) ; need to use as integer index ?
      delete(j) ; need to use as integer index ?
      delete(k) ; need to use as integer index ?
   end if

print("------------------------------------------------------------------------")
print(" compute city properties")
print("------------------------------------------------------------------------")

   city_shortName   = new( (/nSpec/),"string")
   city_fracBuild   = new( (/nSpec/),"double")
   city_height      = new( (/nSpec/),"double")
   city_hwratio     = new( (/nSpec/),"double")
   city_fracPerv    = new( (/nSpec/),"double")
   city_fracRoof    = new( (/nSpec/),"double")
   city_wall_albedo = new( (/nSpec/),"double")
   city_wall_emmiss = new( (/nSpec/),"double")
   city_wall_thick  = new( (/nSpec/),"double")
   city_wall_tk     = new( (/nSpec,maxLayers/),"double")
   city_wall_cv     = new( (/nSpec,maxLayers/),"double")
   city_roof_albedo = new( (/nSpec/),"double")
   city_roof_emmiss = new( (/nSpec/),"double")
   city_roof_thick  = new( (/nSpec/),"double")
   city_roof_tk     = new( (/nSpec,maxLayers/),"double")
   city_roof_cv     = new( (/nSpec,maxLayers/),"double")
   city_road_albedo = new( (/nSpec/),"double")
   city_road_emmiss = new( (/nSpec/),"double")
   city_road_thick  = new( (/nSpec/),"double")
   city_road_tk     = new( (/nSpec,maxLayers/),"double")
   city_road_cv     = new( (/nSpec,maxLayers/),"double")
   city_wall_tmin   = new( (/nSpec/),"double")
   city_wall_tmax   = new( (/nSpec/),"double")
   city_notes       = new( (/nSpec/),"string")

   spval = -999
   city_shortName   = "unset"
   city_fracBuild   = spval
   city_height      = spval
   city_hwratio     = spval
   city_fracPerv    = spval
   city_fracRoof    = spval
   city_wall_albedo = spval
   city_wall_emmiss = spval
   city_wall_thick  = spval
   city_wall_tk     = spval
   city_wall_cv     = spval
   city_roof_albedo = spval
   city_roof_emmiss = spval
   city_roof_thick  = spval
   city_roof_tk     = spval
   city_roof_cv     = spval
   city_road_albedo = spval
   city_road_emmiss = spval
   city_road_thick  = spval
   city_road_tk     = spval
   city_road_cv     = spval
   city_wall_tmin   = spval
   city_wall_tmax   = spval
   city_notes       = "notes "

   do n=0,nSpec - 1
      print("Working on: " + spec_shortName(n))
      city_shortName(n) = spec_shortName(n)  
      city_height   (n) = spec_height   (n)  
      city_hwratio  (n) = spec_hwratio  (n)  
      city_fracBuild(n) = spec_fracBuild(n)  
      city_fracPerv (n) = spec_fracPerv (n)/(1.0-spec_fracRoof(n))
      city_fracRoof (n) = spec_fracRoof (n)  
      city_wall_tmin(n) = spec_Tmin     (n)  + 273.1d  ; convert to Kelvin
      city_wall_tmax(n) = spec_Tmax     (n)  + 273.1d  ; convert to Kelvin

      ;--- wall properties ---
      str = spec_typeWall(n)
      j  = min ( str_match_ind(surf_shortName(:),str)) ; material's index
      if ( ismissing(j)) then
        print("ERROR: no match for surface =" + str)
      end if
      j2 = max ( str_match_ind(surf_shortName(:),str)) ; material's index
      if (j .ne. j2) then
        print("ERROR: multiple matches for surface =" + str)
      end if

      ;--- window properties ---
      str = spec_typeWind(n)
      k  = min ( str_match_ind(surf_shortName(:),str)) ; material's index
      if ( ismissing(k)) then
        print("ERROR: no match for window =" + str)
      end if
      k2 = max ( str_match_ind(surf_shortName(:),str)) ; material's index
      if (k .ne. k2) then
        print("ERROR: multiple matches for window =" + str)
      end if

   ;  ;####### OLD ########
   ;  city_wall_albedo(n) = surf_albedo(j)
   ;  city_wall_emmiss(n) = surf_emmiss(j)
   ;  city_wall_thick (n) = surf_thick (j)
   ;  city_wall_tk    (n,:) = surf_tk  (j,:)
   ;  city_wall_cv    (n,:) = surf_cv  (j,:)

   ;  !####### NEW ########
      frac2 = spec_fracWind(n)
      frac1 = 1.0 - frac2
      thick1 = surf_thick(j)
      thick2 = surf_thick(k)
      thick  = frac1*thick1 + frac2*thick2

      city_wall_tk    (n,:) = (frac1*surf_tk    (j,:)/thick1 + frac2*surf_tk    (k,:)/thick2)*thick
      city_wall_cv    (n,:) = (frac1*surf_cv    (j,:)*thick1 + frac2*surf_cv    (k,:)*thick2)/thick
      city_wall_albedo(n)   =  frac1*surf_albedo(j)          + frac2*surf_albedo(k)
      city_wall_emmiss(n)   =  frac1*surf_emmiss(j)          + frac2*surf_emmiss(k)
      city_wall_thick (n)   =  thick

      if (frac1.lt.0.0 .or. frac1.gt.1.0) then
        print("ERROR: frac1 ")
      end if
      if (frac2.lt.0.0 .or. frac2.gt.1.0) then
        print("ERROR: frac1 ")
      end if
      if (thick1.le.0.0 .or. thick2.le.0.0) then
        print("ERROR: thickness ")
      end if
   ;  !####################

      ;--- roof properties ---
      str = spec_typeRoof(n)
      j  = min ( str_match_ind(surf_shortName(:),str)) ; material's index
      if ( ismissing(j)) then
        print("ERROR: no match for surface =" + str)
      end if
      j2 = max ( str_match_ind(surf_shortName(:),str)) ; material's index
      if (j .ne. j2) then
        print("ERROR: multiple matches for surface =" + str)
      end if
      city_roof_albedo(n) = surf_albedo(j)
      city_roof_emmiss(n) = surf_emmiss(j)
      city_roof_thick (n) = surf_thick (j)
      city_roof_tk    (n,:) = surf_tk  (j,:)
      city_roof_cv    (n,:) = surf_cv  (j,:)
      ;--- road properties ---
      str = spec_typeRoad(n)
      j  = min ( str_match_ind(surf_shortName(:),str)) ; material's index
      if ( ismissing(j)) then
        print("ERROR: no match for surface =" + str)
      end if
      j2 = max ( str_match_ind(surf_shortName(:),str)) ; material's index
      if (j .ne. j2) then
        print("ERROR: multiple matches for surface =" + str)
      end if
      city_road_albedo(n) = surf_albedo(j)
      city_road_emmiss(n) = surf_emmiss(j)
      city_road_thick (n) = surf_thick (j)
      city_road_tk    (n,:) = surf_tk    (j,:)
      city_road_cv    (n,:) = surf_cv    (j,:)

   end do

print("------------------------------------------------------------------------")
print(" output city properties")
print("------------------------------------------------------------------------")

   if (isfilepresent(fn_out)) then
      system("/bin/rm -f " + fn_out)
   end if

   do n=0,nSpec - 1
      alist = [/ city_shortName(n) , " prop" , city_fracBuild(n) , city_height(n) , city_hwratio(n) , city_fracPerv(n) , city_fracRoof(n) , city_wall_tmin(n), city_wall_tmax(n) , city_notes(n) /]
      write_table(fn_out,"a",alist, "%-15s,%-5s, %8.5f,%9.5f,%13.8f,   %8.6f, %10.6f, %10.6f, %10.6f, %s")
      delete(alist)
      alist = [/ city_shortName(n) , " wall"       , city_wall_albedo(n) ,city_wall_emmiss(n), city_wall_thick(n)                \
               ,city_wall_tk(n,0), city_wall_tk(n,1), city_wall_tk(n,2)  ,city_wall_tk(n,3), city_wall_tk(n,4), city_wall_tk(n,5)  ,city_wall_tk(n,6), city_wall_tk(n,7), city_wall_tk(n,8)  ,city_wall_tk(n,9) \
               ,city_wall_cv(n,0), city_wall_cv(n,1), city_wall_cv(n,2)  ,city_wall_cv(n,3), city_wall_cv(n,4), city_wall_cv(n,5)  ,city_wall_cv(n,6), city_wall_cv(n,7), city_wall_cv(n,8)  ,city_wall_cv(n,9) \
               /]
      write_table(fn_out,"a",alist,"%-15s,%-5s,%9.5f,%9.5f,%13.8f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f")
      alist = [/ city_shortName(n) , " roof"       , city_roof_albedo(n) ,city_roof_emmiss(n), city_roof_thick(n)                \
               ,city_roof_tk(n,0), city_roof_tk(n,1), city_roof_tk(n,2)  ,city_roof_tk(n,3), city_roof_tk(n,4), city_roof_tk(n,5)  ,city_roof_tk(n,6), city_roof_tk(n,7), city_roof_tk(n,8)  ,city_roof_tk(n,9) \
               ,city_roof_cv(n,0), city_roof_cv(n,1), city_roof_cv(n,2)  ,city_roof_cv(n,3), city_roof_cv(n,4), city_roof_cv(n,5)  ,city_roof_cv(n,6), city_roof_cv(n,7), city_roof_cv(n,8)  ,city_roof_cv(n,9) \
               /]
      write_table(fn_out,"a",alist,"%-15s,%-5s,%9.5f,%9.5f,%13.8f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f")
      alist = [/ city_shortName(n) , " road"       , city_road_albedo(n) ,city_road_emmiss(n), city_road_thick(n)                \
               ,city_road_tk(n,0), city_road_tk(n,1), city_road_tk(n,2)  ,city_road_tk(n,3), city_road_tk(n,4), city_road_tk(n,5)  ,city_road_tk(n,6), city_road_tk(n,7), city_road_tk(n,8)  ,city_road_tk(n,9) \
               ,city_road_cv(n,0), city_road_cv(n,1), city_road_cv(n,2)  ,city_road_cv(n,3), city_road_cv(n,4), city_road_cv(n,5)  ,city_road_cv(n,6), city_road_cv(n,7), city_road_cv(n,8)  ,city_road_cv(n,9) \
               /]
      write_table(fn_out,"a",alist,"%-15s,%-5s,%9.5f,%9.5f,%13.8f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f")
      delete(alist)
   end do

   ;----- mark End Of Data -----
   alist = [/ "EOF" /]
   write_table(fn_out,"a",alist, "%-20s")
   delete(alist)

   ;----- data key -----
   alist = [/"city ID        , prop,    f_bld,        h,          h:w,      f_prv,       f_rf,       Tmin,       Tmax,      notes"/]
   write_table(fn_out,"a",alist, "%-50s")
   delete(alist)

   alist = [/ "city ID        , surf,   albedo,   emmiss,        thick,        tk1,        tk2,        tk3,        tk4,        tk5,        tk6,        tk7,        tk8,        tk9,       tk10,       cv1,       cv2,       cv3,       cv4,       cv5,       cv6,       cv7,       cv8,       cv9,      cv10 " /]

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

   alist = [/ "Input file: " + fn_in_surf /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "Input file: " + fn_in_spec /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "Ouput file: " + fn_out /]
   write_table(fn_out,"a",alist,"%-50s")

end

