;; ------------------------------------------------------------
;; Workout Tracker Contract
;; ------------------------------------------------------------
;; This contract allows users to log workouts, view their logs,
;; and track their progress over time.
;; ------------------------------------------------------------

;; Error constants
(define-constant err-invalid-input (err u100))
(define-constant err-no-record (err u101))
(define-constant err-not-owner (err u102))

;; Data structure for workout logs
;; Each workout is stored as {date, exercise, reps, sets, duration}
(define-map workout-logs
  {user: principal, workout-id: uint}
  {
    date: (string-ascii 20),
    exercise: (string-ascii 50),
    reps: uint,
    sets: uint,
    duration-mins: uint
  }
)

;; User's total number of workouts
(define-map workout-count principal uint)

;; ------------------------------------------------------------
;; Public Functions
;; ------------------------------------------------------------

;; Log a new workout
(define-public (log-workout (date (string-ascii 20)) (exercise (string-ascii 50)) (reps uint) (sets uint) (duration-mins uint))
  (begin
    (asserts! (> reps u0) err-invalid-input)
    (asserts! (> sets u0) err-invalid-input)
    (asserts! (> duration-mins u0) err-invalid-input)

    ;; Get current count
    (let ((count (default-to u0 (map-get? workout-count tx-sender))))
      (map-set workout-logs
        {user: tx-sender, workout-id: (+ count u1)}
        {date: date, exercise: exercise, reps: reps, sets: sets, duration-mins: duration-mins})
      (map-set workout-count tx-sender (+ count u1))
    )
    (ok "Workout logged successfully")
  )
)

;; View a specific workout
(define-read-only (get-workout (user principal) (workout-id uint))
  (let ((record (map-get? workout-logs {user: user, workout-id: workout-id})))
    (ok record)
  )
)

;; Get total workouts of a user
(define-read-only (get-total-workouts (user principal))
  (ok (default-to u0 (map-get? workout-count user)))
)

;; Delete a workout (only owner can delete their workout)
(define-public (delete-workout (workout-id uint))
  (begin
    (let ((record (map-get? workout-logs {user: tx-sender, workout-id: workout-id})))
      (asserts! (is-some record) err-no-record)
      (map-delete workout-logs {user: tx-sender, workout-id: workout-id})
      (ok "Workout deleted successfully")
    )
  )
)

;; ------------------------------------------------------------
;; Extra Features
;; ------------------------------------------------------------

;; Get all workouts for a user (IDs only)
(define-read-only (list-workouts (user principal))
  (let ((count (default-to u0 (map-get? workout-count user))))
    (ok (if (is-eq count u0)
            none
            (some count)))
  )
)
