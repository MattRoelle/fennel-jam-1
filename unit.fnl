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
                                :radius (love.math.random 4 7)
                                :pos self.pos
                                :body-type :dynamic
                                :linear-damping 0.25
                                :mass 0.5
                                :restitution 0.99}))
  (self.box2d:init)
  (self.box2d.body:applyLinearImpulse 40 40))


(λ Unit.arena-draw [self]
  (let [(x y) (self.box2d.body:getPosition)]
    (graphics.circle
     (vec x y)
     (* self.box2d.radius 1.5)
     (rgba 0 1 1 1))))

(λ Unit.update [self dt]
  (when (> 0.02 (math.random))
    (self.box2d.body:applyLinearImpulse (love.math.random -4 4) (love.math.random -4 4))))

(set Unit.__defaults
     {:z-index 10 :pos (vec (+ 20 (math.abs (* 200 (math.random)))) 32)})

Unit
