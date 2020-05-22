(define-non-fungible-token pst uint)

(define-map meta ((token uint)) ((value uint)))
(define-map resellers ((token uint)) ((owners  (list 3 ((owner principal) (price uint)))))
(define-map offers ((token uint) (owner principal)) ((buyer principal) (price uint)))))

(define-public (create-asset (hash uint) (value uint))
  (match (nft-mint? pst hash tx-sender)
    success  (begin
      (map-insert meta ((token hash)) ((value value)))
    )
    error (err error)
  )
)

(define-public (eib (hash uint) (price uint))
  (ok true)
)

(define-public (sell (hash uint) (value uint) (receiver principal) (price uint))

)

(define-trait tradable ((transfer? () (response bool))))
(impl-trait .profit-sharing-token.tradable)
