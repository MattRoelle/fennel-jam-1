(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.arena-draw [self]
  (graphics.circle self.pos 4 (rgba 0 1 1 1)))

(λ Unit.update [self dt])

(set Unit.__defaults {:z-index 10 :pos (vec 32 32)})

Unit
