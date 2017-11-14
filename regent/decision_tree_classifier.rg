import "regent"

-- Helper module to handle command line arguments
local DecisionTreeConfig = require("decision_tree_config")

local c = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")

local num_attr = 4

struct Row
{
    label : uint32,
    attr : double[num_attr];
}

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
  label      : uint32;  -- classification label 
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
terra show_config(config : DecisionTreeConfig)
  c.printf("**********************************\n")
  c.printf("* Decision Tree Classifier       *\n")
  c.printf("*                                *\n")
  c.printf("* Input:  %s\n",  config.input)
  c.printf("* Number of Rows  :  %11lu *\n",  config.num_row)
  c.printf("* Number of Cols  :  %11lu *\n",  config.num_col)
  c.printf("**********************************\n") 
end


-- Read Row from File 
--------------------------------------------------------------------
terra read_row(f : &c.FILE, label : &uint32, attr : &double)
      return c.fscanf(f, "%d %lf %lf %lf %lf", &label[0], &attr[0], &attr[1], &attr[2], &attr[3]) == num_attr + 1
end


-- utility function: Peeak Head 
--------------------------------------------------------------------
task peek(r_data_points : region(DataPoint),
           k : uint8)
where
    reads(r_data_points)
do
    for data in r_data_points do
        var attr = data.attributes  
        c.printf("%3d -> %lf %lf %lf %lf\n", data.label, attr[0].val, attr[1].val, attr[2].val, attr[3].val)
    end
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
  var label : uint32[1] 
  var attr : double[num_attr]
  for row = 0, num_rows do
    regentlib.assert(read_row(f, label, attr), "Less data that it should be")
    r_data_points[row].row = row
    r_data_points[row].label = label[0]
    for col = 1, num_attr + 1 do
        r_data_points[row].attributes[col-1].row = row
        r_data_points[row].attributes[col-1].col = col
        r_data_points[row].attributes[col-1].val = attr[col-1]
    end 
  end 
  -- c.printf("--------- Read Data Done -------------\n")
end

-- Main Task 
--------------------------------------------------------------------
task main()
  var config : DecisionTreeConfig
  config:initialize_from_command()
  show_config(config)
  -- create a region of data points
  var r_data_points = region(ispace(ptr, config.num_row), DataPoint)
  read_data(r_data_points, config.num_row, config.input)
  peek(r_data_points, 5)
end

regentlib.start(main)
