(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity} (require :helpers))
(local {: Box2dCircle} (require :wall))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.arena-draw [self]
  (self.box2d:draw-world-points))

(λ Unit.init [self]
  (set self.box2d
       (new-entity Box2dCircle {:color (rgba (math.abs (math.random))
                                             (math.abs (math.random))
                                             (math.abs (math.random))
                                             1)
                                :radius (love.math.random 2 8)
                                :pos self.pos
                                :body-type :dynamic
                                :linear-damping 2
                                :restitution 0.98}))
  (self.box2d:init)
  (self.box2d.body:applyLinearImpulse 40 40))

(λ Unit.update [self dt])

(set Unit.__defaults
     {:z-index 10 :pos (vec (+ 20 (math.abs (* 200 (math.random)))) 32)})

Unit
