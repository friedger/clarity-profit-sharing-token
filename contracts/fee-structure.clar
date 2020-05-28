
;; `fee-structure` defines the fee structure of the `token` contract functions.
;;  Fees are paid in `holdng` tokens and are sold by the platform maintainers.
(define-fungible-token hodlng)

(define-constant err-cannot-sell u10)

;; Sell 10000 hodlng tokens to sender
;; `sell` function is part of the business model
;; and will be protected by a check for the tx-sender
;; then it can only be used by the platform maintainer
;; For simplicity of testing, all users are maintainers

;; Returns true if the tx-sender is maintainer of the platform
(define-private (can-sender-sell)
  true
)

;; Returns Response<bool uint>
(define-public (sell (principal principal))
  (if (can-sender-sell)
    (ft-mint? hodlng u10000 principal)
    (err err-cannot-sell)
  )
)

;; Pay a fixed fee of 1000 holdng.
;;
;; Returns Response<bool uint>
(define-public (pay-fixed-fee)
  (ft-transfer? hodlng u1000 tx-sender (as-contract tx-sender))
)

;; Pay a variable fee depending on the price of the token and the value that was bought.
;; The fee is 10% of the price on the first sale.
;; Resellers have to pay a reduced fee.
;;
;; Returns Response<bool uint>
(define-public (pay-variable-fee (price uint) (value uint) (initial-value uint))
  (let ((amount (/ (* price value) initial-value)) )
    (let ((fees (if (> amount u10000) u1000 (/ amount u10))))
      (ft-transfer? hodlng fees tx-sender (as-contract tx-sender))
    )
  )
)

