import "regent"
local c = regentlib.c

terra f()
    var ans : float[2] 
     ans[0] = 1.234243
    -- ans[1] = 10
    return ans 
end 

-- Main Task 
--------------------------------------------------------------------
task main()
    var ans : float[2] = f()
    c.printf("ans %.2f\n", ans[0])
    c.printf("ans %f\n", ans[1])
end

regentlib.start(main)
