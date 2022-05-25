(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.arena-draw [self]
  (graphics.circle self.pos 8 (rgba 0 1 1 1)))

(λ Unit.update [self dt])

(λ Unit.new [?o]
  (let [defaults {:z-index 10
                  :pos (vec 32 32)}
        tbl (lume.merge defaults (or ?o {}))
        inst (setmetatable tbl Unit)]
    inst))

Unit
