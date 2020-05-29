;; Profit Sharing Tokens (pst) represent tokens with a dividable value
;; Owners of a pst can sell the whole or parts of a pst
;; A pst is identified by a hash (that is calculated from some meta data off-chain)
;;
;; `pst` tokens are sold using `usdt` tokens.
;; `usdt` tokens represent the amount of money that was made through sales of `pst` tokens

(define-non-fungible-token pst (buff 32))
(define-fungible-token usdt)

(define-constant err-token-exists u20)
(define-constant err-token-does-not-exist u21)
(define-constant err-token-sold u22)
(define-constant err-token-not-sold u23)
(define-constant err-token-called u24)
(define-constant err-token-not-called u25)
(define-constant err-not-enough-value u26)
(define-constant err-fee-payment u27)
(define-constant err-payment u28)

;; storage
;; meta contains the initial value parts of a pst and the remaining value parts
(define-map meta ((token (buff 32))) ((value uint) (remaining uint)))
;; prev-owners contains the owner of the original pst with the reference to the original hash and price
(define-map prev-owners ((token (buff 32)))
  ((owner  principal) (prev-token (buff 32)) (price uint)))
;; calls contains details about interests in buying a pst
;; index 0 always defines the sale of the whole pst
(define-map calls ((token (buff 32)) (index uint)) ((buyer principal) (value uint) (price uint)))
(define-map next-call-index ((token (buff 32))) ((index uint)))

;; Creates a new token representing a value that can be divided into `value` parts.
;; Creating this token comes with a costs defined in the fee-structure contract
;; tx-sender: seller/exporter
;; Returns Response<bool, uint>
(define-public (create-asset (hash (buff 32)) (value uint))
  (match (nft-mint? pst hash tx-sender)
    success  (begin
      (unwrap! (contract-call? .fee-structure pay-fixed-fee) (err err-fee-payment))
      (if (map-insert meta ((token hash)) ((value value) (remaining value)))
        (ok true)
        (err err-token-exists)
      )
    )
    error (err error)
  )
)

;; Express interest of buying, creates a call for a whole token
;; referres to an existing token
;; tx-sender: buyer
;; Returns Response<bool, uint>
(define-public (ei-buying (hash (buff 32)) (price uint))
  (match (map-get? meta ((token hash)))
    meta-token
    (begin
      (unwrap! (contract-call? .fee-structure pay-variable-fee price (get value meta-token) (get value meta-token)) (err err-fee-payment))
      (unwrap! (ft-mint? usdt price tx-sender) (err err-payment))
      (unwrap! (ft-transfer? usdt price tx-sender (as-contract tx-sender)) (err err-payment))
      (if (map-insert calls ((token hash) (index u0)) ((buyer tx-sender) (value (get value meta-token)) (price price)))
        (ok true)
        (err err-token-called)
      )
    )
    (err err-token-does-not-exist)
  )
)

;; Executes a call for a whole token
;; referres to an existing call
;; tx-sender: seller
;; Returns Response<bool, uint>

(define-private (sell-for (hash (buff 32)) (buyer principal) (price uint))
  (let ((seller tx-sender))
    (match (nft-transfer? pst hash tx-sender buyer)
      success
          (if (map-insert prev-owners ((token hash)) ((owner tx-sender) (prev-token hash) (price price)))
            (as-contract (ft-transfer? usdt price tx-sender seller))
            (err err-token-sold)
          )
      error (err error)
    )
  )
)

;; pst can only be sold after a expressing intersted in buying
(define-public (sell (hash (buff 32)))
  (match (map-get? calls ((token hash) (index u0)))
    call
      (begin
        (contract-call? .fee-structure pay-fixed-fee)
        (sell-for hash (get buyer call) (get price call))
      )
    (err err-token-not-called)
  )
)

;; Express interest of buying, creates a call for a part of a token
;; referres to an existing token
;; tx-sender: re-buyer
;; Returns Response<bool, uint>
(define-public (ei-part-buying (hash (buff 32)) (value uint) (price uint))
   (match (map-get? meta ((token hash)))
    meta-token
      (begin
        (unwrap! (contract-call? .fee-structure pay-variable-fee price value (get value meta-token)) (err err-fee-payment))
        (unwrap! (ft-mint? usdt price tx-sender) (err err-payment))
        (unwrap! (ft-transfer? usdt price tx-sender (as-contract tx-sender)) (err err-payment))
        (if (map-insert calls ((token hash) (index u1)) ((buyer tx-sender) (value value) (price price)))
          (ok true)
          (err err-token-called)
        )

      )
    (err err-token-does-not-exist)
  )
)

(define-private (share-profit (prev-owner {owner: principal, prev-token: (buff 32), price: uint})
                  (token-meta {value: uint, remaining: uint})
                  (value uint) (price uint))
  (let ((prev-price (get price prev-owner)))
    (let ((profit (- price (/ (* prev-price value) (get value token-meta)))))
      (if (> profit u0)
        (let ((shared-profit (/ profit u2 )))
          (ft-transfer? usdt shared-profit tx-sender (get owner prev-owner))
        )
        (ok true)
      )
    )
  )
)

;; Executes a call for parts of a token
;; Creates a new token with a part of the inital token
;; the remaining value parts of the initial token is updates as well
;; tx-sender: first token buyer
;; Returns Response<bool, uint>
(define-private (re-sell-at (hash (buff 32)) (value-as-buff (buff 20)) (recipient principal) (value uint) (price uint))
  (let ((new-hash (calculate-new-hash hash value-as-buff))
    (token-meta (unwrap! (map-get? meta ((token hash))) (err err-token-does-not-exist)))
    (prev-owner (unwrap! (map-get? prev-owners ((token hash))) (err err-token-not-sold)))
    )
    (if (>= (get remaining token-meta) value)
      (begin
        (unwrap! (create-asset new-hash value) (err err-token-exists))
        (unwrap! (sell-for new-hash recipient price) (err err-payment))
        (if (map-set meta ((token hash)) ((value (get value token-meta)) (remaining (- (get remaining token-meta) value))))
          (share-profit prev-owner token-meta value price)
          (err err-token-exists)
        )
      )
      (err err-not-enough-value)
    )
  )
)

;; tokens can't be sold without a call
(define-public (re-sell (hash (buff 32)) (value-as-buff (buff 20)))
  (match (map-get? calls ((token hash) (index u1)))
    call (re-sell-at hash value-as-buff (get buyer call) (get value call) (get price call))
    (err err-token-not-called)
  )
)

;; check balances
(define-read-only (get-balance (principal principal))
  (ft-get-balance usdt principal)
)

(define-read-only (get-owner (hash (buff 32)))
  (nft-get-owner? pst hash)
)

;; calculate hash from previous token and part value
;; currently there is no way in Clarity to convert uint to buff
(define-read-only (calculate-new-hash (hash (buff 32)) (value-as-buff (buff 20)))
  (sha512/256 (concat hash value-as-buff))
)
