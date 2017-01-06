#lang racket

(define wordfile "count_1w.txt")

(define get-initials
  (call-with-input-file wordfile
    (lambda (in)
      (define hash (make-hash))
      (for ([line (in-lines in)])
        (define word (car (string-split line)))
        (define count (string->number (cadr (string-split line))))
        (define char (string-ref word 0))
        
        (hash-set! hash char
          (+ count (hash-ref hash char 0))))
      hash)))

(define sorted-initials
 (sort (hash->list get-initials) #:key cdr >))

(for ([i sorted-initials])
  (printf "~a\t~a\n" (car i) (cdr i)))