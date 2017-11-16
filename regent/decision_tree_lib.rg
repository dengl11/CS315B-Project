import "regent"

local DataPoint = require("field_space_lib")

-- local CONFIG = require("CONFIG")
-- var config : CONFIG 
-- local max_row = require("max_row")

local c = regentlib.c

MAX_ROW = 1000

-- Decision Tree Node 
------------------------------------
struct DTNode
{
    depth         : uint32,    -- depth
    -- for leaf node only, {-1: non-labeled | 0/1: label}
    label         : int32,
    split_feature : uint32,    -- index of splitting feature 
    split_val     : double;    -- value of splitting feature
    gini          : double;    -- gini index 
    left          : &DTNode;   -- left subtree 
    rigth         : &DTNode;   -- right subtree 
    n             : uint64;    -- number of data points in this node
    -- data          : uint64[config:get_max_row()];
    data          : uint64[MAX_ROW];
}

terra DTNode : init(n : uint64, data : uint64[1000])
    self.n = n
    self.data = data 
end 


-- Decision Tree
------------------------------------
struct Tree
{
    root     : DTNode;
    max_depth: uint32;
}

terra Tree : init(n : uint64, max_depth : uint32, data : uint64[1000])
    var root : DTNode 
    root:init(n, data)
    self.max_depth = max_depth 
    self.root = root
end 


-- Split by Feature 
------------------------------------
task split_by_feature(node: DTNode,
                      X : region(DataPoint))

end 

return Tree 
