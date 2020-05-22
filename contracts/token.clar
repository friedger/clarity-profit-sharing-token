(define-non-fungible-token pst (buff 32))
(define-fungible-token usdt)

(define-map meta ((token (buff 32))) ((value uint) (remaining uint)))
(define-map prev-owners ((token (buff 32)))
  ((owner  principal) (prev-token (buff 32)) (price uint)))
(define-map offers ((token (buff 32))) ((buyer principal) (value uint) (price uint)))

;; creates a new token
(define-public (create-asset (hash (buff 32)) (value uint))
  (match (nft-mint? pst hash tx-sender)
    success  (begin
      (ok (map-insert meta ((token hash)) ((value value) (remaining value))))
    )
    error (err error)
  )
)

;; creates an offer for a token
;; referres to an existing token
;; tx-sender: buyer
(define-public (ei-buying (hash uint) (price uint))
  (ft-mint? usdt price tx-sender)
)

;; executes an offer
;; referres to an existing offer
;; tx-sender: seller
(define-public (sell (hash (buff 32)) (recipient principal) (price uint))
  (match (nft-transfer? pst hash tx-sender recipient)
    success (begin
        (map-insert prev-owners ((token hash)) ((owner tx-sender) (prev-token hash) (price price)))
        (ok success)
      )
    error (err error)
  )
)


;; creates an offer for a part of a token
;; referres to an existing token
;; tx-sender: re-buyer
(define-public (ei-part-buying (hash uint) (value uint) (price uint))
  (ok true)
)

(define-private (share-profit (prev-owner {owner: principal, prev-token: (buff 32), price: uint})
                  (token-meta {value: uint, remaining: uint})
                  (value uint) (price uint))
  (let ((prev-price (get price prev-owner)))
    (let ((profit (- price (/ (* prev-price value) (get value token-meta)))))
      (let ((shared-profit (/ profit u2 )))
        (stx-transfer? shared-profit tx-sender (get owner prev-owner))
      )
    )
  )
)

;; creates a new token with a part of the inital token
;; tx-sender: first token buyer
(define-public (re-sell (hash (buff 32)) (value uint)  (value-as-buff (buff 20)) (recipient principal) (price uint))
  (let ((new-hash (sha512/256 (concat hash value-as-buff)))
    (token-meta (unwrap! (map-get? meta ((token hash))) (err u1)))
    (prev-owner (unwrap! (map-get? prev-owners ((token hash))) (err u2)))
    )
    (if (>= (get remaining token-meta) value)
      (begin
        (create-asset new-hash value)
        (sell new-hash recipient price)
        (map-set meta ((token hash)) ((value (get value token-meta)) (remaining (- (get remaining token-meta) value))))
        (share-profit prev-owner token-meta value price)
        (ok true)
      )
      (err u2)
    )
  )
)
