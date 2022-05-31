(import-macros {: fire-timeline : imm-stateful} :macros)

(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity} (require :helpers))
(local {: Box2dCircle : Box2dRectangle : Box2dPolygon} (require :box2d))
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
(local aseprite (require :aseprite))

(local Unit {})
(set Unit.__index Unit)

(λ Unit.get-body-pos [self]
  (let [(x y) (self.box2d.body:getPosition)]
    (vec x y)))

(λ Unit.take-dmg [self v]
  (set self.unit.hp (- self.unit.hp v))
  (effects.text-flash (.. "-" v)
                      (+ (- (self:get-body-pos) (vec 4 0))
                         (vec (love.math.random -10 10)
                              (love.math.random -10 10)))
                      (if (= self.team :enemy)
                          (rgba 1 1 1 1)
                          (rgba 1 0 0 1))
                      assets.f32)
  (self:flash))

(λ Unit.flash [self]
  (when self.flash-timline
    (self.flash-timeline:cancel))
  (set self.flash-timeline
       (fire-timeline
        (set self.scale (vec 1.3 1.3))
        (set self.flashing true)
        (timeline.tween 0.2 self {:scale (vec 1 1)} :outQuad)
        (set self.flashing false)
        (set self.scale (vec 1 1)))))

(λ Unit.gen-eyes [self]
  (set self.eye-gap (+ 0.3 (* 0.3 (math.random))))
  (set self.eye-dist (+ 7 (* 3 (math.random))))
  (set self.eye-size (if (> (math.random) 0.5) 3 4)))

(λ Unit.init [self]
  (set self.scale (vec 1 1))
  (assert self.unit :must-pass-unit)
  (set self.def (or (. data.unit-types self.unit.type)
                    (. data.enemy-types self.unit.type)))
  (if (= :player self.team)
    (set state.state.unit-count (+ state.state.unit-count 1))
    (set state.state.enemy-count (+ state.state.enemy-count 1)))
  (set self.bump-force (or self.def.bump-force 64))
  (self:gen-eyes)
  (set self.box2d
       (new-entity
        (match (or self.def.shape-type)
          :circle Box2dCircle
          _ Box2dPolygon)
        {:radius (if (= :table (type self.def.radius))
                     (love.math.random (. self.def.radius 1) (. self.def.radius 2))
                     (or self.def.radius 8))
         :points (or self.def.points [-10 0 0 -10 10 0 0 10])
         :size (or self.def.size (vec 8 8))
         :pos self.pos
         :body-type :dynamic
         :angular-damping (or self.def.angular-damping 2)
         :linear-damping (or self.def.linear-damping 0.5)
         :mass (or self.def.mass 1)
         :restitution (or self.def.restitution 0.99)
         :category (if (= self.team :player)
                     "00000001"
                     "00000010")
         :mask (if (= self.team :player)
                 "10001011"
                 "10000111")}))
  (self.box2d:init self.id)
  (let [iv (polar-vec2 (* (math.random) 2 math.pi) 20)]
    (self.box2d.body:applyLinearImpulse iv.x iv.y))
  (let [(x y) (self.box2d.body:getPosition)]
    (state.state.director:muzzle-flash (vec x y))))


(λ Unit.get-unit-color [self]
  (match self.def.color
    :enemy (hexcolor :b13253ff)
    :bumper (hexcolor :ef7d57ff)
    :shooter (hexcolor :38b764ff)
    :support (hexcolor :41a6f6ff)
    _ (rgba 1 1 1 1)))

(λ Unit.pop [self]
  (fire-timeline
   (timeline.tween 0.4 self {:scale (vec 1.8 1.8)} :outQuad)
   (let [(x y) (self.box2d.body:getPosition)]
     (state.state.director:muzzle-flash (vec x y) 2.5))
   (set self.dead true)))

(λ Unit.update-eyes [self]
  (match self.eye-state
    :blinking
    (when (> self.timers.blink.t 0.1)
      (set self.timers.blink.t 0)
      (set self.eye-state :normal))
    _
    (when (> self.timers.blink.t 2)
      (set self.timers.blink.t 0)
      (set self.eye-state :blinking))))

