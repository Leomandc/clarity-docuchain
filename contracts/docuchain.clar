;; DocuChain - Document Verification System

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-doc-exists (err u101))
(define-constant err-doc-not-found (err u102))
(define-constant err-not-authorized (err u103))
(define-constant err-invalid-input (err u104))
(define-constant err-invalid-status (err u105))

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
  )
)

(define-public (verify-document (doc-hash (buff 32)))
  (match (map-get? documents {doc-hash: doc-hash})
    doc (ok {
      owner: (get owner doc),
      status: (get status doc),
      version: (get version doc)
    })
    err-doc-not-found
  )
)

(define-public (update-status 
  (doc-hash (buff 32))
  (new-status (string-ascii 16)))
  (let ((doc (map-get? documents {doc-hash: doc-hash})))
    (match doc
      existing-doc 
      (begin
        (asserts! (is-eq (get owner existing-doc) tx-sender) err-not-authorized)
        (asserts! (or (is-eq new-status "ACTIVE") 
                    (is-eq new-status "INACTIVE") 
                    (is-eq new-status "EXPIRED")) 
                err-invalid-status)
        (let ((new-version (get-next-version doc-hash)))
          (map-set documents
            {doc-hash: doc-hash}
            (merge existing-doc {
              status: new-status,
              version: new-version
            })
          )
          (map-set document-history
            {doc-hash: doc-hash, version: new-version}
            {
              timestamp: block-height,
              updated-by: tx-sender,
              status: new-status,
              action: "STATUS_UPDATE"
            }
          )
          (ok true)
        )
      )
      err-doc-not-found
    )
  )
)

(define-public (transfer-ownership 
  (doc-hash (buff 32))
  (new-owner principal))
  (let ((doc (map-get? documents {doc-hash: doc-hash})))
    (match doc
      existing-doc 
      (begin
        (asserts! (is-eq (get owner existing-doc) tx-sender) err-not-authorized)
        (let ((new-version (get-next-version doc-hash)))
          (map-set documents
            {doc-hash: doc-hash}
            (merge existing-doc {
              owner: new-owner,
              version: new-version
            })
          )
          (map-set document-history
            {doc-hash: doc-hash, version: new-version}
            {
              timestamp: block-height,
              updated-by: tx-sender,
              status: (get status existing-doc),
              action: "TRANSFER"
            }
          )
          (ok true)
        )
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
