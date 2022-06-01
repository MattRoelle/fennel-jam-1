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
(local aseprite (require :aseprite))

(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))

;(local moonshine (require :moonshine))

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
      (values k {:t (if v.random (* 2 (math.random)) 0)
                 :active v.active}))))

(λ timers-system.process [self e dt]
  (each [_ v (pairs e.timers)]
    (when v.active
      (set v.t (+ v.t (* state.state.time-scale dt))))))

(tiny.addSystem ecs.world timers-system)

;; index-system handles sorting player/enemy units into easily accessible tables
(local index-system (tiny.processingSystem))
(set index-system.filter (tiny.requireAll :id))

(λ index-system.onAdd [self e]
  (tset state.state.idmap e.id e)
  (when e.destroy-after-combat
    (tset state.state.destroy-after-combat e.id e))
  (when e.team
    (tset state.state :teams e.team e.id e)))

(λ index-system.onRemove [self e]
  (tset state.state.idmap e.id nil)
  (when e.destroy-after-combat
    (tset state.state.destroy-after-combat e.id nil))
  (when e.team
    (tset state.state :teams e.team e.id nil)))

(tiny.addSystem ecs.world index-system)

;; update-system handles calling update on entities with a dt
(local update-system (tiny.processingSystem))
(set update-system.filter (tiny.requireAll :update))

(λ update-system.process [self e dt]
  (e:update dt))

(tiny.addSystem ecs.world update-system)

;; time-update-system handles calling update on entities with a dt
;; Can be scaled/paused etc
(local time-update-system (tiny.processingSystem))
(set time-update-system.filter (tiny.requireAll :time-update))

(λ time-update-system.process [self e dt]
  (e:time-update (* state.state.time-scale dt)))

(tiny.addSystem ecs.world time-update-system)

(local timeline-system (tiny.processingSystem))
(set timeline-system.filter (tiny.requireAll :timeline))

(λ timeline-system.process [self e dt]
  (when (e.timeline:update dt)
    (tiny.removeEntity ecs.world e)))

(tiny.addSystem ecs.world timeline-system)

;; draw system handles drawing in order of highest-to-lowest z-index
(local draw-system (tiny.sortedProcessingSystem))
(set draw-system.filter (tiny.requireAll :draw :z-index))

(set draw-system.bg-img aseprite.bgpat)
(draw-system.bg-img.img:setWrap :repeat :repeat)
(set draw-system.bg-t 0)
(set draw-system.bg-quad
     (love.graphics.newQuad 0 0
                            aseprite.bgpat.width aseprite.bgpat.height
                            stage-size.x stage-size.y))

(λ draw-system.preProcess [self dt]
  (set self.bg-t (+ self.bg-t (* 10 dt)))
  (love.graphics.push)
  (love.graphics.clear)
  (love.graphics.scale state.state.screen-scale.x state.state.screen-scale.y)
  (love.graphics.setColor 1 1 1 1)
  (self.bg-quad:setViewport (* -0.5 self.bg-t)
                            self.bg-t
                            stage-size.x stage-size.y
                            aseprite.bgpat.width aseprite.bgpat.height)
  (love.graphics.draw self.bg-img.img self.bg-quad))
  
(λ draw-system.process [self e dt]
  (e:draw))

(λ draw-system.postProcess [self dt]
  (love.graphics.pop))

(λ draw-system.compare [self e1 e2]
  (< e1.z-index e2.z-index))
  
(tiny.addSystem ecs.world draw-system)

;; arena-draw and arena-draw-fg system handles drawing in order of highest-to-lowest z-index
;; draws to arena canvas
(local arena-canvas (love.graphics.newCanvas arena-size.x arena-size.y))
(local arena-canvas-fg (love.graphics.newCanvas arena-size.x arena-size.y))
(local arena-canvas-entities (love.graphics.newCanvas arena-size.x arena-size.y))
(arena-canvas:setFilter :nearest :nearest)
(arena-canvas-fg:setFilter :nearest :nearest)
(arena-canvas-entities:setFilter :nearest :nearest)

;(local arena-moonshine (moonshine arena-size.x arena-size.y moonshine.effects.dmg))
;(set arena-moonshine.dmg.palette "default")
;(set arena-moonshine.posterize.num_bands 16)
;(arena-moonshine.chain moonshine.effects.dmg)

(local arena-draw-fg-system (tiny.sortedProcessingSystem))
(set arena-draw-fg-system.filter (tiny.requireAll :arena-draw-fg :z-index))

