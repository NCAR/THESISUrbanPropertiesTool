;===============================================================================
; SVN $Id: gen_lam.ncl 176 2017-02-18 00:57:00Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_lam.ncl $
;===============================================================================
; convert properties from csv to a netcdf file
;===============================================================================

begin

   dbug = 0  ; debug level: 0 => no debug output

;-------------------------------------------------------------------------------
; svn keywords to document output data
;-------------------------------------------------------------------------------
   sys_date = systemfunc("date")
   sys_user = systemfunc("whoami")
   svn_id  = "SVN $Id: gen_lam.ncl 176 2017-02-18 00:57:00Z kauff $"
   svn_url = "SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_lam.ncl $"

;-------------------------------------------------------------------------------
; set input & output file names -- set these via ncl command line, eg.
; ncl fn_in_mat=\"mat_prop.csv\" fn_in_lam=\"surf_spec_fw.csv\"  fn_out=\"lam_prop.csv\"  gen_lam.ncl
;-------------------------------------------------------------------------------
;  fn_in_mat = "mat_prop.csv"
;  fn_in_lam = "lam_spec.csv"
;  fn_out    = "lam_prop.csv"

   print("file name fn_in_mat = " + fn_in_mat )
   print("file name fn_in_lam = " + fn_in_lam )
   print("file name fn_out    = " + fn_out    )

print("------------------------------------------------------------------------")
print(" input material properties data")
print("------------------------------------------------------------------------")

   ;---Read in file as array of strings so we can parse each line
   lines = asciiread(fn_in_mat,-1,"string")
   split_lines = str_split_csv(lines,",",0)

   nLines  = dimsizes(split_lines(:,0))
   nfields = dimsizes(split_lines(0,:))

   nMats = min ( str_match_ind(lines(:),"EOF") )
   print("file " + fn_in_mat + " : nLines  =             " + nLines )
   print("file " + fn_in_mat + " : nfields =             " + nfields)
   print("file " + fn_in_mat + " : number of materials = " + nMats  )

   spval = 1.0000e32
   mat_shortName    = new( (/nMats/),"string")
   mat_therm_cond   = new( (/nMats/),"double")
   mat_density      = new( (/nMats/),"double")
   mat_spec_heat    = new( (/nMats/),"double")
   mat_vol_heat_cap = new( (/nMats/),"double")
   mat_emmiss       = new( (/nMats/),"double")
   mat_albedo       = new( (/nMats/),"double")
   mat_src_therm    = new( (/nMats/),"string")
   mat_src_albedo   = new( (/nMats/),"string")
   mat_src_emmiss   = new( (/nMats/),"string")
   k_mat_shortName    = 0
   k_mat_therm_cond   = 1
   k_mat_density      = 2
   k_mat_spec_heat    = 3
   k_mat_vol_heat_cap = 4
   k_mat_emmiss       = 5
   k_mat_albedo       = 6
   k_mat_src_therm    = 7
   k_mat_src_emmiss   = 8
   k_mat_src_albedo   = 9 

   do n=0,nMats-1
      mat_shortName    (n) =                split_lines(n,k_mat_shortName     )  
      mat_therm_cond   (n) = stringtodouble( split_lines(n,k_mat_therm_cond    ) )
      mat_density      (n) = stringtodouble( split_lines(n,k_mat_density       ) )
      mat_spec_heat    (n) = stringtodouble( split_lines(n,k_mat_spec_heat     ) )
      mat_vol_heat_cap (n) = stringtodouble( split_lines(n,k_mat_vol_heat_cap  ) )
      mat_emmiss       (n) = stringtodouble( split_lines(n,k_mat_emmiss        ) )
      mat_albedo       (n) = stringtodouble( split_lines(n,k_mat_albedo        ) )
      mat_src_therm    (n) =                split_lines(n,k_mat_src_therm)    
      mat_src_albedo   (n) =                split_lines(n,k_mat_src_albedo)
      mat_src_emmiss   (n) =                split_lines(n,k_mat_src_emmiss)   
   end do

print("------------------------------------------------------------------------")
print(" input laminant specification data")
print("------------------------------------------------------------------------")

   ;--- Read in whole csv/text file, excluding everything after "EOF" ---
   delete(lines)
   temp_lines = asciiread(fn_in_lam,-1,"string")
   nLines = min ( str_match_ind(temp_lines(:),"EOF") )
   lines = temp_lines(0:nLines-1) ; exclude lines after EOF
   print("file " + fn_in_lam + " : number of input lines = " + nLines )

   ;--- determine how many laminates are indicated by the input data ---
   nLams = dimsizes( str_match(lines(0:nLines-1),"short_name") )
   print("file " + fn_in_lam + " : number of laminates   = " + nLams )

   ;--- form 2d array of input data --- 
   delete(split_lines)
   split_lines = str_split_csv(lines(:),",",0)
