;===============================================================================
; SVN $Id: gen_data_1km.ncl 211 2017-11-16 22:59:53Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/gen_data_1km.ncl $
;===============================================================================
; NCL script
; generate_netcdf_1km_urbanparam_file.ncl
; This program takes Brian Kauffman's urban properties tool output for Johan's 10-layer
; version of the urban dataset and converts it to netcdf. Then takes it and urban density at 
; 1km resolution and creates a netcdf file at 1km resolution with parameters for the TBD, 
; HD, and MD density types.
; Keith Oleson, Aug 2016
;**************************************

load "./keyword_values.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"

;----------------------------------------------------------------------
; FUNCTIONS FROM DENNIS SHEA
;----------------------------------------------------------------------
;----------------------------------------------------------------------
; This function returns the index locations of the given delimiter
; in a row or several rows of strings.
;----------------------------------------------------------------------
function delim_indices(strings,nfields,delimiter)
local cstrings, cdelim
begin
  nrows = dimsizes(strings)
;
; Handle special case if we only have one string. Make sure it
; is put into a 2D array.
;
  if(nrows.eq.1) then
    cstrings = new((/1,strlen(strings)+1/),character)
  end if

  cstrings = stringtochar(strings)        ; Convert to characters.
  cdelim   = stringtochar(delimiter)      ; Convert delimiter to character.
;
; Som error checking here. Make sure delimiter is one character.
;
  nc   = dimsizes(cdelim)
  rank = dimsizes(nc)
  if(rank.ne.1.or.(rank.eq.1.and.nc.ne.2)) then
    print("delim_indices: fatal: the delimiter you've selected")
    print("must be a single character. Can't continue.")
    exit
  end if

;
; Create array to hold indices of delimiter locations, and then loop
; through each row and find all the delimiters. Make sure each row has
; the correct number of delimiters.
;
  ndelims  = nfields-1
  cindices = new((/nrows,ndelims/),integer)
  do i = 0, nrows-1
    ii = ind(cstrings(i,:).eq.cdelim(0))
;
; Make sure there were delimiters on this row. If not, we just quit.
; This could probably be modified to do this more gracefully.
;
    if(any(ismissing(ii))) then
      print("delim_indices: fatal: I didn't find any delimiters")
      print("('" + delimiter + "') on row " + i + ". Can't continue.")
      exit
    end if
    if(dimsizes(ii).ne.ndelims) then
      print("delim_indices: fatal: I expected to find " + ndelims)
      print("delimiters on row " + i + ". Instead, I found " + dimsizes(ii) + ".")
      print("Can't continue.")
      exit
    end if

    cindices(i,:) = ii

    delete(ii)            ; For next time through loop
  end do

  return(cindices)
end

