
p_adult_tiny:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 3\
		-p 8

adult_tiny_no_map:
	clear
	~/legion/language/regent.py ./decision_tree_classifier_no_mapping.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 2

p_adult_medium:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/adult/adult_train_medium.tsv\
		-test ../data/adult/adult_test_medium.tsv\
		-p 8\
		-d 5

adult_medium:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train_medium.tsv\
		-test ../data/adult/adult_test_medium.tsv\
		-d 5

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
		-p 8\
		-d 4

adult:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train.tsv\
		-test ../data/adult/adult_test.tsv\
		-d 4
