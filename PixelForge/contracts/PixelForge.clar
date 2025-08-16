;; PixelForge Gaming Platform Smart Contract
;; A Stacks-based gaming ecosystem with collectible NFTs, milestones, and gamer progression

;; Constants
(define-constant platform-admin tx-sender)
(define-constant err-admin-only (err u200))
(define-constant err-not-exists (err u201))
(define-constant err-duplicate-entry (err u202))
(define-constant err-insufficient-funds (err u203))
(define-constant err-invalid-value (err u204))
(define-constant err-unauthorized-access (err u205))

;; Data Variables
(define-data-var next-title-id uint u1)
(define-data-var next-collectible-id uint u1)
(define-data-var ecosystem-fee-percentage uint u300) ;; 3.0% in basis points

;; Data Maps
(define-map game-titles 
    uint 
    {
        title: (string-ascii 50),
        publisher: principal,
        enabled: bool,
        registered-gamers: uint,
        launch-block: uint
    }
)

(define-map gamer-accounts 
    principal 
    {
        handle: (string-ascii 30),
        lifetime-points: uint,
        titles-played: uint,
        collectibles-count: uint,
        milestones-earned: uint,
        registration-block: uint
    }
)

(define-map title-collectibles 
    uint 
    {
        title-id: uint,
        collectible-name: (string-ascii 50),
        tier: (string-ascii 20),
        cost: uint,
        max-supply: uint,
        current-minted: uint,
        available: bool
    }
)

(define-map gamer-inventory 
    {gamer: principal, collectible-id: uint} 
    {
        amount: uint,
        obtained-at: uint
    }
)

(define-map title-leaderboards 
    {gamer: principal, title-id: uint} 
    {
        best-score: uint,
        recent-play: uint,
        play-count: uint
    }
)

(define-map milestone-definitions 
    uint 
    {
        milestone-name: (string-ascii 50),
        criteria: (string-ascii 100),
        bonus-reward: uint,
        enabled: bool
    }
)

(define-map gamer-milestones 
    {gamer: principal, milestone-id: uint} 
    bool
)

;; Public Functions

;; Register a new game title on the platform
(define-public (register-title (title (string-ascii 50)))
    (let 
        ((title-id (var-get next-title-id)))
        (asserts! (is-eq tx-sender platform-admin) err-admin-only)
        (map-set game-titles title-id {
            title: title,
            publisher: tx-sender,
            enabled: true,
            registered-gamers: u0,
            launch-block: stacks-block-height
        })
        (var-set next-title-id (+ title-id u1))
        (ok title-id)
    )
)

;; Create gamer account
(define-public (create-gamer-account (handle (string-ascii 30)))
    (let 
        ((existing-account (map-get? gamer-accounts tx-sender)))
        (asserts! (is-none existing-account) err-duplicate-entry)
        (map-set gamer-accounts tx-sender {
            handle: handle,
            lifetime-points: u0,
            titles-played: u0,
            collectibles-count: u0,
            milestones-earned: u0,
            registration-block: stacks-block-height
        })
        (ok true)
    )
)

;; Submit gameplay score
(define-public (record-score (title-id uint) (score uint))
    (let 
        ((title (unwrap! (map-get? game-titles title-id) err-not-exists))
         (current-record (default-to 
            {best-score: u0, recent-play: u0, play-count: u0} 
            (map-get? title-leaderboards {gamer: tx-sender, title-id: title-id})))
         (account (unwrap! (map-get? gamer-accounts tx-sender) err-not-exists)))
        
        (asserts! (get enabled title) err-not-exists)
        
        ;; Update leaderboard if it's a new best score
        (if (> score (get best-score current-record))
            (begin
                (map-set title-leaderboards 
                    {gamer: tx-sender, title-id: title-id}
                    {
                        best-score: score,
                        recent-play: stacks-block-height,
                        play-count: (+ (get play-count current-record) u1)
                    }
                )
                ;; Update gamer account
                (map-set gamer-accounts tx-sender
                    (merge account {
                        lifetime-points: (+ (get lifetime-points account) score),
                        titles-played: (if (is-eq (get play-count current-record) u0) 
                                        (+ (get titles-played account) u1)
                                        (get titles-played account))
                    })
                )
                (ok true)
            )
            (ok false)
        )
    )
)