;----------------------------------------------------------------------
; This function reads in a particular field from a string array,
; given the field number to read (fields start at #1 and go to #nfield),
; and the indices of the delimiters.
;
; It returns either an integer, float, double, character, or a string,
; depending on the input flag "return_type".
;----------------------------------------------------------------------
function read_field(strings,ifield,indices,return_type)
local nstring, cstrings, nf, tmp_str
begin
  nrows = dimsizes(strings)
;
; Handle special case if we only have one string. Make sure it
; is put into a 2D array.
;
  if(nrows.eq.1) then
    cstrings = new((/1,strlen(strings)+1/),character)
  end if

  cstrings = stringtochar(strings)
  nf       = dimsizes(indices(0,:))+1     ; indices is nrows x (nfields-1)

;
; Error checking. Make sure user has entered a valid field.
;
  if(ifield.le.0.or.ifield.gt.nf) then
    print("read_field: fatal: you've selected a field that is")
    print("out-of-range of the number of fields that you have (" + nf + ").")
    exit
  end if

;
; Set up array to return. For string, int, float, or double arrays,
; we don't have to do anything special. For character arrays,
; however, we do.
;
  if(return_type.ne."character") then
    return_array = new(nrows,return_type)
  else
;
; We don't know what the biggest character array is at this point, so
; make it bigger than necessary, and then resize later as necessary.
;
    tmp_return_array = new((/nrows,dimsizes(cstrings(0,:))/),"character")

    max_len = 0     ; Use to keep track of max lengths of strings.
  end if

  do i = 0,nrows-1
;
; Special case of first field in row.
;
    if(ifield.eq.1) then
      ibeg = 0
      iend = indices(i,ifield-1)-1
    else
;
; Special case of first field in row.
;
      if(ifield.eq.nf) then
        ibeg = indices(i,ifield-2)+1
        iend = dimsizes(cstrings(i,:))-1
;
; Any field between first and last field.
;
      else
        ibeg = indices(i,ifield-2)+1
        iend = indices(i,ifield-1)-1
      end if
    end if
;
; Here's the code that pulls off the correct string, and converts it
; to float if desired.
;
    if(return_type.eq."integer") then
      return_array(i) = stringtointeger(chartostring(cstrings(i,ibeg:iend)))
    end if
    if(return_type.eq."float") then
      return_array(i) = stringtofloat(chartostring(cstrings(i,ibeg:iend)))
    end if
    if(return_type.eq."double") then
      return_array(i) = stringtodouble(chartostring(cstrings(i,ibeg:iend)))
    end if
    if(return_type.eq."string") then
      return_array(i) = chartostring(cstrings(i,ibeg:iend))
    end if
    if(return_type.eq."character") then
      if( (iend-ibeg+1) .gt. max_len) then
        max_len = iend-ibeg+1
      end if
      tmp_return_array(i,0:iend-ibeg) = cstrings(i,ibeg:iend)
    end if
  end do

  if(return_type.eq."character") then
    return_array = new((/nrows,max_len/),"character")
    return_array = tmp_return_array(:,0:max_len-1)
  end if

  return(return_array)
end

;----------------------------------------------------------------------
; This function reads in string fields only to get the maximum string
; length.
;----------------------------------------------------------------------
function get_maxlen(strings,ifield,indices)
local nstring, cstrings, nf, tmp_str
begin
  nrows = dimsizes(strings)
;
; Handle special case if we only have one string. Make sure it
; is put into a 2D array.
;
  if(nrows.eq.1) then
    cstrings = new((/1,strlen(strings)+1/),character)
  end if

  cstrings = stringtochar(strings)
  nf       = dimsizes(indices(0,:))+1     ; indices is nrows x (nfields-1)

;
; Error checking. Make sure user has entered a valid field.
;
  if(ifield.le.0.or.ifield.gt.nf) then
    print("read_field: fatal: you've selected a field that is")
    print("out-of-range of the number of fields that you have (" + nf + ").")
    exit
  end if
;
; We don't know what the biggest character array is at this point, so
; make it bigger than necessary, and then resize later as necessary.
;
  tmp_return_array = new((/nrows,dimsizes(cstrings(0,:))/),"character")

  max_len = 0     ; Use to keep track of max lengths of strings.

  do i = 0,nrows-1
;
; Special case of first field in row.
;
    if(ifield.eq.1) then
      ibeg = 0
      iend = indices(i,ifield-1)-1
    else
;
; Special case of first field in row.
;
      if(ifield.eq.nf) then
        ibeg = indices(i,ifield-2)+1
        iend = dimsizes(cstrings(i,:))-1
;
; Any field between first and last field.
;
      else
        ibeg = indices(i,ifield-2)+1
        iend = indices(i,ifield-1)-1
      end if
    end if
    if( (iend-ibeg+1) .gt. max_len) then
      max_len = iend-ibeg+1
    end if
  end do

  return(max_len)
end

;===============================================================================
; MAIN CODE
;===============================================================================

begin
   subName = "(gen_1km_data: main) "

;  LID = systemfunc("date +%y%m%d-%H%M%S")   ; get Log ID from command line
   print(subName+"Log ID = " + LID)
   creation_info = systemfunc("whoami")+" "+systemfunc ("date")

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Input namelist variables")
;rint(subName+                    " Input namelist variables")
print(subName+"-----------------------------------------------------------------")

;  nml_fn = "./gen_1km_data.nml"  ; get namelist file name from command line
   print(subName+"namelist file = " + nml_fn)

   ;----- non-case-specific input -----
   nml_variable = "input_dir"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   input_dir = temp_str 

   nml_variable = "urban_tbd_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   urban_tbd_fn = temp_str 

   nml_variable = "urban_hd_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   urban_hd_fn = temp_str 

   nml_variable = "urban_md_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   urban_md_fn = temp_str 

   nml_variable = "regions_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   regions_fn = temp_str 

   ;----- case-specific urban properties input -----
   nml_variable = "urban_prop_dir"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   print(subName + nml_variable + "  = " + temp_str)
   urban_prop_dir = temp_str 

   nml_variable = "urban_prop_fn"
   temp_str = keyword_values(nml_fn,nml_variable,"string")
   temp_str  = str_squeeze(temp_str)   ; remove any blank spaces
   temp_str = str_sub_str(temp_str,"LID",LID)
   print(subName + nml_variable + "  = " + temp_str)
   urban_prop_fn = temp_str 

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

   temp_str = urban_prop_fn
;  temp_str = str_sub_str(temp_str,"csv","TEMPWORKF."+LID+".nc")
   temp_str = str_sub_str(temp_str,"csv","TEMPWORK.nc")
   print(subName + "Temporary/work urban properties netCDF file  = " + temp_str)
   scratch_fn = temp_str 
  
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
print(subName+systemfunc("date")+" Create scratch/temporary version of urban properies input")
print(subName+"-----------------------------------------------------------------")

; Set up defaults here.  We are hard-coding the field types here.
; You can set up this script to try to determine the field types
; automatically, but this is a bit tedious. Maybe later.


; There are now four sets of fields for each region and density type (prop, wall, roof, road)
  nfields_prop  = 14                    ; # of fields for prop
  nfields_wall  = 29                    ; # of fields for wall
  nfields_roof  = 29                    ; # of fields for roof
  nfields_road  = 29                    ; # of fields for road
  delimiter = ","                       ; field delimiter
  units_prop = (/" "," "," "," "," "," "," ","m"," ","Fraction","Fraction","K","K"," "/)
  units_wall = (/" "," "," "," "," "," "," "," ","m","W/m*K","W/m*K","W/m*K","W/m*K","W/m*K","W/m*K", \
                 "W/m*K","W/m*K","W/m*K","W/m*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K",   \
                 "J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K"/)
  units_roof = (/" "," "," "," "," "," "," "," ","m","W/m*K","W/m*K","W/m*K","W/m*K","W/m*K","W/m*K", \
                 "W/m*K","W/m*K","W/m*K","W/m*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K",   \
                 "J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K"/)
  units_road = (/" "," "," "," "," "," "," "," ","m","W/m*K","W/m*K","W/m*K","W/m*K","W/m*K","W/m*K", \
                 "W/m*K","W/m*K","W/m*K","W/m*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K",   \
                 "J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K","J/m^3*K"/)

  var_names_prop = (/"Region_ID","Cat_ID","Build_ID","Region","Cat","Type","Build_percent","Ht","H_W","Pervious", \
                     "Roof_Area","Inside_Wall_Min_T","Inside_Wall_Max_T","Notes"/)
  var_names_wall = (/"Region_ID","Cat_ID","Build_ID","Region","Cat","Type","Wall_Albedo","Wall_e","Wall_Layer_Thick", \
                     "Wall_1_tk","Wall_2_tk","Wall_3_tk","Wall_4_tk","Wall_5_tk", \
                     "Wall_6_tk","Wall_7_tk","Wall_8_tk","Wall_9_tk","Wall_10_tk", \
                     "Wall_1_Cv","Wall_2_Cv","Wall_3_Cv","Wall_4_Cv","Wall_5_Cv", \
                     "Wall_6_Cv","Wall_7_Cv","Wall_8_Cv","Wall_9_Cv","Wall_10_Cv"/)
  var_names_roof = (/"Region_ID","Cat_ID","Build_ID","Region","Cat","Type","Roof_Albedo","Roof_e","Roof_Layer_Thick", \
                     "Roof_1_tk","Roof_2_tk","Roof_3_tk","Roof_4_tk","Roof_5_tk", \
                     "Roof_6_tk","Roof_7_tk","Roof_8_tk","Roof_9_tk","Roof_10_tk", \
                     "Roof_1_Cv","Roof_2_Cv","Roof_3_Cv","Roof_4_Cv","Roof_5_Cv", \
                     "Roof_6_Cv","Roof_7_Cv","Roof_8_Cv","Roof_9_Cv","Roof_10_Cv"/)
  var_names_road = (/"Region_ID","Cat_ID","Build_ID","Region","Cat","Type","Road_Albedo","Road_e","Road_Layer_Thick", \
                     "Road_1_tk","Road_2_tk","Road_3_tk","Road_4_tk","Road_5_tk", \
                     "Road_6_tk","Road_7_tk","Road_8_tk","Road_9_tk","Road_10_tk", \
                     "Road_1_Cv","Road_2_Cv","Road_3_Cv","Road_4_Cv","Road_5_Cv", \
                     "Road_6_Cv","Road_7_Cv","Road_8_Cv","Road_9_Cv","Road_10_Cv"/)

  fn = output_dir + scratch_fn
  if(isfilepresent(fn))
    print("Warning: '" + fn + "' exists. Will remove it.")
    system("/bin/rm " + fn)
  end if

  num_regions = 33
  num_dens = 4
;
; Read in data as strings. This will create a string array that has the
; same number of strings as there are rows in the file. We will then need
; to parse each string later.
;
  fn = urban_prop_dir + urban_prop_fn
  print(subName+"read file = " + fn)
  read_data = asciiread(fn,-1,"string")
  nrows = min ( str_match_ind(read_data(:),"EOF") )

  data_prop = new(nrows/4,"string")
  data_wall = new(nrows/4,"string")
  data_roof = new(nrows/4,"string")
  data_road = new(nrows/4,"string")
  st_prop = 0
  st_wall = 1
  st_roof = 2
  st_road = 3
  do n = 0, num_regions*num_dens-1
     data_prop(n) = read_data(st_prop)
     data_wall(n) = read_data(st_wall)
     data_roof(n) = read_data(st_roof)
     data_road(n) = read_data(st_road)
     st_prop = st_prop + 4
     st_wall = st_wall + 4
     st_roof = st_roof + 4
     st_road = st_road + 4
  end do
  print(data_prop)

; prop (Properties other than associated with wall, roof, road)
  nfields = nfields_prop
  var_types      = new(nfields,string)
  var_strlens    = new(nfields,integer)   ; var to hold strlens, just in case.

  var_types      = "float"   
  var_types(0:2) = "integer"
  var_types(3:5) = "character"
  var_types(13)  = "character"

;
; Read in locations of delimiters in each string row.
;
  dindices = delim_indices(data_prop,nfields,delimiter)     ; rest of file

;
; Read in the field names which will become variable names on
; the netCDF file.
;
  var_names = var_names_prop

;



; Write out this netCDF file efficiently so it will be faster.
; Try to predefine everything before you write to it.
;

  fn = output_dir+scratch_fn
  print(subName+"addfile = " + fn)
  f = addfile(fn,"c")
  setfileoption(f,"DefineMode",True)       ; Enter predefine phase.

;
; Write global attributes to file. It's okay to do this before
; predefining the file's variables. We are still in "define" mode.
;
  fAtt               = True
  fAtt@Source        = urban_prop_dir + urban_prop_fn
; fAtt@creation_date = systemfunc ("date")
  fAtt@creation_date = creation_info  
  fileattdef( f, fAtt )

;
; Write dimension names to file. If there are no character variables,
; then there's only one dimension name ("nvalues").
;
; Otherwise, we need to write a dimension name for every character
; variable, which will indicate the maximum string length for that
; variable.
;
  indc = ind(var_types.eq."character")
  if(.not.any(ismissing(indc))) then
;
; We have to treat the character arrays special here. We need to
; know their sizes so we can write the maximum size of each char
; array to the netCDF file as a dimension name. This means we
; need to read in the character variables once to get the string
; lengths, then we'll read them again later to get the actual values.
;
    do i=0,dimsizes(indc)-1
      var_strlens(indc(i)) = get_maxlen(data_prop,indc(i)+1,dindices)
    end do

    ndims    = dimsizes(indc) + 1
    dimNames = new(ndims,string)
    dimSizes = new(ndims,integer)
    dimUnlim = new(ndims,logical)

    dimUnlim            = False
    dimUnlim(0)         = True
    dimNames(0)         = "nvalues"
    dimNames(1:ndims-1) = var_names(indc) + "_StrLen"
    print(dimNames)
    dimSizes(0)         = -1
    dimSizes(1:ndims-1) = var_strlens(indc)
    filedimdef(f,dimNames,dimSizes,dimUnlim)
  else
;
; No character variables, so just write the one dimension name.
;
    filedimdef(f,"nvalues",-1,True)
  end if

;
; Define each variable on the file.
;
; Don't deal with variables that are of type string.
;
  do i=0,nfields-1
    if(var_types(i).ne."string") then
      if(var_types(i).ne."character") then
        filevardef(f, var_names(i), var_types(i), "nvalues")
      else
        filevardef(f, var_names(i), var_types(i),  \
                   (/"nvalues",var_names(i)+"_StrLen"/))
      end if
    end if
  end do

;
; Loop through each field, read the values for that field, print
; information about the variable, and then write it to the netCDF
; file.
;
  do i=0,nfields-1
    ifield = i+1
;
; Note: you can't write strings to a netCDF file, so these have
; to be written out as character arrays.
;
    tmp_data = read_field(data_prop,ifield,dindices,var_types(i))
    tmp_data@units = units_prop(i)
    if (var_types(i) .eq. "float") then
;     print(tmp_data)
      tmp_data@_FillValue = -999.000
;     tmp_data@_FillValue = -999.990
;     indx = ind(ismissing(tmp_data))
;     if (.not.all(ismissing(indx))) then
;       tmp_data(indx) = -999.000
;       tmp_data@_FillValue = -999.000
;     else
;       tmp_data@_FillValue = -999.000
;     end if
;     delete(indx)
    else
      if (var_types(i) .eq. "character") then
        delete(tmp_data@_FillValue)
      end if
    end if
;
; Print some info about the variable.
;
    print("")
    print("Writing variable '" + var_names(i) + "' (field #" + ifield + ").")
    print("Type is " + var_types(i) + ".")
    if(var_types(i).ne."string".and.var_types(i).ne."character") then
      print("min/max = " + min(tmp_data) + "/" + max(tmp_data))
    end if

    if(any(ismissing(tmp_data))) then
      print("This variable does contain missing values.")
    else
      print("This variable doesn't contain missing values.")
    end if

    f->$var_names(i)$ = tmp_data       ; Write to netCDF file.

    delete(tmp_data)                   ; Delete for next round.
  end do

  delete(var_types)
  delete(var_strlens)
  delete(dindices)
  delete(var_names)
  delete(indc)
  delete(dimNames)
  delete(dimSizes)
  delete(dimUnlim)

; wall
  nfields = nfields_wall
  var_types      = new(nfields,string)
  var_strlens    = new(nfields,integer)   ; var to hold strlens, just in case.

  var_types      = "float"       
  var_types(0:2) = "integer"
  var_types(3:5) = "character"

;
; Read in locations of delimiters in each string row.
;
  dindices = delim_indices(data_wall,nfields,delimiter)     ; rest of file

;
; Read in the field names which will become variable names on
; the netCDF file.
;
  var_names = var_names_wall

;
; Write dimension names to file. If there are no character variables,
; then there's only one dimension name ("nvalues").
;
; Otherwise, we need to write a dimension name for every character
; variable, which will indicate the maximum string length for that
; variable.
;
  indc = ind(var_types.eq."character")
  if(.not.any(ismissing(indc))) then
;
; We have to treat the character arrays special here. We need to
; know their sizes so we can write the maximum size of each char
; array to the netCDF file as a dimension name. This means we
; need to read in the character variables once to get the string
; lengths, then we'll read them again later to get the actual values.
;
    do i=0,dimsizes(indc)-1
      var_strlens(indc(i)) = get_maxlen(data_wall,indc(i)+1,dindices)
    end do

    ndims    = dimsizes(indc) + 1
    dimNames = new(ndims,string)
    dimSizes = new(ndims,integer)
    dimUnlim = new(ndims,logical)

    dimUnlim            = False
    dimUnlim(0)         = True
    dimNames(0)         = "nvalues"
    dimNames(1:ndims-1) = var_names(indc) + "_StrLen"
    dimSizes(0)         = -1
    dimSizes(1:ndims-1) = var_strlens(indc)
    filedimdef(f,dimNames,dimSizes,dimUnlim)
  else
;
; No character variables, so just write the one dimension name.
;
    filedimdef(f,"nvalues",-1,True)
  end if

;
; Define each variable on the file.
;
; Don't deal with variables that are of type string.
;
  do i=0,nfields-1
    if(var_types(i).ne."string") then
      if(var_types(i).ne."character") then
        filevardef(f, var_names(i), var_types(i), "nvalues")
      else
        filevardef(f, var_names(i), var_types(i),  \
                   (/"nvalues",var_names(i)+"_StrLen"/))
      end if
    end if
  end do

;
; Loop through each field, read the values for that field, print
; information about the variable, and then write it to the netCDF
; file.
;
  do i=0,nfields-1
    ifield = i+1
;
; Note: you can't write strings to a netCDF file, so these have
; to be written out as character arrays.
;
    tmp_data = read_field(data_wall,ifield,dindices,var_types(i))
    tmp_data@units = units_wall(i)
    if (var_types(i) .eq. "float") then
;     print(tmp_data)
      tmp_data@_FillValue = -999.000
;     tmp_data@_FillValue = -999.990
;     indx = ind(ismissing(tmp_data))
;     if (.not.all(ismissing(indx))) then
;       tmp_data(indx) = -999.000
;       tmp_data@_FillValue = -999.000
;     else
;       tmp_data@_FillValue = -999.000
;     end if
;     delete(indx)
    else
      if (var_types(i) .eq. "character") then
        delete(tmp_data@_FillValue)
      end if
    end if
;
; Print some info about the variable.
;
    print("")
    print("Writing variable '" + var_names(i) + "' (field #" + ifield + ").")
    print("Type is " + var_types(i) + ".")
    if(var_types(i).ne."string".and.var_types(i).ne."character") then
      print("min/max = " + min(tmp_data) + "/" + max(tmp_data))
    end if

    if(any(ismissing(tmp_data))) then
      print("This variable does contain missing values.")
    else
      print("This variable doesn't contain missing values.")
    end if

    f->$var_names(i)$ = tmp_data       ; Write to netCDF file.

    delete(tmp_data)                   ; Delete for next round.
  end do

  delete(var_types)
  delete(var_strlens)
  delete(dindices)
  delete(var_names)
  delete(indc)

; roof
  nfields = nfields_roof
  var_types      = new(nfields,string)
  var_strlens    = new(nfields,integer)   ; var to hold strlens, just in case.

  var_types      = "float"       
  var_types(0:2) = "integer"
  var_types(3:5) = "character"

;
; Read in locations of delimiters in each string row.
;
  dindices = delim_indices(data_roof,nfields,delimiter)     ; rest of file

;
; Read in the field names which will become variable names on
; the netCDF file.
;
  var_names = var_names_roof

;
; Write dimension names to file. If there are no character variables,
; then there's only one dimension name ("nvalues").
;
; Otherwise, we need to write a dimension name for every character
; variable, which will indicate the maximum string length for that
; variable.
;
  indc = ind(var_types.eq."character")
  if(.not.any(ismissing(indc))) then
;
; We have to treat the character arrays special here. We need to
; know their sizes so we can write the maximum size of each char
; array to the netCDF file as a dimension name. This means we
; need to read in the character variables once to get the string
; lengths, then we'll read them again later to get the actual values.
;
    do i=0,dimsizes(indc)-1
      var_strlens(indc(i)) = get_maxlen(data_roof,indc(i)+1,dindices)
    end do

    ndims    = dimsizes(indc) + 1
    dimNames = new(ndims,string)
    dimSizes = new(ndims,integer)
    dimUnlim = new(ndims,logical)

    dimUnlim            = False
    dimUnlim(0)         = True
    dimNames(0)         = "nvalues"
    dimNames(1:ndims-1) = var_names(indc) + "_StrLen"
    dimSizes(0)         = -1
    dimSizes(1:ndims-1) = var_strlens(indc)
    filedimdef(f,dimNames,dimSizes,dimUnlim)
  else
;
; No character variables, so just write the one dimension name.
;
    filedimdef(f,"nvalues",-1,True)
  end if

;
; Define each variable on the file.
;
; Don't deal with variables that are of type string.
;
  do i=0,nfields-1
    if(var_types(i).ne."string") then
      if(var_types(i).ne."character") then
        filevardef(f, var_names(i), var_types(i), "nvalues")
      else
        filevardef(f, var_names(i), var_types(i),  \
                   (/"nvalues",var_names(i)+"_StrLen"/))
      end if
    end if
  end do

;
; Loop through each field, read the values for that field, print
; information about the variable, and then write it to the netCDF
; file.
;
  do i=0,nfields-1
    ifield = i+1
;
; Note: you can't write strings to a netCDF file, so these have
; to be written out as character arrays.
;
    tmp_data = read_field(data_roof,ifield,dindices,var_types(i))
    tmp_data@units = units_roof(i)
    if (var_types(i) .eq. "float") then
;     print(tmp_data)
      tmp_data@_FillValue = -999.000
;     tmp_data@_FillValue = -999.990
;     indx = ind(ismissing(tmp_data))
;     if (.not.all(ismissing(indx))) then
;       tmp_data(indx) = -999.000
;       tmp_data@_FillValue = -999.000
;     else
;       tmp_data@_FillValue = -999.000
;     end if
;     delete(indx)
    else
      if (var_types(i) .eq. "character") then
        delete(tmp_data@_FillValue)
      end if
    end if
;
; Print some info about the variable.
;
    print("")
    print("Writing variable '" + var_names(i) + "' (field #" + ifield + ").")
    print("Type is " + var_types(i) + ".")
    if(var_types(i).ne."string".and.var_types(i).ne."character") then
      print("min/max = " + min(tmp_data) + "/" + max(tmp_data))
    end if

    if(any(ismissing(tmp_data))) then
      print("This variable does contain missing values.")
    else
      print("This variable doesn't contain missing values.")
    end if

    f->$var_names(i)$ = tmp_data       ; Write to netCDF file.

    delete(tmp_data)                   ; Delete for next round.
  end do

  delete(var_types)
  delete(var_strlens)
  delete(dindices)
  delete(var_names)
  delete(indc)

; road
  nfields = nfields_road
  var_types      = new(nfields,string)
  var_strlens    = new(nfields,integer)   ; var to hold strlens, just in case.

  var_types      = "float"       
  var_types(0:2) = "integer"
  var_types(3:5) = "character"

;
; Read in locations of delimiters in each string row.
;
  dindices = delim_indices(data_road,nfields,delimiter)     ; rest of file

;
; Read in the field names which will become variable names on
; the netCDF file.
;
  var_names = var_names_road

;
; Write dimension names to file. If there are no character variables,
; then there's only one dimension name ("nvalues").
;
; Otherwise, we need to write a dimension name for every character
; variable, which will indicate the maximum string length for that
; variable.
;
  indc = ind(var_types.eq."character")
  if(.not.any(ismissing(indc))) then
;
; We have to treat the character arrays special here. We need to
; know their sizes so we can write the maximum size of each char
; array to the netCDF file as a dimension name. This means we
; need to read in the character variables once to get the string
; lengths, then we'll read them again later to get the actual values.
;
    do i=0,dimsizes(indc)-1
      var_strlens(indc(i)) = get_maxlen(data_road,indc(i)+1,dindices)
    end do

    ndims    = dimsizes(indc) + 1
    dimNames = new(ndims,string)
    dimSizes = new(ndims,integer)
    dimUnlim = new(ndims,logical)

    dimUnlim            = False
    dimUnlim(0)         = True
    dimNames(0)         = "nvalues"
    dimNames(1:ndims-1) = var_names(indc) + "_StrLen"
    dimSizes(0)         = -1
    dimSizes(1:ndims-1) = var_strlens(indc)
    filedimdef(f,dimNames,dimSizes,dimUnlim)
  else
;
; No character variables, so just write the one dimension name.
;
    filedimdef(f,"nvalues",-1,True)
  end if

;
; Define each variable on the file.
;
; Don't deal with variables that are of type string.
;
  do i=0,nfields-1
    if(var_types(i).ne."string") then
      if(var_types(i).ne."character") then
        filevardef(f, var_names(i), var_types(i), "nvalues")
      else
        filevardef(f, var_names(i), var_types(i),  \
                   (/"nvalues",var_names(i)+"_StrLen"/))
      end if
    end if
  end do

;
; Loop through each field, read the values for that field, print
; information about the variable, and then write it to the netCDF
; file.
;
  do i=0,nfields-1
    ifield = i+1
;
; Note: you can't write strings to a netCDF file, so these have
; to be written out as character arrays.
;
    tmp_data = read_field(data_road,ifield,dindices,var_types(i))
    tmp_data@units = units_road(i)
    if (var_types(i) .eq. "float") then
;     print(tmp_data)
      tmp_data@_FillValue = -999.000
;     tmp_data@_FillValue = -999.990
;     indx = ind(ismissing(tmp_data))
;     if (.not.all(ismissing(indx))) then
;       tmp_data(indx) = -999.000
;       tmp_data@_FillValue = -999.000
;     else
;       tmp_data@_FillValue = -999.000
;     end if
;     delete(indx)
    else
      if (var_types(i) .eq. "character") then
        delete(tmp_data@_FillValue)
      end if
    end if
;
; Print some info about the variable.
;
    print("")
    print("Writing variable '" + var_names(i) + "' (field #" + ifield + ").")
    print("Type is " + var_types(i) + ".")
    if(var_types(i).ne."string".and.var_types(i).ne."character") then
      print("min/max = " + min(tmp_data) + "/" + max(tmp_data))
    end if

    if(any(ismissing(tmp_data))) then
      print("This variable does contain missing values.")
    else
      print("This variable doesn't contain missing values.")
    end if

    f->$var_names(i)$ = tmp_data       ; Write to netCDF file.

    delete(tmp_data)                   ; Delete for next round.
  end do

 ; Define some dimensions
 ; There are four urban types but here we use TBD, HD, and MD
 num_urban_types = 3
 nlevurb = 10
 numrad = 2
 numsolar = 2

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Get 1km TBD, HD, and MD extent data")
;rint(subName+                    " Get 1km TBD, HD, and MD extent data")
print(subName+"-----------------------------------------------------------------")

 fn = input_dir + urban_tbd_fn
 print(subName+"addfile "+fn)
 urban_tbd_file = addfile(fn,"r")
;urban_tbd_file = addfile("/glade/p/cgd/tss/people/oleson/urban_sfcdata/Feddema_urban_data_080410/HIGH_RES_VERSION2/tall_bldg_dist_1km.nc","r")
 tmplat_hr = urban_tbd_file->lat
 tmpnlat_hr = dimsizes(tmplat_hr)
 lon_hr = urban_tbd_file->lon
 nlon_hr = dimsizes(lon_hr)

 tmp = new((/tmpnlat_hr,nlon_hr,num_urban_types/),"double")
 tmp(:,:,0) = todouble(urban_tbd_file->tbd)

 fn = input_dir + urban_hd_fn
 print(subName+"addfile "+fn)
 urban_hd_file = addfile(fn,"r")
;urban_hd_file = addfile("/glade/p/cgd/tss/people/oleson/urban_sfcdata/Feddema_urban_data_080410/HIGH_RES_VERSION2/high_dens_1km.nc","r")
 tmp(:,:,1) = todouble(urban_hd_file->hd)

 fn = input_dir + urban_md_fn
 print(subName+"addfile "+fn)
 urban_md_file = addfile(fn,"r")
;urban_md_file = addfile("/glade/p/cgd/tss/people/oleson/urban_sfcdata/Feddema_urban_data_080410/HIGH_RES_VERSION2/med_dens_1km.nc","r")
 tmp(:,:,2) = todouble(urban_md_file->md))

