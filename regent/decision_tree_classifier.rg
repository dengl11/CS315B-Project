import "regent"

-- Helper module to handle command line arguments
local DecisionTreeConfig = require("decision_tree_config")

local c = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")

local num_attr = 4

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
  row        : uint64; -- row number, i.e. ID of this data point 
  label      : uint8;  -- classification label 
  attributes : Cell[num_attr]         -- an array of cells 
}



-- skip header in file 
--------------------------------------------------------------------
terra skip_header(f : &c.FILE)
  var x : uint64, y : uint64
  c.fscanf(f, "%llu\n%llu\n", &x, &y)
end



-- init configuration 
--------------------------------------------------------------------
terra init_config(config : DecisionTreeConfig)
  config:initialize_from_command()
  c.printf("**********************************\n")
  c.printf("* Decision Tree Classifier       *\n")
  c.printf("*                                *\n")
  c.printf("* Number of Rows  :  %11lu *\n",  config.num_row)
  c.printf("* Number of Cols  :  %11lu *\n",  config.num_col)
  c.printf("**********************************\n") 
end


-- Read Row from File 
--------------------------------------------------------------------
terra read_row(f : &c.FILE, attr : &double)
      return (c.fscanf(f, "%lf %lf %lf %lf %lf\n", &attr[0], &attr[1], &attr[2], &attr[3], &attr[4])) == num_attr + 1
end


-- Read Data from File 
--------------------------------------------------------------------
task read_data(r_data_points   : region(DataPoint),
              num_rows : uint64,
              filename  : int8[512])
where
  reads writes(r_data_points)
do
  var f = c.fopen(filename, "rb")
  skip_header(f)
  var attr : double[num_attr + 1]
  var row = 1
  for data in r_data_points do
    regentlib.assert(read_row(f, attr), "Less data that it should be")
    data.row = row
    data.label = attr[0]
    for i = 1, num_attr + 1 do
        var cell = 
        data.attributes[i-1] = attr[i]
    row += 1
  end 
  end 
  
end

-- Main Task 
--------------------------------------------------------------------
task main()
  var config : DecisionTreeConfig
  init_config(config)
  -- create a region of data points
  var r_data_points = region(ispace(ptr, config.num_row), DataPoint)
end

regentlib.start(main)
