(import-macros {: fire-timeline} :macros)

(local timeline (require :timeline))
(local tiny (require :lib.tiny))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local graphics (require :graphics))
(local lume (require :lib.lume))
(local input (require :input))
(local {: new-entity} (require :helpers))
(local {: Box2dCircle} (require :wall))
(local {: world} (require :ecs))
(local {: state} (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local {: text : view : image : shop-button} (require :imm))
(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))
(local {: new-entity : get-mouse-position} (require :helpers))
(local Unit (require :unit))

(λ shop-row []
  [view {:display :stack
         :direction :right
         :position (vec 0 (- stage-size.y 112))
         :padding (vec 8 0)
         :size (vec stage-size.x 110)}
   [[view {:color (rgba 0.5 0.3 0.3 1)
           :padding (vec 10 10)
           :display :flex
           :size (vec 100 100)}
      [[#(tset state.shop-row 1 :button (shop-button (. state.shop-row 1 :button) $...)) {:label :test}]]]
    [view {:color (rgba 0.5 0.3 0.3 1)
           :padding (vec 10 10)
           :display :flex
           :size (vec 100 100)}
      [[#(tset state.shop-row 2 :button (shop-button (. state.shop-row 2 :button) $...)) {:label :test}]]]]])

(local Director {})
(set Director.__index Director)

(λ Director.init [self])


(λ Director.arena-draw [self]
  (when state.active-shop-btn
    (graphics.circle state.arena-mpos 10 (rgba 1 1 1 1))))

(λ Director.draw [self]
   (layout #nil {:size stage-size} 
     [[view {:display :absolute}
       [(shop-row)]]])
   (let [fps (love.timer.getFPS)]
     (love.graphics.setColor 1 0 0 1)
     (love.graphics.print (tostring fps) 4 4))) 

(λ Director.update [self dt]
  (input:update)
  (state.pworld:update dt)
  (when (and state.active-shop-btn (input:mouse-released?))
    (fire-timeline
      (for [i 1 5]
        (timeline.wait 0.05)
        (tiny.addEntity world
          (new-entity Unit
                      {:pos (vec (love.math.random 100 200)
                                 (love.math.random 100 200))})))))
    
  (let [mpos (- (get-mouse-position) arena-margin
                (- arena-offset (/ state.screen-offset state.screen-scale.x)))]
    (set state.arena-mpos mpos)))

(set Director.__defaults
     {:z-index 1000})

Director