; Files are not global, so fill out full arrays
; And they are north to south, so reverse to south to north
 nlat_hr = doubletoint(floor(180.d/0.00833333333333d))
 lat_hr = new((/nlat_hr/),"double")
 lat_hr(0:tmpnlat_hr-1) = tmplat_hr(::-1)
 do i = tmpnlat_hr, nlat_hr-1
   lat_hr(i) = lat_hr(tmpnlat_hr-1) + 0.00833333333333d * (i-tmpnlat_hr+1)
 end do
 lat_hr!0 = "lat"
 lat_hr&lat = lat_hr

 pct_urban_hr = new((/nlat_hr,nlon_hr,num_urban_types/),"double")
 pct_urban_hr(0:tmpnlat_hr-1,:,:) = tmp(::-1,:,:)
 pct_urban_hr!0 = "lat"
 pct_urban_hr&lat = lat_hr
 pct_urban_hr!1 = "lon"
 pct_urban_hr&lon = lon_hr
 pct_urban_hr!2 = "density_class"
;print(dimsizes(ind(ndtooned(pct_urban_hr(:,:,0)) .eq. 1)))

; Create a landmask from one of the density classes
 landmask = doubletobyte(where(ismissing(pct_urban_hr(:,:,0)),0,1))
 landmask!0 = "lat"
 landmask&lat = lat_hr
 landmask!1 = "lon"
 landmask&lon = lon_hr
 landmask = lonFlip(landmask)
 landmask@long_name = "land mask"
 landmask@units = "unitless"

 pct_urban_hr = where(ismissing(pct_urban_hr),0,pct_urban_hr)
