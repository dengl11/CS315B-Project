import "regent"

-- Helper module to handle command line arguments
local DecisionTreeConfig = require("decision_tree_config")
local Tree = require("decision_tree_lib")

local c = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")
local std = terralib.includec("stdlib.h")

local num_feature = 4

struct Row
{
    label : uint32,
    features : double[num_feature];
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
        if k <= 0 then break end  
        var feature = data.features  
        c.printf("%3d -> %lf %lf %lf %lf\n", data.label, feature[0].val, feature[1].val, feature[2].val, feature[3].val)
        k -= 1
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
-- task best_split(r_data_points : region(DataPoint))
-- end 

-- Decision Tree Algorithm 
--------------------------------------------------------------------
task build_tree(r_data_points : region(DataPoint),
                depth: uint8)
end 

local std = terralib.includec("stdlib.h")

terra comp_fn(p1:DataPoint, p2:DataPoint)
end 

-- construct a decision tree 
--------------------------------------------------------------------
task construct_tree(r_data_points : region(DataPoint),
                max_depth: uint32)
    var tree : Tree 
    var n:uint64 = 0
    var data : uint64[1000]
    for row in r_data_points do 
        n += 1
    end 
    tree:init(n, max_depth, data) 
    return tree 
end


-- sort data points by a certain feature
--------------------------------------------------------------------
-- task sort_by_feature(r_data_points : region(DataPoint),
--                     feature_ind: uint32)
--     std.qsort(r_data_points, n_data_points, c.sizeof(DataPoint), comp_fn)
-- end 

task sort_on_feature(r_data_points : region(DataPoint),
                     feature       : uint32)
where
  reads (r_data_points.features),
  writes (r_data_points.ranks)
do
    for i in r_data_points do
        c.printf("%f\t", r_data_points[i].features[feature].val)
    end 
end 


-- sort data points 
--------------------------------------------------------------------
task sort_data(r_data_points : region(DataPoint))
where
  reads (r_data_points.features),
  writes (r_data_points.ranks)
do
    for i = 0, num_feature do
        sort_on_feature(r_data_points, i)
    end 
end 

-- Main Task 
--------------------------------------------------------------------
-- task main()
--   var config : DecisionTreeConfig
--   config:initialize_from_command()
--   show_config(config)
--   -- create a region of data points
--   var r_data_points = region(ispace(ptr, config.num_row), DataPoint)
--   read_data(r_data_points, config.num_row, config.input)
--   sort_data(r_data_points)
--   -- sort_by_feature(r_data_points, 1)
-- 
--   peek(r_data_points, 5)
--   var tree : Tree = construct_tree(r_data_points, config.max_depth)
-- end

terra cmp(a : int, b : int)
    return a - b
end 


terra sort()
 -- Sort the info by sample count
    var counts = {1, 3, 2}
    var sortedcounts = {}
    for k,v in pairs(counts) do
        table.insert(sortedcounts, {key = k, count = v})
    end
    table.sort(sortedcounts, function(a, b) return a.count > b.count end)
end 

task main()
    sort()
end 

-- regentlib.start(sort)
regentlib.start(main)
