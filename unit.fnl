(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity} (require :helpers))
(local {: Box2dCircle} (require :wall))
(local data (require :data))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.arena-draw [self]
  (self.box2d:draw-world-points))

(λ Unit.init [self]
  (assert self.unit-type :must-pass-unit-type)
  (set self.def (. data.unit-types self.unit-type))
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
  (let [iv (polar-vec2 (* (math.random) 2 math.pi) 20)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))


(λ Unit.arena-draw [self]
  (let [(x y) (self.box2d.body:getPosition)]
    (graphics.circle
     (vec x y)
     (* self.box2d.radius 1.5)
     (match self.unit-type
       :warrior (rgba 0 1 0 1)
       _ (rgba 1 1 1 1)))))

(λ Unit.update [self dt]
  (when (> 0.02 (math.random))
    (let [iv (polar-vec2 (* (math.random) 2 math.pi) 5)]
      (self.box2d.body:applyLinearImpulse iv.x iv.y))))

(set Unit.__defaults
     {:z-index 10
      :pos (vec 32 32)
      :team :player})

(local Enemy (setmetatable {} Unit))

(λ Enemy.init [self]
  (assert self.enemy-type :must-pass-enemy-type)
  (set self.def (. data.unit-types self.enemy-type))
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
  (let [iv (polar-vec2 (* (math.random) 2 math.pi) 20)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))

(set Enemy.__defaults
     (lume.merge Unit.__defaults {:team :enemy}))

{: Unit
 : Enemy}