;print(dimsizes(ind(ndtooned(pct_urban_hr(:,:,0)) .eq. 1)))

 delete(pct_urban_hr@_FillValue)
 delete(tmp)
 delete(tmpnlat_hr)
 delete(tmplat_hr)

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Get urban regions data")
;rint(subName+                    " Get urban regions data")
print(subName+"-----------------------------------------------------------------")

;regions_file = addfile("/glade/p/cgd/tss/people/oleson/urban_sfcdata/Feddema_urban_data_080410/HIGH_RES_VERSION2/urban_regions.nc","r")
; Fix for bus error on cheyenne
 setfileoption ("nc", "MissingToFillValue", False)
 fn = input_dir + regions_fn
 print(subName+"addfile "+fn)
 regions_file = addfile(fn,"r")
 tmp = (/regions_file->reg_shift/)
 region_id = tmp(::-1,:)
 region_id!0 = "lat"
 region_id&lat = lat_hr
 region_id!1 = "lon"
 region_id&lon = lon_hr
 region_id@long_name = "Region ID"
 region_id@units = "unitless"
 setfileoption ("nc", "MissingToFillValue", True)

 region_id_hr = lonFlip(region_id)
 print((/"Done creating region_id"/))
 delete(tmp)

 ; This sum should be no greater than 100
 pct_urban_hr_all = pct_urban_hr(:,:,0) + pct_urban_hr(:,:,1) + pct_urban_hr(:,:,2)
 indx = ind(ndtooned(pct_urban_hr_all) .gt. 1)
 if (.not.(all(ismissing(indx)))) then
   print((/"Number of points with multiple density types: "+dimsizes(index)/))
 else
   num_indx= 0
   print((/"Number of points with multiple density types: "+num_indx/))
 end if
 print((/"Done checking urban density types"/))
 delete(indx)

 lon_hr = lonFlip(lon_hr)
 lon_hr = (/lon_hr&lon/)

