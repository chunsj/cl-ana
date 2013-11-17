;;;; typed-table.lisp

(in-package :typed-table)

(defclass typed-table (table)
  ((column-specs
    :initarg :column-specs
    :initform ()
    :accessor typed-table-column-specs
    :documentation "list of typespecs, one per column")))

(defun typespec->column-names (compound-typespec)
  "Returns column names from the compound type designation."
  (if (typespec-compound-p compound-typespec)
      (mapcar #'car (rest compound-typespec))
      (error "Non compound type given to typespec->column-names")))

(defun typespec->column-specs (compound-typespec)
  "Returns column typespecs from the compound type designation."
  (if (typespec-compound-p compound-typespec)
      (mapcar #'cdr (rest compound-typespec))
      (error "Non compound type given to typespec->column-specs")))

(defun typed-table->typespec (table)
  "Creates a typespec from the table"
  (append (list :compound)
	  (zip (table-column-names table)
		   (typed-table-column-specs table))))

(defun keywordify (symbol)
  (intern
   (string symbol)
   (package-name :keyword)))

(defmacro do-typed-table ((rowvar table &optional (mark "/"))
			  &body body)
  "Macro for providing table loop like dotable, but where column
values are automatically converted into LISP types."
  (with-gensyms (read-status column-type-map symbol-specs keywordify)
    (let* ((marked-column-symbols
	    (table::collect-marked-symbols body mark))
	   (unmarked-column-symbols
	    (mapcar
	     #'(lambda (x) (table::unmark-symbol x mark))
	     marked-column-symbols))
	   (marked-symbol-bindings
	    (loop
	       for m in marked-column-symbols
	       for u in unmarked-column-symbols
	       collecting `(,m (table-get-field ,table ',u))))
	   (quoted-unmarked-column-symbols
	    (mapcar
	     #'(lambda (x)
		 `(quote ,x))
	     unmarked-column-symbols))
	   (quoted-marked-column-symbols
	    (mapcar
	     #'(lambda (x)
		 `(quote ,x))
	     marked-column-symbols))
	   (conversion-bindings
	    (loop
	       for m in marked-column-symbols
	       collecting `(,m
			    (convert-from-foreign
			     ,m
			     (gethash ,(typed-table::keywordify m)
				      ,column-type-map))))))
      ;; I've thought about dynamically (with memoization)
      ;; generating structures instead of using a hash table,
      ;; we'll see if there is a performance hit first
      `(let ((,column-type-map (make-hash-table :test 'equal))
	     (,symbol-specs
	      (zip (mapcar #'keywordify (table-column-symbols ,table))
		   (typed-table-column-specs ,table))))
	   (loop
	      for m in (list ,@quoted-marked-column-symbols)
	      for u in (list ,@quoted-unmarked-column-symbols)
	      do (setf (gethash (typed-table::keywordify m) ,column-type-map)
		       (typespec-flatten-arrays
			(typespec->cffi-type
			 (cdr
			  (assoc (keywordify u) ,symbol-specs))))))
	   (do ((,read-status
		 (table-load-next-row ,table)
		 (table-load-next-row ,table))
		(,rowvar 0 (1+ ,rowvar)))
	       ((not ,read-status))
	     (let ,marked-symbol-bindings
	       (let ,conversion-bindings
		 ,@body)))))))