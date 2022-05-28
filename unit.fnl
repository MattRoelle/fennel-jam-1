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
(local effects (require :effects))
(local palette (require :palette))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.get-body-pos [self]
  (let [(x y) (self.box2d.body:getPosition)]
    (vec x y)))

(λ Unit.take-dmg [self v]
  (set self.hp (- self.hp v))
  (effects.text-flash (.. "-" v) (- (self:get-body-pos) (vec 4 0))
                      (rgba 1 1 1 1) assets.f32)
  (self:flash))

(λ Unit.flash [self]
  (when self.flash-timline
    (self.flash-timeline:cancel))
  (set self.flash-timeline
       (fire-timeline
         (set self.flash-t 1)
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
                                :linear-damping
                                (match self.unit-type
                                  :pulse 0
                                  :shooter 1.5
                                  _ 0.5)
                                :mass
                                (match self.unit-type
                                  :warrior 5
                                  _ 1) 
                                :restitution
                                (match self.unit-type
                                  _ 0.99)
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
     (if (> self.box2d.radius 10)
         (* self.box2d.radius 1.1)
         (* self.box2d.radius 1.4))
     (match (values self.unit-type self.enemy-type)
       (:warrior _) palette.default.green
       (:shooter _) palette.default.blue
       (:pulse _) palette.default.teal
       (_ :basic) palette.default.red
       (_ :brute-1) palette.default.red
       (_ _) (rgba 1 1 1 1)))
    (when (or (= self.unit-type :warrior))
      (graphics.rectangle (- p (vec 8 8)) (vec 16 16)
                          (rgba 0 1 0 1)))
    (when (or (= self.unit-type :pulse))
      (graphics.circle
       p 70 (rgba 1 0 1 0.05)))
    (when self.unit-type
      (graphics.print-centered self.hp assets.f16 (+ p (vec 0 20)) (rgba 1 1 1 1)))
    (when (> self.flash-t 0)
      (graphics.circle
       p
       (* self.box2d.radius (* (+ 1.15 (* (if (> self.box2d.radius 10) 0.3 0.7) self.flash-t))))
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

(λ Unit.get-enemies-in-range [self r]
  (let [(x y) (self.box2d.body:getPosition)]
    (icollect [k v (pairs state.state.teams.enemy)]
      (let [(x2 y2) (v.box2d.body:getPosition)]
        (when (< (: (vec x y) :distance-to (vec x2 y2)) (or self.pulse-radius 70))
          v)))))
          
(λ Unit.pulse-update [self dt]
  (when (> self.timers.shoot-tick.t 2)
    (let [in-range (self:get-enemies-in-range (* 1.1 (or self.pulse-radius 70)))]
      (when (> (length in-range) 0)
        (set self.timers.shoot-tick.t 0)
        (each [_ e (ipairs in-range)]
          (when e
            (self:shoot-enemy e)))))))

(λ Unit.shoot-update [self dt]
  (when (> self.timers.move-tick.t 1.5)
    (set self.timers.move-tick.t 0)
    (let [iv (polar-vec2 (* (math.random) 2 math.pi) 10)]
      (self.box2d.body:applyLinearImpulse iv.x iv.y)))
  (when (> self.timers.shoot-tick.t 0.5)
    (set self.timers.shoot-tick.t 0)
    (when (> state.state.enemy-count 0)
      (let [e-id (lume.randomchoice (lume.keys state.state.teams.enemy))
            e (. state.state.teams.enemy e-id)]
        (when e
          (self:shoot-enemy e))))))

(λ Unit.destroy [self]
  (effects.box2d-explode (self:get-body-pos) 10 4 (rgba 1 1 1 1))
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
    :shooter (self:shoot-update dt)
    :pulse (self:pulse-update dt)))

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
  (effects.box2d-explode (self:get-body-pos) 10 4 (rgba 1 0 0 1))
  (self.box2d.body:destroy)
  (state.state.director:add-gold 1)
  (when (> (math.random) 0.5)
    (state.state.director:loot self))
  (set state.state.enemy-count
       (- state.state.enemy-count 1)))

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
                                :radius
                                (match self.enemy-type
                                  :brute-1 40
                                  _ (love.math.random 6 10))
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
