(import-macros {: fire-timeline} :macros)

(local graphics (require :graphics))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local tiny (require :lib.tiny))
(local ecs (require :ecs))
(local timeline (require :timeline))
(local state (require :state))
(local {: new-entity : get-mouse-position} (require :helpers))
(local aabb (require :aabb))
(local Director (require :director))
(local {: Box2dRectangle} (require :wall))

(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))

(state.reset-state)
(ecs.reset-ecs)

;; init-system handles calling init on entities with a dt
(local init-system (tiny.processingSystem))
(set init-system.filter (tiny.requireAll :init))

(λ init-system.onAdd [self e]
  (e:init))

(tiny.addSystem ecs.world init-system)

;; timer-system handles updating timers on
;; entities which declare a timer field
(local timers-system (tiny.processingSystem))
(set timers-system.filter (tiny.requireAll :__timers))

(λ timers-system.onAdd [self e]
  (set e.timers
    (collect [k v (pairs e.__timers)]
      (values k {:t 0 :active v.active}))))

(λ timers-system.process [self e dt]
  (each [_ v (pairs e.timers)]
    (when v.active
      (set v.t (+ v.t dt)))))

(tiny.addSystem ecs.world timers-system)

;; index-system handles sorting player/enemy units into easily accessible tables
(local index-system (tiny.processingSystem))
(set index-system.filter (tiny.requireAll :id))

(λ index-system.onAdd [self e]
  (tset state.state.idmap e.id e)
  (when e.team
    (tset state.state :teams e.team e.id e))
  (when e.unit-type
    (tset state.state.units e.unit-type e.id e)))

(λ index-system.onRemove [self e]
  (tset state.state.idmap e.id nil)
  (when e.team
    (tset state.state :teams e.team e.id nil))
  (when e.unit-type
    (tset state.state.units e.unit-type e.id nil)))

(tiny.addSystem ecs.world index-system)

;; update-system handles calling update on entities with a dt
(local update-system (tiny.processingSystem))
(set update-system.filter (tiny.requireAll :update))

(λ update-system.process [self e dt]
  (e:update dt))

(tiny.addSystem ecs.world update-system)

(local timeline-system (tiny.processingSystem))
(set timeline-system.filter (tiny.requireAll :timeline))

(λ timeline-system.process [self e dt]
  (when (e.timeline:update dt)
    (tiny.removeEntity ecs.world e)))

(tiny.addSystem ecs.world timeline-system)

;; draw system handles drawing in order of highest-to-lowest z-index
(local draw-system (tiny.sortedProcessingSystem))
(set draw-system.filter (tiny.requireAll :draw :z-index))

(λ draw-system.preProcess [self dt]
  (love.graphics.push)
  (love.graphics.scale state.state.screen-scale.x state.state.screen-scale.y)
  (love.graphics.translate state.state.camera-shake.x state.state.camera-shake.y))
  
(λ draw-system.process [self e dt]
  (e:draw))

(λ draw-system.postProcess [self dt]
  (love.graphics.pop))

(λ draw-system.compare [self e1 e2]
  (< e1.z-index e2.z-index))
  
(tiny.addSystem ecs.world draw-system)

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
  
(tiny.addSystem ecs.world arena-draw-system)

;; cleanup-system handles removing entities that have :dead = true
(local cleanup-system (tiny.processingSystem))
(set cleanup-system.filter (tiny.requireAll :id))

(λ cleanup-system.process [self e dt]
  (when e.debug
    (print :debug e.dead))
  (when e.dead
    (when e.destroy
      (e:destroy))
    (tiny.removeEntity ecs.world e)))

(tiny.addSystem ecs.world cleanup-system)

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
          (set state.state.screen-offset (vec 0 (* 0.5 (- window-size.y (* s stage-size.y)))))
          (set state.state.screen-offset (vec (* 0.5 (- window-size.x (* s stage-size.x))) 0))))
    (set state.state.screen-scale (vec s s))))
    
;; Main
(λ draw-bg []
  (graphics.rectangle (vec 0 0) stage-size (hexcolor :212121ff)))

;; The root game timeline
(λ game-timeline []
  ;; Game started, wait for first buy
  (print :starting)
  (while (not state.state.started)
    (coroutine.yield))

  (print :here)
  (timeline.wait 1)

  ;; Main game loop
  (while (not state.game-over?)
    (coroutine.yield)
    (var phase-1-t 0)
    (while (< phase-1-t 5)
      (set phase-1-t (+ phase-1-t (coroutine.yield)))
      (when (= state.state.enemy-count 0)
        (state.state.director:spawn-enemy-group
         (vec (love.math.random 50 (- arena-size.x 50))
              (love.math.random 50 (- arena-size.y 50)))
         [:basic :basic])))
    (for [i 1 5]
      (state.state.director:spawn-enemy-group
       (vec (love.math.random 50 (- arena-size.x 50))
            (love.math.random 50 (- arena-size.y 50)))
       [:basic :basic :basic :basic :basic :basic :basic])))
  (print :done))

(λ main []
  (set-win-size)

  ;; Add global drawer
  (tiny.addEntity ecs.world
                  {:z-index 100
                   :draw
                   (λ self []
                     ;(draw-bg)
                     (love.graphics.setColor 1 1 1 1)
                     (love.graphics.draw arena-canvas
                                         (+ arena-margin.x arena-offset.x)
                                         (+ arena-margin.y arena-offset.y)
                                         0 1 1))})

  ;; Add director 
  (set state.state.director (new-entity Director))
  (tiny.addEntity ecs.world state.state.director)

  ;; Add walls
  (tiny.add ecs.world
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) arena-size.y)
                 :size (vec arena-size.x 10)
                 :category "10000000"
                 :mask "11111111"})
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) 0)
                 :size (vec arena-size.x 10)
                 :category "10000000"
                 :mask "11111111"})
    (new-entity Box2dRectangle
                {:pos (vec 0 (/ arena-size.y 2))
                 :size (vec 10 arena-size.y)
                 :category "10000000"
                 :mask "11111111"})
    (new-entity Box2dRectangle
                {:pos (vec arena-size.x (/ arena-size.y 2))
                 :size (vec 10 arena-size.y)
                 :category "10000000"
                 :mask "11111111"}))

  ;; Start main timeline
  (fire-timeline (game-timeline)))

(main)

{:update
 (fn update [dt set-mode]
   (tiny.update ecs.world dt))
 :keypressed (fn keypressed [key set-mode])
 :resize set-win-size}
