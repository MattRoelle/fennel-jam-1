(import-macros {: fire-timeline : imm-stateful} :macros)

(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity} (require :helpers))
(local {: Box2dCircle} (require :wall))
(local state (require :state))
(local data (require :data))
(local timeline (require :timeline))
(local assets (require :assets))

(local Projectile {})
(set Projectile.__index Projectile)

(λ Projectile.init [self]
  (set self.box2d
       (new-entity Box2dCircle {:color (rgba (math.abs (math.random))
                                             (math.abs (math.random))
                                             (math.abs (math.random))
                                             1)
                                :radius 2
                                :pos self.pos
                                :body-type :dynamic
                                :linear-damping 0
                                :category 3
                                :mask 2
                                :mass 0.5})) 
  (self.box2d:init self.id)
  (self.box2d.fixture:setCategory 1)
  (let [iv (polar-vec2 (* (math.random) 2 math.pi) 100)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))

(set Projectile.__defaults
     {:z-index 10
      :flash-t 0
      :bullet {:dmg 3}
      :pos (vec 32 32)
      :team :player})

Projectile