;  maxLayers    = dimsizes(split_lines(0,:)) - 1  ; why are there problems with this?
   maxLayers    = 10
   print("file " + fn_in_lam + " : max number of layers  = " + maxLayers )

   spec_shortName  = new( (/nLams/)          ,"string")
   spec_kLayers    = new( (/nLams/)          ,"integer")
   spec_mThickness = new( (/nLams/)          ,"double")
   spec_bThickness = new( (/nLams/)          ,"double")
   spec_material   = new( (/nLams,maxLayers/),"string")
   spec_bmaterial  = new( (/nLams,maxLayers/),"string")
   spec_bfraction  = new( (/nLams/)          ,"double")
   spec_fmaterial  = new( (/nLams/)          ,"string")

   spec_shortName  = "unset"
   spec_kLayers    = -999
   spec_mThickness  = -999
   spec_bThickness  = -999
   spec_material   = "unset"
   spec_bmaterial  = "unset"
   spec_bfraction  = -999
   spec_fmaterial  = "unset"

   ;--- short name ---
   delete(temp_lines)
   delete(split_lines)
   temp_lines    = str_match(lines(:),"short_name")
   split_lines   = str_split_csv(temp_lines,",",0)
   spec_shortName = str_strip (split_lines(:,1))

   ;--- main layer thickness ---
   delete(temp_lines)
   delete(split_lines)
   temp_lines    = str_match(lines(:),"main_thickness")
   split_lines   = str_split_csv(temp_lines,",",0)
   spec_mThickness(:) = stringtodouble( split_lines(:,1))

   ;--- bridge layer thickness ---
   delete(temp_lines)
   delete(split_lines)
   temp_lines    = str_match(lines(:),"bridge_thickness")
   split_lines   = str_split_csv(temp_lines,",",0)
   spec_bThickness(:) = stringtodouble( split_lines(:,1))

   ;--- main material ---
   delete(temp_lines)
   delete(split_lines)
   temp_lines    = str_match(lines(:),"main_material")
   split_lines   = str_split_csv(temp_lines,",",0)
   spec_material(:,:) =  split_lines(:,1:)

   ;--- bridge material ---
   delete(temp_lines)
   delete(split_lines)
   temp_lines    = str_match(lines(:),"bridge_material")
   split_lines   = str_split_csv(temp_lines,",",0)
   spec_bmaterial(:,:) =  split_lines(:,1:)

   ;--- bridge fraction ---
   delete(temp_lines)
   delete(split_lines)
   temp_lines    = str_match(lines(:),"bridge_fraction")
   split_lines   = str_split_csv(temp_lines,",",0)
   spec_bfraction(:) = stringtodouble( split_lines(:,1))
 
;  hard-code/assume all laminants have the same number of layers
   do n=0,nLams-1
;  spec_kLayers(n) = maxLayers
   do k=0,maxLayers-1
       if (.not. ismissing(spec_material(n,k))) then
         spec_kLayers(n) = k + 1
      end if
   end do
   end do

   if (dbug .gt. 0) then
      do n=0,nLams-1
         print("short name  = " + spec_shortName (n)  )
         kLayers = spec_kLayers(n)
         print("n layers    = " + kLayers)
       ; temp= tostring(spec_mThickness(n,0:kLayers-1))
         temp= tostring(spec_mThickness(n))
         temp= temp + "  "
         print("thickness   = " + str_concat(temp))
         delete(temp)
         print("material    = " + str_concat(spec_material (n,0:kLayers-1)))
         print("b material  = " + str_concat(spec_bmaterial(n,0:kLayers-1)))
         print("b fraction  = " + spec_bfraction (n)  )
      end do
   end if

print("------------------------------------------------------------------------")
print(" compute laminate properties")
print("------------------------------------------------------------------------")

   spval = 1.0000e32
   lam_shortName    = new( (/nLams+1/),"string")
   lam_therm_cond   = new( (/nLams,maxLayers/),"double")
   lam_spec_heat    = new( (/nLams,maxLayers/),"double")
   lam_albedo       = new( (/nLams/),"double")
   lam_emmiss       = new( (/nLams/),"double")
   lam_thick        = new( (/nLams/),"float")

   lam_shortName (0:nLams-1) = spec_shortName(:)
   lam_shortName(nLams) = "EOF"
   lam_therm_cond(:,:) = -11
   lam_spec_heat (:,:) = -22
   lam_albedo    (:) = -33
   lam_emmiss    (:) = -44
   lam_thick     (:) = -55

   do n=0,nLams-1
      ;--- local vars without "n" dimension ---
      lName   = str_strip(spec_shortName(n))
      print("working on " + lName)
      kLayers = spec_kLayers(n)
      mat     = spec_material (n,0:kLayers-1)
      bmat    = spec_bmaterial(n,0:kLayers-1)
      mThick  = spec_mThickness(n)
      bThick  = spec_bThickness(n)
      bFrac   = spec_bfraction(n)

      mFrac = 1.0-bFrac

      ;--- special case: thickness = -999 ---
      if (mThick .gt. 0.0 .and. bThick .gt. 0.0) then
         lThick = (mFrac*mThick + bFrac*bThick)  ; combine material & bridge thickness
      else
         if (mThick .ge. 0.0 .or. bThick .ge. 0.0) then
            print("ERROR: incompatible main_thickness & bridge_thickness ")
         end if
         lThick = mThick  
         mThick = 1.0
         bThick = 1.0
      end if
