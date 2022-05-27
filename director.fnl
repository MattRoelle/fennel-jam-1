(import-macros {: fire-timeline : imm-stateful : with-entities} :macros)

(local timeline (require :timeline))
(local tiny (require :lib.tiny))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local graphics (require :graphics))
(local lume (require :lib.lume))
(local input (require :input))
(local {: new-entity : get-id} (require :helpers))
(local {: Box2dCircle} (require :wall))
(local ecs (require :ecs))
(local state (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local aabb (require :aabb))
(local {: text : view : image : shop-button : button} (require :imm))
(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))
(local {: new-entity : get-mouse-position} (require :helpers))
(local {: Unit : Enemy} (require :unit))
(local data (require :data))
(local aseprite (require :aseprite))
(local {: get-copy-str} (require :copy))

(λ tooltip []
  (when state.state.hover-shop-btn
    (let [sz (vec 400 200)]
      [view {:display :flex
             :position (- center-stage (/ sz 2))
             :size sz
             :color (rgba 0 0 0 1)
             :padding (vec 4 4)}
       [[text {:text (get-copy-str :en :units :shooter)
               :color (rgba 1 1 1 1)}]]])))

(λ unit-list []
  [view {:display :stack
         :position (vec (- stage-size.x arena-margin.x) (/ arena-margin.y 2))
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
   [[view {:color (rgba 0.5 0.3 0.3 1)
           :display :stack
           :direction :down
           :size (vec 800 100)}
     (when (> state.state.unit-count 0)
       (icollect [k grp (pairs state.state.units)]
         (let [keys (lume.keys grp)]
           (when (> (length keys) 0)
             [view {:size (vec 100 40)
                    :color (rgba 0.1 0.1 0.1 1)
                    :display :flex
                    :flex-direction :column}
              [[text {:text k
                      :color (rgba 1 1 1 1)}]
               [text {:text (length keys)
                      :color (rgba 1 1 1 1)}]
               (imm-stateful button state.state.units [k :bstate]
                             {:label :Promote})]]))))]]])

(λ shop-row []
  [view {:display :stack
         :direction :right
         :position (vec 0 (- stage-size.y 112))
         :padding (vec 8 0)
         :size (vec stage-size.x 110)}
   (icollect [ix btn (ipairs state.state.shop-row)]
     [view {:color (rgba 0.5 0.3 0.3 1)
            :padding (vec 10 10)
            :display :flex
            :size (vec 100 100)}
      [(imm-stateful shop-button
                     state.state.shop-row [ix]
                     {:label btn.label})]])])

(local Director {})
(set Director.__index Director)

(λ Director.attack-bump [self ea eb]
  (ea:flash)
  (eb:flash)
  (set ea.hp (- ea.hp eb.def.bump-damage))
  (set eb.hp (- eb.hp eb.def.bump-damage))
  (self:screen-shake))

(λ Director.bullet-hit [self bullet target]
  (target:flash)
  (set target.hp (- target.hp bullet.bullet.dmg))
  (self:screen-shake)
  (set bullet.dead true))

(λ Director.process-collision [self ea eb]
  (let [(collision-type A B)
        (if (and ea.bullet (= eb.team :enemy))
            (values :player-bullet-to-enemy ea eb)
            (and eb.bullet (= ea.team :enemy))
            (values :player-bullet-to-enemy eb ea)
            (and (= ea.team :player) (= eb.team :enemy))
            (values :bump-player-enemy ea eb)
            (and (= eb.team :player) (= ea.team :enemy))
            (values :bump-player-enemy eb ea))]
    (match collision-type
      :bump-player-enemy (self:attack-bump A B)
      :player-bullet-to-enemy (self:bullet-hit A B))))

;; box2d collision callbacks
(λ Director.begin-contact [self a b col]
  (let [ea (state.get-entity-by-id (a:getUserData))
        eb (state.get-entity-by-id (b:getUserData))]
    (when (and ea eb)
      (self:process-collision ea eb))))

(λ Director.end-contact [self a b col])
(λ Director.pre-solve [self a b col])
(λ Director.post-solve [self a b col])

(λ Director.init [self]
  (self:roll-shop)
  (state.state.pworld:setCallbacks
    #(self:begin-contact $...)
    #(self:end-contact $...)
    #(self:pre-solve $...)
    #(self:post-solve $...)))

(λ Director.screen-shake [self ?duration ?intensity]
  (let [duration (or ?duration 0.3)
        intensity (or ?intensity 1)]
    (when self.shake-timeline
      (self.shake-timeline:cancel))
    (set self.shake-timeline
         (fire-timeline
          (var t 0)
          (while (< t duration)
            (set state.state.camera-shake
                 (vec (love.math.random (- intensity) intensity)
                      (love.math.random (- intensity) intensity)))
            (set t (+ t (coroutine.yield))))))))

(λ Director.roll-shop [self]
  (set state.state.shop-row [])
  (table.insert state.state.shop-row
                {:cost 3 :group [:warrior :warrior :warrior]
                 :label "3 warriors"})
  (table.insert state.state.shop-row
                {:cost 3 :group [:shooter :shooter :shooter]
                 :label "3 shooters"}))

(λ Director.arena-draw [self]
  (when state.active-shop-btn
    (graphics.circle state.state.arena-mpos 10 (rgba 1 1 1 1))))

(λ Director.draw [self]
   (layout #nil {:size stage-size} 
     [[view {:display :absolute}
       [(imm-stateful button state.state [:debug-spawn-enemy]
                      {:label :spawn-enemies
                       :size (vec 60 60)
                       :on-click #(self:spawn-enemy-group (vec (love.math.random 10 arena-size.x)
                                                               (love.math.random 10 arena-size.y))
                                                          [:basic :basic :basic :basic :basic :basic])
                       :position (vec 10 10)})
        (unit-list)
        (shop-row)
        (tooltip)]]])
   (let [fps (love.timer.getFPS)]
     (love.graphics.setColor 1 0 0 1)
     (love.graphics.print (tostring fps) 4 4)
     (love.graphics.setColor 0 1 0 1)
     (love.graphics.print (tostring state.state.unit-count) 40 4)))

(λ Director.spawn-enemy-group [self pos group]
  (fire-timeline
    (local img {: pos
                :id (tostring (get-id))
                :z-index 100
                :__timers {:spawn {:t 0 :active true}}
                :arena-draw
                (λ [self]
                  (when (= 0 (% (math.floor (* self.timers.spawn.t 10)) 2))
                    (graphics.image aseprite.warn self.pos)))})
    (tiny.addEntity ecs.world img)
    (timeline.wait 1)
    (each [_ enemy-type (ipairs group)]
      (tiny.addEntity ecs.world
                      (new-entity Enemy {: pos : enemy-type})))
    (set img.dead true)))


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
    (self:spawn-group state.state.active-shop-btn.group))
    
  (let [mpos (- (get-mouse-position) arena-margin
                (- arena-offset (/ state.state.screen-offset state.state.screen-scale.x)))]
    (set state.state.arena-mpos mpos)))

(set Director.__defaults
     {:z-index 1000})

Director