(λ Unit.draw-eyes [self]
  (let [a1 (- self.eye-gap)
        a2 (+ self.eye-gap)
        e1 (+ (polar-vec2 a1 self.eye-dist))
        e2 (+ (polar-vec2 a2 self.eye-dist))]
    (if self.flashing
        (do
          (graphics.image aseprite.flash-eye e1)
          (graphics.image aseprite.flash-eye e2))
        (match self.eye-state
          :blinking
          (do
            (graphics.rectangle (- e1 (vec 2 2)) (vec 2 5) (hexcolor :000000ff))
            (graphics.rectangle (- e2 (vec 2 2)) (vec 2 5) (hexcolor :000000ff)))
          _
          (do
            (graphics.circle e1 self.eye-size (hexcolor :f1f1f1ff))
            (graphics.circle e2 self.eye-size (hexcolor :f1f1f1ff))
            (graphics.circle e1 2 (hexcolor :000000ff))
            (graphics.circle e2 2 (hexcolor :000000ff)))))))

(λ Unit.arena-draw [self]
  (let [(x y) (self.box2d.body:getPosition)
        a (self.box2d.body:getAngle)
        p (vec x y)
        c
        (if self.flashing
            (rgba 1 1 1 1)
            (self:get-unit-color))]
    (love.graphics.push)
    (love.graphics.translate x y)
    (love.graphics.rotate a)
    (love.graphics.scale self.scale.x self.scale.y)
    (graphics.circle (vec 0 0) 3 (hexcolor :f10000ff))
    (self.box2d:draw-local-points c)
    (self:draw-eyes)
    (love.graphics.pop)
    (when (and (= :shop state.state.phase)
               self.unit.hovering)
      (graphics.stroke-circle (vec x y) 32 4 (rgba 1 1 1 1)))))

(λ Unit.random-update [self dt]
  (when (> 0.02 (math.random))
    (let [iv (polar-vec2 (* (math.random) 2 math.pi) 5)]
      (self.box2d.body:applyLinearImpulse iv.x iv.y))))

(λ Unit.get-wobble [self]
  (- 0.3 (* 0.6 (math.random))))

(λ Unit.get-pos [self]
  (let [(x y) (self.box2d.body:getPosition)]
    (vec x y)))

(λ Unit.fire-projectile [self direction]
  (let [(x y) (self.box2d.body:getPosition)
        pos (+ (vec x y) (* (direction:normalize) 10))]
    (self.box2d.body:setAngle (direction:angle))
    (state.state.director:muzzle-flash pos)
    (tiny.addEntity ecs.world
                    (new-entity Projectile
                                {: pos
                                 :speed (or self.def.fire-speed 50)
                                 :range (or self.def.range 0.3)
                                 : direction}))))

(λ Unit.shoot-enemy [self e]
  (let [(ex ey) (e.box2d.body:getPosition)
        ep (vec ex ey)
        (x y) (self.box2d.body:getPosition)
        p (vec x y)
        angle (p:angle-to ep)
        wobble (self:get-wobble)
        iv (polar-vec2 (+ angle wobble) 3)]
    (self:fire-projectile iv)))

(λ Unit.get-enemies-in-range [self r]
  (let [(x y) (self.box2d.body:getPosition)]
    (icollect [k v (pairs state.state.teams.enemy)]
      (let [(x2 y2) (v.box2d.body:getPosition)]
        (when (< (: (vec x y) :distance-to (vec x2 y2))
                 (or self.pulse-radius 70))
          v)))))
          
(λ Unit.pulse-update [self dt]
  (when (> self.timers.shoot-tick.t 0.25)
    (let [in-range (self:get-enemies-in-range (* 1.1 (or self.pulse-radius 70)))]
      (when (> (length in-range) 0)
        (set self.timers.shoot-tick.t 0)
        (each [_ e (ipairs in-range)]
          (when e
            (self:shoot-enemy e)))))))

(λ Unit.random-move-update [self dt]
  (when (> self.timers.move-tick.t 2)
    (set self.timers.move-tick.t 0)
    (let [iv (polar-vec2 (* (math.random) 2 math.pi) 16)]
      (self.box2d.body:applyLinearImpulse iv.x iv.y))))

