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

local max_row = 1000

local num_feature = 6

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


-- Field Space for decision tree node 
------------------------------------
fspace Tree{
    left : uint32,
    right: uint32,
    depth: uint32,    -- depth
    max_depth: uint32,    -- depth
    -- for leaf node only, {-1: non-labeled | 0/1: label}
    label         : int32,
    -- index of splitting feature | -1 for not splitting 
    split_feature : int32,     
    split_val     : float;    -- value of splitting feature
    gini          : float;    -- gini index 
    n             : uint64;    -- number of data points in this node
    data          : uint64[max_row]
}


-- Read Row from File
--------------------------------------------------------------------
terra read_row(f : &c.FILE, label : &uint32, feature : &float)
     if num_feature == 4 then
      return c.fscanf(f, "%d %f %f %f %f", &label[0], &feature[0], &feature[1], &feature[2], &feature[3]) == num_feature + 1
     else 
      return c.fscanf(f, "%d %f %f %f %f %f %f", &label[0], &feature[0], &feature[1], &feature[2], &feature[3], &feature[4], &feature[5]) == num_feature + 1
     end 
end


-- utility function: Peek Head 
--------------------------------------------------------------------
task peek(r_data_points : region(ispace(ptr), DataPoint),
          k : uint8)
where
    reads(r_data_points)
do
    for data in r_data_points do
        if k <= 0 then break end  
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


-- show trees 
--------------------------------------------------------------------
task show_trees(r_trees : region(ispace(ptr), Tree))
where
    reads (r_trees)
do
    c.printf("--------------- Trees ------------------\n")
    for t in r_trees do
        for i = 0, t.depth do
            c.printf("\t")
        end 
        c.printf("[%d]\tL=%d\tR=%d\tn=%d\tG=%.2f", t, t.left, t.right, t.n, t.gini)
        if t.split_feature < 0 then
            c.printf("->%d", t.label)
        else
            c.printf("\tSF=%d\tSV=%.1f", t.split_feature, t.split_val)
        end 
        c.printf("\n")
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
    var depth = 0
    var n_samelevel = 1
    for t in r_trees do
        t.split_feature = -1
        t.left = child
        t.right = child + 1
        t.depth = depth
        t.max_depth = max_depth
        if n_samelevel == cmath.pow(2, depth) then
            depth += 1
            n_samelevel = 1
        else
            n_samelevel += 1
        end 
        child += 2
    end 
end
 
 
-- split a node by feature 
--------------------------------------------------------------------
-- feature:  index of feature in feature list to be splited 
-- return {gini_index, split_val}
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
        var curr_val = r_data_points[node.data[i]].features[feature]
        var num_pos_left : float = 0
        var num_left : float = 0
        var num_pos_right : float = 0
        var num_right : float = 0
        for j = 0, node.n do
            var point = r_data_points[node.data[j]]
            if point.features[feature] <= curr_val then
                num_pos_left += point.label 
                num_left += 1
            else
                num_pos_right += point.label 
                num_right += 1
            end 
        end 
        -- weighted average of gini index after splitted 
        var curr_gini = 
                (num_left * compute_gini(num_pos_left/num_left) 
                + num_right * compute_gini(num_pos_right/num_right)) / node.n 
       -- c.printf("val %f -> %f\n", curr_val, curr_gini)
        -- update best gini and split value 
        if curr_gini < best_gini then
            best_gini = curr_gini
            split_val = curr_val 
        end 
    end 
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
    var node_ptr = unsafe_cast(ptr(Tree, r_trees), tree_index)
    var node = r_trees[node_ptr]
    var nPos : float = 0
    for i = 0,  node.n do
        nPos += r_data_points[node.data[i]].label 
    end 
    -- ratio of positive points 
    var pos_ratio : float = nPos/node.n 
    var best_gini = compute_gini(pos_ratio)

    r_trees[node_ptr].gini = best_gini 
    -- stop splitting criteria 
    if node.depth >= node.max_depth or best_gini == 0.0 then 
        r_trees[tree_index].label = [int](nPos > node.n / 2)
        return 
    end 

    var split_feature : uint8 
    var split_val:float 
    for feature = 0, num_feature do
        var result : float[2] = split_by_feature(r_trees, r_data_points, tree_index, feature)
        -- c.printf("feature: %d -> %f\n", feature, result[0])
        if result[0] < best_gini then
            best_gini = result[0]
            split_val = result[1]
            split_feature = feature 
        end 
    end 
    r_trees[node_ptr].split_feature = split_feature
    r_trees[node_ptr].split_val = split_val 
    -- split the region of data points into two 
    var left_ptr = unsafe_cast(ptr(Tree, r_trees), node.left)
    var right_ptr = unsafe_cast(ptr(Tree, r_trees), node.right)
    var n_left = 0
    var n_right = 0
    for i = 0, node.n do
        var row = node.data[i]
        var point = r_data_points[row]
        if point.features[split_feature] <= split_val then
            r_trees[left_ptr].data[n_left] = row 
            n_left += 1
        else
            r_trees[right_ptr].data[n_right] = row 
            n_right += 1
        end 
    end 
    r_trees[left_ptr].n = n_left 
    r_trees[right_ptr].n = n_right 
