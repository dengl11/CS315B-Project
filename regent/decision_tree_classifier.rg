import "regent"

-- Helper module to handle command line arguments
local DecisionTreeConfig = require("decision_tree_config")
local Tree = require("decision_tree_lib")

local c = regentlib.c
local sqrt  = regentlib.sqrt(float)
local cmath = terralib.includec("math.h")
local std = terralib.includec("stdlib.h")

local num_feature = 4

struct Row
{
    label : uint32,
    features : float[num_feature];
}


terra square(x : float)
    return cmath.pow(x, 2)
end 

terra compute_gini(pos_ratio : float)
    return 1 - square(pos_ratio) - square(1-pos_ratio) 
end 

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
terra read_row(f : &c.FILE, label : &uint32, feature : &float)
      return c.fscanf(f, "%d %f %f %f %f", &label[0], &feature[0], &feature[1], &feature[2], &feature[3]) == num_feature + 1
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
  var feature : float[num_feature]
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
    -- var data = ispace(int1d, 1000)
    var data : uint64[1000]
    for row in r_data_points do 
        n += 1
        data[n] = n
    end 
    tree:init(n, max_depth, data) 
    return tree 
end

-- split by feature 
--------------------------------------------------------------------
-- feature:  index of feature in feature list to be splited 
-- return {gini_index, split_val}
task split_by_feature(r_data_points : region(DataPoint), 
                      node: DTNode, feature : uint32)
where
  reads (r_data_points)
do
    var best_gini = node.gini 
    for i in r_data_points do
        -- c.printf("%f\t", r_data_points[i].features[feature].val)
    end 
end 




-- split a node into two 
--------------------------------------------------------------------
task split_node(r_data_points : region(DataPoint), node : DTNode)
where
  reads (r_data_points)
do
    var nPos : float = 0
    for i = 0,  node.n + 1 do
        nPos += r_data_points[node.data[i]].label 
    end 
    var pos_ratio : float = nPos/node.n 
    node:set_gini(compute_gini(pos_ratio))
    c.printf("local gini = %f\n", node.gini)
    for feature = 0, num_feature do
        split_by_feature(r_data_points, node, feature)
    end 
end 


-- train a tree on data points 
--------------------------------------------------------------------
task train(r_data_points : region(DataPoint),
           tree : Tree)
where
  reads (r_data_points)
do
    split_node(r_data_points, tree.root) 
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
task main()
  var config : DecisionTreeConfig
  config:initialize_from_command()
  show_config(config)
  -- create a region of data points
  var r_data_points = region(ispace(ptr, config.num_row), DataPoint)
  read_data(r_data_points, config.num_row, config.input)
  -- sort_data(r_data_points)
  -- sort_by_feature(r_data_points, 1)

  peek(r_data_points, 5)
  var tree : Tree = construct_tree(r_data_points, config.max_depth)
  train(r_data_points, tree)
  tree:show()
end

terra cmp(a : ptr, b : ptr)
    return 1
end 


-- terra sort()
--     var counts = {1, 3, 2}
--     std.qsort(&counts, 3, 4, cmp)
-- end 

-- task main()
--     sort()
-- end 

-- regentlib.start(sort)
regentlib.start(main)
