(module test-model mzscheme
  (require (lib "unitsig.ss")
	   (lib "etc.ss")
	   "sig.ss"
	   "model.ss")

  (define failed? #f)

  (define-syntax test
    (syntax-rules ()
      [(_ expect expr)
       (begin
	 (printf "~s =>" 'expr)
	 (flush-output)
	 (let ([v expr]
	       [ex expect])
	   (printf " ~s" v)
	   (unless (equal? v ex)
	     (set! failed? #t)
	     (printf " EXPECTED ~s" ex))
	   (printf "~n")))]))

  (define (basic-tests size xform 4x4-finish-pos)
    ;; When xform is the identity, then we build toward
    ;;  _ _ Y -    _ = empty
    ;;  _ Y _ -    - = optional (3x3 vs 4x4)
    ;;  y R R -
    ;;  - - - -
    ;; The xform changes the cooridnate system so that we
    ;; test rows and columns in addition to this diagonal.
    (begin-with-definitions
     (define BOARD-SIZE size)

     (define-values (i00 j00) (xform 0 0))
     (define-values (i11 j11) (xform 1 1))
     (define-values (i22 j22) (xform 2 2))
     (define-values (i12 j12) (xform 1 2))
     (define-values (i02 j02) (xform 0 2))
     (define-values (i20 j20) (xform 2 0))

     (define-values/invoke-unit/sig model^
       model-unit #f config^)

     ;; Empty board --------------------
     (define b empty-board)

     (test null (board-ref b i00 j00))
     (test null (board-ref b i22 j22))

     (test #f (winner? b 'red))
     (test #f (winner? b 'yellow))

     (define big-red (list-ref red-pieces 2))
     (define big-yellow (list-ref yellow-pieces 2))
     (define med-red (list-ref red-pieces 1))
     (define med-yellow (list-ref yellow-pieces 1))
     (define small-yellow (list-ref yellow-pieces 0))

     ;; Big red --------------------

     (define b1 (move b big-red #f #f i00 j00 values void))
     (test (list big-red) (board-ref b1 i00 j00))
     (test (void) (move b1 big-yellow #f #f i00 j00 values void))

     (test #f (winner? b1 'red))
     (test #f (winner? b1 'yellow))

     ;; Big red, big yellow --------------------

     (define b2 (move b1 big-yellow #f #f i11 j11 values void))
     (test (list big-red) (board-ref b2 i00 j00))
     (test (list big-yellow) (board-ref b2 i11 j11))

     (test #f (winner? b2 'red))
     (test #f (winner? b2 'yellow))

     (test (void) (move b2 big-red #f #f i11 j11 values void))
     (test (void) (move b2 big-red i00 j00 i11 j11 values void))

     ;; Big red moved, big yellow --------------------

     (define b3 (move b2 big-red i00 j00 i22 j22 values void))
     (test null (board-ref b3 i00 j00))
     (test (list big-yellow) (board-ref b3 i11 j11))
     (test (list big-red) (board-ref b3 i22 j22))

     (test #f (winner? b3 'red))
     (test #f (winner? b3 'yellow))

     ;; Big red, big yellow, med yellow --------------------

     (define b4 (move b3 med-yellow #f #f i02 j02 values void))
     (test (list big-yellow) (board-ref b4 i11 j11))
     (test (list big-red) (board-ref b4 i22 j22))
     (test (list med-yellow) (board-ref b4 i02 j02))

     (test #f (winner? b4 'red))
     (test #f (winner? b4 'yellow))

     (test (void) (move b4 med-red #f #f i02 j02 values void))
     
     ;; Big red gobble med yellow, big yellow --------------------
     ;;  --- Add big red
     (define b5.1 (move b4 big-red #f #f i02 j02 values void))
     (when (= size 4)
       ;; can't gobble yellow, since it's not in a 3-in-arow
       (test (void) b5.1) 
       ;; Generate board by cheating, giving red two turns...
       (set! b5.1 (move (move b4 big-red i22 j22 i02 j02 values void)
			big-red #f #f i22 j22 values void)))
     (test (list big-yellow) (board-ref b5.1 i11 j11))
     (test (list big-red) (board-ref b5.1 i22 j22))
     (test (list big-red med-yellow) (board-ref b5.1 i02 j02))

     ;;  --- Move big red
     (define b5.2 (move b4 big-red i22 j22 i02 j02 values void))
     (test (list big-yellow) (board-ref b5.2 i11 j11))
     (test null (board-ref b5.2 i22 j22))
     (test (list big-red med-yellow) (board-ref b5.2 i02 j02))

     ;; Add small yellow ------------------------------
     ;;  --- with 2 big red
     (define b6.1 (move b5.1 small-yellow #f #f i20 j20 values void))
     (test (list big-yellow) (board-ref b6.1 i11 j11))
     (test (list big-red) (board-ref b6.1 i22 j22))
     (test (list big-red med-yellow) (board-ref b6.1 i02 j02))
     (test (list small-yellow) (board-ref b6.1 i20 j20))

     (test #f (winner? b6.1 'red))
     (test #f (winner? b6.1 'yellow))

     ;;  --- with 1 big red
     (define b6.2 (move b5.2 small-yellow #f #f i20 j20 values void))
     (test (list big-yellow) (board-ref b6.2 i11 j11))
     (test null (board-ref b6.2 i22 j22))
     (test (list big-red med-yellow) (board-ref b6.2 i02 j02))
     (test (list small-yellow) (board-ref b6.2 i20 j20))

     (test #f (winner? b6.2 'red))
     (test #f (winner? b6.2 'yellow))

     ;; Expose med yellow for 3-in-row ----------
     (define b7.1 (move b6.1 big-red i02 j02 i12 j12 values void))
     (test (list big-yellow) (board-ref b7.1 i11 j11))
     (test (list big-red) (board-ref b7.1 i22 j22))
     (test (list med-yellow) (board-ref b7.1 i02 j02))
     (test (list small-yellow) (board-ref b7.1 i20 j20))
     (test (list big-red) (board-ref b7.1 i12 j12))

     (test #f (winner? b7.1 'red))
     (test (= size 3) (winner? b7.1 'yellow))

     (define b7.2 (move b6.2 big-red i02 j02 i12 j12 values void))
     (test (list big-yellow) (board-ref b7.2 i11 j11))
     (test null (board-ref b7.2 i22 j22))
     (test (list med-yellow) (board-ref b7.2 i02 j02))
     (test (list small-yellow) (board-ref b7.2 i20 j20))
     (test (list big-red) (board-ref b7.2 i12 j12))

     (test #f (winner? b7.2 'red))
     (test (= size 3) (winner? b7.2 'yellow))

     (when (and (= size 4)
		4x4-finish-pos)
       ;; 4 x 4 game: now red can cover small yellow, because it's
       ;; part of 3 in a row
       (begin-with-definitions
	(test #t (3-in-a-row? b7.2 i20 j20 'yellow))
	(test #f (3-in-a-row? b7.2 i20 j20 'red))

	(define b8.2 (move b7.2 med-red #f #f i20 j20 values void))
	(test (list big-yellow) (board-ref b8.2 i11 j11))
	(test null (board-ref b8.2 i22 j22))
	(test (list med-yellow) (board-ref b8.2 i02 j02))
	(test (list med-red small-yellow) (board-ref b8.2 i20 j20))
	(test (list big-red) (board-ref b8.2 i12 j12))

	(test #f (winner? b8.2 'red))
	(test #f (winner? b8.2 'yellow))

	(define b8.2x (move b7.2 med-yellow #f #f (car 4x4-finish-pos) (cdr 4x4-finish-pos) values void))
	(test #f (winner? b8.2x 'red))
	(test #t (winner? b8.2x 'yellow))))))
	
  (define (rotate i j)
    (case i
      [(0) (case j
	     [(0) (values 1 0)]
	     [(1) (values 0 0)]
	     [(2) (values 0 1)])]
      [(1) (case j
	     [(0) (values 2 0)]
	     [(1) (values 1 1)]
	     [(2) (values 0 2)])]
      [(2) (case j
	     [(0) (values 2 1)]
	     [(1) (values 2 2)]
	     [(2) (values 1 2)])]
      [else (values i j)]))

  (map (lambda (xform+?)
	 (basic-tests 3 ((cdr xform+?) 3) (car xform+?))
	 (basic-tests 4 ((cdr xform+?) 4) (car xform+?)))
       (list (cons #f (lambda (sz) (lambda (i j) (values i j))))
	     (cons #f (lambda (sz) (lambda (i j) (values j i))))
	     (cons #f (lambda (sz) (lambda (i j) (values i (- sz 1 j)))))
	     (cons '(3 . 1) (lambda (sz) (lambda (i j) (rotate i j))))
	     (cons '(1 . 3) (lambda (sz) (lambda (i j) (rotate i (- 3 1 j)))))))

  ;; Extra tests for 4 x 4 to get yellow 3-in-a-row on diagonals:
  (basic-tests 4 (lambda (i j) (values i (+ j 1))) '(3 . 0))
  (basic-tests 4 (lambda (i j) (values i (- 3 (+ j 1)))) '(3 . 3))

  (printf (if failed?
	      "~nTESTS FAILED~n"
	      "~nAll tests passed.~n")))

	