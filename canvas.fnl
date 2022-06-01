(local {: arena-size} (require :constants))

(local arena-canvas-splat (love.graphics.newCanvas arena-size.x arena-size.y))
(arena-canvas-splat:setFilter :nearest :nearest)

arena-canvas-splat
