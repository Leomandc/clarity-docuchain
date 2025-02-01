;; DocuChain - Document Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-doc-exists (err u101))
(define-constant err-doc-not-found (err u102))
(define-constant err-not-authorized (err u103))

;; Data structures
(define-map documents
  { doc-hash: (buff 32) }
  {
    owner: principal,
    timestamp: uint,
    title: (string-ascii 64),
    description: (string-ascii 256),
    status: (string-ascii 16)
  }
)

(define-map document-history
  { doc-hash: (buff 32), version: uint }
  {
    timestamp: uint,
    updated-by: principal,
    status: (string-ascii 16)
  }
)

;; Public functions
(define-public (register-document 
  (doc-hash (buff 32))
  (title (string-ascii 64))
  (description (string-ascii 256)))
  (let ((existing-doc (get owner (map-get? documents {doc-hash: doc-hash}))))
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
            status: "ACTIVE"
          }
        )
        (map-set document-history
          {doc-hash: doc-hash, version: u1}
          {
            timestamp: block-height,
            updated-by: tx-sender,
            status: "REGISTERED"
          }
        )
        (ok true)
      )
    )
  )
)

(define-public (verify-document (doc-hash (buff 32)))
  (match (map-get? documents {doc-hash: doc-hash})
    doc (ok doc)
    err-doc-not-found
  )
)

(define-public (transfer-ownership 
  (doc-hash (buff 32))
  (new-owner principal))
  (let ((doc (map-get? documents {doc-hash: doc-hash})))
    (match doc
      existing-doc (if (is-eq (get owner existing-doc) tx-sender)
        (begin
          (map-set documents
            {doc-hash: doc-hash}
            (merge existing-doc {owner: new-owner})
          )
          (ok true)
        )
        err-not-authorized
      )
      err-doc-not-found
    )
  )
)

;; Read only functions
(define-read-only (get-document-info (doc-hash (buff 32)))
  (map-get? documents {doc-hash: doc-hash})
)

(define-read-only (get-document-history 
  (doc-hash (buff 32))
  (version uint))
  (map-get? document-history {doc-hash: doc-hash, version: version})
)