end 


-- train a tree on data points 
--------------------------------------------------------------------
task train(r_trees : region(Tree), 
           r_data_points : region(DataPoint))
where
  reads (r_data_points, r_trees),
  writes (r_trees)
do
    for t_index in r_trees do 
        split_node(r_trees, r_data_points, t_index) 
    end 
    return 1
end 


-- predict a single point 
--------------------------------------------------------------------
task predict_point(r_trees : region(Tree), 
           point : DataPoint)
where
  reads (r_trees)
do
    var tree_index = 0
    var node = r_trees[unsafe_cast(ptr(Tree, r_trees), tree_index)]
    while node.split_feature >= 0 do
        if point.features[node.split_feature] <= node.split_val then
            tree_index = node.left
        else
            tree_index = node.right
        end 
        node = r_trees[unsafe_cast(ptr(Tree, r_trees), tree_index)]
    end 
    return node.label
end 


-- test on data points 
--------------------------------------------------------------------
task test(r_trees : region(Tree), 
           r_data_points : region(DataPoint))
where
  reads (r_data_points, r_trees)
do
    var n = 0
    var correct : float = 0
    for e in r_data_points do
        var prediction = predict_point(r_trees, r_data_points[e])
        correct += [int](prediction == r_data_points[e].label)
        n += 1
    end 
    return correct / n 
end 


-- Main Task 
--------------------------------------------------------------------
task main()
  ------------------ Init Config ----------------------
  var config : DecisionTreeConfig
  config:initialize_from_command()
  show_config(config)

  ------------------ Read in Data ----------------------
  -- create a region of data points
  var r_train = region(ispace(ptr, config.train_row), DataPoint)
  read_data(r_train, config.train_row, config.input_train)

  var r_test = region(ispace(ptr, config.test_row), DataPoint)

  c.printf("\n**** Read Data ******\n")
  read_data(r_test, config.test_row, config.input_test)
  c.printf("\n**** Data Loaded ******\n")

  -- peek(r_train, 10)

  var n_trees = cmath.pow(2, config.max_depth + 1) - 1
  var r_trees = region(ispace(ptr, n_trees), Tree)
  init_trees(r_trees, config.train_row, config.max_depth)
  c.printf("\n**** INIT ******\n")
  -- show_trees(r_trees)

  ------------------ Train ----------------------
  var train_start = c.legion_get_current_time_in_micros()
  var dummy = train(r_trees, r_train)
  var train_stop = c.legion_get_current_time_in_micros()

  -- c.printf("\n**** Train Done ******\n")
  -- show_trees(r_trees)

  ------------------ Test ----------------------
  var test_start = c.legion_get_current_time_in_micros()

  var train_acc = test(r_trees, r_train)
  var test_acc = test(r_trees, r_test)

  var test_stop = c.legion_get_current_time_in_micros()

  c.printf("Training time: %.4f sec\n", (train_stop - train_start) * 1e-6)
  c.printf("Testing  time: %.4f sec\n", (test_stop - test_start) * 1e-6)

  c.printf("Train Acc: %.2f\n", train_acc)
  c.printf("Test  Acc: %.2f\n", test_acc)
end

regentlib.start(main)
