
p_adult_tiny:
	clear
	~/legion/language/regent.py ./decision_tree_parallel_classifier.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 8\
		-p 8

adult_tiny:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train_tiny.tsv\
		-test ../data/adult/adult_test_tiny.tsv\
		-d 2

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

adult:
	clear
	~/legion/language/regent.py ./decision_tree_classifier.rg\
		-train ../data/adult/adult_train.tsv\
		-test ../data/adult/adult_test.tsv\
		-d 1
