-------------------------------------------------------------
-- Classifier of My Decision Tree 
-------------------------------------------------------------

import "regent"
require("util")
require("CONFIG")

local DecisionTreeConfig = require("decision_tree_config")
-- local Tree = require("decision_tree_lib")

local c = regentlib.c
local sqrt  = regentlib.sqrt(float)
local cmath = terralib.includec("math.h")
local std = terralib.includec("stdlib.h")
-- local List = require("terralist")

local max_row = 1000
local num_feature = 4

-- Field Space for each data point 
------------------------------------
fspace DataPoint {
  -- row number, i.e. ID of this data point 
  row        : uint64;            
  -- classification label 
  label      : uint32;  
  -- features: an array of cells 
  features   : float[num_feature];         
}

fspace Tree{
    left : uint32,
    right: uint32,
    depth: uint32,    -- depth
    -- for leaf node only, {-1: non-labeled | 0/1: label}
    label         : int32,
    -- index of splitting feature | -1 for not splitting 
    split_feature : int32,     
    split_val     : float;    -- value of splitting feature
    gini          : float;    -- gini index 
    n             : uint64;    -- number of data points in this node
    data          : uint64[max_row]
}


-- Read Row from File --------------------------------------------------------------------
terra read_row(f : &c.FILE, label : &uint32, feature : &float)
      return c.fscanf(f, "%d %f %f %f %f", &label[0], &feature[0], &feature[1], &feature[2], &feature[3]) == num_feature + 1
end


-- utility function: Peeak Head 
--------------------------------------------------------------------
task peek(r_data_points : region(ispace(ptr), DataPoint),
          k : uint8)
where
    reads(r_data_points)
do
    for data in r_data_points do
        if k <= 0 then break end  
        -- var data = r_data_points[i]
        var feature = data.features  
        c.printf("%3d -> %.2f %.2f %.2f %.2f\n", data.label, feature[0], feature[1], feature[2], feature[3])
        k -= 1
    end
end



