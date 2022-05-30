(import-macros {: fire-timeline : imm-stateful} :macros)

(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity : get-id} (require :helpers))
(local {: Box2dCircle : Box2dRectangle} (require :box2d))
(local state (require :state))
(local data (require :data))
(local timeline (require :timeline))
(local assets (require :assets))
(local {: new-entity} (require :helpers))
(local tiny (require :lib.tiny))
(local ecs (require :ecs))

(λ screen-text-flash [s pos color ?font]
  (fire-timeline
    (local txt {: pos
                :id (tostring (get-id))
                :z-index 100
                :__timers {:spawn {:t 0 :active true}}
                :draw
                (λ [self]
                  (graphics.print-centered s (or ?font assets.f32)
                                           (+ self.pos (vec 0 (* self.timers.spawn.t -100)))
                                           (rgba color.r color.g color.b (- 1 self.timers.spawn.t))))})
    (tiny.addEntity ecs.world txt)
    (timeline.wait 1)
    (set txt.dead true)))

(λ text-flash [s pos color ?font]
  (fire-timeline
    (local txt {: pos
                :id (tostring (get-id))
                :z-index 100
                :__timers {:spawn {:t 0 :active true}}
                :arena-draw
                (λ [self]
                  (graphics.print-centered s (or ?font assets.f32)
                                           (+ self.pos (vec 0 (* self.timers.spawn.t -100)))
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
              Box2dRectangle
               {:restitution 1
                : color
                :pos p
                :body-type :dynamic
                :linear-damping 0
                :mass 0.5
                :category "10000000"
                :mask "10000000"
                :size (vec 4 4)
                :iv (polar-vec2 (* 2 math.pi (math.random))
                               (+ 8 (* 4 (math.random))))}))
      (tiny.addEntity ecs.world ent)
      (fire-timeline
       (timeline.tween 0.6 ent.size {:x 0 :y 0} :outQuad)
       (set ent.dead true)))))


{: text-flash
 : screen-text-flash
 : box2d-explode}
