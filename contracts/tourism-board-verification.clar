;; Tourism Board Verification Contract
;; Validates and manages destination management organizations

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_VERIFIED (err u101))
(define-constant ERR_NOT_FOUND (err u102))

;; Data structures
(define-map verified-boards
  { board-id: uint }
  {
    name: (string-ascii 100),
    location: (string-ascii 100),
    verified-at: uint,
    status: (string-ascii 20)
  }
)

(define-map board-permissions
  { board-id: uint }
  { can-allocate-resources: bool, can-track-visitors: bool }
)

(define-data-var next-board-id uint u1)

;; Public functions
(define-public (register-tourism-board (name (string-ascii 100)) (location (string-ascii 100)))
  (let ((board-id (var-get next-board-id)))
    (map-set verified-boards
      { board-id: board-id }
      {
        name: name,
        location: location,
        verified-at: block-height,
        status: "pending"
      }
    )
    (var-set next-board-id (+ board-id u1))
    (ok board-id)
  )
)

(define-public (verify-board (board-id uint))
  (if (is-eq tx-sender CONTRACT_OWNER)
    (match (map-get? verified-boards { board-id: board-id })
      board-data
      (begin
        (map-set verified-boards
          { board-id: board-id }
          (merge board-data { status: "verified" })
        )
        (map-set board-permissions
          { board-id: board-id }
          { can-allocate-resources: true, can-track-visitors: true }
        )
        (ok true)
      )
      ERR_NOT_FOUND
    )
    ERR_UNAUTHORIZED
  )
)

;; Read-only functions
(define-read-only (get-board-info (board-id uint))
  (map-get? verified-boards { board-id: board-id })
)

(define-read-only (is-board-verified (board-id uint))
  (match (map-get? verified-boards { board-id: board-id })
    board-data (is-eq (get status board-data) "verified")
    false
  )
)

(define-read-only (get-board-permissions (board-id uint))
  (map-get? board-permissions { board-id: board-id })
)
