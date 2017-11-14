import "regent"

local c = regentlib.c

local util = {}

struct DecisionTreeConfig
{
  input  : int8[512],
  num_row: uint64;
  num_col: uint64;
}

local cstring = terralib.includec("string.h")

-- show program usage 
--------------------------------------------------------------------
terra print_usage_and_abort()
  c.printf("Usage: regent.py decision_tree_classifier.rg [OPTIONS]\n")
  c.printf("OPTIONS\n")
  c.printf("  -h            : Print the usage and exit.\n")
  c.printf("  -i {file}     : Use {file} as input.\n")
  c.abort()
end


-- return if file already exists 
--------------------------------------------------------------------
terra file_exists(filename : rawstring)
  var file = c.fopen(filename, "rb")
  if file == nil then return false end
  c.fclose(file)
  return true
end


-- initialize configuration from command 
--------------------------------------------------------------------
terra DecisionTreeConfig:initialize_from_command()
  var input_given = false

  var args = c.legion_runtime_get_input_args()
  var i = 1
  while i < args.argc do
    if cstring.strcmp(args.argv[i], "-h") == 0 then
      print_usage_and_abort()
    elseif cstring.strcmp(args.argv[i], "-i") == 0 then
      i = i + 1

      var file = c.fopen(args.argv[i], "rb")
      if file == nil then
        c.printf("File '%s' doesn't exist!\n", args.argv[i])
        c.abort()
      end
      cstring.strcpy(self.input, args.argv[i])
      c.fscanf(file, "%llu\n%llu\n", &self.num_row, &self.num_col)
      input_given = true
      c.fclose(file)
    i = i + 1
  end
  end
  if not input_given then
    c.printf("Input file must be given!\n\n")
    print_usage_and_abort()
  end
end

return DecisionTreeConfig
