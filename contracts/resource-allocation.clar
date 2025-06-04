;; Resource Allocation Contract
;; Manages tourism resource distribution and allocation

(define-constant ERR_UNAUTHORIZED (err u300))
(define-constant ERR_INSUFFICIENT_RESOURCES (err u301))
(define-constant ERR_INVALID_ALLOCATION (err u302))

;; Data structures
(define-map resource-pools
  { destination-id: uint, resource-type: (string-ascii 30) }
  {
    total-capacity: uint,
    allocated: uint,
    available: uint,
    price-per-unit: uint
  }
)

(define-map allocation-requests
  { request-id: uint }
  {
    destination-id: uint,
    resource-type: (string-ascii 30),
    requested-amount: uint,
    requester: principal,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-data-var next-request-id uint u1)

;; Public functions
(define-public (create-resource-pool
  (destination-id uint)
  (resource-type (string-ascii 30))
  (total-capacity uint)
  (price-per-unit uint)
)
  (begin
    (map-set resource-pools
      { destination-id: destination-id, resource-type: resource-type }
      {
        total-capacity: total-capacity,
        allocated: u0,
        available: total-capacity,
        price-per-unit: price-per-unit
      }
    )
    (ok true)
  )
)

(define-public (request-resource-allocation
  (destination-id uint)
  (resource-type (string-ascii 30))
  (requested-amount uint)
)
  (let ((request-id (var-get next-request-id)))
    (map-set allocation-requests
      { request-id: request-id }
      {
        destination-id: destination-id,
        resource-type: resource-type,
        requested-amount: requested-amount,
        requester: tx-sender,
        status: "pending",
        created-at: block-height
      }
    )
    (var-set next-request-id (+ request-id u1))
    (ok request-id)
  )
)

(define-public (approve-allocation (request-id uint))
  (match (map-get? allocation-requests { request-id: request-id })
    request-data
    (let (
      (destination-id (get destination-id request-data))
      (resource-type (get resource-type request-data))
      (requested-amount (get requested-amount request-data))
      (current-pool (unwrap-panic (map-get? resource-pools
        { destination-id: destination-id, resource-type: resource-type })))
    )
      (if (>= (get available current-pool) requested-amount)
        (begin
          (map-set resource-pools
            { destination-id: destination-id, resource-type: resource-type }
            {
              total-capacity: (get total-capacity current-pool),
              allocated: (+ (get allocated current-pool) requested-amount),
              available: (- (get available current-pool) requested-amount),
              price-per-unit: (get price-per-unit current-pool)
            }
          )
          (map-set allocation-requests
            { request-id: request-id }
            (merge request-data { status: "approved" })
          )
          (ok true)
        )
        ERR_INSUFFICIENT_RESOURCES
      )
    )
    ERR_INVALID_ALLOCATION
  )
)

;; Read-only functions
(define-read-only (get-resource-pool (destination-id uint) (resource-type (string-ascii 30)))
  (map-get? resource-pools { destination-id: destination-id, resource-type: resource-type })
)

(define-read-only (get-allocation-request (request-id uint))
  (map-get? allocation-requests { request-id: request-id })
)

(define-read-only (calculate-allocation-cost (destination-id uint) (resource-type (string-ascii 30)) (amount uint))
  (match (map-get? resource-pools { destination-id: destination-id, resource-type: resource-type })
    pool-data (* (get price-per-unit pool-data) amount)
    u0
  )
)
