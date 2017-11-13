import "regent"

-- Helper module to handle command line arguments
local DesisionTreeConfig = require("decision_tree_config")

local c = regentlib.c
local sqrt  = regentlib.sqrt(double)
local cmath = terralib.includec("math.h")

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
  label      : uint8;  -- classification label 
  attributes:          -- an array of cells 
}

--
-- TODO: Define fieldspace 'Link' which has two pointer fields,
--       one that points to the source and another to the destination.
--
fspace Link(p : region(Page)) { 
    src : ptr(Page, p); 
    dst : ptr(Page, p);
}


-- skip header in file 
--------------------------------------------------------------------
terra skip_header(f : &c.FILE)
  var x : uint64, y : uint64
  c.fscanf(f, "%llu\n%llu\n", &x, &y)
end


-- read node ids from file 
--------------------------------------------------------------------
terra read_ids(f : &c.FILE, page_ids : &uint32)
  return c.fscanf(f, "%d %d\n", &page_ids[0], &page_ids[1]) == 2
end


-- initialize graph 
--------------------------------------------------------------------
-- initialize fields in page nodes 
-- initialize fields in links 
task initialize_graph(r_pages   : region(Page),
                      r_links   : region(Link(r_pages)),
                      damp      : double,
                      num_pages : uint64,
                      filename  : int8[512])
where
  reads writes(r_pages, r_links)
do
  var ts_start = c.legion_get_current_time_in_micros()
  for page in r_pages do
    page.rank = 1.0 / num_pages
    page.outs = 0
    page.new_rank = 0
  end

  var f = c.fopen(filename, "rb")
  skip_header(f)
  var page_ids : uint32[2]
  for link in r_links do
    regentlib.assert(read_ids(f, page_ids), "Less data that it should be")
    var src_page = unsafe_cast(ptr(Page, r_pages), page_ids[0])
    var dst_page = unsafe_cast(ptr(Page, r_pages), page_ids[1])
    --
    -- TODO: Initialize the link with 'src_page' and 'dst_page'
    --
    link.src = src_page 
    link.dst = dst_page 
    src_page.outs += 1
  end
  c.fclose(f)
  var ts_stop = c.legion_get_current_time_in_micros()
  c.printf("Graph initialization took %.4f sec\n", (ts_stop - ts_start) * 1e-6)
end


-- initialize graph 
--------------------------------------------------------------------
-- initialize fields in page nodes 
-- initialize fields in links 
task dump_ranks(r_pages  : region(Page),
                filename : int8[512])
where
  reads(r_pages.rank)
do
  var f = c.fopen(filename, "w")
  for page in r_pages do c.fprintf(f, "%g\n", page.rank) end
  c.fclose(f)
end


-- each update iteration 
--------------------------------------------------------------------
task update_iter(r_pages : region(Page),
                 r_links : region(Link(r_pages)),
                 damp    : double,
                 n       : uint64 
                 )
where
  reads(r_pages.rank, r_pages.new_rank, r_pages.outs, r_links.src, r_links.dst),
  writes(r_pages.rank, r_pages.new_rank, r_links.dst.new_rank)
do
    -- step 1: update new_rank for each page by links 
    var err : double = 0 -- accumulative error for all ranks 
    for link in r_links do
        link.dst.new_rank += link.src.rank / link.src.outs 
    end 

    -- step 2: update new_rank to rank for each page 
    for page in r_pages do
        var rank = page.rank
        page.rank = page.new_rank * damp + (1 - damp) / n
        err += cmath.pow(page.rank - rank, 2)
        page.new_rank = 0
    end 

    return sqrt(err)
end 

-- utility function: show a table for graph statistics 
--------------------------------------------------------------------
task show_graph(r_pages : region(Page))
where
  reads(r_pages)
do
    c.printf("%11s\t\t%11s\n", "Node", "Out")
    for page in r_pages do 
        c.printf("%11zu\t\t%11zu\n", page, page.outs)
    end
end 


-- Main Task 
--------------------------------------------------------------------
task toplevel()
  var config : PageRankConfig
  config:initialize_from_command()
  c.printf("**********************************\n")
  c.printf("* PageRank                       *\n")
  c.printf("*                                *\n")
  c.printf("* Number of Pages  : %11lu *\n",  config.num_pages)
  c.printf("* Number of Links  : %11lu *\n",  config.num_links)
  c.printf("* Damping Factor   : %11.4f *\n", config.damp)
  c.printf("* Error Bound      : %11g *\n",   config.error_bound)
  c.printf("* Max # Iterations : %11u *\n",   config.max_iterations)
  c.printf("* Dump Output      : %11d *\n",   config.dump_output)
  c.printf("**********************************\n")


  -- Create a region of pages
  var r_pages = region(ispace(ptr, config.num_pages), Page)
  --
  -- TODO: Create a region of links.
  --       It is your choice how you allocate the elements in this region.
  --
  var r_links = region(ispace(ptr, config.num_links), Link(r_pages))

  -- Initialize the page graph from a file
  initialize_graph(r_pages, r_links, config.damp, config.num_pages, config.input)

  show_graph(r_pages)

  var num_iterations = 0
  var converged = false
  var ts_start = c.legion_get_current_time_in_micros()
  var err : double = 0
  while not converged do
    num_iterations += 1
    -- update ranks and get current error 
    err = update_iter(r_pages, r_links, config.damp, config.num_pages)
    converged = (err <= config.error_bound)
    c.printf("Iter %5d: error = %f\n", num_iterations, err)
    -- check maximum iterations 
    if num_iterations >= config.max_iterations then
        break
    end  
  end
  var ts_stop = c.legion_get_current_time_in_micros()

  if converged then 
      c.printf("PageRank converged after %d iterations in %.4f sec\n", num_iterations, (ts_stop - ts_start) * 1e-6)
  else
      c.printf("Not Converged: final error = %f\n", err)
  end 

  if config.dump_output then dump_ranks(r_pages, config.output) end
end

regentlib.start(toplevel)
