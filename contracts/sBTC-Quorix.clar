
;; sBTC-Quorix

;; ========== Constants ==========

;; Error codes
(define-constant ERR-TAG-EXISTS u100)
(define-constant ERR-NOT-PENDING u101) 
(define-constant ERR-INSUFFICIENT-FUNDS u102)
(define-constant ERR-NOT-FOUND u103)
(define-constant ERR-UNAUTHORIZED u104)
(define-constant ERR-EXPIRED u105)
(define-constant ERR-INVALID-AMOUNT u106)
(define-constant ERR-EMPTY-MEMO u107)
(define-constant ERR-MAX-EXPIRATION-EXCEEDED u108)

;; State constants
(define-constant STATE-PENDING "pending")
(define-constant STATE-PAID "paid")
(define-constant STATE-EXPIRED "expired")
(define-constant STATE-CANCELED "canceled")

;; Official sBTC token contract
(define-constant SBTC-CONTRACT 'ST1F7QA2MDF17S807EPA36TSS8AMEFY4KA9TVGWXT.sbtc-token)


;; Contract owner (for potential upgrades or admin functions)
(define-constant CONTRACT-OWNER tx-sender)

;; Maximum expiration time (30 days in blocks, assuming ~10 min per block)
(define-constant MAX-EXPIRATION-BLOCKS u4320) ;; ~30 days

;; ========== Data Maps ==========

;; Main map to store payment tags
(define-map pay-tags 
    {id : uint }
    { 
    creator: principal,
    recipient: principal,
    amount: uint,
    created-at: uint,
    expires-at: uint,
    memo: (optional (string-ascii 256)),
    state: (string-ascii 16),
    payment-tx: (optional (buff 32)) ;; txid when paid
    })


;; Index of tags by creator
(define-map tags-by-creator 
    { creator: principal } 
    { ids: (list 50 uint)
})

;; Index of tags by recipient
(define-map tags-by-recipient 
    { recipient: principal } 
    { ids: (list 50 uint)
})

;; ========== Variables ==========

;; Counter for auto-incrementing IDs
(define-data-var last-id uint u0)

;; ========== Internal Functions ==========
(define-private (add-id-to-principal-list (user principal) (id uint))
  (let (
    (current-list-data (default-to {ids: (list)} (map-get? tags-by-creator {creator: user})))
    (current-list (get ids current-list-data))
    (new-list (unwrap! (as-max-len? (append current-list id) u50) current-list))
  )
  (begin
    (map-set tags-by-creator {creator: user} {ids: new-list})
    new-list)))


;; Check if current block height is past the expiration
(define-private (is-expired (expires-at uint))
  (>= stacks-block-height expires-at))

;; ========== Read-Only Functions ==========

;; Get the current ID counter
(define-read-only (get-last-id)
  (ok (var-get last-id)))

;; Get details of a specific PayTag
(define-read-only (get-pay-tag (id uint))
  (match (map-get? pay-tags {id: id})
    entry (ok entry)
    (err ERR-NOT-FOUND)))

;; Get IDs of all tags created by a principal
(define-read-only (get-creator-tags (creator principal))
  (match (map-get? tags-by-creator {creator: creator})
    entry (ok (get ids entry))
    (ok (list))))

;; Get IDs of all tags where principal is recipient
(define-read-only (get-recipient-tags (recipient principal))
  (match (map-get? tags-by-recipient {recipient: recipient})
    entry (ok (get ids entry))
    (ok (list))))

;; Check if a tag is expired but not marked as expired yet
(define-read-only (check-tag-expired (id uint))
  (match (map-get? pay-tags {id: id})
    tag (if (and 
             (is-eq (get state tag) STATE-PENDING) 
             (is-expired (get expires-at tag)))
          (ok true)
          (ok false))
    (err ERR-NOT-FOUND)))


