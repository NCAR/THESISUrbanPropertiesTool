;===============================================================================
; SVN $Id: keyword_values.ncl 207 2017-11-10 19:55:55Z kauff $
; SVN $URL: https://svn-iam-thesis.cgd.ucar.edu/urban_properties/trunk_tags/urban_properties_180622/src/keyword_values.ncl $
;===============================================================================
undef("keyword_values")
function keyword_values(pfName[1]:string, keynam[1]:string, return_type[1]:string)
;--------------------------------------------------
;  Read a 'simple'  ASCII (text): key=value(s)
;--------------------------------------------------
; Nomenclature:
;    pfName - path for file: dir+filname
;    keynam - key name [no spaces; _ allowed)
;    delim  - delimiters/ seperators
;    return_type - "integer", "logical", "float", "string"
;
local types, tab, dq, delim, keyval, nline, KEY, iKEY, nKEY, nfld, chr, nchr, n, val, value
begin
;---Error test
   types = (/ "integer", "float", "double", "logical", "string" /)
   if (.not.(any(types.eq.return_type))) then 
       print("keyword_values:  return_type="+return_type+" not supported: ?correct spelling?")
       exit
   end if

;---Create delimiter string
   tab     = str_get_tab()        ; TAB
   dq      = str_get_dq()         ; "
   delim   = "=, "+dq+tab         ; add TAB and " 

;---read text (ascii) file and 'squeeze' leading spaces and TABs
   keyval = asciiread(pfName, -1, "string")        ; p(ath)/(f)ile Name
   keyval = str_squeeze(keyval)                    ; eliminate leading/trailing spaces and TABs
   nline  = dimsizes(keyval)                       ; # of lines (rows)

;---Extract field #1 (keynam)
   KEY    = str_get_field(keyval, 1, delim)        ; extract 'keynam' (leftmost) field 

;---Index of line containing 'keynam'
   iKEY   = ind(keynam.eq.KEY)                     ; index of line with 'keynam'
   if (ismissing(iKEY)) then
       print("keyword_values:  key name="+keynam+" not found: ?correct spelling?")
       return(default_fillvalue(return_type))
       exit
   end if

   nKEY   = dimsizes(iKEY)                          ; # keynam found             
   if (nKEY.gt.1) then
       print("keyword_values:  There are multiple entries named "+keynam)
       print("keyword_values:  The indices of the multiple entries are:")
       print("                 "+iKEY)
       return(default_fillvalue(return_type))
       exit
   end if

;---Number of fields for 'keyval(iKEY)' line.  This *includes* the keyword.
   nfld  = str_fields_count(keyval(iKEY), delim)   
   if (nfld.eq.1) then
       print("keyword_values:  key name="+keynam+" has no associated value(s)")
       return(default_fillvalue(return_type))
       exit
   end if

;---Create return field
   value = new(nfld-1, return_type)

   if (return_type.eq."string") then
       do n=1,nfld-1
          value(n-1) = str_get_field(keyval(iKEY), n+1, delim) 
       end do
   else
       if (return_type.eq."logical") then
           value = False                ; set default return value to False
           do n=1,nfld-1
              val = str_get_field(keyval(iKEY), n+1, delim)
              if (val.eq.".true." .or. val.eq.".TRUE." .or.  val.eq."TRUE" .or. \   
                  val.eq.".T." .or. val.eq.".t."       .or.  val.eq."T"    .or. \
                  val.eq."True".or. val.eq.".True.") then
                  value(n-1) = True     ; NCL logical
              end if   
           end do
        else
           do n=1,nfld-1
              value(n-1) = totype(str_get_field(keyval(iKEY), n+1, delim), return_type) 
           end do
        end if
   end if

   return(value) 
end

