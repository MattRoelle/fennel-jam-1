(import-macros {: fire-timeline : imm-stateful} :macros)

(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity} (require :helpers))
(local {: Box2dCircle} (require :box2d))
(local state (require :state))
(local data (require :data))
(local timeline (require :timeline))
(local assets (require :assets))

(local Projectile {})
(set Projectile.__index Projectile)

(λ Projectile.update [self dt]
  (when (> self.timers.spawn.t self.range)
    (set self.dead true)))

(λ Projectile.init [self]
  (set self.box2d
       (new-entity Box2dCircle {:color (rgba (math.abs (math.random))
                                             (math.abs (math.random))
                                             (math.abs (math.random))
                                             1)
                                :radius 6
                                :pos self.pos
                                :body-type :dynamic
                                :linear-damping 0
                                :restitution 1
                                :mass 0.5
                                :id self.id
                                :category "00000100"
                                :mask "10000010"}))
  (self.box2d:init self.id)
  (let [iv (* self.direction self.speed)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))

(λ Projectile.arena-draw [self]
  (let [(x y) (self.box2d.body:getPosition)
        p (vec x y)]
    (graphics.circle
     p
     self.box2d.radius
     (rgba 1 1 1 1))))

(λ Projectile.destroy [self]
  (self.box2d.body:destroy))

(set Projectile.__defaults
     {:z-index 10
      :flash-t 0
      :bullet {:dmg 3}
      :__timers {:spawn {:t 0 :active true}}
      :pos (vec 32 32)})

Projectile
