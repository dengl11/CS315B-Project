-------------------------------------------------------------
-- Classifier of My Decision Tree (Parallel)
-------------------------------------------------------------

import "regent"
require("util")
require("CONFIG")

local DecisionTreeConfig = require("decision_tree_config")

local c = regentlib.c
local sqrt  = regentlib.sqrt(float)
local cmath = terralib.includec("math.h")
local std = terralib.includec("stdlib.h")
local assert = regentlib.assert

local max_row = 376079
                

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

-- Field Space for mapping 
------------------------------------
fspace Mapping {
  -- row number, i.e. ID of this data point 
  row        : uint64;            
}


-- Field Space for decision tree node 
------------------------------------
fspace Tree{
    ID  : uint8,
    left : uint32,
    right: uint32,
    depth: uint32,            -- depth
    max_depth: uint32,        -- depth
    -- for leaf node only, {-1: non-labeled | 0/1: label}
    label         : int32,
    -- index of splitting feature | -1 for not splitting 
    split_feature : int32,     
    split_val     : float;    -- value of splitting feature
    gini          : float;    -- gini index 
    n             : uint64;   -- number of data points in this node
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
task read_data(r_data_points   : region(ispace(int1d), DataPoint),
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
    assert(read_row(f, label, feature), "Less data that it should be")
    r_data_points[row].row = row
    r_data_points[row].label = label[0]
    for col = 1, num_feature + 1 do
        r_data_points[row].features[col-1] = feature[col-1]
    end 
  end 
end


-- show trees 
--------------------------------------------------------------------
task show_trees(r_trees : region(ispace(int1d), Tree))
where
    reads (r_trees)
do
    c.printf("--------------- Trees ------------------\n")
    for t in r_trees do
        if t.n > 0 then 
            for i = 0, t.depth do
                c.printf("\t")
            end 
            c.printf("[%d]\tL=%d\tR=%d\tn=%d\tG=%.2f", t, t.left, t.right, t.n, t.gini)
            if t.label >= 0 then
                c.printf("->%d", t.label)
            else
                c.printf("\tSF=%d\tSV=%.1f", t.split_feature, t.split_val)
            end 
            c.printf("\n")
        end 
    end 
    c.printf("----------------------------------------\n")
end 


-- init a region of decision trees 
--------------------------------------------------------------------
task init_trees(r_trees : region(ispace(int1d), Tree),
                num_row : uint64, 
                max_depth: uint32,
                r_mapping : region(ispace(int1d), Mapping))
where
    reads writes(r_trees),
    reads writes(r_mapping)
do
    -- init root node 
    var root_index = 0
    r_trees[root_index].n = num_row 
    for i = 0, num_row do
        r_mapping[i].row = i
    end 
    -- init all other trees 
    var child = 1
    var depth = 0
    var n_samelevel = 1
    for t in r_trees do
        t.ID = t  
        t.split_feature = -1
        t.left = child
        t.right = child + 1
        t.label = -1 -- initialize with no label 
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
    return 1
end
 
 
-- split a node by feature 
--------------------------------------------------------------------
-- feature:  index of feature in feature list to be splited 
-- return {gini_index, split_val}
__demand(__inline) task split_by_feature(r_trees : region(ispace(int1d), Tree), 
                      r_data_points : region(ispace(int1d), DataPoint), 
                      r_mapping : region(ispace(int1d), Mapping), 
                      tree_index : uint8, 
                      feature : uint32)
where
  reads (r_data_points, r_trees, r_mapping)
do
    var node = r_trees[tree_index]
    var best_gini = node.gini 
    var split_val : float 
    var s = node.ID * max_row
    for i = 0, node.n do
        var curr_val = r_data_points[r_mapping[s + i].row].features[feature]
        var num_pos_left : float = 0
        var num_left : float = 0
        var num_pos_right : float = 0
        var num_right : float = 0
        
        for j = 0, node.n do
            var point = r_data_points[r_mapping[s + j].row]
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


-- apply data to mapping region 
--------------------------------------------------------------------
__demand(__inline) task apply_mapping(r_trees : region(ispace(int1d), Tree),
                                      node_index : uint8,
                                      r_mapping : region(ispace(int1d), Mapping),
                                      rows : &uint64)
where
  reads (r_trees, r_mapping),
  writes (r_trees, r_mapping)
do
    var pre = r_trees[node_index - 1]
    var s = max_row * r_trees[node_index].ID 
     
    for i = 0, r_trees[node_index].n do
        r_mapping[s + i].row = rows[i]
    end 
end 



-- split a node into two 
--------------------------------------------------------------------
task split_node(r_trees : region(ispace(int1d), Tree), 
                r_data_points : region(ispace(int1d), DataPoint), 
                r_mapping : region(ispace(int1d), Mapping), 
                tree_index : uint32)
where
  reads (r_data_points, r_trees, r_mapping),
  writes (r_trees, r_mapping)
do
    var node_index = tree_index
    var node = r_trees[node_index]

    if node.n == 0 then return end 

    var nPos : float = 0
    var s = node.ID * max_row
    for i = 0,  node.n do
        nPos += r_data_points[r_mapping[s+i].row].label 
    end 
    -- ratio of positive points 
    var pos_ratio : float = nPos/node.n 
    var best_gini = compute_gini(pos_ratio)
    r_trees[node_index].gini = best_gini 
    -- stop splitting criteria 
    if node.depth >= node.max_depth or best_gini == 0.0 then 
        r_trees[tree_index].label = [int](nPos > node.n / 2)
        assert(r_trees[tree_index].split_feature < 0, "wrong feature")
        return 
    end 

    var split_feature : uint8 
    var split_val:float 
    for feature = 0, num_feature do
        var result : float[2] = split_by_feature(r_trees, r_data_points, r_mapping, tree_index, feature)
        if result[0] < best_gini then
            best_gini = result[0]
            split_val = result[1]
            split_feature = feature 
        end 
    end 
    r_trees[node_index].split_feature = split_feature
    r_trees[node_index].split_val = split_val 
    -- split the region of data points into two 
    var left_index = node.left
    var right_index = node.right
    var n_left = 0
    var n_right = 0
    var left_data : uint64[max_row]
    var right_data : uint64[max_row]

    for i = 0, node.n do
        var row = r_mapping[s + i].row
        var point = r_data_points[row]
        if point.features[split_feature] <= split_val then
            left_data[n_left] = row 
            n_left += 1
        else
            right_data[n_right] = row 
            n_right += 1
        end 
    end 

    r_trees[left_index].n = n_left 
    apply_mapping(r_trees, left_index, r_mapping, left_data)

    r_trees[right_index].n = n_right 
    apply_mapping(r_trees, right_index, r_mapping, right_data)
    
end 


-- train a tree on data points 
--------------------------------------------------------------------
task train(r_trees : region(ispace(int1d), Tree), 
           r_data_points : region(ispace(int1d),DataPoint),
           r_mapping : region(ispace(int1d),Mapping),
           num_tree : int)
where
  reads (r_data_points, r_trees, r_mapping),
  writes (r_trees, r_mapping)
do

    -- create coloring of tree region 
    var tree_coloring = ispace(int1d, num_tree)
    -- create a partition of tree  
    var tree_partition = partition(equal, r_trees, tree_coloring)

    -- create coloring of map 
    var map_coloring = ispace(int1d, num_tree)
    -- create a partition of map 
    var map_partition = partition(equal, r_mapping, map_coloring)

    var start = 0
    var scaler = 1

    while start < num_tree do 
        __demand(__parallel)
        for t_index = start, start + scaler do 
            split_node(tree_partition[t_index], r_data_points, map_partition[t_index], t_index) 
        end 
        start += scaler 
        scaler *= 2
    end 
    return 1 -- return a dummy value  
end 


-- predict a single point 
--------------------------------------------------------------------
__demand(__inline) task predict_point(r_trees : region(ispace(int1d), Tree), 
                   point : DataPoint)
where
  reads (r_trees)
do
    var tree_index = 0
    var node = r_trees[tree_index]
    while node.label < 0 do
        if point.features[node.split_feature] <= node.split_val then
            tree_index = node.left
        else
            tree_index = node.right
        end 
        node = r_trees[tree_index]
    end 
    return node.label
end 


-- test a batch a data 
--------------------------------------------------------------------
task test_batch(r_trees : region(ispace(int1d), Tree), 
          r_data_points : region(ispace(int1d), DataPoint))
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

-- test on data points 
--------------------------------------------------------------------
task test(r_trees : region(ispace(int1d), Tree), 
           r_data_points : region(ispace(int1d), DataPoint),
           parallelism : int)
where
  reads (r_data_points, r_trees)
do
    var data_coloring = ispace(int1d, parallelism)
    var data_partition = partition(equal, r_data_points, data_coloring)

    var acc : float = 0

    __demand(__parallel)
    for e in data_partition.colors do
        acc += test_batch(r_trees, data_partition[e])
    end 

    return acc / parallelism 
end 


-- Main Task 
--------------------------------------------------------------------
task main()
  ------------------ Init Config ----------------------
  var config : DecisionTreeConfig
  config:initialize_from_command()
  show_config(config)
  assert(config.train_row <= max_row, "Too Many Rows!")

  var n_trees = cmath.pow(2, config.max_depth + 1) - 1

  -- create a region of mapping 
  var r_mapping = region(ispace(int1d, n_trees * max_row), Mapping)

  ------------------ Read in Data ----------------------

  -- create a region of data points
  var r_train = region(ispace(int1d, config.train_row), DataPoint)
  read_data(r_train, config.train_row, config.input_train)

  var r_test = region(ispace(int1d, config.test_row), DataPoint)

  c.printf("\n**** Read Data ******\n")
  read_data(r_test, config.test_row, config.input_test)
  c.printf("\n**** Data Loaded ******\n")

  -- peek(r_train, 10)

  var r_trees = region(ispace(int1d, n_trees), Tree)
  init_trees(r_trees, config.train_row, config.max_depth, r_mapping)
  -- c.printf("\n**** Init Done ******\n")
  -- show_trees(r_trees)

  ------------------ Train ----------------------
  var train_start = c.legion_get_current_time_in_micros()
  var _ = train(r_trees, r_train, r_mapping, n_trees)
  var train_stop = c.legion_get_current_time_in_micros()

  c.printf("\n**** Train Done ******\n")
  -- show_trees(r_trees)

  ------------------ Test ----------------------
  var test_start = c.legion_get_current_time_in_micros()

  var train_acc = test(r_trees, r_train, config.parallelism)
  var test_acc = test(r_trees, r_test, config.parallelism)

  var test_stop = c.legion_get_current_time_in_micros()

  c.printf("Training Time: %.4f sec\n", (train_stop - train_start) * 1e-6)
  c.printf("Testing  Time: %.4f sec\n", (test_stop - test_start) * 1e-6)

  c.printf("Train Acc: %.4f\n", train_acc)
  c.printf("Test  Acc: %.4f\n", test_acc)
end

regentlib.start(main)
