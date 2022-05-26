(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local tiny (require :lib.tiny))
(local {: world} (require :ecs))
(local timeline (require :timeline))
(local {: state : reset-state} (require :state))
(local {: new-entity} (require :helpers))
(local {: layout : get-layout-rect} (require :imgui))
(local aabb (require :aabb))
(import-macros {: fire-timeline} :macros)

(λ text [context props]
  "Basic text component"
  (let [rect (get-layout-rect context)
        alignment (or props.align :center)]
    (when props.color
      (love.graphics.setColor (unpack (props.color:serialize)))
      (love.graphics.print (or props.text "nil")
                           (. rect alignment :x)
                           (. rect alignment :y)))))

(λ image [context props]
  "Basic image component"
  (let [rect (get-layout-rect context)]
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.push)
    (love.graphics.translate rect.center.x rect.center.y)
    (love.graphics.scale (or props.scale 1) (or props.scale 1))
    (love.graphics.draw props.image)
    (love.graphics.pop)))

(λ view [context props]
  "Basic view component"
  (when props.color
    (graphics.rectangle context.position context.size props.color)))
    ;(print context.position context.size)
  ; (let [rect (get-layout-rect context)])))
  ;     (love.graphics.circle :fill rect.center.x rect.center.y 6))))
  ;     (love.graphics.circle :fill rect.left-center.x rect.left-center.y 6))))
  ;     (love.graphics.circle :fill rect.right-center.x rect.right-center.y 6))))
  ;     (love.graphics.circle :fill rect.top-center.x rect.top-center.y 6))))
  ;     (love.graphics.circle :fill rect.bottom-center.x rect.bottom-center.y 6))))

(λ get-mouse-position []
  (let [(x y) (love.mouse.getPosition)]
    (vec x y)))

(λ mouse-interaction [context]
  "Returns values indicating mouse-down? and hovering? state"
  (let [mpos (get-mouse-position)
        mouse-down? (love.mouse.isDown 1)
        (sx sy) (love.graphics.transformPoint context.position.x
                                              context.position.y)
        screen-space-pos (vec sx sy)
        screen-space-size context.size
        rect (aabb screen-space-pos screen-space-size)
        hovering? (rect:contains-point? mpos)]
    (values mouse-down? hovering?)))

(λ button [?state context props]
  "An immediate mode button"
  (let [state (or ?state {:hover false})
        (mouse-down? in-range?) (mouse-interaction context)]
    (set state.hover in-range?)
    (when (and props.on-click
               in-range?
               (not state.mouse-down?)
               mouse-down?)
      (props.on-click))
    (set state.mouse-down? mouse-down?)
    (love.graphics.setColor (unpack (if state.hover
                                        [0.4 0.4 0.4 1]
                                        [0.2 0.2 0.2 1])))
    (love.graphics.rectangle :fill
                            context.position.x
                            context.position.y
                            context.size.x
                            context.size.y)
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print (or props.label "na") context.position.x context.position.y)
    state))

(local Unit (require :unit))
(local {: Box2dRectangle} (require :wall))

;; Constants
(local stage-size (vec 720 450))
(local center-stage (/ stage-size 2))
(local arena-margin (vec 100 70))
(local arena-offset (vec 0 -40))
(local arena-size (- stage-size (* arena-margin 2)))

;; Reset ECS 
(tiny.clearEntities world)
(tiny.clearSystems world)

;; init-system handles calling init on entities with a dt
(local init-system (tiny.processingSystem))
(set init-system.filter (tiny.requireAll :init))

(λ init-system.onAdd [self e]
  (e:init))

(tiny.addSystem world init-system)

;; update-system handles calling update on entities with a dt
(local update-system (tiny.processingSystem))
(set update-system.filter (tiny.requireAll :update))

(λ update-system.process [self e dt]
  (e:update dt))

(tiny.addSystem world update-system)

(local timeline-system (tiny.processingSystem))
(set timeline-system.filter (tiny.requireAll :timeline))

(λ timeline-system.process [self e dt]
  (when (e.timeline:update dt)
    (tiny.removeEntity world e)))

(tiny.addSystem world timeline-system)

;; draw system handles drawing in order of highest-to-lowest z-index
(local draw-system (tiny.sortedProcessingSystem))
(set draw-system.filter (tiny.requireAll :draw :z-index))

(λ draw-system.preProcess [self dt]
  (love.graphics.push)
  (love.graphics.scale state.screen-scale.x state.screen-scale.y))
  
(λ draw-system.process [self e dt]
  (e:draw))

(λ draw-system.postProcess [self dt]
  (love.graphics.pop))

(λ draw-system.compare [self e1 e2]
  (< e1.z-index e2.z-index))
  
(tiny.addSystem world draw-system)

;; arena-draw system handles drawing in order of highest-to-lowest z-index
;; draws to arena canvas
(local arena-canvas (love.graphics.newCanvas arena-size.x arena-size.y))
(arena-canvas:setFilter :nearest :nearest)
(local arena-draw-system (tiny.sortedProcessingSystem))
(set arena-draw-system.filter (tiny.requireAll :arena-draw :z-index))

(λ arena-draw-system.preProcess [self]
  (set self.old-canvas (love.graphics.getCanvas))
  (love.graphics.setCanvas arena-canvas)
  (love.graphics.push)
  (love.graphics.origin)
  (love.graphics.setColor 0 0 0 0.7)
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
    
;; Main
(λ shop-row []
  [view {:display :absolute
         :left 20
         :position (vec 0 (- stage-size.y 300))
         :flex-direction :row
         :size (vec stage-size.x 100)
         :padding (vec 10 10)}
   [[view {:color (rgba 0.5 0.3 0.3 1)
            :padding (vec 10 10)}]
    [view {:color (rgba 0.3 0.3 0.5 1)
            :padding (vec 10 10)}]
    [view {:color (rgba 0.3 0.5 0.3 1)
            :padding (vec 10 10)}]]])

(λ draw-bg []
  (graphics.rectangle (vec 0 0) stage-size (hexcolor :212121ff)))

(λ main []
  (reset-state)
  (set-win-size)

  ;; Add global drawer
  (tiny.addEntity world
                  {:z-index 100
                   :draw
                   (λ self []
                     ;(draw-bg)
                     (love.graphics.setColor 1 1 1 1)
                     (love.graphics.draw arena-canvas
                                         arena-margin.x
                                         arena-margin.y 0 1 1))})

  ;; Add director 
  (set state.director
       {:z-index 10000
        :draw
        (λ [self]
          (layout #nil {:size stage-size} 
            [[view {:display :absolute}
              [(shop-row)]]])) 
        :update
        (λ [self dt]
          (state.pworld:update dt))})

  (tiny.addEntity world state.director)

  (tiny.add world
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) arena-size.y)
                 :size (vec arena-size.x 10)})
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) 0)
                 :size (vec arena-size.x 10)})
    (new-entity Box2dRectangle
                {:pos (vec 0 (/ arena-size.y 2))
                 :size (vec 10 arena-size.y)})
    (new-entity Box2dRectangle
                {:pos (vec arena-size.x (/ arena-size.y 2))
                 :size (vec 10 arena-size.y)}))

  (fire-timeline
    (for [i 1 100]
      (coroutine.yield)
      (tiny.addEntity world
        (new-entity Unit
                    {:pos (vec (love.math.random 100 200)
                               (love.math.random 100 200))})))))

(main)
(tiny.refresh world)

{:update
 (fn update [dt set-mode]
   (tiny.update world dt))
 :keypressed (fn keypressed [key set-mode])
 :resize set-win-size}
                 ;(love.event.quit))}