;     print("DEBUG: mThick, bThick, lThick" + mThick + bThick + lThick)
         
      ;--- initialize main & bridge material properties ---
      mtk = 0.0d0  ; main   tk
      btk = 0.0d0  ; bridge tk

      mcv = 0.0d0
      bcv = 0.0d0

      malb = -1.0d0
      balb = 0.0d0

      memm = 0.0d0
      bemm = 0.0d0

      do k=0,kLayers-1
         ;--- main material ----
         str = str_strip(mat(k))                        ; specified material 
         j = min ( str_match_ind(mat_shortName(:),str)) ; index of this material
         j2 = max( str_match_ind(mat_shortName(:),str)) ; index of this material
         if (j .ne. j2) then
            print("WARNING: multiple matches for " + str  )
         end if
         mtk = mat_therm_cond(j)
         mcv = mat_vol_heat_cap(j)
         if (k .eq. 0) then 
            malb = mat_albedo(j)
            memm = mat_emmiss(j)
         end if

         ;--- bridge material ----
         str = str_strip(bmat(k))                       ; specified material 
         j = min ( str_match_ind(mat_shortName(:),str)) ; index of this material
         j2 = max( str_match_ind(mat_shortName(:),str)) ; index of this material
         if (j .ne. j2) then
            print("WARNING: multiple matches for " + str  )
         end if
         btk = mat_therm_cond(j)
         bcv = mat_vol_heat_cap(j)
         if (k .eq. 0) then  
            balb = mat_albedo(j)
            bemm = mat_emmiss(j)
         end if

         ;----- combine properties of main, bridge materials -----
         if (mThick .eq. bThick ) then  
            tk    = (mFrac*mtk        + bFrac*btk       )        ; combine material & bridge tk
            cv    = (mFrac*mcv        + bFrac*bcv       )        ; combine material & bridge cv
         else
            tk    = (mFrac*mtk/mThick + bFrac*btk/bThick)*lThick ; combine material & bridge tk
            cv    = (mFrac*mcv*mThick + bFrac*bcv*bThick)/lThick ; combine material & bridge cv
         end if
         lam_therm_cond(n,k) = tk
         lam_spec_heat (n,k) = cv
      end do
      do k=kLayers,maxLayers-1
         lam_therm_cond(n,k) = -999.0
         lam_spec_heat (n,k) = -999.0
      end do

      ;----- combine properties of main, bridge materials -----
      albedo = (1.0-bFrac)*malb + bFrac*balb   ; combine material & bridge albedo
      emmiss = (1.0-bFrac)*memm + bFrac*bemm   ; combine material & bridge emmsivity

      ;----- add properties for this particular laminant to array of all laminant properties ---
      lam_emmiss    (n) = emmiss
      lam_thick     (n) = tofloat(lThick)
      lam_albedo    (n) = albedo
      ;--------------
      delete(mat  )
      delete(bmat )
   end do

print("------------------------------------------------------------------------")
print(" output laminate properties")
print("------------------------------------------------------------------------")

   if (isfilepresent(fn_out)) then
      system("/bin/rm -f " + fn_out)
   end if

   alist = [/lam_shortName, lam_albedo ,lam_emmiss, lam_thick                \
            ,lam_therm_cond(:,0), lam_therm_cond(:,1), lam_therm_cond(:,2)  ,lam_therm_cond(:,3), lam_therm_cond(:,4), lam_therm_cond(:,5)  ,lam_therm_cond(:,6), lam_therm_cond(:,7), lam_therm_cond(:,8)  ,lam_therm_cond(:,9) \
            ,lam_spec_heat (:,0), lam_spec_heat (:,1), lam_spec_heat (:,2)  ,lam_spec_heat (:,3), lam_spec_heat (:,4), lam_spec_heat (:,5)  ,lam_spec_heat (:,6), lam_spec_heat (:,7), lam_spec_heat (:,8)  ,lam_spec_heat (:,9) \
            /]
   write_table(fn_out,"w",alist,"%-29s,%9.6f,%8.5f,%13.8f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%11.6f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f,%10.1f")

   delete(alist)
   alist = [/ "laminant                     ,   albedo,  emmiss,        thick,        tk1,        tk2,        tk3,        tk4,        tk5,        tk6,        tk7,        tk8,        tk9,       tk10,       cv1,       cv2,       cv3,       cv4,       cv5,       cv6,       cv7,       cv8,       cv9,      cv10 " /]
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

   alist = [/ "Input file: " + fn_in_mat  /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "Input file: " + fn_in_lam  /]
   write_table(fn_out,"a",alist,"%-50s")
   alist = [/ "Ouput file: " + fn_out /]
   write_table(fn_out,"a",alist,"%-50s")
end
