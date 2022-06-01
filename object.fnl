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

(local Object {})
(set Object.__index Object)

(λ Object.time-update [self dt]
  (var colliding-ent nil)
  (fn cb [fixture]
    (let [id (fixture:getUserData)
          ent (state.get-entity-by-id id)]
      (when (and ent ent.team (= ent.team self.target-team))
        (set colliding-ent ent)))
    0)
  (let [p self.pos]
    (state.state.pworld:rayCast (- p.x self.radius) p.y
                                (+ p.x self.radius) p.y
                                cb)
    (state.state.pworld:rayCast p.x (- p.y self.radius)
                                p.x (+ p.y self.radius)
                                cb))
  (when colliding-ent
    (state.state.director:object-collision self colliding-ent)))

(λ Object.arena-draw [self]
  (graphics.circle self.pos self.radius (rgba 1 0 0 1)))

(λ Object.init [self])

(set Object.__defaults
     {:z-index 10
      :radius 4
      :destroy-after-combat true
      :target-team :enemy})

{: Object}
