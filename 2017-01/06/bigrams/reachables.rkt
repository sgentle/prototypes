#lang racket

(require racket/format)

(define wordfile "count_2w.txt")

; The internet is a wonderful place
(define blacklist-data
  '("<S> posted"
    "<S> free"
    "<S> but"
    "<S> on"
    "<S> of"
    "ass"
    "pussy"
    "mouth"
    "sex"
    "porn"
    "xxx"
    "cock"
    "cocks"
    "incest"
    "cum"
    "cumming"
    "rape"
    "anal"
    "squirting"
    "dildo"
    "orgy"
    "bondage"
    "milf"
    "threesome"
    "fucking"
    "hentai"
    "sexcam"
    "webcame"
    "masterbating"
    "masturbating"
    "twinks"
    "fuck"
    "fucker"
    "zoophilia"
    "bestiality"
    "beastality"
    "beastiality"
    "interracial"
    "bukkake"
    "blowjob"
    "blowjobs"
    "cumshot"
    "cumshots"
    ))

(define blacklist (for/hash ([b blacklist-data]) (values b '())))

(define (blacklisted word1 word2)
  (or
   (and (= 1 (string-length word2)) (not (equal? word2 "a")) (not (equal? word2 "i")))
   (hash-has-key? blacklist (~a word1 " " word2))
   (hash-has-key? blacklist word2)))

(define bigramhash
  (call-with-input-file wordfile
    (lambda (in)
      (define hash (make-hash))
      (for ([line (in-lines in)])
        (define word1 (car (string-split line)))
        (define word2 (cadr (string-split line)))
        (define count (string->number (caddr (string-split line))))

        (unless (blacklisted word1 word2)
          (hash-set! hash word1
                     (cons (cons word2 count) (hash-ref hash word1 '())))))
      hash)))

(define (build26 inhash outhash word1)
  (unless (hash-has-key? outhash word1)
    (define words (sort (hash-ref inhash word1 '()) #:key cdr >))
    (for ([wordcount words] [i (in-naturals)] #:break (= i 26))
      (hash-set! outhash word1
                 (cons wordcount (hash-ref outhash word1 '())))
      (build26 inhash outhash (car wordcount)))))
  
(define (walk26 inhash)
  (define outhash (make-hash))
  (build26 inhash outhash "<S>")
  outhash)

(define walked (walk26 bigramhash))

(define (unpair p) (values (car p) (cdr p)))

(for ([word1words (sort (hash->list walked) #:key car string<?)])
  (define-values (word1 words) (unpair word1words))
  (for ([word2count (reverse words)])
    (define-values (word2 count) (unpair word2count))
    (printf "~a\t~a\t~a\n" word1 word2 count)))