init:
	mkdir -p out 
	mkdir -p out/adult


p_adult_mini:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/adult/adult_train_mini.tsv\
		-test ../data/adult/adult_test_mini.tsv\
		-d 3\
		-p 4\
		-lg:spy -logfile ./out/adult/mini.log
	# spy
	~/legion/tools/legion_spy.py -d -e ./out/adult/mini.log

p_adult_tiny:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 1\
		-p 2\
		-lg:spy -logfile ./out/adult/tiny.log
	# spy
	~/legion/tools/legion_spy.py -d -e ./out/adult/tiny.log

adult_tiny_no_map:
	clear
	~/legion/language/regent.py ./decision_tree_classifier_no_mapping.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 2

p_adult_medium_nm:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier_no_mapping.rg\
		-train ../data/adult/adult_train_medium.tsv\
		-test ../data/adult/adult_test_medium.tsv\
		-lg:spy -logfile ./out/adult/medium_nm.log\
		-p 8\
		-d 2
	
	# spy
	~/legion/tools/legion_spy.py -d -e ./out/adult/medium_nm.log


p_adult_tiny_nm:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier_no_mapping.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-lg:spy -logfile ./out/adult/tiny_nm.log\
		-p 8\
		-d 2
	
	# spy
	~/legion/tools/legion_spy.py -d -e ./out/adult/tiny_nm.log

p_adult_medium:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/adult/adult_train_medium.tsv\
		-test ../data/adult/adult_test_medium.tsv\
		-p 4\
		-d 8
		#-lg:spy -logfile ./out/adult/medium.log\
	
	# spy
	#~/legion/tools/legion_spy.py -d -e ./out/adult/medium.log


adult_medium:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train_medium.tsv\
		-test ../data/adult/adult_test_medium.tsv\
		-d 8
		#-lg:spy -logfile ./out/adult/seq_medium.log\
	# spy
	#~/legion/tools/legion_spy.py -d -e ./out/adult/seq_medium.log

adult_tiny:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 3

adult_small:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train_small.tsv\
		-test ../data/adult/adult_test_small.tsv\
		-d 1

p_iris:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/iris/iris_train.tsv\
		-test ../data/iris/iris_test.tsv\
		-d 5
iris:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/iris/iris_train.tsv\
		-test ../data/iris/iris_test.tsv\
		-d 2

p_adult:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train.tsv\
		-test ../data/adult/adult_test.tsv\
		-lg:spy -logfile ./out/adult/large.log\
		-p 8\
		-d 4
	
	# spy
	~/legion/tools/legion_spy.py -d -e ./out/adult/large.log

adult:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train.tsv\
		-test ../data/adult/adult_test.tsv\
		-lg:spy -logfile ./out/adult/seq_large.log\
		-d 4
	# spy
	#~/legion/tools/legion_spy.py -d -e ./out/adult/seq_large.log

adult_10:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train_10_fold.tsv\
		-test ../data/adult/adult_test_10_fold.tsv\
		-lg:spy -logfile ./out/adult/seq_large.log\
		-d 4
	 spy
	~/legion/tools/legion_spy.py -d -e ./out/adult/seq_large.log

clear:
	rm run_pbs.sh.o*
	rm run_pbs.sh.e*
