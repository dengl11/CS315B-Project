import "regent"

struct CONFIG 
{
  max_row: uint64;
}

local max_row = 1000

terra CONFIG : get_max_row()
   return max_row  
end 

return max_row
