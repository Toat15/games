(let ([pred (lambda (x) (void? x))]
      [old-load-framework-automatically? (load-framework-automatically)])

  (load-framework-automatically #f)

  (test
   'guiutilss.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "guiutilss.ss" "framework")
      (global-defined-value 'framework:gui-utils^)
      (void)))
  
  (test
   'guiutils.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "guiutils.ss" "framework")
      (global-defined-value 'gui-utils:read-snips/chars-from-text)
      (void)))

  (test
   'guiutilsr.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "guiutilss.ss" "framework")
      (eval
       '(invoke-unit/sig
         (compound-unit/sig
           (import)
           (link [m : mred^ (mred@)]
                 [g : framework:gui-utils^ ((require-library "guiutilsr.ss" "framework") m)])
           (export))))
      (void)))

  
  (test
   'macro.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "macro.ss" "framework")
      (global-defined-value 'mixin)
      (void)))
  (test
   'tests.ss
   (lambda (x) x)
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "tests.ss" "framework")
      (unit/sig? (require-library "keys.ss" "framework"))))
  (test
   'testr.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "tests.ss" "framework")
      (eval
       '(define-values/invoke-unit/sig
         ((unit test : framework:test^))
	 (compound-unit/sig
	   (import)
	   (link [mred : mred^ (mred@)]
		 [keys : framework:keys^ ((require-library "keys.ss" "framework"))]
		 [test : framework:test^ ((require-library "testr.ss" "framework") mred keys)])
	   (export (unit test)))))
      (global-defined-value 'test:run-one)
      (global-defined-value 'test:button-push)
      (void)))
  (test
   'test.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "test.ss" "framework")
      (global-defined-value 'test:run-one)
      (global-defined-value 'test:button-push)
      (void)))

  (test
   'frameworkp.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "frameworks.ss" "framework")
      (require-library "file.ss")
      (eval
       '(define-values/invoke-unit/sig
	  framework^
	  (compound-unit/sig
	    (import)
	    (link [mred : mred^ (mred@)]
		  [core : mzlib:core^ ((require-library "corer.ss"))]
		  [pf : framework:prefs-file^
		      ((let ([tf (make-temporary-file)])
			 (unit/sig framework:prefs-file^ (import)
				   (define preferences-filename tf))))]
		  [framework : framework^ ((require-library "frameworkp.ss" "framework")
					   core mred pf)])
	    (export (open framework)))))
      (global-defined-value 'preferences:get)
      (void)))

  (test
   'frameworkr.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "frameworks.ss" "framework")
      (eval
       '(define-values/invoke-unit/sig
         framework^
	 (compound-unit/sig
	   (import)
	   (link [mred : mred^ (mred@)]
		 [core : mzlib:core^ ((require-library "corer.ss"))]
		 [framework : framework^ ((require-library "frameworkr.ss" "framework") core mred)])
	   (export (open framework)))))
      (global-defined-value 'test:run-one)
      (global-defined-value 'test:button-push)
      (global-defined-value 'frame:basic-mixin)
      (global-defined-value 'editor:basic-mixin)
      (global-defined-value 'exit:exit)
      (void)))
  (test
   'framework.ss
   pred
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "framework.ss" "framework")
      (global-defined-value 'test:run-one)
      (global-defined-value 'test:button-push)
      (global-defined-value 'frame:basic-mixin)
      (global-defined-value 'editor:basic-mixin)
      (global-defined-value 'exit:exit)
      (void)))
  (test
   'framework.ss/gen
   (lambda (x) x)
   '(parameterize ([current-namespace (make-namespace 'mred)])
      (require-library "pretty.ss")
      (let* ([op ((global-defined-value 'pretty-print-print-line))]
	     [np  (lambda x (apply op x))])
	((global-defined-value 'pretty-print-print-line) np)
	(require-library "framework.ss" "framework")
	(eq? np ((global-defined-value 'pretty-print-print-line))))))

  (load-framework-automatically old-load-framework-automatically?))
