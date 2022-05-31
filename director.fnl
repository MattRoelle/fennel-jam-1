(import-macros {: fire-timeline : imm-stateful : with-entities} :macros)

(local timeline (require :timeline))
(local tiny (require :lib.tiny))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local graphics (require :graphics))
(local lume (require :lib.lume))
(local input (require :input))
(local {: new-entity : get-id} (require :helpers))
(local {: Box2dCircle : Box2dRectangle} (require :box2d))
(local ecs (require :ecs))
(local state (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local aabb (require :aabb))
(local {: text : view : image : shop-button : button} (require :imm))
(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))
(local {: new-entity : get-mouse-position} (require :helpers))
(local {: Unit} (require :unit))
(local data (require :data))
(local aseprite (require :aseprite))
(local {: get-copy-str} (require :copy))
(local assets (require :assets))
(local effects (require :effects))

(λ start-game-prompt []
  (when (not state.state.started)
    (let [sz (vec 400 200)]
      [view {:display :flex
             :position (- center-stage (/ sz 2) (vec 0 80))
             :size sz
             :color (rgba 0 0 0 1)
             :padding (vec 4 4)}
       [[text {:text "Purchase a unit to begin"
               :color (rgba 1 1 1 1)}]]])))

(λ upgrade-screen []
  (when state.state.upgrade-screen-open?
    (let [sz (vec 600 300)]
      [view {:display :flex
             :position (- center-stage (/ sz 2) (vec 0 60))
             :size sz
             :color (rgba 0 0 0 1)
             :flex-direction :column
             :padding (vec 4 4)}
       [[text {:text "Choose Upgrade"
               :font assets.f32
               :color (rgba 0 0 0 1)}]
        [view {:display :flex}
          (icollect [ix upgrade (ipairs state.state.upgrade-choices)]
            [view {:display :flex
                   :flex-direction :column}
             [[text {:text upgrade.upgrade
                     :font assets.f32
                     :color (rgba 1 1 1 1)}]
              (imm-stateful button upgrade [:bstate]
                            {:label :Choose
                             :on-click #(state.state.director:choose-upgrade upgrade)})]])]]])))
          

(λ tooltip []
  (when state.state.hover-shop-btn
    (let [sz (vec 400 200)]
      [view {:display :flex
             :position (- center-stage (/ sz 2))
             :size sz
             :color (rgba 0 0 0 1)
             :padding (vec 4 4)}
       [[text {:text (get-copy-str :en :units (. state.state.hover-shop-btn.group 1))
               :color (rgba 1 1 1 1)}]]])))

(λ upgrade-list []
  [view {:display :stack
         :position (vec 10 10)
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
   [[view {:display :stack
           :direction :down}
     (icollect [k v (pairs state.state.upgrades)]
       [text {:size (vec 80 20)
              :text (.. k ": " (tostring v))
              :color (rgba 1 1 1 1)}])]]])

(λ unit-list []
  [view {:display :stack
         :position (vec (- stage-size.x arena-margin.x) (/ arena-margin.y 2))
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
   [[view {:color (rgba 0.5 0.3 0.3 0)
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

(λ top-row []
  [view {:display :stack
         :direction :right
         :position (vec -440 (- stage-size.y 192))
         :padding (vec 8 0)
         :size (vec stage-size.x 110)}
   [[text {:text (.. "$" (tostring state.state.money))
           :font assets.f32      
           :color (rgba 1 1 1 1)}]]])

(λ shop-row []
  [view {:display :stack
         :direction :right
         :position (vec 0 (- stage-size.y 112))
         :padding (vec 8 0)
         :size (vec stage-size.x 110)}
   (icollect [ix btn (ipairs state.state.shop-row)]
     (when (. state.state.shop-row ix)
       [view {:display :flex
              :size (vec 120 80)}
        (when btn 
          [[view {:display :flex
                  :padding (vec 10 0)}
             [(imm-stateful shop-button
                            state.state.shop-row [ix]
                            {:label btn.label
                             :cost btn.cost
                             :index ix})]]])]))])

(local Director {})
(set Director.__index Director)

(λ Director.attack-bump [self ea eb]
  (self:screen-shake)
  (ea:take-dmg eb.def.bump-damage)
  (eb:take-dmg ea.def.bump-damage))

(λ Director.bullet-hit [self bullet target]
  (target:take-dmg bullet.bullet.dmg)
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
            (values :bump-player-enemy eb ea)
            (and eb.wall ea.bullet)
            (values :bullet-wall ea nil)
            (and ea.wall eb.bullet)
            (values :bullet-wall eb nil))]
    (match collision-type
      :bullet-wall (set A.dead true)
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
  (state.state.pworld:setCallbacks
    #(self:begin-contact $...)
    #(self:end-contact $...)
    #(self:pre-solve $...)
    #(self:post-solve $...))
  (fire-timeline (self:main-timeline)))

(λ Director.screen-shake [self ?duration ?intensity]
  (let [duration (or ?duration 0.25)
        intensity (or ?intensity 2)]
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

(λ Director.clamp-shop [self]
  (while (> (length state.state.shop-row) 8)
    (table.remove state.state.shop-row (length state.state.shop-row))))

(λ Director.loot [self]
  (let [k (lume.randomchoice (lume.keys data.unit-types))]
    (table.insert state.state.shop-row
                  {:cost 3 :group [k]
                   :label k}))
  (self:clamp-shop))

(λ Director.buy-roll-shop [self]
  (when (> state.state.money 0)
    (set state.state.money (- state.state.money 1))
    (self:roll-shop)))

(λ Director.get-shop-tier [self] 1)
  ;(if (> state.state.level 4) 2 1))

(λ Director.generate-shop-unit [self]
  (let [tier (self:get-shop-tier)
        choices
        (icollect [k v (pairs data.unit-types)]
          (when (<= v.tier tier) k))]
    (lume.randomchoice choices)))

(λ Director.roll-shop [self]
  (set state.state.shop-row [])
  (fire-timeline
   (for [i 1 5]
     (let [u (self:generate-shop-unit)]
       (table.insert state.state.shop-row
                       {:cost 3 :group [u]
                        :label u}))
     (self:clamp-shop)
     (timeline.wait 0.2))))

(λ Director.arena-draw [self]
  (when state.active-shop-btn
    (graphics.circle state.state.arena-mpos 10 (rgba 1 1 1 1))))

(λ Director.muzzle-flash [self pos ?scale]
  (tset state.state.muzzle-flashes
        (get-id)
        {:t (+ state.state.time 0.04)
         :scale (or ?scale 1)
         : pos}))

(λ Director.setup-arena-entities [self]
  ;; Add walls
  (set self.bottom-wall
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) arena-size.y)
                 :size (vec arena-size.x 10)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.top-wall
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) 0)
                 :size (vec arena-size.x 10)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.left-wall
    (new-entity Box2dRectangle
                {:pos (vec 0 (/ arena-size.y 2))
                 :size (vec 10 arena-size.y)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.right-wall
    (new-entity Box2dRectangle
                {:pos (vec arena-size.x (/ arena-size.y 2))
                 :size (vec 10 arena-size.y)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.divider
    (new-entity Box2dRectangle
                {:center-pos (vec (/ arena-size.x 4) (/ arena-size.y 2))
                 :pos (self.right-wall.pos:clone)
                 :size (vec 10 arena-size.y)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (tiny.add ecs.world 
            self.bottom-wall
            self.top-wall
            self.left-wall
            self.right-wall
            self.divider))

(λ Director.draw [self]
   (layout #nil {:size stage-size} 
     [[view {:display :absolute}
       [(imm-stateful button state.state [:end-turn-btn]
                      {:label "End Turn"
                       :disabled (not= :shop state.state.phase)
                       :size (vec 60 60)
                       :on-click #(self:end-turn)
                       :position (vec 10 210)})
        (imm-stateful button state.state [:reroll-shop-btn]
                      {:label "Reroll 1"
                       :disabled (not= :shop state.state.phase)
                       :size (vec 60 60)
                       :on-click #(self:buy-roll-shop)
                       :position (vec 10 290)})
        (upgrade-list)
        (unit-list)
        (top-row)
        (shop-row)
        (upgrade-screen)
        (tooltip)
        (start-game-prompt)]]])
   (let [fps (love.timer.getFPS)]
     (love.graphics.setColor 1 0 0 1)
     (love.graphics.print (tostring fps) 4 4)
     (love.graphics.setColor 0 1 0 1)
     (love.graphics.print (tostring state.state.unit-count) 40 4)))


(λ Director.add-gold [self v]
  (set state.state.money (+ state.state.money v))
  (effects.screen-text-flash
    (.. "+ " v)
    (vec 32 370)
    (rgba 1 1 0 1)))

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
      (let [def (. data.enemy-types enemy-type)
            unit {:hp def.hp
                  :type enemy-type}]
        (tiny.addEntity ecs.world
                        (new-entity Unit {: pos : unit :team :enemy}))))
    (set img.dead true)))

(λ Director.spawn-group [self pos group]
  (set state.state.started true)
  (let [p (+ pos (vec (love.math.random -50 50)
                      (love.math.random -50 50)))]
    (fire-timeline
      ;(local img {:pos p
                  :id (tostring (get-id))
                  :z-index 100
                  :__timers {:spawn {:t 0 :active true}}
                  :arena-draw
                  (λ [self]
                    (when (= 0 (% (math.floor (* self.timers.spawn.t 10)) 2))
                      (graphics.image aseprite.spawn self.pos)))
      ;(tiny.addEntity ecs.world img)
      ;(timeline.wait 1)
      (each [_ unit-type (ipairs group)]
        (let [def (. data.unit-types unit-type)
              unit {:type unit-type
                    :level 1
                    :hp def.hp}]
          (tiny.addEntity ecs.world
                          (new-entity Unit {:pos p : unit})))))))
      ;(set img.dead true))))

(λ Director.choose-upgrade [self upgrade]
  (set state.state.upgrade-screen-open? false)
  (tset state.state.upgrades upgrade.upgrade
        (+ (or (. state.state.upgrades upgrade.upgrade) 0) 1)))

(λ Director.purchase [self index]
  (let [shop-item (. state.state.shop-row index)]
    (when (>= state.state.money shop-item.cost)
      (set state.state.money (- state.state.money shop-item.cost))
      (self:screen-shake)
      (self:spawn-group (vec (* 0.5 arena-size.x)
                             (/ arena-size.y 2))
                        shop-item.group)
      (set state.state.shop-row
           (icollect [ix si (ipairs state.state.shop-row)]
             (when (not= index ix) si))))))

(λ Director.update [self dt]
  (set state.state.time
       (+ state.state.time dt))
  (input:update)
  (state.state.pworld:update dt)
  ;; (when (and state.state.active-shop-btn
  ;;            (input:mouse-released?)
  ;;            (: (aabb (vec 0 0) arena-size) :contains-point?
  ;;               state.state.arena-mpos))
  ;;   (self:spawn-group state.state.active-shop-btn.group))
    
  (let [mpos (- (get-mouse-position) arena-margin
                (- arena-offset (/ state.state.screen-offset state.state.screen-scale.x)))]
    (set state.state.arena-mpos mpos)))

(λ Director.open-upgrade-screen [self]
  (set state.state.upgrade-choices
       [{:upgrade :atk-speed-up}
        {:upgrade :bump-dmg-up}])
  (set state.state.upgrade-screen-open? true))

(λ Director.save-unit-state [self]
  (set state.state.team-state [])
  (each [_ unit (pairs state.state.teams.player)]
    (table.insert state.state.team-state
                  (lume.merge unit.unit {:hp (. data.unit-types unit.unit.type :hp)}))))

(λ Director.restore-unit-state [self]
  (when state.state.team-state
    (each [_ unit (pairs state.state.team-state)]
      (tiny.addEntity ecs.world
                      (new-entity Unit
                                  {:pos (/ arena-size 2)
                                   : unit})))))

(λ Director.play-win-level-sequence [self]
  (local spin-in
         {:z-index 20000
          :t 0
          :id (get-id)
          :arena-draw
          (fn [self]
            (love.graphics.push)
            (love.graphics.translate (/ arena-size.x 2)
                                     (/ arena-size.y 2))
            (love.graphics.rotate (* self.t 2 math.pi))
            (love.graphics.scale (* 3 self.t) (* 3 self.t))
            (graphics.print-centered "VICTORY" assets.f32
                                     (vec 0 0) (rgba 1 1 1 1))
            (love.graphics.pop))})
  (tiny.addEntity ecs.world spin-in)
  (timeline.tween 1.5 spin-in {:t 1} :outQuad)
  (each [team teamlist (pairs state.state.teams)]
    (each [_ unit (pairs teamlist)]
      (unit:pop)
      (timeline.wait 0.2)))
  (timeline.wait 1)
  (set spin-in.dead true)
  (effects.text-flash (.. "Level  " state.state.display-level " Complete")
                      center-stage
                      (rgba 1 1 1 1)
                      assets.f32)
  (self:add-gold
   (if (< state.state.display-level 5)
       10
       15))
  (timeline.wait 1))

(λ text-flash [s pos color ?font])

(λ Director.line-up-units [self]
  (var unit-index 1)
  (each [k grp (pairs state.state.units)]
    (let [ctx {: unit-index
               :count 0
               :pos (vec 32 (+ 16 (* (- unit-index 1) 34)))}]
      (set unit-index (+ unit-index 1))
      (each [id e (pairs grp)]
        (when (= :table (type e))
          (set e.targpos (e:get-body-pos))
          (let [c ctx.count]
            (fire-timeline
             (timeline.tween 1 e {:targpos (+ ctx.pos (* c (vec 30 0)))} :outQuad)))
          (set ctx.count (+ ctx.count 1)))))))

(λ Director.do-shop-phase [self]
  (set state.state.phase :shop)
  (self:roll-shop)
  (self:line-up-units)
  (while (= :shop state.state.phase)
    (coroutine.yield)))

(λ Director.end-turn [self]
  (set state.state.shop-row [])
  (set state.state.phase :combat))

(λ Director.pre-combat-animation [self])
  ;(set self.divider.targpos (self.divider.pos:clone))
 ;(timeline.tween 1 self.divider
 ;                {:targpos self.divider.center-pos}
 ;                :outQuad
 ;(timeline.wait 0.5))

(λ Director.spawn-enemies [self group-options waves]
  (each [_ wave (ipairs waves)]
    (for [i 1 wave.groups]
      (let [grp (lume.randomchoice group-options)]
        (self:spawn-enemy-group
         (vec (* (/ 3 4) arena-size.x)
              (/ arena-size.y 2))
         grp)))))

(λ Director.main-timeline [self]
 (self:setup-arena-entities)

 ;; Main game loop
 (while (not state.state.game-over?)
   (coroutine.yield)
   (let [level-def (assert (. data.levels state.state.level)
                           "Error loading level")]
     (match level-def
       {:type :combat
        : group-options
        : waves}
       (do
         (timeline.wait 0.5)
         (self:restore-unit-state)
         (self:do-shop-phase)
         (self:save-unit-state)
         (self:pre-combat-animation)
         (self:spawn-enemies group-options waves)
         (timeline.wait 1.5)
         (while (> state.state.enemy-count 0)
           (coroutine.yield))
         (timeline.wait 0.5))
       {:type :upgrade}
       (do
         (self:open-upgrade-screen)
         (while state.state.upgrade-screen-open?
           (coroutine.yield))))

     (when (and (not state.state.game-over?)
                (= :combat level-def.type))
       (self:play-win-level-sequence)
       (set state.state.display-level (+ state.state.display-level 1)))
     (set state.state.level (+ state.state.level 1)))))

      

(set Director.__defaults
     {:z-index 10000})

Director
