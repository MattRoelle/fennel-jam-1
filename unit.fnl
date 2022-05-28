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
(local {: new-entity} (require :helpers))
(local tiny (require :lib.tiny))
(local ecs (require :ecs))
(local Projectile (require :projectile))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.flash [self]
  (when self.flash-timline
    (self.flash-timeline:cancel))
  (set self.flash-timeline
       (fire-timeline
         (set self.flash-t 2)
         (timeline.tween 0.25 self {:flash-t 0} :outQuad))))

(λ Unit.init [self]
  (assert self.unit-type :must-pass-unit-type)
  (set self.def (. data.unit-types self.unit-type))
  (set state.state.unit-count (+ state.state.unit-count 1))
  (set self.hp self.def.hp)
  (set self.box2d
       (new-entity Box2dCircle {:color (rgba (math.abs (math.random))
                                             (math.abs (math.random))
                                             (math.abs (math.random))
                                             1)
                                :radius 5
                                :pos self.pos
                                :body-type :dynamic
                                :linear-damping 0.5
                                :mass 1 
                                :restitution 0.99
                                :category "00000001"
                                :mask "10001011"}))
  (self.box2d:init self.id)
  (let [iv (polar-vec2 (* (math.random) 2 math.pi) 20)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))


(λ Unit.arena-draw [self]
  (let [(x y) (self.box2d.body:getPosition)
        p (vec x y)]
    (graphics.circle
     p
     (* self.box2d.radius 1.5)
     (match self.unit-type
       :warrior (rgba 0 1 0 1)
       :shooter (rgba 0 0 1 1)
       _ (rgba 1 1 1 1)))
    (graphics.print-centered self.hp assets.f16 (+ p (vec 0 20)) (rgba 1 1 1 1))
    (when (> self.flash-t 0)
      (graphics.circle
       p
       (* self.box2d.radius (+ 1.5 self.flash-t))
       (rgba 1 1 1 1)))))
    ;(graphics.rectangle (- p (vec 8 14)) (vec 16 4) (rgba 1 1 1 1))))

(λ Unit.random-update [self dt]
  (when (> 0.02 (math.random))
    (let [iv (polar-vec2 (* (math.random) 2 math.pi) 5)]
      (self.box2d.body:applyLinearImpulse iv.x iv.y))))

(λ Unit.shoot-enemy [self e]
  (let [(ex ey) (e.box2d.body:getPosition)
        ep (vec ex ey)
        (x y) (self.box2d.body:getPosition)
        p (vec x y)
        angle (p:angle-to ep)
        iv (polar-vec2 angle 1)]
    (tiny.addEntity ecs.world (new-entity Projectile
                                          {:pos (vec x y)
                                           :direction iv}))))

(λ Unit.shoot-update [self dt]
  (when (> self.timers.shoot-tick.t 0.5)
    (set self.timers.shoot-tick.t 0)
    (when (> state.state.enemy-count 0)
      (let [e-id (lume.randomchoice (lume.keys state.state.teams.enemy))
            e (. state.state.teams.enemy e-id)]
        (when e
          (self:shoot-enemy e))))))

(λ Unit.destroy [self]
  (self.box2d.body:destroy)
  (set state.state.unit-count (- state.state.unit-count 1)))

(λ Unit.bump-enemy [self e]
  (let [(ex ey) (e.box2d.body:getPosition)
        ep (vec ex ey)
        (x y) (self.box2d.body:getPosition)
        p (vec x y)
        angle (p:angle-to ep)
        iv (polar-vec2 angle 32)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))

(λ Unit.bump-update [self dt]
  (when (and (> state.state.enemy-count 0) (> self.timers.move-tick.t 1.5))
    (set self.timers.move-tick.t 0)
    (let [e-id (lume.randomchoice (lume.keys state.state.teams.enemy))
          e (. state.state.teams.enemy e-id)]
      (when e
        (self:bump-enemy e)))))

(λ Unit.update [self dt]
  (when (<= self.hp 0)
   (set self.dead true))
  (match self.unit-type
    :warrior (self:bump-update dt)
    :shooter (self:shoot-update dt)))

(set Unit.__defaults
     {:z-index 10
      :flash-t 0
      :__timers {:spawn {:t 0 :active true}
                 :move-tick {:t 0 :active true}
                 :shoot-tick {:t 0 :active true}}
      :pos (vec 32 32)
      :team :player})

(local Enemy (setmetatable {} Unit))
(set Enemy.__index Enemy)

(λ Enemy.destroy [self]
  (state.state.director:add-gold 1)
  (state.state.director:loot self)
  (print :here)
  (set state.state.enemy-count
       (- state.state.enemy-count 1)))

(λ Enemy.arena-draw [self]
  (let [(x y) (self.box2d.body:getPosition)]
    (graphics.circle
     (vec x y)
     (* self.box2d.radius 1.5)
     (match self.enemy-type
       _ (rgba 1 0 0 1)))
    (when (> self.flash-t 0)
      (graphics.circle
       (vec x y)
       (* self.box2d.radius (+ 1.5 self.flash-t))
       (rgba 1 1 1 1)))))

(λ Enemy.update [self dt]
  (when (<= self.hp 0)
    (set self.dead true)))

(λ Enemy.init [self]
  (assert self.enemy-type :must-pass-enemy-type)
  (set self.def (. data.enemy-types self.enemy-type))
  (set self.hp self.def.hp)
  (set self.box2d
       (new-entity Box2dCircle {:color (rgba (math.abs (math.random))
                                             (math.abs (math.random))
                                             (math.abs (math.random))
                                             1)
                                :radius (love.math.random 6 10)
                                :pos self.pos
                                :body-type :dynamic
                                :linear-damping 1
                                :mass 3
                                :restitution 0.99
                                :category "00000010"
                                :mask "10000111"}))
  (self.box2d:init self.id)
  (let [iv (polar-vec2 (* (math.random) 2 math.pi) 20)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))

(set Enemy.__defaults
     (lume.merge Unit.__defaults {:team :enemy}))

{: Unit
 : Enemy}
