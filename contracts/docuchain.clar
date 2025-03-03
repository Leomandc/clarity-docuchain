;; DocuChain - Document Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-doc-exists (err u101))
(define-constant err-doc-not-found (err u102))
(define-constant err-not-authorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-invalid-status (err u105))
(define-constant err-invalid-hash (err u106))

;; Data structures
(define-map documents
  { doc-hash: (buff 32) }
  {
    owner: principal,
    timestamp: uint,
    title: (string-ascii 64),
    description: (string-ascii 256),
    status: (string-ascii 16),
    version: uint
  }
)

(define-map document-history
  { doc-hash: (buff 32), version: uint }
  {
    timestamp: uint,
    updated-by: principal,
    status: (string-ascii 16),
    action: (string-ascii 16)
  }
)

;; Private functions
(define-private (validate-string (input (string-ascii 256)))
  (not (is-eq input "")))

(define-private (validate-hash (hash (buff 32)))
  (is-eq (len hash) u32))

(define-private (validate-status (status (string-ascii 16)))
  (or (is-eq status "ACTIVE")
      (is-eq status "INACTIVE")
      (is-eq status "EXPIRED")))

(define-private (get-next-version (doc-hash (buff 32)))
  (default-to u1
    (match (map-get? documents {doc-hash: doc-hash})
      doc (+ (get version doc) u1)
      u1)))

;; Public functions
(define-public (register-document 
  (doc-hash (buff 32))
  (title (string-ascii 64))
  (description (string-ascii 256)))
  (begin
    (asserts! (validate-hash doc-hash) err-invalid-hash)
    (asserts! (validate-string title) err-invalid-input)
    (asserts! (validate-string description) err-invalid-input)
    (let ((existing-doc (map-get? documents {doc-hash: doc-hash})))
      (if (is-some existing-doc)
        err-doc-exists
        (begin
          (map-set documents
            {doc-hash: doc-hash}
            {
              owner: tx-sender,
              timestamp: block-height,
              title: title,
              description: description,
              status: "ACTIVE",
              version: u1
            }
          )
          (map-set document-history
            {doc-hash: doc-hash, version: u1}
            {
              timestamp: block-height,
              updated-by: tx-sender,
              status: "ACTIVE",
              action: "REGISTERED"
            }
          )
          (ok true)
        )
      )
    )
  ))

;; [Rest of the contract functions remain the same]

;; New read-only function for complete history
(define-read-only (get-complete-history (doc-hash (buff 32)))
  (let ((doc (map-get? documents {doc-hash: doc-hash})))
    (match doc
      existing-doc 
      (ok (list 
        (map get-document-history 
          doc-hash 
          (list u1 u2 u3 u4 u5))))
      err-doc-not-found)))
