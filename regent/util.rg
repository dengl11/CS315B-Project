-------------------------------------------------------------
-- Utility Functions 
-------------------------------------------------------------

local cmath = terralib.includec("math.h")
local c = regentlib.c

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