-- Read Data from File 
--------------------------------------------------------------------
task read_data(r_data_points   : region(ispace(ptr), DataPoint),
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
        r_data_points[row].features[col-1] = feature[col-1]
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
-- task build_tree(r_data_points : region(DataPoint),
--                 depth: uint8)
-- end 
-- 
-- local std = terralib.includec("stdlib.h")
-- 
-- terra comp_fn(p1:DataPoint, p2:DataPoint)
-- end 
-- 

-- show trees 
--------------------------------------------------------------------
task show_trees(r_trees : region(ispace(ptr), Tree))
where
    reads (r_trees)
do
    c.printf("--------------- Trees ------------------\n")
    for t in r_trees do
        for i = 1, t.depth do
            c.printf("\t")
        end 
        c.printf("ID=%d\tDepth=%d\tLeft=%d\tRight=%d\tn=%d\n", t, t.depth, t.left, t.right, t.n)
    end 
    c.printf("----------------------------------------\n")
end 

-- init a region of decision trees 
--------------------------------------------------------------------
task init_trees(r_trees : region(ispace(ptr), Tree),
                num_row : uint64, 
                max_depth: uint32)
where
    reads writes(r_trees)
do
    -- init root node 
    var root_ptr = unsafe_cast(ptr(Tree, r_trees), 0)
    r_trees[root_ptr].n = num_row 
    for i = 0, num_row do
        r_trees[root_ptr].data[i] = i
    end 
    -- init all other trees 
    var child = 1
    var depth = 1
    var n_samelevel = 1
    for t in r_trees do
        t.split_feature = -1
        t.left = child
        t.right = child + 1
        t.depth = depth
        if n_samelevel == cmath.pow(2, depth-1) then
            depth += 1
            n_samelevel = 1
        else
            n_samelevel += 1
        end 
        child += 2
    end 
end
-- 
-- 
-- -- split a node by feature 
-- --------------------------------------------------------------------
-- -- feature:  index of feature in feature list to be splited 
-- -- return {gini_index, split_val}
task split_by_feature(r_trees : region(Tree), 
                      r_data_points : region(DataPoint), 
                      tree_index : uint8, 
                      feature : uint32)
where
  reads (r_data_points, r_trees)
do
    var node = r_trees[unsafe_cast(ptr(Tree, r_trees), tree_index)]
    var best_gini = node.gini 
    var split_val : float 
    for i = 0, node.n do
        var curr_val = r_data_points[i].features[feature]
        var num_pos_left : float = 0
        var num_left : float = 0
        var num_pos_right : float = 0
        var num_right : float = 0
        for j in r_data_points do
            if r_data_points[j].features[feature] <= curr_val then
                num_pos_left += r_data_points[i].label 
                num_left += 1
            else
                num_pos_right += r_data_points[i].label 
                num_right += 1
            end 
        end 
        -- weighted average of gini index after splitted 
        var curr_gini = 
                (num_left * compute_gini(num_pos_left/num_left) 
                + num_right * compute_gini(num_pos_right/num_right)) / node.n 
        -- update best gini and split value 
        if curr_gini < best_gini then
            best_gini = curr_gini
            split_val = curr_val 
        end 
    end 
    c.printf("return best_gini = %f\n", best_gini)
    c.printf("return split_val = %f\n", split_val)
    var ans:float[2]
    ans[0] = best_gini 
    ans[1] = split_val 
    return ans 
end 




-- split a node into two 
--------------------------------------------------------------------
task split_node(r_trees : region(Tree), 
                r_data_points : region(DataPoint), 
                tree_index : uint8)
where
  reads (r_data_points, r_trees),
  writes (r_trees)
do
    var node = r_trees[unsafe_cast(ptr(Tree, r_trees), tree_index)]
    var nPos : float = 0
    for i = 0,  node.n + 1 do
        nPos += r_data_points[node.data[i]].label 
    end 
    -- ratio of positive points 
    var pos_ratio : float = nPos/node.n 
    node.gini = compute_gini(pos_ratio)
    for feature = 0, num_feature do
        var result : float[2] = split_by_feature(r_trees, r_data_points, tree_index, feature)
        c.printf("%f\n", result[0])
        c.printf("%f\n", result[1])
    end 
end 


-- train a tree on data points 
--------------------------------------------------------------------
task train(r_trees : region(Tree), 
           r_data_points : region(DataPoint))
where
  reads (r_data_points, r_trees),
  writes (r_trees)
do
    split_node(r_trees, r_data_points, 0) 
end 


-- test a tree on data points 
--------------------------------------------------------------------
-- task test(r_data_points : region(DataPoint),
--            tree : Tree)
-- where
--   reads (r_data_points)
-- do
-- end 
-- sort data points by a certain feature
--------------------------------------------------------------------
-- task sort_by_feature(r_data_points : region(DataPoint),
--                     feature_ind: uint32)
--     std.qsort(r_data_points, n_data_points, c.sizeof(DataPoint), comp_fn)
-- end 

-- task sort_on_feature(r_data_points : region(DataPoint),
--                      feature       : uint32)
-- where
--   reads (r_data_points.features),
--   writes (r_data_points.ranks)
-- do
--     for i in r_data_points do
--         c.printf("%f\t", r_data_points[i].features[feature].val)
--     end 
-- end 


-- sort data points 
--------------------------------------------------------------------
-- task sort_data(r_data_points : region(DataPoint))
-- where
--   reads (r_data_points.features),
--   writes (r_data_points.ranks)
-- do
--     for i = 0, num_feature do
--         sort_on_feature(r_data_points, i)
--     end 
-- end 

-- Main Task 
--------------------------------------------------------------------
task main()
  ------------------ Init Config ----------------------
  var config : DecisionTreeConfig
  config:initialize_from_command()
  show_config(config)

  ------------------ Read in Data ----------------------
  -- create a region of data points
  var r_data_points = region(ispace(ptr, config.num_row), DataPoint)
  read_data(r_data_points, config.num_row, config.input_train)

  peek(r_data_points, 10)

  var n_trees = cmath.pow(2, config.max_depth) - 1
  var r_trees = region(ispace(ptr, n_trees), Tree)
  init_trees(r_trees, config.num_row, config.max_depth)
  show_trees(r_trees)

  ------------------ Train ----------------------
  train(r_trees, r_data_points)

  -- tree:show()

  ------------------ Test ----------------------
  -- var r_test = region(ispace(ptr, config.num_row), DataPoint)
  -- read_data(r_test, config.num_row, config.input_train)
  -- test(r_test, tree)
end

regentlib.start(main)
