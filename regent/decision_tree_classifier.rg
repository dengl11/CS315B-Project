import "regent"

-- Helper module to handle command line arguments
local DecisionTreeConfig = require("decision_tree_config")

local c = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")

local num_feature = 4

struct Row
{
    label : uint32,
    features : double[num_feature];
}


-- Decision Tree
------------------------------------
struct Tree
{
    feature_ind : uint32, -- index of splitting feature 
    feature_val : double; -- value of splitting feature
    left        : Tree;   -- left subtree 
    rigth       : Tree;   -- right subtree 
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
  features : Cell[num_feature]         -- an array of cells 
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
terra read_row(f : &c.FILE, label : &uint32, feature : &double)
      return c.fscanf(f, "%d %lf %lf %lf %lf", &label[0], &feature[0], &feature[1], &feature[2], &feature[3]) == num_feature + 1
end


-- utility function: Peeak Head 
--------------------------------------------------------------------
task peek(r_data_points : region(DataPoint),
           k : uint8)
where
    reads(r_data_points)
do
    for data in r_data_points do
        var feature = data.features  
        c.printf("%3d -> %lf %lf %lf %lf\n", data.label, feature[0].val, feature[1].val, feature[2].val, feature[3].val)
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
  var feature : double[num_feature]
  for row = 0, num_rows do
    regentlib.assert(read_row(f, label, feature), "Less data that it should be")
    r_data_points[row].row = row
    r_data_points[row].label = label[0]
    for col = 1, num_feature + 1 do
        r_data_points[row].features[col-1].row = row
        r_data_points[row].features[col-1].col = col
        r_data_points[row].features[col-1].val = feature[col-1]
    end 
  end 
  -- c.printf("--------- Read Data Done -------------\n")
end


-- split the tree on a certain feature 
--------------------------------------------------------------------
-- feature:  index of feature in feature list to be splited 
-- return:   gini index value
task split_by_feature(r_data_points : region(DataPoint),
                      feature : uint8)
end 


-- Find Best Split 
--------------------------------------------------------------------
-- first sort the feature
-- return: (feature_index, feature_val)
task best_split(r_data_points : region(DataPoint))
end 

-- Decision Tree Algorithm 
--------------------------------------------------------------------
task build_tree(r_data_points : region(DataPoint),
                depth: uint8)
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
