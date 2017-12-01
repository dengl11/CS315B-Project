-------------------------------------------------------------
-- Configuration of Classifier 
-------------------------------------------------------------
local c = regentlib.c
local cstring = terralib.includec("string.h")
local std = terralib.includec("stdlib.h")

struct DecisionTreeConfig
{
  input_train  : int8[512],
  input_test  : int8[512],
  train_row: uint64;
  test_row: uint64;
  num_col: uint64;
  max_depth: uint64; 
  parallelism: uint8; 
}


-- init configuration 
--------------------------------------------------------------------
terra show_config(config : DecisionTreeConfig)
  c.printf("****************************************\n")
  c.printf("* Decision Tree Classifier             \n")
  c.printf("*                                      \n")
  c.printf("* Max Depth: %d\n",  config.max_depth)
  c.printf("* Train Input: %s\n",  config.input_train)
  c.printf("* Test  Input: %s\n",  config.input_test)
  c.printf("* Train - Number of Rows  :  %11lu       \n",  config.train_row)
  c.printf("* Test  - Number of Rows  :  %11lu       \n",  config.test_row)
  c.printf("* Number of Cols          :  %11lu       \n",  config.num_col)
  c.printf("* Parallelism             :  %11lu       \n",  config.parallelism)
  c.printf("****************************************\n") 
end


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
  self.max_depth = 3
  self.parallelism = 0

  var args = c.legion_runtime_get_input_args()
  var i = 1
  while i < args.argc do
    if cstring.strcmp(args.argv[i], "-h") == 0 then
      print_usage_and_abort()
    elseif cstring.strcmp(args.argv[i], "-d") == 0 then
        i = i + 1
        self.max_depth = std.atoi(args.argv[i])
    elseif cstring.strcmp(args.argv[i], "-p") == 0 then
        i = i + 1
        self.parallelism = std.atoi(args.argv[i])
    elseif cstring.strcmp(args.argv[i], "-train") == 0 then
      i = i + 1

      var file = c.fopen(args.argv[i], "rb")
      if file == nil then
        c.printf("File '%s' doesn't exist!\n", args.argv[i])
        c.abort()
      end
      cstring.strcpy(self.input_train, args.argv[i])
      c.fscanf(file, "%llu\n%llu\n", &self.train_row, &self.num_col)
      input_given = true
      c.fclose(file)
    elseif cstring.strcmp(args.argv[i], "-test") == 0 then
        i = i + 1
          var file = c.fopen(args.argv[i], "rb")
          if file == nil then
            c.printf("File '%s' doesn't exist!\n", args.argv[i])
            c.abort()
          end
        cstring.strcpy(self.input_test, args.argv[i])
          c.fscanf(file, "%llu\n%llu\n", &self.test_row, &self.num_col)
          input_given = true
          c.fclose(file)
    end
        i = i + 1
  end
  if not input_given then
    c.printf("Input file must be given!\n\n")
    print_usage_and_abort()
  end
end

return DecisionTreeConfig
