;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.
;; RUN: wasm-opt %s --optimize-casts -all -S -o - | filecheck %s

(module
  ;; CHECK:      (type $A (struct ))
  (type $A (struct_subtype data))

  ;; CHECK:      (type $B (sub $A (struct )))
  (type $B (struct_subtype $A))

  ;; CHECK:      (type $void (func))

  ;; CHECK:      (type $D (array (mut i32)))
  (type $D (array (mut i32)))

  (type $void (func))

  ;; CHECK:      (global $a (mut i32) (i32.const 0))
  (global $a (mut i32) (i32.const 0))

  ;; CHECK:      (func $ref.as (type $ref?|$A|_=>_none) (param $x (ref null $A))
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $ref.as (param $x (ref null $A))
    ;; We duplicate the ref.as to the first local.get, since it is more refined
    ;; than the local.get alone. We then use the refined index throughout.
    (drop
      (local.get $x)
    )
    (drop
      ;; In this case we don't need this ref.as here after the pass as it is
      ;; duplicated above, but we leave that to later opts.
      (ref.as_non_null
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    ;; In this case we don't really need the last ref.as here, because of earlier
    ;; ref.as expressions, but we leave that for later opts.
    (drop
      (ref.as_non_null
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $ref.as-no (type $ref|$A|_=>_none) (param $x (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $ref.as-no (param $x (ref $A))
    ;; As above, but the param is now non-nullable anyhow, so we should do
    ;; nothing.

    ;; Because of this, a ref.as_non_null cast is not moved up to the first
    ;; local.get $x even though it could because it would make no difference.
    (drop
      (local.get $x)
    )
    (drop
      (ref.as_non_null
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    (drop
      (ref.as_non_null
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $ref.cast (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $ref.cast (param $x (ref struct))
    ;; As $ref.as but with ref.casts: we should use the cast value after it has
    ;; been computed, in both gets.
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $not-past-set (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (call $get)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $not-past-set (param $x (ref struct))
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    ;; The local.set in the middle stops us from helping the last get.
    (local.set $x
      (call $get)
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $not-past-call (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (call $get)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $not-past-call (param $x (ref struct))
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    ;; The call in the middle stops us from helping the last get, since a call
    ;; might branch out. TODO we could still optimize in this case, with more
    ;; precision (since if we branch out it doesn't matter what we have below).
    (drop
      (call $get)
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $not-past-call_ref (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (call_ref $void
  ;; CHECK-NEXT:   (ref.func $void)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $not-past-call_ref (param $x (ref struct))
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    ;; As in the last function, the call in the middle stops us from helping the
    ;; last get (this time with a call_ref).
    (call_ref $void
      (ref.func $void)
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $best (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (local $2 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $a
  ;; CHECK-NEXT:   (i32.const 10)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $a
  ;; CHECK-NEXT:   (i32.const 20)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $2
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $a
  ;; CHECK-NEXT:   (i32.const 30)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $best (param $x (ref struct))
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    ;; global.sets prevent casts from being moved before them
    ;; but uses can be added after them.
    (global.set $a
      (i32.const 10)
    )
    ;; Here we should use $A.
    (drop
      (local.get $x)
    )
    (global.set $a
      (i32.const 20)
    )
    (drop
      (ref.cast $B
        (local.get $x)
      )
    )
    (global.set $a
      (i32.const 30)
    )
    ;; Here we should use $B, which is even better.
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $best-2 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $best-2 (param $x (ref struct))
    ;; As above, but with the casts reversed. Now we should use $B in both
    ;; gets.
    (drop
      (ref.cast $B
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $fallthrough (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (block (result (ref struct))
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $fallthrough (param $x (ref struct))
    (drop
      (ref.cast $A
        ;; We look through the block, and optimize.
        (block (result (ref struct))
          (local.get $x)
        )
      )
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $past-basic-block (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (return)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $past-basic-block (param $x (ref struct))
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    ;; The if means the later get is in another basic block. We do not handle
    ;; this atm.
    (if
      (i32.const 0)
      (return)
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $multiple (type $ref|struct|_ref|struct|_=>_none) (param $x (ref struct)) (param $y (ref struct))
  ;; CHECK-NEXT:  (local $a (ref struct))
  ;; CHECK-NEXT:  (local $b (ref struct))
  ;; CHECK-NEXT:  (local $4 (ref $A))
  ;; CHECK-NEXT:  (local $5 (ref $A))
  ;; CHECK-NEXT:  (local.set $a
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $b
  ;; CHECK-NEXT:   (local.get $y)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $4
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $a)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $5
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $b)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $4)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $5)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $b
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $4)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $b)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $multiple (param $x (ref struct)) (param $y (ref struct))
    (local $a (ref struct))
    (local $b (ref struct))
    ;; Two different locals, with overlapping lives.
    (local.set $a
      (local.get $x)
    )
    (local.set $b
      (local.get $y)
    )
    (drop
      (ref.cast $A
        (local.get $a)
      )
    )
    (drop
      (ref.cast $A
        (local.get $b)
      )
    )
    ;; These two can be optimized.
    (drop
      (local.get $a)
    )
    (drop
      (local.get $b)
    )
    (local.set $b
      (local.get $x)
    )
    ;; Now only the first can be, since $b changed.
    (drop
      (local.get $a)
    )
    (drop
      (local.get $b)
    )
  )

  ;; CHECK:      (func $move-cast-1 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.tee $1
  ;; CHECK-NEXT:     (ref.cast $B
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-1 (param $x (ref struct))
    (drop
      ;; The later cast to $B will be moved between ref.cast $A
      ;; and local.get $x. This will cause this ref.cast $A to be
      ;; converted to a second ref.cast $B due to ReFinalize().
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    (drop
      ;; The most refined cast of $x is to $B, which we can move up to
      ;; the top and reuse from there.
      (ref.cast $B
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-cast-2 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.tee $1
  ;; CHECK-NEXT:     (ref.cast $B
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-2 (param $x (ref struct))
    (drop
      ;; As in $move-cast-1, the later cast to $B will be moved
      ;; between ref.cast $A and local.get $x, causing ref.cast $A
      ;; to be converted into a second ref.cast $B by ReFinalize();
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      ;; This will be moved up to the first local.get $x.
      (ref.cast $B
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $move-cast-3 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-3 (param $x (ref struct))
    (drop
      (local.get $x)
    )
    (drop
      ;; Converted to $B by ReFinalize().
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      ;; This will be moved up to the first local.get $x.
      (ref.cast $B
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-cast-4 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-4 (param $x (ref struct))
    (drop
      (local.get $x)
    )
    (drop
      ;; This will be moved up to the first local.get $x.
      (ref.cast $B
        (local.get $x)
      )
    )
    (drop
      ;; Converted to $B by ReFinalize().
      (ref.cast $A
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-cast-5 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-5 (param $x (ref struct))
    (drop
      ;; The first location is already the most refined cast, so nothing will be moved up.
      ;; (But we will save the cast to a local and re-use it below.)
      (ref.cast $B
        (local.get $x)
      )
    )
    (drop
      ;; Converted to $B by ReFinalize().
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $move-cast-6 (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-6 (param $x (ref struct))
    (drop
      ;; This is already the most refined cast, so nothing will be moved.
      (ref.cast $B
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
    (drop
      ;; Converted to $B by ReFinalize().
      (ref.cast $A
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $no-move-already-refined-local (type $ref|$B|_=>_none) (param $x (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $no-move-already-refined-local (param $x (ref $B))
    (drop
      (local.get $x)
    )
    (drop
      ;; Since we know $x is of type $B, this cast to a less refined type $A
      ;; will not be moved higher.
      (ref.cast $A
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $no-move-ref.as-to-non-nullable-local (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $no-move-ref.as-to-non-nullable-local (param $x (ref struct))
    (drop
      (local.get $x)
    )
    (drop
      ;; Since $x is non-nullable, this cast is useless. Hence, this
      ;; will not be duplicated to the first local.get, since doing
      ;; so would also be useless.
      (ref.as_non_null
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $avoid-erroneous-cast-move (type $ref|$A|_=>_none) (param $x (ref $A))
  ;; CHECK-NEXT:  (local $a (ref $A))
  ;; CHECK-NEXT:  (local.set $a
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $D
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $avoid-erroneous-cast-move (param $x (ref $A))
    ;; This test shows that we avoid moving a cast earlier if doing so would
    ;; violate typing rules.
    (local $a (ref $A))
    (local.set $a
      ;; We could move the ref.cast $D here. However, as $a is already known
      ;; to have type ref null $A, not type $D, it would fail, since those
      ;; types are incompatible. Moving the cast will also cause the
      ;; local.set $b to fail, since $b is of type ref null $A, not $D.
      (local.get $x)
    )
    (drop
      (ref.cast $D
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-as-1 (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (local $1 (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-as-1 (param $x (ref null struct))
    (drop
      (local.get $x)
    )
    (drop
      ;; The most refined cast of $x is this ref.as_non_null, so we will move it
      ;; and reuse from there.
      (ref.as_non_null
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-as-2 (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (local $1 (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $1)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-as-2 (param $x (ref null struct))
    (drop
      ;; This is already the most refined cast, so the cast is not copied
      ;; (but we do save it to a local and use it below).
      (ref.as_non_null
        (local.get $x)
      )
    )
    (drop
      (local.get $x)
    )
  )

  ;; CHECK:      (func $move-cast-side-effects (type $ref|struct|_ref|struct|_=>_none) (param $x (ref struct)) (param $y (ref struct))
  ;; CHECK-NEXT:  (local $2 (ref $A))
  ;; CHECK-NEXT:  (local $3 (ref $B))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (global.set $a
  ;; CHECK-NEXT:   (i32.const 10)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $2
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $3
  ;; CHECK-NEXT:    (ref.cast $B
  ;; CHECK-NEXT:     (local.get $y)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (local.get $3)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $3)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-cast-side-effects (param $x (ref struct)) (param $y (ref struct))
    ;; This verifies that casts cannot be moved past side-effect producing
    ;; operations like global.set, and that casts cannot be moved past a local.set
    ;; to its own local index.
    (drop
      (local.get $x)
    )
    ;; Cannot move past global set due to trap possibility, so the cast to $A will
    ;; move up to here but not further up.
    (global.set $a
      (i32.const 10)
    )
    (drop
      (local.get $x)
    )
    (drop
      (local.get $y)
    )
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    ;; Casts to $x cannot be moved past local.set $x, but the cast of $y can and will be.
    (local.set $x
      (local.get $y)
    )
    (drop
      ;; This can be moved past local.set $x.
      (ref.cast $B
        (local.get $y)
      )
    )
    (drop
      ;; This cannot be moved past local.set $x.
      (ref.cast $B
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-ref.as-for-separate-index (type $structref_structref_=>_none) (param $x structref) (param $y structref)
  ;; CHECK-NEXT:  (local $2 (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $2
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (local.get $y)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (local.set $x
  ;; CHECK-NEXT:   (local.get $2)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $2)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-ref.as-for-separate-index (param $x (ref null struct)) (param $y (ref null struct))
    ;; This test shows that local index $x and local index $y are tracked separately.
    (drop
      ;; The later local.set $x will prevent casts from being moved here.
      (local.get $x)
    )
    (drop
      ;; A ref.as_non_null will be moved here, because the local.set
      ;; will only prevent casts involving local.get $x from being moved.
      (local.get $y)
    )
    (local.set $x
      (local.get $y)
    )
    (drop
      (ref.as_non_null
        (local.get $y)
      )
    )
    (drop
      (ref.as_non_null
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-ref.as-and-ref.cast (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (ref.cast null $A
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $1)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-ref.as-and-ref.cast (param $x (ref null struct))
    ;; This test shows how a nested ref.as_non_null and ref.cast can be
    ;; moved to the same local.get.
    (drop
      (local.get $x)
    )
    (drop
      ;; Here these two nested casts will be moved up to the earlier local.get.
      (ref.as_non_null
        ;; This will be converted to a non-nullable cast because the local we
        ;; save to in the optimization ($1) is now non-nullable.
        (ref.cast null $A
          (local.get $x)
        )
      )
    )
  )

  ;; CHECK:      (func $move-ref.as-and-ref.cast-2 (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (ref.cast null $A
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-ref.as-and-ref.cast-2 (param $x (ref null struct))
    ;; This test shows how a ref.cast followed by a ref.as_non_null
    ;; can both be moved to an earlier local.get.
    (drop
      ;; The separate ref.as_non_null and the ref.cast below will both be moved here.
      (local.get $x)
    )
    (drop
      ;; This is converted to ref.cast $A, because we will save $x to
      ;; a non-nullable $A local as part of the optimization.
      (ref.cast null $A
        (local.get $x)
      )
    )
    (drop
      (ref.as_non_null
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $move-ref.as-and-ref.cast-3 (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (ref.cast null $A
  ;; CHECK-NEXT:      (local.get $x)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.as_non_null
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-ref.as-and-ref.cast-3 (param $x (ref null struct))
    ;; This test shows how a ref.as_non_null followed by a ref.cast can be
    ;; both moved to an earlier local.get.
    (drop
      ;; Even though the ref.as_non_null appears first, it will still
      ;; be the outer cast when both casts are moved here.
      (local.get $x)
    )
    (drop
      (ref.as_non_null
        (local.get $x)
      )
    )
    (drop
      ;; This is converted to ref.cast $A, because we will save $x to
      ;; a non-nullable $A local as part of the optimization.
      (ref.cast null $A
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $unoptimizable-nested-casts (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $B
  ;; CHECK-NEXT:    (ref.as_non_null
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $unoptimizable-nested-casts (param $x (ref null struct))
    ;; No optimizations should be made here for this nested cast.
    ;; This test is here to ensure this.
    (drop
      (ref.cast $B
        (ref.as_non_null
          (local.get $x)
        )
      )
    )
  )

  ;; CHECK:      (func $no-move-over-self-tee (type $structref_structref_=>_none) (param $x structref) (param $y structref)
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.tee $x
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $no-move-over-self-tee (param $x (ref null struct)) (param $y (ref null struct))
    (drop
      (local.get $x)
    )
    (drop
      ;; We do not move this ref.cast of $x because $x is set by the local.tee,
      ;; and we do not move casts past a set of a local index. This is treated
      ;; like a local.set and we do not have a special case for this.
      (ref.cast $A
        (local.tee $x
          (local.get $x)
        )
      )
    )
  )

  ;; CHECK:      (func $move-over-tee (type $structref_structref_=>_none) (param $x structref) (param $y structref)
  ;; CHECK-NEXT:  (local $a structref)
  ;; CHECK-NEXT:  (local $3 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $3
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.tee $a
  ;; CHECK-NEXT:     (local.get $3)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-over-tee (param $x (ref null struct)) (param $y (ref null struct))
    (local $a (ref null struct))
    (drop
      (local.get $x)
    )
    (drop
      ;; We can move this ref.cast because the local.tee sets another local index.
      (ref.cast $A
        (local.tee $a
          (local.get $x)
        )
      )
    )
  )

  ;; CHECK:      (func $move-identical-repeated-casts (type $ref|struct|_=>_none) (param $x (ref struct))
  ;; CHECK-NEXT:  (local $1 (ref $A))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.tee $1
  ;; CHECK-NEXT:    (ref.cast $A
  ;; CHECK-NEXT:     (local.get $x)
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $1)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $move-identical-repeated-casts (param $x (ref struct))
    ;; This tests the case where there are two casts with equal type which can
    ;; be moved to an earlier local.get. Only one of the casts will be duplicated
    ;; to the earliest local.get (which one is not visible to the test).
    (drop
      (local.get $x)
    )
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
    (drop
      (ref.cast $A
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $no-move-past-non-linear (type $structref_=>_none) (param $x structref)
  ;; CHECK-NEXT:  (local $1 (ref struct))
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (local.get $x)
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (if
  ;; CHECK-NEXT:   (i32.const 0)
  ;; CHECK-NEXT:   (block
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (local.tee $1
  ;; CHECK-NEXT:      (ref.as_non_null
  ;; CHECK-NEXT:       (local.get $x)
  ;; CHECK-NEXT:      )
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:    (drop
  ;; CHECK-NEXT:     (ref.as_non_null
  ;; CHECK-NEXT:      (local.get $1)
  ;; CHECK-NEXT:     )
  ;; CHECK-NEXT:    )
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT:  (drop
  ;; CHECK-NEXT:   (ref.cast $A
  ;; CHECK-NEXT:    (local.get $x)
  ;; CHECK-NEXT:   )
  ;; CHECK-NEXT:  )
  ;; CHECK-NEXT: )
  (func $no-move-past-non-linear (param $x (ref null struct))
    (drop
      ;; No cast can be moved up here, since this is immediately
      ;; followed by the if statement, which resets the state of
      ;; the optimization pass and blocks subsequent casts from
      ;; being moved past it.
      (local.get $x)
    )
    (if
      (i32.const 0)
      (block
        (drop
          ;; The ref.as_non_null can be moved here because
          ;; it is in the same block in the same arm of the
          ;; if statement.
          (local.get $x)
        )
        (drop
          (ref.as_non_null
            (local.get $x)
          )
        )
      )
    )
    (drop
      ;; This cannot be moved earlier because it is blocked by
      ;; the if statement. All state information is cleared when
      ;; entering and leaving the if statement.
      (ref.cast $A
        (local.get $x)
      )
    )
  )

  ;; CHECK:      (func $get (type $none_=>_ref|struct|) (result (ref struct))
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $get (result (ref struct))
    ;; Helper for the above.
    (unreachable)
  )

  ;; CHECK:      (func $void (type $void)
  ;; CHECK-NEXT:  (nop)
  ;; CHECK-NEXT: )
  (func $void
    ;; Helper for the above.
  )
)
