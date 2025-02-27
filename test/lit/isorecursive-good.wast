;; NOTE: Assertions have been generated by update_lit_checks.py and should not be edited.

;; RUN: wasm-opt %s -all -S -o - | filecheck %s
;; RUN: wasm-opt %s -all --roundtrip -S -o - | filecheck %s

(module
  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $super-struct (struct (field i32)))
    (type $super-struct (sub (struct i32)))
    ;; CHECK:       (type $sub-struct (sub $super-struct (struct (field i32) (field i64))))
    (type $sub-struct (sub $super-struct (struct i32 i64)))
    ;; CHECK:       (type $final-struct (sub final $sub-struct (struct (field i32) (field i64) (field f32))))
    (type $final-struct (sub final $sub-struct (struct i32 i64 f32)))
  )

  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $super-array (array (ref $super-struct)))
    (type $super-array (sub (array (ref $super-struct))))
    ;; CHECK:       (type $sub-array (sub $super-array (array (ref $sub-struct))))
    (type $sub-array (sub $super-array (array (ref $sub-struct))))
    ;; CHECK:       (type $final-array (sub final $sub-array (array (ref $final-struct))))
    (type $final-array (sub final $sub-array (array (ref $final-struct))))
  )

  (rec
    ;; CHECK:      (rec
    ;; CHECK-NEXT:  (type $super-func (func (param (ref $sub-array)) (result (ref $super-array))))
    (type $super-func (sub (func (param (ref $sub-array)) (result (ref $super-array)))))
    ;; CHECK:       (type $sub-func (sub $super-func (func (param (ref $super-array)) (result (ref $sub-array)))))
    (type $sub-func (sub $super-func (func (param (ref $super-array)) (result (ref $sub-array)))))
    ;; CHECK:       (type $final-func (sub final $sub-func (func (param (ref $super-array)) (result (ref $final-array)))))
    (type $final-func (sub final $sub-func (func (param (ref $super-array)) (result (ref $final-array)))))
  )

  ;; CHECK:      (type $final-root (sub final (struct )))
  (type $final-root (sub final (struct)))

  ;; CHECK:      (func $make-super-struct (type $6) (result (ref $super-struct))
  ;; CHECK-NEXT:  (call $make-final-struct)
  ;; CHECK-NEXT: )
  (func $make-super-struct (result (ref $super-struct))
    (call $make-final-struct)
  )

  ;; CHECK:      (func $make-final-struct (type $7) (result (ref $final-struct))
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $make-final-struct (result (ref $final-struct))
    (unreachable)
  )

  ;; CHECK:      (func $make-super-array (type $8) (result (ref $super-array))
  ;; CHECK-NEXT:  (call $make-final-array)
  ;; CHECK-NEXT: )
  (func $make-super-array (result (ref $super-array))
    (call $make-final-array)
  )

  ;; CHECK:      (func $make-final-array (type $9) (result (ref $final-array))
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $make-final-array (result (ref $final-array))
    (unreachable)
  )

  ;; CHECK:      (func $make-super-func (type $13) (result (ref $super-func))
  ;; CHECK-NEXT:  (call $make-final-func)
  ;; CHECK-NEXT: )
  (func $make-super-func (result (ref $super-func))
    (call $make-final-func)
  )

  ;; CHECK:      (func $make-final-func (type $14) (result (ref $final-func))
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $make-final-func (result (ref $final-func))
    (unreachable)
  )

  ;; CHECK:      (func $make-final-root (type $16) (result (ref $final-root))
  ;; CHECK-NEXT:  (unreachable)
  ;; CHECK-NEXT: )
  (func $make-final-root (result (ref $final-root))
    (unreachable)
  )
)