(λ Unit.get-random-target [self]
  (let [target-team (if (= :player self.team) :enemy :player)
        targ-team  (lume.keys (. state.state.teams target-team))
        e-id (if (> (length targ-team) 0)
                 (lume.randomchoice targ-team)
                 nil)]
    (when e-id (. state.state.teams target-team e-id))))

(λ Unit.shoot-update [self dt]
  (when (> self.timers.shoot-tick.t (or self.def.fire-rate 2))
    (set self.timers.shoot-tick.t 0)
    (when (> state.state.enemy-count 0)
      (if (= :random-shoot self.def.ai-type)
          (self:fire-projectile (polar-vec2 (* 2 math.pi (math.random)) 1))
          (let [e (self:get-random-target)]
            (when e
              (self:shoot-enemy e)))))))

(λ Unit.destroy [self]
  (effects.box2d-explode (self:get-body-pos) 5 4 (rgba 1 1 1 1))
  (self.box2d.body:destroy)
  (if (= :player self.team)
    (set state.state.unit-count (- state.state.unit-count 1))
    (set state.state.enemy-count (- state.state.enemy-count 1))))

(λ Unit.bump-enemy [self e]
  (let [(ex ey) (e.box2d.body:getPosition)
        ep (vec ex ey)
        (x y) (self.box2d.body:getPosition)
        p (vec x y)
        angle (p:angle-to ep)
        iv (polar-vec2 angle (or self.bump-force 64))]
    (self.box2d.body:setAngle (iv:angle))
    (self.box2d.body:applyLinearImpulse iv.x iv.y)))

(λ Unit.bump-update [self dt]
  (when (and (> self.timers.move-tick.t (or self.def.bump-timer 1.75)))
    (set self.timers.move-tick.t 0)
    (let [e (self:get-random-target)]
      (when e
        (self:bump-enemy e)))))

(λ Unit.enemy-ai-update [self dt]
  (when (or (not self.target) self.target.dead)
    (let [e (self:get-random-target)]
      (set self.target e)))
  (when (and (> self.timers.move-tick.t (or self.def.bump-timer 1.75)))
    (set self.timers.move-tick.t 0)
    (when self.target
      (self:bump-enemy self.target))))

(λ Unit.look-velocity-dir [self dt]
  (let [(vx vy) (self.box2d.body:getLinearVelocity)
        a (math.atan2 vy vx)
        theta (self.box2d.body:getAngle)
        da (- theta a)]
    (self.box2d.body:setAngle a)))
    ;(when (> (+ (* vx vx) (* vy vy)) 0.1)
    ; (self.box2d.body:applyAngularImpulse (* -64 dt da)))))

(λ Unit.update [self dt]
  (self:update-eyes dt)
  (let [angle (self.box2d.body:getAngle)
        f (* dt 1000)]
    (self.box2d.body:applyForce (* f (math.cos angle))
                                (* f (math.sin angle))))
  (when (<= self.unit.hp 0)
    (set self.dead true))
  ;;(self:look-velocity-dir dt)
  (if (and self.targpos (= :shop state.state.phase))
    (self.box2d.body:setPosition self.targpos.x self.targpos.y)
    (match (or self.def.ai-type :bump)
      :basic (self:enemy-ai-update dt)
      :bump (self:bump-update dt)
      :shoot (self:shoot-update dt)
      :random-shoot (self:shoot-update dt))))

(set Unit.__defaults
     {:z-index 10
      :__timers
      {:spawn {:t 0 :active true}
       :move-tick {:t 0 :active true :random true}
       :shoot-tick {:t 0 :active true :random true}
       :blink {:t 0 :active true :random true}}
      :pos (vec 32 32)
      :team :player})

(fn get-random-points []
  (local ret [])
  (local np 8)
  (for [i 1 np]
    (let [t (* 2 math.pi (/ i np))
          r (love.math.random 6 14)]
      (table.insert ret (* r (math.cos t)))
      (table.insert ret (* r (math.sin t)))))
  ret)

{: Unit}