;; Create title collectible (NFT)
(define-public (mint-collectible (title-id uint) (collectible-name (string-ascii 50)) (tier (string-ascii 20)) (cost uint) (max-supply uint))
    (let 
        ((collectible-id (var-get next-collectible-id))
         (title (unwrap! (map-get? game-titles title-id) err-not-exists)))
        
        (asserts! (is-eq tx-sender (get publisher title)) err-unauthorized-access)
        (asserts! (> max-supply u0) err-invalid-value)
        
        (map-set title-collectibles collectible-id {
            title-id: title-id,
            collectible-name: collectible-name,
            tier: tier,
            cost: cost,
            max-supply: max-supply,
            current-minted: u0,
            available: true
        })
        (var-set next-collectible-id (+ collectible-id u1))
        (ok collectible-id)
    )
)

;; Acquire collectible
(define-public (acquire-collectible (collectible-id uint))
    (let 
        ((collectible (unwrap! (map-get? title-collectibles collectible-id) err-not-exists))
         (existing-collectible (map-get? gamer-inventory {gamer: tx-sender, collectible-id: collectible-id}))
         (current-amount (match existing-collectible 
                            some-collectible (get amount some-collectible)
                            u0))
         (account (unwrap! (map-get? gamer-accounts tx-sender) err-not-exists)))
        
        (asserts! (get available collectible) err-not-exists)
        (asserts! (< (get current-minted collectible) (get max-supply collectible)) err-insufficient-funds)
        
        ;; Transfer STX for collectible purchase
        (try! (stx-transfer? (get cost collectible) tx-sender platform-admin))
        
        ;; Update collectible minted count
        (map-set title-collectibles collectible-id
            (merge collectible {current-minted: (+ (get current-minted collectible) u1)})
        )
        
        ;; Update gamer's inventory
        (map-set gamer-inventory 
            {gamer: tx-sender, collectible-id: collectible-id}
            {
                amount: (+ current-amount u1),
                obtained-at: stacks-block-height
            }
        )
        
        ;; Update gamer account
        (map-set gamer-accounts tx-sender
            (merge account {
                collectibles-count: (if (is-eq current-amount u0) 
                               (+ (get collectibles-count account) u1)
                               (get collectibles-count account))
            })
        )
        
        (ok true)
    )
)

;; Grant milestone
(define-public (grant-milestone (gamer principal) (milestone-id uint))
    (let 
        ((milestone (unwrap! (map-get? milestone-definitions milestone-id) err-not-exists))
         (already-granted (default-to false (map-get? gamer-milestones {gamer: gamer, milestone-id: milestone-id})))
         (account (unwrap! (map-get? gamer-accounts gamer) err-not-exists)))
        
        (asserts! (is-eq tx-sender platform-admin) err-admin-only)
        (asserts! (not already-granted) err-duplicate-entry)
        (asserts! (get enabled milestone) err-not-exists)
        
        ;; Mark milestone as granted
        (map-set gamer-milestones {gamer: gamer, milestone-id: milestone-id} true)
        
        ;; Update gamer account
        (map-set gamer-accounts gamer
            (merge account {milestones-earned: (+ (get milestones-earned account) u1)})
        )
        
        ;; Award STX bonus if any and return final result
        (if (> (get bonus-reward milestone) u0)
            (as-contract (stx-transfer? (get bonus-reward milestone) tx-sender gamer))
            (ok true)
        )
    )
)

;; Read-only functions

(define-read-only (get-title (title-id uint))
    (map-get? game-titles title-id)
)

(define-read-only (get-gamer-account (gamer principal))
    (map-get? gamer-accounts gamer)
)

(define-read-only (get-gamer-score (gamer principal) (title-id uint))
    (map-get? title-leaderboards {gamer: gamer, title-id: title-id})
)

(define-read-only (get-collectible (collectible-id uint))
    (map-get? title-collectibles collectible-id)
)

(define-read-only (get-gamer-collectible (gamer principal) (collectible-id uint))
    (map-get? gamer-inventory {gamer: gamer, collectible-id: collectible-id})
)

(define-read-only (get-milestone (milestone-id uint))
    (map-get? milestone-definitions milestone-id)
)

(define-read-only (has-milestone (gamer principal) (milestone-id uint))
    (default-to false (map-get? gamer-milestones {gamer: gamer, milestone-id: milestone-id}))
)

(define-read-only (get-next-title-id)
    (var-get next-title-id)
)

(define-read-only (get-next-collectible-id)
    (var-get next-collectible-id)
)