(λ arena-draw-fg-system.preProcess [self]
  (love.graphics.setCanvas arena-canvas-fg)
  (love.graphics.push)
  (love.graphics.clear)
  (love.graphics.origin))

(λ arena-draw-fg-system.process [self e dt]
  (e:arena-draw-fg))

(λ arena-draw-fg-system.postProcess [self]
  (love.graphics.pop)
  (love.graphics.setCanvas))

(λ arena-draw-fg-system.compare [self e1 e2]
  (> e1.z-index e2.z-index))
  
(tiny.addSystem ecs.world arena-draw-fg-system)

(local arena-draw-system (tiny.sortedProcessingSystem))
(set arena-draw-system.filter (tiny.requireAll :arena-draw :z-index))


(local arena-shader-code
    "
float res = 0.003;
float threshold = 0.01;
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    vec4 up = Texel(tex, texture_coords+vec2(0,-res));
    vec4 right = Texel(tex, texture_coords+vec2(res,0));
    vec4 upright = Texel(tex, texture_coords+vec2(res,-res));
    vec4 down = Texel(tex, texture_coords+vec2(0,res));
    vec4 left = Texel(tex, texture_coords+vec2(-res,0));
    vec4 downleft = Texel(tex, texture_coords+vec2(-res,res));

    if (texturecolor.a > threshold && (up.a < threshold || right.a < threshold || upright.a < threshold)) {
      return texturecolor * 2.0;
    }

    if (texturecolor.a < threshold && (up.a > threshold || right.a > threshold || upright.a > threshold)) {
      return vec4(0.0/255.0,0.0/255.0,0.0/255.0,1);
    }

      return texturecolor * color;
}
    ")

(local arena-shader (love.graphics.newShader arena-shader-code))

(λ arena-draw-system.preProcess [self]
  (love.graphics.setCanvas arena-canvas-entities)
  (love.graphics.push)
  (love.graphics.clear)
  (love.graphics.origin))

(λ arena-draw-system.process [self e dt]
  (e:arena-draw))

(λ arena-draw-system.postProcess [self]
  (love.graphics.pop)
  (love.graphics.setCanvas arena-canvas)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.push)
  (love.graphics.origin)
  (love.graphics.draw aseprite.arena-bg.img)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.setShader arena-shader)
  (love.graphics.translate state.state.camera-shake.x state.state.camera-shake.y)
  (let [offset (- (/ (- (* state.state.arena-zoom arena-size) arena-size) 2))]
    (love.graphics.translate offset.x offset.y)
    (love.graphics.scale state.state.arena-zoom state.state.arena-zoom))
  (love.graphics.draw arena-canvas-entities)
  (love.graphics.setShader)
  (love.graphics.draw arena-canvas-fg)
  (each [k v (pairs state.state.muzzle-flashes)]
    (if (> state.state.time v.t)
        (tset state.state.muzzle-flashes k nil)
        (graphics.circle v.pos (* v.scale (love.math.random 14 32))
                         (rgba 1 1 1 1))))
  (love.graphics.pop)
  (love.graphics.setColor 0 0 0 1)
  (love.graphics.setLineWidth 8)
  (love.graphics.rectangle :line 0 0 arena-size.x arena-size.y)
  (love.graphics.setCanvas))

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

(var reset? false)

(λ main []
  (set-win-size)

  ;; Add global drawer
  (tiny.addEntity ecs.world
                  {:z-index 100
                   :draw
                   (λ self []
                     ;(draw-bg)
                     (love.graphics.push)
                     (love.graphics.translate (+ arena-margin.x arena-offset.x)
                                              (+ arena-margin.y arena-offset.y))
                     ;(arena-moonshine.draw
                                        ;(fn []
                     (love.graphics.setColor 1 1 1 1)
                     (love.graphics.draw arena-canvas 0 0)
                     (love.graphics.pop))})

  ;; Add director 
  (set state.state.director
       (new-entity Director
                   {:reset-game
                    (fn []
                      (set reset? true))}))
  (tiny.addEntity ecs.world state.state.director))

{:activate main
 :update
 (fn update [dt set-mode]
   (tiny.update ecs.world dt)
   (when reset?
     (set reset? false)
     (ecs.world:clearEntities)
     (state.reset-state)
     (main)))
 :keypressed (fn keypressed [key set-mode])
 :resize set-win-size}
