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

(local {: spineasset} (require :spine))

(local referee-spine (spineasset :spine :idle))

(local Referee {})
(set Referee.__index Referee)

(λ Referee.init [self]
  (set self.spine (referee-spine)))

(λ Referee.update [self dt]
  (self.spine:update dt))

(λ Referee.draw [self]
  (love.graphics.push)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.translate 100 100)
  (self.spine:draw)
  (love.graphics.pop))

(set Referee.__defaults
     {:z-index 100000
      :pos (vec 32 32)})

{: Referee}
