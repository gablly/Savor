;; Recipe Collection Smart Contract
;; Store and manage cooking recipes with sharing capabilities

;; Constants
(define-constant head-chef tx-sender)
(define-constant err-chef-only (err u100))
(define-constant err-recipe-unavailable (err u101))
(define-constant err-recipe-collision (err u102))
(define-constant err-invalid-dish-name (err u103))
(define-constant err-invalid-servings (err u104))
(define-constant err-forbidden (err u105))

;; Data variables
(define-data-var recipe-tally uint u0)

;; Map to store recipe data
(define-map cookbook-entries
  { recipe-id: uint }
  {
    chef: principal,
    dish-name: (string-ascii 64),
    servings: uint,
    published-at: uint,
    sharing-policy: { cook: principal, can-access: bool }
  }
)

;; Private functions
(define-private (recipe-in-cookbook (recipe-id uint))
  (is-some (map-get? cookbook-entries { recipe-id: recipe-id }))
)

;; Public functions
(define-public (add-recipe (dish-name (string-ascii 64)) (servings uint))
  (let
    (
      (recipe-id (+ (var-get recipe-tally) u1))
    )
    (asserts! (> (len dish-name) u0) err-invalid-dish-name)
    (asserts! (< (len dish-name) u65) err-invalid-dish-name)
    (asserts! (> servings u0) err-invalid-servings)
    (asserts! (< servings u1000000000) err-invalid-servings)
    
    (map-insert cookbook-entries
      { recipe-id: recipe-id }
      {
        chef: tx-sender,
        dish-name: dish-name,
        servings: servings,
        published-at: stacks-block-height,
        sharing-policy: { cook: tx-sender, can-access: true }
      }
    )
    (var-set recipe-tally recipe-id)
    (ok recipe-id)
  )
)

(define-public (revise-recipe (recipe-id uint) (updated-dish-name (string-ascii 64)) (updated-servings uint))
  (let
    (
      (entry (unwrap! (map-get? cookbook-entries { recipe-id: recipe-id }) err-recipe-unavailable))
    )
    (asserts! (recipe-in-cookbook recipe-id) err-recipe-unavailable)
    (asserts! (is-eq (get chef entry) tx-sender) err-forbidden)
    (asserts! (> (len updated-dish-name) u0) err-invalid-dish-name)
    (asserts! (< (len updated-dish-name) u65) err-invalid-dish-name)
    (asserts! (> updated-servings u0) err-invalid-servings)
    (asserts! (< updated-servings u1000000000) err-invalid-servings)
    
    (map-set cookbook-entries
      { recipe-id: recipe-id }
      (merge entry { dish-name: updated-dish-name, servings: updated-servings })
    )
    (ok true)
  )
)

(define-public (remove-recipe (recipe-id uint))
  (let
    (
      (entry (unwrap! (map-get? cookbook-entries { recipe-id: recipe-id }) err-recipe-unavailable))
    )
    (asserts! (recipe-in-cookbook recipe-id) err-recipe-unavailable)
    (asserts! (is-eq (get chef entry) tx-sender) err-forbidden)
    (map-delete cookbook-entries { recipe-id: recipe-id })
    (ok true)
  )
)

(define-public (handoff-recipe (recipe-id uint) (new-chef principal))
  (let
    (
      (entry (unwrap! (map-get? cookbook-entries { recipe-id: recipe-id }) err-recipe-unavailable))
    )
    (asserts! (recipe-in-cookbook recipe-id) err-recipe-unavailable)
    (asserts! (is-eq (get chef entry) tx-sender) err-forbidden)
    
    (map-set cookbook-entries
      { recipe-id: recipe-id }
      (merge entry { chef: new-chef })
    )
    (ok true)
  )
)

(define-public (share-recipe (recipe-id uint) (can-access bool) (cook principal))
  (let
    (
      (entry (unwrap! (map-get? cookbook-entries { recipe-id: recipe-id }) err-recipe-unavailable))
    )
    (asserts! (recipe-in-cookbook recipe-id) err-recipe-unavailable)
    (asserts! (is-eq (get chef entry) tx-sender) err-forbidden)
    
    (map-set cookbook-entries
      { recipe-id: recipe-id }
      (merge entry { sharing-policy: { cook: cook, can-access: can-access } })
    )
    (ok true)
  )
)

(define-public (unshare-recipe (recipe-id uint) (can-access bool) (cook principal))
  (let
    (
      (entry (unwrap! (map-get? cookbook-entries { recipe-id: recipe-id }) err-recipe-unavailable))
    )
    (asserts! (recipe-in-cookbook recipe-id) err-recipe-unavailable)
    (asserts! (is-eq (get chef entry) tx-sender) err-forbidden)
    
    (map-set cookbook-entries
      { recipe-id: recipe-id }
      (merge entry { sharing-policy: { cook: cook, can-access: can-access } })
    )
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-cookbook-size)
  (ok (var-get recipe-tally))
)

(define-read-only (get-recipe-info (recipe-id uint))
  (match (map-get? cookbook-entries { recipe-id: recipe-id })
    entry-data (ok entry-data)
    err-recipe-unavailable
  )
)

(define-private (is-chef-of-recipe (recipe-id int) (chef principal))
  (match (map-get? cookbook-entries { recipe-id: (to-uint recipe-id) })
    entry-data (is-eq (get chef entry-data) chef)
    false
  )
)

(define-private (get-recipe-servings-by-chef (recipe-id int))
  (default-to u0 
    (get servings 
      (map-get? cookbook-entries { recipe-id: (to-uint recipe-id) })
    )
  )
)