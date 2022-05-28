(import-macros {: fire-timeline : imm-stateful} :macros)

(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity : get-id} (require :helpers))
(local {: Box2dCircle} (require :wall))
(local state (require :state))
(local data (require :data))
(local timeline (require :timeline))
(local assets (require :assets))
(local {: new-entity} (require :helpers))
(local tiny (require :lib.tiny))
(local ecs (require :ecs))

(λ text-flash [s pos color ?font]
  (fire-timeline
    (local txt {: pos
                :id (tostring (get-id))
                :z-index 100
                :__timers {:spawn {:t 0 :active true}}
                :arena-draw
                (λ [self]
                  (graphics.print-centered s (or ?font assets.f32)
                                           (+ self.pos (vec 0 (* self.timers.spawn.t -50)))
                                           (rgba color.r color.g color.b (- 1 self.timers.spawn.t))))})
    (tiny.addEntity ecs.world txt)
    (timeline.wait 1)
    (set txt.dead true)))

(λ box2d-explode [pos count r color]
  (for [i 1 count]
    (let [p (+ pos (polar-vec2 (* 2 math.pi (math.random)) r))
          radius (love.math.random 1 4)]
      (local ent
             (new-entity
              Box2dCircle
               {:restitution 1
                : color
                :pos p
                :body-type :dynamic
                :linear-damping 0
                :mass 0.5
                :category "10000000"
                :mask "10000000"
                :iv (polar-vec2 (* 2 math.pi (math.random))
                               (+ 8 (* 4 (math.random))))
                : radius}))
      (tiny.addEntity ecs.world ent)
      (fire-timeline
       (timeline.wait 0.3)
       (set ent.dead true)))))


{: text-flash
 : box2d-explode}