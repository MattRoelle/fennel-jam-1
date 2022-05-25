(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local tiny (require :lib.tiny))
(local {: state : reset-state} (require :state))
(local Unit (require :unit))

;; Constants
(local stage-size (vec 720 450))
(local center-stage (/ stage-size 2))
(local arena-margin (vec 40 70))
(local arena-offset (vec 0 -32))
(local arena-size (- stage-size (* arena-margin 2)))


;; ECS setup
(local world (tiny.world))

;; update-system handles calling :update on entities with a dt
(local update-system (tiny.processingSystem))
(set update-system.filter (tiny.requireAll :update))

(λ update-system.process [self e dt]
  (e:update dt))

(tiny.addSystem world update-system)

;; draw system handles drawing in order of highest-to-lowest z-index
(local draw-system (tiny.processingSystem))
(set draw-system.filter (tiny.requireAll :draw :z-index))

(λ draw-system.preProcess [self dt]
  (love.graphics.push)
  (love.graphics.scale state.screen-scale.x state.screen-scale.y))
  
(λ draw-system.process [self e dt]
  (e:draw))

(λ draw-system.postProcess [self dt]
  (love.graphics.pop))

(λ draw-system.compare [self e1 e2]
  (> e1.z-index e2.z-index))
  
(tiny.addSystem world draw-system)

;; arena-draw system handles drawing in order of highest-to-lowest z-index
;; draws to arena canvas
(local arena-canvas (love.graphics.newCanvas arena-size.x arena-size.y))
(arena-canvas:setFilter :nearest :nearest)
(local arena-draw-system (tiny.processingSystem))
(set arena-draw-system.filter (tiny.requireAll :arena-draw :z-index))

(λ arena-draw-system.preProcess [self]
  (set self.old-canvas (love.graphics.getCanvas))
  (love.graphics.setCanvas arena-canvas)
  (love.graphics.push)
  (love.graphics.origin)
  (love.graphics.setColor 0 0 0 1)
  (love.graphics.rectangle :fill 0 0 arena-size.x arena-size.y)
  (love.graphics.setColor 1 1 1 1))

(λ arena-draw-system.process [self e dt]
  (e:arena-draw))

(λ arena-draw-system.postProcess [self]
  (love.graphics.pop)
  (love.graphics.setCanvas self.old-canvas))

(λ arena-draw-system.compare [self e1 e2]
  (> e1.z-index e2.z-index))
  
(tiny.addSystem world arena-draw-system)

;; Screen scaling
(var window-size (vec (love.graphics.getWidth)
                      (love.graphics.getHeight)))

(λ set-win-size []
  (set window-size (vec (love.graphics.getWidth)
                        (love.graphics.getHeight)))
  (let [sx (/ window-size.x stage-size.x)
        sy (/ window-size.y stage-size.y)
        s (math.min sx sy)]
    (when (not= sx sy)
      (if (= s sx)
          (set state.screen-offset (vec 0 (* 0.5 (- window-size.y (* s stage-size.y)))))
          (set state.screen-offset (vec (* 0.5 (- window-size.x (* s stage-size.x))) 0))))
    (set state.screen-scale (vec s s))))
    
(set-win-size)

;; Main
(λ draw-bg []
  (graphics.rectangle (vec 0 0) stage-size (hexcolor :212121ff)))

(λ main []
  (reset-state)

  ;; Add global drawer
  (tiny.addEntity world
                  {:z-index 100
                   :draw
                   (λ self []
                     (draw-bg)
                     (love.graphics.setColor 1 1 1 1)
                     (love.graphics.draw arena-canvas
                                         arena-margin.x
                                         arena-margin.y 0 1 1))})

  (tiny.addEntity world (Unit.new)))

(main)

{:update
 (fn update [dt set-mode]
   (tiny.update world dt))
 :keypressed (fn keypressed [key set-mode])
 :resize set-win-size}
                 ;(love.event.quit))}