; Get interim building table data that was created above
;bldg_table_file = addfile(           output_file,"r")
 fn = output_dir + scratch_fn
 print(subName+"addfile "+fn)
 bldg_table_file = addfile(fn,"r")
 region_id_table = bldg_table_file->Region_ID

 region_name = charactertostring(bldg_table_file->Region)

 cat = charactertostring(bldg_table_file->Cat)

 tmp = bldg_table_file->Ht
 ht_roof_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tmp = bldg_table_file->H_W
 canyon_hwr_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 ;Pervious is a fraction, not percent
 tmp = bldg_table_file->Pervious
 wtroad_perv_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 ;Roof_Area is a fraction, not percent
 tmp = bldg_table_file->Roof_Area
 wtlunit_roof_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tmp = bldg_table_file->Inside_Wall_Min_T
 t_building_min_table = onedtond(tmp,(/num_regions,num_urban_types+1/))  ; degK
 delete(tmp)

 tmp = bldg_table_file->Inside_Wall_Max_T
 t_building_max_table = onedtond(tmp,(/num_regions,num_urban_types+1/))  ; degK
 delete(tmp)

 tmp = bldg_table_file->Wall_Albedo
 tmp2d = onedtond(tmp,(/num_regions,num_urban_types+1/))
 alb_wall_table = new((/numsolar,numrad,num_regions,num_urban_types+1/),"float")
 alb_wall_table(0,0,:,:) = tmp2d
 alb_wall_table(0,1,:,:) = tmp2d
 alb_wall_table(1,0,:,:) = tmp2d
 alb_wall_table(1,1,:,:) = tmp2d
 delete(tmp)
 delete(tmp2d)

 tmp = bldg_table_file->Wall_e
 em_wall_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tmp = nlevurb*(bldg_table_file->Wall_Layer_Thick)
 thick_wall_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tk_wall_table = new((/nlevurb,num_regions,num_urban_types+1/),"float")
 tk_wall_table@_FillValue = -999.
 tmp = bldg_table_file->Wall_1_tk
 tk_wall_table(0,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_2_tk
 tk_wall_table(1,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_3_tk
 tk_wall_table(2,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_4_tk
 tk_wall_table(3,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_5_tk
 tk_wall_table(4,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_6_tk
 tk_wall_table(5,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_7_tk
 tk_wall_table(6,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_8_tk
 tk_wall_table(7,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_9_tk
 tk_wall_table(8,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_10_tk
 tk_wall_table(9,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 cv_wall_table = new((/nlevurb,num_regions,num_urban_types+1/),"float")
 cv_wall_table@_FillValue = -999.
 tmp = bldg_table_file->Wall_1_Cv
 cv_wall_table(0,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_2_Cv
 cv_wall_table(1,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_3_Cv
 cv_wall_table(2,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_4_Cv
 cv_wall_table(3,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_5_Cv
 cv_wall_table(4,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_6_Cv
 cv_wall_table(5,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_7_Cv
 cv_wall_table(6,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_8_Cv
 cv_wall_table(7,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_9_Cv
 cv_wall_table(8,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Wall_10_Cv
 cv_wall_table(9,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tmp = bldg_table_file->Roof_Albedo
 tmp2d = onedtond(tmp,(/num_regions,num_urban_types+1/))
 alb_roof_table = new((/numsolar,numrad,num_regions,num_urban_types+1/),"float")
 alb_roof_table(0,0,:,:) = tmp2d
 alb_roof_table(0,1,:,:) = tmp2d
 alb_roof_table(1,0,:,:) = tmp2d
 alb_roof_table(1,1,:,:) = tmp2d
 delete(tmp)
 delete(tmp2d)

 tmp = bldg_table_file->Roof_e
 em_roof_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tmp = nlevurb*(bldg_table_file->Roof_Layer_Thick)
 thick_roof_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tk_roof_table = new((/nlevurb,num_regions,num_urban_types+1/),"float")
 tk_roof_table@_FillValue = -999.
 tmp = bldg_table_file->Roof_1_tk
 tk_roof_table(0,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_2_tk
 tk_roof_table(1,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_3_tk
 tk_roof_table(2,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_4_tk
 tk_roof_table(3,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_5_tk
 tk_roof_table(4,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_6_tk
 tk_roof_table(5,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_7_tk
 tk_roof_table(6,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_8_tk
 tk_roof_table(7,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_9_tk
 tk_roof_table(8,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_10_tk
 tk_roof_table(9,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 cv_roof_table = new((/nlevurb,num_regions,num_urban_types+1/),"float")
 cv_roof_table@_FillValue = -999.
 tmp = bldg_table_file->Roof_1_Cv
 cv_roof_table(0,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_2_Cv
 cv_roof_table(1,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_3_Cv
 cv_roof_table(2,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_4_Cv
 cv_roof_table(3,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_5_Cv
 cv_roof_table(4,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_6_Cv
 cv_roof_table(5,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_7_Cv
 cv_roof_table(6,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_8_Cv
 cv_roof_table(7,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_9_Cv
 cv_roof_table(8,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 tmp = bldg_table_file->Roof_10_Cv
 cv_roof_table(9,:,:) = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)

 tmp = bldg_table_file->Road_Albedo
 ; Impervious Road albedo can be missing for some regions because it is dirt,
 ; so assign pervious road albedo to these regions
 indx = ind(ismissing(tmp))
 if (.not.(all(ismissing(indx)))) then
   tmp(indx) = 0.08
 end if
 tmp2d = onedtond(tmp,(/num_regions,num_urban_types+1/))
 alb_improad_table = new((/numsolar,numrad,num_regions,num_urban_types+1/),"float")
 alb_improad_table(0,0,:,:) = tmp2d
 alb_improad_table(0,1,:,:) = tmp2d
 alb_improad_table(1,0,:,:) = tmp2d
 alb_improad_table(1,1,:,:) = tmp2d
 delete(tmp)
 delete(tmp2d)

 tmp = bldg_table_file->Road_e
 ; Road emissivity can be missing for some regions because it is dirt,
 ; so assign pervious road emissivity to these regions
 indx = ind(ismissing(tmp))
 if (.not.(all(ismissing(indx)))) then
   tmp(indx) = 0.95
 end if
 em_improad_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 em_perroad_table = em_improad_table
 em_perroad_table = 0.95

 ; No data for albedo of pervious road
 alb_perroad_table = alb_improad_table
 alb_perroad_table = 0.08

 wind_hgt_canyon_table = ht_roof_table/2.

; Valid data for up to three layers
 tk_improad_table = new((/nlevurb,num_regions,num_urban_types+1/),"float")
 tmp = bldg_table_file->Road_1_tk
 tk1_road_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 tmp = bldg_table_file->Road_2_tk
 tk2_road_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 tmp = bldg_table_file->Road_3_tk
 tk3_road_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 tk_improad_table(0,:,:) = tk1_road_table
 tk_improad_table(1,:,:) = tk2_road_table
 tk_improad_table(2,:,:) = tk3_road_table

; Valid data for up to three layers
 cv_improad_table = new((/nlevurb,num_regions,num_urban_types+1/),"float")
 tmp = bldg_table_file->Road_1_Cv
 cv1_road_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 tmp = bldg_table_file->Road_2_Cv
 cv2_road_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 tmp = bldg_table_file->Road_3_Cv
 cv3_road_table = onedtond(tmp,(/num_regions,num_urban_types+1/))
 delete(tmp)
 cv_improad_table(0,:,:) = cv1_road_table
 cv_improad_table(1,:,:) = cv2_road_table
 cv_improad_table(2,:,:) = cv3_road_table

 nlevimproad_table = new((/num_regions,num_urban_types+1/),"float")
 nlevimproad_table@_FillValue = -999.
 do nr = 0,num_regions-1
   do nu = 0,num_urban_types
     nlevimproad_table(nr,nu) = num(.not.(ismissing(tk_improad_table(:,nr,nu))))
   end do
 end do

 print((/"Done getting building table data"/))

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date")+ " Arrays for final output data, select only TBD, HD, MD")
;rint(subName+                    " Arrays for final output data, select only TBD, HD, MD")
print(subName+"-----------------------------------------------------------------")

 canyon_hwr_hr = canyon_hwr_table(:,0:2)
 wtlunit_roof_hr = wtlunit_roof_table(:,0:2)
 wtroad_perv_hr = wtroad_perv_table(:,0:2)
 em_roof_hr = em_roof_table(:,0:2)
 em_wall_hr = em_wall_table(:,0:2)
 em_improad_hr = em_improad_table(:,0:2)
 em_perroad_hr = em_perroad_table(:,0:2)
 alb_roof_hr = alb_roof_table(:,:,:,0:2)
 alb_wall_hr = alb_wall_table(:,:,:,0:2)
 alb_improad_hr = alb_improad_table(:,:,:,0:2)
 alb_perroad_hr = alb_perroad_table(:,:,:,0:2)
 ht_roof_hr = ht_roof_table(:,0:2)
 wind_hgt_canyon_hr = wind_hgt_canyon_table(:,0:2)
 tk_wall_hr = tk_wall_table(:,:,0:2)
 tk_roof_hr = tk_roof_table(:,:,0:2)
 tk_improad_hr = tk_improad_table(:,:,0:2)
 cv_wall_hr = cv_wall_table(:,:,0:2)
 cv_roof_hr = cv_roof_table(:,:,0:2)
 cv_improad_hr = cv_improad_table(:,:,0:2)
 nlevimproad_hr = nlevimproad_table(:,0:2)
 thick_wall_hr = thick_wall_table(:,0:2)
 thick_roof_hr = thick_roof_table(:,0:2)
 t_building_min_hr = t_building_min_table(:,0:2)
 t_building_max_hr = t_building_max_table(:,0:2)
 print((/"Finish arrays for final output data"/))

; Assign coordinates etc to high resolution arrays
 canyon_hwr_hr!0 = "region"
 canyon_hwr_hr!1 = "density_class"
 canyon_hwr_hr@long_name = "canyon height to width ratio"
 canyon_hwr_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,wtlunit_roof_hr)
 wtlunit_roof_hr@long_name = "fraction of roof"
 wtlunit_roof_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,wtroad_perv_hr)
 wtroad_perv_hr@long_name = "fraction of pervious road"
 wtroad_perv_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,em_roof_hr)
 em_roof_hr@long_name = "emissivity of roof"
 em_roof_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,em_wall_hr)
 em_wall_hr@long_name = "emissivity of wall"
 em_wall_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,em_improad_hr)
 em_improad_hr@long_name = "emissivity of impervious road"
 em_improad_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,em_perroad_hr)
 em_perroad_hr@long_name = "emissivity of pervious road"
 em_perroad_hr@units = "unitless"

 alb_roof_hr!0 = "numsolar"
 alb_roof_hr&numsolar = ispan(1,numsolar,1)
 alb_roof_hr!1 = "numrad"
 alb_roof_hr&numrad = ispan(1,numrad,1)
 alb_roof_hr!2 = "region"
 alb_roof_hr!3 = "density_class"
 alb_roof_hr@long_name = "albedo of roof"
 alb_roof_hr@units = "unitless"

 copy_VarCoords(alb_roof_hr,alb_wall_hr)
 alb_wall_hr@long_name = "albedo of wall"
 alb_wall_hr@units = "unitless"

 copy_VarCoords(alb_roof_hr,alb_improad_hr)
 alb_improad_hr@long_name = "albedo of impervious road"
 alb_improad_hr@units = "unitless"

 copy_VarCoords(alb_roof_hr,alb_perroad_hr)
 alb_perroad_hr@long_name = "albedo of pervious road"
 alb_perroad_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,ht_roof_hr)
 ht_roof_hr@long_name = "height of roof"
 ht_roof_hr@units = "meters"

 copy_VarCoords(canyon_hwr_hr,wind_hgt_canyon_hr)
 wind_hgt_canyon_hr@long_name = "height of wind in canyon"
 wind_hgt_canyon_hr@units = "meters"

 tk_wall_hr!0 = "nlevurb"
 tk_wall_hr&nlevurb = ispan(1,nlevurb,1)
 tk_wall_hr!1 = "region"
 tk_wall_hr!2 = "density_class"
 tk_wall_hr@long_name = "thermal conductivity of wall"
 tk_wall_hr@units = "W/m*K"

 copy_VarCoords(tk_wall_hr,tk_roof_hr)
 tk_roof_hr@long_name = "thermal conductivity of roof"
 tk_roof_hr@units = "W/m*K"

 copy_VarCoords(tk_wall_hr,cv_wall_hr)
 cv_wall_hr@long_name = "volumetric heat capacity of wall"
 cv_wall_hr@units = "J/m^3*K"

 copy_VarCoords(tk_wall_hr,cv_roof_hr)
 cv_roof_hr@long_name = "volumetric heat capacity of roof"
 cv_roof_hr@units = "J/m^3*K"

 copy_VarCoords(tk_wall_hr,tk_improad_hr)
 tk_improad_hr@long_name = "thermal conductivity of impervious road"
 tk_improad_hr@units = "W/m*K"

 copy_VarCoords(tk_wall_hr,cv_improad_hr)
 cv_improad_hr@long_name = "volumetric heat capacity of impervious road"
 cv_improad_hr@units = "J/m^3*K"

 copy_VarCoords(canyon_hwr_hr,nlevimproad_hr)
 nlevimproad_hr@long_name = "number of impervious road layers"
 nlevimproad_hr@units = "unitless"

 copy_VarCoords(canyon_hwr_hr,thick_wall_hr)
 thick_wall_hr@long_name = "thickness of wall"
 thick_wall_hr@units = "m"

 copy_VarCoords(canyon_hwr_hr,thick_roof_hr)
 thick_roof_hr@long_name = "thickness of roof"
 thick_roof_hr@units = "m"

 copy_VarCoords(canyon_hwr_hr,t_building_min_hr)
 t_building_min_hr@long_name = "minimum interior building temperature"
 t_building_min_hr@units = "K"

 copy_VarCoords(canyon_hwr_hr,t_building_max_hr)
 t_building_max_hr@long_name = "maximum interior building temperature"
 t_building_max_hr@units = "K"

; Strip off coordinate variables but keep other info
 landmask_out = (/landmask/)
 landmask_out!0 = "lat"
 landmask_out!1 = "lon"
 landmask_out@long_name = "land mask"
 landmask_out@units = "unitless"

 lat_out = (/lat_hr/)
 lat_out!0 = "lat"
 lat_out@long_name = "lat"
 lat_out@units = "degrees north"
 delete(lat_out@_FillValue)

 lon_out = (/lon_hr/)
 lon_out!0 = "lon"
 lon_out@long_name = "lon"
 lon_out@units = "degrees east"

 latixy = conform_dims((/nlat_hr,nlon_hr/),(/lat_hr/),0)
 latixy_out = (/latixy/)
 latixy_out!0 = "lat"
 latixy_out!1 = "lon"
 latixy_out@long_name = "latitude-2d"
 latixy_out@units = "degrees north"
 delete(latixy_out@_FillValue)

 longxy = conform_dims((/nlat_hr,nlon_hr/),(/lon_hr/),1)
 longxy_out = (/longxy/)
 longxy_out!0 = "lat"
 longxy_out!1 = "lon"
 longxy_out@long_name = "longitude-2d"
 longxy_out@units = "degrees east"

 urban_fraction_out = (/pct_urban_hr/)
 urban_fraction_out!0 = "lat"
 urban_fraction_out!1 = "lon"
 urban_fraction_out!2 = "density_class"
 urban_fraction_out@long_name = "Percent urban for three classes"
 urban_fraction_out@units = "unitless"
 delete(urban_fraction_out@_FillValue)
;print(dimsizes(ind(ndtooned(dens_class_out) .eq. 1)))
;print(dimsizes(ind(ndtooned(dens_class_out) .eq. 2)))
;print(dimsizes(ind(ndtooned(dens_class_out) .eq. 3)))

;region_id_out = doubletobyte((/region_id_hr/)) ; already is a byte, conversion causes fatal error
 region_id_out =              (/region_id_hr/)    
 region_id_out!0 = "lat"
 region_id_out!1 = "lon"
 region_id_out@long_name = "Region ID"
 region_id_out@units = "unitless"

 delete(fAtt)
 delete(dimNames)
 delete(dimSizes)
 delete(dimUnlim)

print(subName+"-----------------------------------------------------------------")
print(subName+systemfunc("date") + " create output file " + output_fn_1km)
;rint(subName+                     " create output file " + output_fn_1km)
print(subName+"-----------------------------------------------------------------")

;setfileoption("nc","Format","LargeFile") 
 setfileoption("nc","Format","NetCDF4Classic") 
fn = output_dir + output_fn_1km
 system("/bin/rm -f " + fn)
 out_file = addfile(fn,"c")

; Define mode
 setfileoption(out_file,"DefineMode",True)
 fAtt = True
 fAtt@title = metadata_title
 fAtt@source = metadata_source
 fAtt@case_id = metadata_caseID
;fAtt@date = systemfunc("date")
 fAtt@created_by = creation_info  
 fileattdef( out_file, fAtt)
 
 dimNames = (/"lat",   "lon",   "numsolar", "numrad", "nlevurb", "region",    "density_class"/)
 dimSizes = (/nlat_hr, nlon_hr, numsolar,   numrad,   nlevurb,   num_regions, num_urban_types/)
 dimUnlim = (/False,   False,   False,      False,    False,     False,       False/)
 filedimdef(out_file,dimNames,dimSizes,dimUnlim)

 filevardef(out_file, "LANDMASK", typeof(landmask_out), getvardims(landmask_out))
 filevardef(out_file, "LAT", typeof(lat_out), getvardims(lat_out))
 filevardef(out_file, "LON", typeof(lon_out), getvardims(lon_out))
 filevardef(out_file, "LATIXY", typeof(latixy_out), getvardims(latixy_out))
 filevardef(out_file, "LONGXY", typeof(longxy_out), getvardims(longxy_out))
 filevardef(out_file, "URBAN_FRACTION", typeof(urban_fraction_out), getvardims(urban_fraction_out))
 filevardef(out_file, "REGION_ID", typeof(region_id_out), getvardims(region_id_out))
 filevardef(out_file, "CANYON_HWR", typeof(canyon_hwr_hr), getvardims(canyon_hwr_hr))
 filevardef(out_file, "WTLUNIT_ROOF", typeof(wtlunit_roof_hr), getvardims(wtlunit_roof_hr))
 filevardef(out_file, "WTROAD_PERV", typeof(wtroad_perv_hr), getvardims(wtroad_perv_hr))
 filevardef(out_file, "EM_ROOF", typeof(em_roof_hr), getvardims(em_roof_hr))
 filevardef(out_file, "EM_WALL", typeof(em_wall_hr), getvardims(em_wall_hr))
 filevardef(out_file, "EM_IMPROAD", typeof(em_improad_hr), getvardims(em_improad_hr))
 filevardef(out_file, "EM_PERROAD", typeof(em_perroad_hr), getvardims(em_perroad_hr))
 filevardef(out_file, "ALB_ROOF", typeof(alb_roof_hr), getvardims(alb_roof_hr))
 filevardef(out_file, "ALB_WALL", typeof(alb_wall_hr), getvardims(alb_wall_hr))
 filevardef(out_file, "ALB_IMPROAD", typeof(alb_improad_hr), getvardims(alb_improad_hr))
 filevardef(out_file, "ALB_PERROAD", typeof(alb_perroad_hr), getvardims(alb_perroad_hr))
 filevardef(out_file, "HT_ROOF", typeof(ht_roof_hr), getvardims(ht_roof_hr))
 filevardef(out_file, "WIND_HGT_CANYON", typeof(wind_hgt_canyon_hr), getvardims(wind_hgt_canyon_hr))
 filevardef(out_file, "TK_ROOF", typeof(tk_roof_hr), getvardims(tk_roof_hr))
 filevardef(out_file, "TK_WALL", typeof(tk_wall_hr), getvardims(tk_wall_hr))
 filevardef(out_file, "TK_IMPROAD", typeof(tk_improad_hr), getvardims(tk_improad_hr))
 filevardef(out_file, "CV_ROOF", typeof(cv_roof_hr), getvardims(cv_roof_hr))
 filevardef(out_file, "CV_WALL", typeof(cv_wall_hr), getvardims(cv_wall_hr))
 filevardef(out_file, "CV_IMPROAD", typeof(cv_improad_hr), getvardims(cv_improad_hr))
 filevardef(out_file, "NLEV_IMPROAD", typeof(nlevimproad_hr), getvardims(nlevimproad_hr))
 filevardef(out_file, "THICK_ROOF", typeof(thick_roof_hr), getvardims(thick_roof_hr))
 filevardef(out_file, "THICK_WALL", typeof(thick_wall_hr), getvardims(thick_wall_hr))
 filevardef(out_file, "T_BUILDING_MIN", typeof(t_building_min_hr), getvardims(t_building_min_hr))
 filevardef(out_file, "T_BUILDING_MAX", typeof(t_building_max_hr), getvardims(t_building_max_hr))

 filevarattdef(out_file, "LANDMASK", landmask_out)
 filevarattdef(out_file, "LAT", lat_out)
 filevarattdef(out_file, "LON", lon_out)
 filevarattdef(out_file, "LATIXY", latixy_out)
 filevarattdef(out_file, "LONGXY", longxy_out)
 filevarattdef(out_file, "URBAN_FRACTION", urban_fraction_out)
 filevarattdef(out_file, "REGION_ID", region_id_out)
 filevarattdef(out_file, "CANYON_HWR", canyon_hwr_hr)
 filevarattdef(out_file, "WTLUNIT_ROOF", wtlunit_roof_hr)
 filevarattdef(out_file, "WTROAD_PERV", wtroad_perv_hr)
 filevarattdef(out_file, "EM_ROOF", em_roof_hr)
 filevarattdef(out_file, "EM_WALL", em_wall_hr)
 filevarattdef(out_file, "EM_IMPROAD", em_improad_hr)
 filevarattdef(out_file, "EM_PERROAD", em_perroad_hr)
 filevarattdef(out_file, "ALB_ROOF", alb_roof_hr)
 filevarattdef(out_file, "ALB_WALL", alb_wall_hr)
 filevarattdef(out_file, "ALB_IMPROAD", alb_improad_hr)
 filevarattdef(out_file, "ALB_PERROAD", alb_perroad_hr)
 filevarattdef(out_file, "HT_ROOF", ht_roof_hr)
 filevarattdef(out_file, "WIND_HGT_CANYON", wind_hgt_canyon_hr)
 filevarattdef(out_file, "TK_ROOF", tk_roof_hr)
 filevarattdef(out_file, "TK_WALL", tk_wall_hr)
 filevarattdef(out_file, "TK_IMPROAD", tk_improad_hr)
 filevarattdef(out_file, "CV_ROOF", cv_roof_hr)
 filevarattdef(out_file, "CV_WALL", cv_wall_hr)
 filevarattdef(out_file, "CV_IMPROAD", cv_improad_hr)
 filevarattdef(out_file, "NLEV_IMPROAD", nlevimproad_hr)
 filevarattdef(out_file, "THICK_ROOF", thick_roof_hr)
 filevarattdef(out_file, "THICK_WALL", thick_wall_hr)
 filevarattdef(out_file, "T_BUILDING_MIN", t_building_min_hr)
 filevarattdef(out_file, "T_BUILDING_MAX", t_building_max_hr)

 setfileoption(out_file,"DefineMode",False)

 out_file->LANDMASK = (/landmask_out/)
 out_file->LAT = (/lat_out/)
 out_file->LON = (/lon_out/)
 out_file->LATIXY = (/latixy_out/)
 out_file->LONGXY = (/longxy_out/)
 out_file->URBAN_FRACTION = (/urban_fraction_out/)
 out_file->REGION_ID = (/region_id_out/)
 out_file->CANYON_HWR = (/canyon_hwr_hr/)
 out_file->WTLUNIT_ROOF = (/wtlunit_roof_hr/)
 out_file->WTROAD_PERV = (/wtroad_perv_hr/)
 out_file->EM_ROOF = (/em_roof_hr/)
 out_file->EM_WALL = (/em_wall_hr/)
 out_file->EM_IMPROAD = (/em_improad_hr/)
 out_file->EM_PERROAD = (/em_perroad_hr/)
 out_file->ALB_ROOF = (/alb_roof_hr/)
 out_file->ALB_WALL = (/alb_wall_hr/)
 out_file->ALB_IMPROAD = (/alb_improad_hr/)
 out_file->ALB_PERROAD = (/alb_perroad_hr/)
 out_file->HT_ROOF = (/ht_roof_hr/)
 out_file->WIND_HGT_CANYON = (/wind_hgt_canyon_hr/)
 out_file->TK_ROOF = (/tk_roof_hr/)
 out_file->TK_WALL = (/tk_wall_hr/)
 out_file->TK_IMPROAD = (/tk_improad_hr/)
 out_file->CV_ROOF = (/cv_roof_hr/)
 out_file->CV_WALL = (/cv_wall_hr/)
 out_file->CV_IMPROAD = (/cv_improad_hr/)
 out_file->NLEV_IMPROAD = (/nlevimproad_hr/)
 out_file->THICK_ROOF = (/thick_roof_hr/)
 out_file->THICK_WALL = (/thick_wall_hr/)
 out_file->T_BUILDING_MIN = (/t_building_min_hr/)
 out_file->T_BUILDING_MAX = (/t_building_max_hr/)

print(subName+"=================================================================")
print(subName+systemfunc("date")+ " Finished.")
print(subName+"=================================================================")

end

