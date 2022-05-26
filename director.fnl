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
(local ecs (require :ecs))
(local state (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local aabb (require :aabb))
(local {: text : view : image : shop-button} (require :imm))
(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))
(local {: new-entity : get-mouse-position} (require :helpers))
(local {: Unit : Enemy} (require :unit))
(local data (require :data))

(λ unit-list []
  [view {:display :stack
         :direction :right
         :position (vec (- stage-size.x arena-margin.x) 0)
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
   [[view {:color (rgba 0.5 0.3 0.3 1)
           :padding (vec 10 10)
           :display :flex
           :size (vec 800 100)}
     (when (> state.state.unit-count 0)
       (icollect [k grp (pairs state.state.units)]
         (when (> (length grp) 0)
           [view {:size (vec 100 100)
                  :color (rgba 0 1 0 1)}])))]]])

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
      [[#(tset state.state.shop-row 1 :button (shop-button (. state.state.shop-row 1 :button) $...)) {:label :test}]]]
    [view {:color (rgba 0.5 0.3 0.3 1)
           :padding (vec 10 10)
           :display :flex}
          :size (vec 100 100)
      [[#(tset state.state.shop-row 2 :button (shop-button (. state.state.shop-row 2 :button) $...)) {:label :test}]]]]])

(local Director {})
(set Director.__index Director)

(λ Director.init [self]
  (fire-timeline
    (timeline.wait 0.5)
    (set state.state.arena-mpos (vec 100 100))
    (self:spawn-group [:warrior :warrior :warrior])))


(λ Director.arena-draw [self]
  (when state.active-shop-btn
    (graphics.circle state.state.arena-mpos 10 (rgba 1 1 1 1))))

(λ Director.draw [self]
   (layout #nil {:size stage-size} 
     [[view {:display :absolute}
       [(unit-list)
        (shop-row)]]])
   (let [fps (love.timer.getFPS)]
     (love.graphics.setColor 1 0 0 1)
     (love.graphics.print (tostring fps) 4 4)
     (love.graphics.setColor 0 1 0 1)
     (love.graphics.print (tostring state.state.unit-count) 40 4)))

(λ Director.spawn-group [self group]
  (each [_ unit-type (ipairs group)]
    (tiny.addEntity ecs.world
                    (new-entity Unit {:pos state.state.arena-mpos
                                                                                      : unit-type}))))

(λ Director.update [self dt]
  (input:update)
  (state.state.pworld:update dt)
  (when (and state.state.active-shop-btn
             (input:mouse-released?)
             (: (aabb (vec 0 0) arena-size) :contains-point?
                state.state.arena-mpos))
    (self:spawn-group [:warrior :warrior :warrior]))
    
  (let [mpos (- (get-mouse-position) arena-margin
                (- arena-offset (/ state.state.screen-offset state.state.screen-scale.x)))]
    (set state.state.arena-mpos mpos)))

(set Director.__defaults
     {:z-index 1000})

Director
