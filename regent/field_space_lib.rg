import "regent"

local num_feature = 4

-- Field Space for each cell
------------------------------------
fspace Cell {
  row: uint64;
  col: uint64;
  val: double;
}

-- Field Space for each data point 
------------------------------------
fspace DataPoint {
  -- row number, i.e. ID of this data point 
  row        : uint64;            
  -- classification label 
  label      : uint32;  
  -- features: an array of cells 
  features   : Cell[num_feature];         
  -- rank for each feature 
  ranks      : uint64[num_feature];
}

return DataPoint 
