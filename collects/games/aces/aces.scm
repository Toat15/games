#|

possible to disable dragging but still allow double-clicking?
possible to remap single click (instead of double click)?

|#

(require-library "cards.ss" "games" "cards")
(require-library "function.ss")

(invoke-unit/sig
 (unit/sig ()
   (import cards^
	   mred^
	   mzlib:function^)

   (define table (make-table "Aces" 6 5))
   (make-object button% "Help" table
		(let ([show-help
		       ((require-library "show-help.ss" "games")
			(list "games" "aces")
			"Aces Help")])
		  (lambda x
		    (show-help))))

   (define deck null)
   (define draw-pile null)

   (define card-height (send (car (make-deck)) card-height))
   (define region-width (send (car (make-deck)) card-width))
   (define region-height (send table table-height))

   (define-struct stack (x y cards))

   (define (get-x-offset n)
     (+ (quotient region-width 2)
	(* n region-width)))

   (define draw-pile-region
     (make-button-region 
      (get-x-offset 0)
      0
      region-width
      card-height
      #f
      #f))

   (define stacks
     (list
      (make-stack
       (get-x-offset 1) 
       0
       null)
      (make-stack
       (get-x-offset 2)
       0
       null)
      (make-stack
       (get-x-offset 3) 
       0
       null)
      (make-stack
       (get-x-offset 4)
       0
       null)))

   (define (position-cards stack)
     (let ([m (length (stack-cards stack))])
       (lambda (i)
	 (values 0
		 (if (= m 0)
		     0
		     (* (- m i 1) 30))))))

   (define (reset-game)
     (send table remove-cards deck)

     (let ([set-stack
	    (lambda (which)
	      (set-stack-cards! (which stacks) (list (which deck))))])
       (set! deck (shuffle-list (make-deck) 7))
       (set! draw-pile (cddddr deck))
       (set-stack car)
       (set-stack cadr)
       (set-stack caddr)
       (set-stack cadddr))

     (for-each
      (lambda (stack)
	(send table add-cards
	      (stack-cards stack)
	      (stack-x stack)
	      (stack-y stack)
	      (position-cards stack))
	(for-each
	 (lambda (card) (send card flip))
	 (stack-cards stack)))
      stacks)

     (send table add-cards-to-region draw-pile draw-pile-region)

     (for-each (lambda (card) 
		 ;;(send card user-can-move #f)
		 (send card user-can-flip #f))
	       deck))

   (define (handle-draw)
     (unless (null? draw-pile)
       (let ([move-one
	      (lambda (select)
		(let ([stack (select stacks)]
		      [card (select draw-pile)])
		  (set-stack-cards! stack
				    (cons card (stack-cards stack)))
		  (send table card-to-front card)
		  (send table flip-card card)
		  (send table move-cards 
			(stack-cards stack)
			(stack-x stack)
			(stack-y stack)
			(position-cards stack))))])
	 (move-one car)
	 (move-one cadr)
	 (move-one caddr)
	 (move-one cadddr)
	 (set! draw-pile (cddddr draw-pile)))))

   (send table set-single-click-action
	 (lambda (card)
	   (cond
	    [(send card face-down?) (handle-draw)]
	    [else 
	     (let ([bottom-four
		    (let loop ([l stacks])
		      (cond
		       [(null? l) null]
		       [else (let ([stack (car l)])
			       (if (null? (stack-cards stack))
				   (loop (cdr l))
				   (cons (car (stack-cards stack))
					 (loop (cdr l)))))]))])
	       (when (memq card bottom-four)
		 (cond
		  [(ormap (lambda (bottom-card)
			    (and (eq? (send card get-suit)
				      (send bottom-card get-suit))
				 (or 
				  (and (not (= 1 (send card get-value)))
				       (= 1 (send bottom-card get-value)))
				  (and (not (= 1 (send card get-value)))
				       (< (send card get-value)
					  (send bottom-card get-value))))))
			  bottom-four)
		   (remove-card card)]
		  [else (let loop ([stacks stacks])
			  (cond
			   [(null? stacks) (void)]
			   [else (let ([stack (car stacks)])
				   (if (null? (stack-cards stack))
				       (begin
					 (send table move-cards 
					       (list card)
					       (stack-x stack)
					       (stack-y stack)
					       (position-cards stack))
					 (remove-card-from-stacks card)
					 (set-stack-cards! 
					  stack
					  (cons card (stack-cards stack))))
				       (loop (cdr stacks))))]))])))])
	   (check-game-over)))

   (define (game-over?)
     (and (null? draw-pile)
	  (let ([suits
		 (map (lambda (x) (send (car (stack-cards x)) get-suit))
		      stacks)])
	    (and (memq 'clubs suits)
		 (memq 'diamonds suits)
		 (memq 'hearts suits)
		 (memq 'spades suits)))))

   (define (check-game-over)
     (when (game-over?)
       (case (message-box "Aces"
			  "Game Over. Play again?"
			  table
			  '(yes-no))
	 [(yes) (reset-game)]
	 [(no) (send table show #f)])))

   (define (remove-card card)
     (send table remove-card card)
     (remove-card-from-stacks card))

   (define (remove-card-from-stacks card)
     (let ([old-cards (map stack-cards stacks)])
       (for-each
	(lambda (stack)
	  (set-stack-cards! stack (remq card (stack-cards stack))))
	stacks)
       (for-each (lambda (stack old-cards)
		   (unless (equal? (stack-cards stack) old-cards)
		     (send table move-cards 
			   (stack-cards stack)
			   (stack-x stack)
			   (stack-y stack)
			   (position-cards stack))))
		 stacks
		 old-cards)))
   
   (send table add-region draw-pile-region)
   (reset-game)

   (send table show #t))
 cards^
 mred^
 mzlib:function^)