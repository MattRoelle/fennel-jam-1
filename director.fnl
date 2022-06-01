(import-macros {: fire-timeline : imm-stateful : with-entities} :macros)

(local timeline (require :timeline))
(local tiny (require :lib.tiny))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local graphics (require :graphics))
(local lume (require :lib.lume))
(local input (require :input))
(local {: new-entity : get-id : calc-stats} (require :helpers))
(local {: Box2dCircle : Box2dRectangle} (require :box2d))
(local ecs (require :ecs))
(local state (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local aabb (require :aabb))
(local {: text : view : image : shop-button : button : unit-display : class-display} (require :imm))
(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))
(local {: new-entity : get-mouse-position} (require :helpers))
(local {: Unit} (require :unit))
(local {: Object} (require :object))
(local {: Referee} (require :referee))
(local data (require :data))
(local aseprite (require :aseprite))
(local {: get-copy-str} (require :copy))
(local assets (require :assets))
(local effects (require :effects))

;(local wall-color (hexcolor :4460aaff))
(local wall-color (hexcolor :000000ff))

(λ upgrade-screen []
  [view {:display :absolute}
   [(when state.state.upgrade-screen-open?
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
                               :on-click #(state.state.director:choose-upgrade upgrade)})]])]]]))]])

(λ class-tooltip [class-info sz]
  (let [copy class-info.class-type]
    [[view {:display :flex
            :position (+ (vec 0 80) (- center-stage (/ sz 2)))
            :size sz
            :color (rgba 0 0 0 1)
            :padding (vec 4 4)}

      [[text {:text copy :color (rgba 1 1 1 1)}]]]]))

(λ unit-tooltip [unit sz]
  (let [copy (get-copy-str :en :units unit.type)
        stats (calc-stats unit)]
    [[view {:display :flex
            :position (+ (vec 0 80) (- center-stage (/ sz 2)))
            :size sz
            :color (rgba 0 0 0 1)
            :padding (vec 4 4)}

      [[view {:display :flex
              :flex-direction :column}
        [[text {:text (.. "HP:" stats.hp) :color (rgba 1 1 1 1)}]
         [text {:text (.. "Defense: " stats.defense) :color (rgba 1 1 1 1)}]
         [text {:text (.. "DMG: " stats.damage) :color (rgba 1 1 1 1)}]]]
       [text {:text copy :color (rgba 1 1 1 1)}]]]]))

(λ tooltip []
  [view {:display :absolute}
    (let [(tooltip-type v)
          (if (> (or (?. state.state :hover-unit :t) 0) state.state.time)
              (values :unit state.state.hover-unit)
              (> (or (?. state.state :hover-class :t) 0) state.state.time)
              (values :class state.state.hover-class))
          sz (vec 400 80)]
      (when v
        (if (= tooltip-type :unit)
            (unit-tooltip v sz)
            (class-tooltip v sz))))])

(λ upgrade-list []
  [view {:display :stack
         :position (vec 100 10)
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
   [[view {:display :stack
           :direction :right}
     (icollect [k v (pairs state.state.upgrades)]
       [text {:size (vec 50 20)
              :text k
              :color (rgba 0 0 0 1)}])]]])

(λ class-list []
  [view {:display :stack
         :position (vec 0 (/ arena-margin.y 2))
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
   (when (= :shop state.state.phase)
     [[view {:color (rgba 0.5 0.3 0.3 0)
             :display :stack
             :direction :down}
       (icollect [class-type info (pairs state.state.class-synergies)]
         [view {:size (vec (- arena-margin.x 10) 54)
                :display :flex}
           [(imm-stateful class-display state.state.class-synergies [class-type]
                          {: class-type
                           :size (vec (- arena-margin.x 10) 44)
                           :count info.count})]])]])])

(λ unit-list []
  [view {:display :stack
         :position (vec (- stage-size.x arena-margin.x) (/ arena-margin.y 2))
         :size (vec arena-margin.x stage-size.y)
         :padding (vec 4 4)}
    [[view {:color (rgba 0.5 0.3 0.3 0)
            :display :stack
            :direction :down}
      (when (> state.state.unit-count 0)
        (icollect [ix unit (ipairs state.state.team-state)]
          [view {:size (vec (- arena-margin.x 10) 44)
                 :display :stack
                 :padding (vec 0 2)
                 :direction :right}
           [(imm-stateful unit-display unit [:display]
                          {: unit
                           :size (vec (- arena-margin.x 10) 32)})]]))]]])

(λ money-display []
  [view {:display :stack
         :direction :right
         :position (vec 80 0)
         :padding (vec 8 0)
         :size (vec 200 30)}
   [(when state.state.started
      [text {:text (.. "$" (tostring state.state.money))
             :font assets.f32      
             :color (rgba 0 0 0 1)}])]])

(λ team-count-display []
  [view {:display :stack
         :direction :right
         :position (vec (- stage-size.x 120) 0)
         :padding (vec 8 0)
         :size (vec 100 30)}
   [(when state.state.started
      [text {:text (.. (length state.state.team-state) " / 10")
             :font assets.f32
             :color (rgba 0 0 0 1)}])]])

(λ level-display []
  [view {:display :stack
         :direction :right
         :position (vec (- stage-size.x 320) 0)
         :padding (vec 8 0)
         :size (vec 200 30)}
   [(when state.state.started
      [text {:text (.. "LEVEL " (tostring state.state.display-level))
             :font assets.f32
             :color (rgba 0 0 0 1)}])]])

(λ shop-row []
  [view {:display :stack
         :direction :right
         :position (vec 0 (- stage-size.y 89))
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

(λ Director.do-buff [self ea eb]
  (match ea.unit.type
    :healer (eb:heal ea.unit.level)))

(λ Director.friendly-bump [self ea eb col]
  (when state.state.combat-started
    (when (or (self:do-buff ea eb)
              (self:do-buff eb ea))
      (self:screen-shake))))

(λ Director.spinner-collision [self ea eb]
  (when (or (not eb.spinner-invin)
            (< eb.spinner-invin state.state.time))
    (set eb.spinner-invin (+ state.state.time 0.5))
    (self:screen-shake)
    (self:brief-pause)
    (eb:take-dmg 1)))

(λ Director.get-units-in-range [self team pos r]
  (icollect [k v (pairs (. state.state.teams
                           (if (= :player team)
                               :player
                               :enemy)))]
    (let [(x2 y2) (v.box2d.body:getPosition)]
      (when (< (pos:distance-to (vec x2 y2)) r)
        v))))

(λ Director.object-collision [self obj target]
  (set obj.dead true)
  (match obj.object-type
    :bomb
    (do
      (self:muzzle-flash obj.pos 3)
      (self:screen-shake)
      (self:brief-pause)
      (let [in-range (self:get-units-in-range obj.target-team obj.pos 90)]
        (each [_ unit (ipairs in-range)]
          (unit:take-dmg 3))))))

(λ Director.calc-dmg [self ent]
  (+ ent.unit.damage
     (match (. (or ent.def.classes []) 1)
       :bumper (* state.state.class-synergies.bumpers.level 2)
       _ 0)))

(λ Director.attack-bump [self ea eb col]
  (self:screen-shake)
  (let [(nx ny) (col:getNormal)
        angle (math.atan2 ny nx)
        c (math.cos angle)
        s (math.sin angle)
        f 1000000]
    (self:brief-pause)
    (print :ea-eb ea.unit.type ea.unit.damage eb.unit.type eb.unit.damage)
    (ea:take-dmg (self:calc-dmg eb))
    (eb:take-dmg (self:calc-dmg ea))
    (ea.box2d.body:applyLinearImpulse (* f c) (* f s))
    (ea.box2d.body:applyLinearImpulse (* (- f) c) (* (- f) s))))

(λ Director.bullet-hit [self bullet target]
  (target:take-dmg bullet.bullet.dmg)
  (self:screen-shake)
  (self:brief-pause)
  (set bullet.dead true))

(λ Director.process-collision [self ea eb col]
  (let [(collision-type A B)
        (if (and ea.bullet (= eb.team :enemy))
            (values :player-bullet-to-enemy ea eb)
            (and eb.bullet (= ea.team :enemy))
            (values :player-bullet-to-enemy eb ea)
            (and (= ea.team :player) (= eb.team :enemy))
            (values :bump-player-enemy ea eb)
            (and (= eb.team :player) (= ea.team :enemy))
            (values :bump-player-enemy eb ea)
            (and (= ea.team :player) (= eb.team :player))
            (values :bump-player-player ea eb)
            (and eb.wall ea.bullet)
            (values :bullet-wall ea nil)
            (and ea.wall eb.bullet)
            (values :bullet-wall eb nil))]
    (match collision-type
      :bullet-wall (set A.dead true)
      :bump-player-player (self:friendly-bump A B col)
      :bump-player-enemy (self:attack-bump A B col)
      :player-bullet-to-enemy (self:bullet-hit A B))))

;; box2d collision callbacks
(λ Director.begin-contact [self a b col]
  (let [ea (state.get-entity-by-id (a:getUserData))
        eb (state.get-entity-by-id (b:getUserData))]
    (when (and ea eb state.state.combat-started)
      (self:process-collision ea eb col))))

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
                  {:cost 3 :unit-type k :label k}))
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
                       {:cost 3 :unit-type u :label u}))
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
                {:pos (vec (/ arena-size.x 2) (* 1.25 arena-size.y))
                 :shrink-position (vec (/ arena-size.x 2) (* 1 arena-size.y))
                 :arena-draw-fg
                 (fn [self]
                   (self:draw-world-points))
                 :color wall-color
                 :size (vec arena-size.x (* arena-size.y 0.6))
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.top-wall
    (new-entity Box2dRectangle
                {:pos (vec (/ arena-size.x 2) (* -0.25 arena-size.y))
                 :shrink-position (vec (/ arena-size.x 2) (* 0 arena-size.y))
                 :arena-draw-fg
                 (fn [self]
                   (self:draw-world-points))
                 :color wall-color
                 :size (vec arena-size.x (* arena-size.y 0.6))
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.left-wall
    (new-entity Box2dRectangle
                {:pos (vec (* arena-size.x -0.27) (/ arena-size.y 2))
                 :shrink-position (vec (* arena-size.x 0.05) (/ arena-size.y 2))
                 :arena-draw-fg
                 (fn [self]
                   (self:draw-world-points))
                 :color wall-color
                 :size (vec (* arena-size.x 0.6) arena-size.y)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (set self.right-wall
    (new-entity Box2dRectangle
                {:pos (vec (* arena-size.x 1.27) (/ arena-size.y 2))
                 :shrink-position (vec (* arena-size.x 0.95) (/ arena-size.y 2))
                 :arena-draw-fg
                 (fn [self]
                   (self:draw-world-points))
                 :color wall-color
                 :size (vec (* arena-size.x 0.6) arena-size.y)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (each [_ w (ipairs [:top-wall :left-wall :bottom-wall :right-wall])]
    (new-entity Box2dRectangle
                {:pos (vec (* arena-size.x 1.27) (/ arena-size.y 2))
                 :shrink-position (vec (* arena-size.x 1) (/ arena-size.y 2))
                 :color wall-color
                 :size (vec (* arena-size.x 0.6) arena-size.y)
                 :wall true
                 :category "10000000"
                 :mask "11111111"}))

  (tiny.add ecs.world 
            self.bottom-wall
            self.top-wall
            self.left-wall
            self.right-wall))

(λ Director.draw [self]
   (layout #nil {:size stage-size} 
     [[view {:display :absolute}
       [(imm-stateful button state.state [:end-turn-btn]
                      {:label "End Turn"
                       :disabled (or (not state.state.started)
                                     (not= :shop state.state.phase))
                       :size (vec 140 80)
                       :on-click #(self:end-turn)
                       :position (vec (- stage-size.x 160) (- stage-size.y 88))})
        (imm-stateful button state.state [:reroll-shop-btn]
                      {:label "Reroll 1"
                       :disabled (or (not state.state.started)
                                     (not= :shop state.state.phase))
                       :size (vec 100 80)
                       :on-click #(self:buy-roll-shop)
                       :position (vec 20 350)})
        (upgrade-list)
        (class-list)
        (unit-list)
        (money-display)
        (level-display)
        (team-count-display)
        (shop-row)
        (upgrade-screen)
        (tooltip)]]])
   (let [fps (love.timer.getFPS)]
     (love.graphics.setColor 1 0 0 1)
     (love.graphics.print (tostring fps) 4 4)
     (love.graphics.setColor 0 1 0 1)
     (love.graphics.print (tostring state.state.unit-count) 40 4)))


(λ Director.add-gold [self v]
  (set state.state.money (+ state.state.money v)))

(λ Director.spawn-enemy-group [self pos group]
  (each [_ enemy-type (ipairs group)]
    (let [def (. data.enemy-types enemy-type)
          unit {:hp def.hp
                :damage def.damage
                :type enemy-type}]
      (tiny.addEntity ecs.world
                      (new-entity Unit {: pos : unit :team :enemy})))))

(λ Director.choose-upgrade [self upgrade]
  (set state.state.upgrade-screen-open? false)
  (tset state.state.upgrades upgrade.upgrade
        (+ (or (. state.state.upgrades upgrade.upgrade) 0) 1)))

(λ Director.spawn-object [self pos object-type]
  (tiny.addEntity ecs.world
                  (new-entity Object {: object-type
                                      :pos (pos:clone)})))

(λ Director.connect [self a b]
  (fire-timeline
   (local line {:z-index 10
                :id (get-id)
                :arena-draw-fg
                (fn []
                  (when (and (not a.dead) (not b.dead))
                    (graphics.line (a:get-pos) (b:get-pos) 4 (rgba 1 1 1 1))))})
   (tiny.addEntity ecs.world line)
   (timeline.wait 0.25)
   (set line.dead true)))

(λ Director.direct-damage [self v ent target]
  (self:screen-shake)
  (self:brief-pause)
  (self:connect ent target)
  (target:take-dmg v)
  (ent:flash (rgba 1 1 0 1)))

(λ Director.sell-unit [self unit]
  (set state.state.team-state
       (icollect [_ b (ipairs state.state.team-state)]
         (when (not= b.id unit.id) b)))
  (self:add-gold unit.level)
  (let [ent (state.get-entity-by-id unit.entity-id)]
    (set ent.dead true)
    (effects.text-flash
      (.. "+ " unit.level)
      (ent:get-pos)
      (rgba 1 1 0 1)))
  (fire-timeline
   (timeline.wait 0.25)
   (each [_ unit (ipairs state.state.team-state)]
     (let [ent (state.get-entity-by-id unit.entity-id)]
       (match unit.type
         :trader
         (let [target (ent:get-random-ally)]
           (when target
             (self:screen-shake)
             (self:brief-pause)
             (self:connect ent target)
             (target:heal 1)
             (ent:flash (rgba 1 1 0 1))))))))
  (self:calc-classes))

(λ Director.calc-classes [self]
  (set state.state.class-synergies
       (accumulate [acc {} _ unit (ipairs state.state.team-state)]
         (do
           (each [_ class-type (ipairs (. data.unit-types unit.type :classes))]
             (when (not (. acc class-type))
               (tset acc class-type {:count 0}))
             (tset acc class-type {:count (+ 1 (. acc class-type :count))})
             (tset acc class-type :level (if (<= 6 (. acc class-type :count)) 3
                                             (<= 4 (. acc class-type :count)) 2
                                             (<= 2 (. acc class-type :count)) 1
                                             0)))
           acc)))
  (fire-timeline
   (timeline.wait 0.25)
   (each [_ ent (pairs state.state.teams.player)]
     (ent:on-class-change))))

(λ Director.spawn-addtl [self pos team unit-type count]
  (self:screen-shake)
  (self:muzzle-flash pos)
  (for [i 1 count]
    (let [def (. data.unit-types unit-type)]
      (tiny.addEntity ecs.world
                      (new-entity Unit
                                  {: pos
                                   : team
                                   :unit {:hp def.hp
                                          :damage def.damage
                                          :type unit-type}})))))

(λ Director.merge-units [self a b]
   (self:brief-pause)
   (self:screen-shake)
   (self:connect a b)
   (a:flash)
   (b:flash)
   (timeline.wait 0.25)
   (set a.dead true)
   (set b.dead true)
   (set state.state.team-state
        (icollect [_ unit (ipairs state.state.team-state)]
          (when (and (not= unit.entity-id a.id)
                     (not= unit.entity-id b.id))
            unit)))
   (let [hp (math.ceil (+ (math.max a.unit.max-hp b.unit.max-hp)
                          (/ (+ a.unit.max-hp b.unit.max-hp) 4)))
         dmg (math.ceil (+ (math.max a.unit.damage b.unit.damage)
                           (/ (+ a.unit.damage b.unit.damage) 4)))
         unit
         (lume.merge
          a.unit
          b.unit
          {:level (if (= a.unit.level 1) 2 3)
           : hp
           :max-hp hp
           :damage dmg})
         ent (tiny.addEntity ecs.world
                             (new-entity Unit
                                         {:pos (/ arena-size 2)
                                          : unit}))]
     (set unit.entity-id ent.id)
     (table.insert state.state.team-state unit)
     (self:calc-classes)
     (self:check-do-merges unit)
     (effects.text-flash "LEVEL UP"
                         (/ arena-size 2)
                         (rgba 1 1 1 1)
                         assets.f32)))
  
(λ Director.check-do-merges [self unit]
    (var merged false)
    (each [_ u2 (ipairs state.state.team-state) :until merged]
      (when (and (not= unit u2) (= unit.level u2.level) (= u2.type unit.type))
        (set merged true)
        (fire-timeline
            (timeline.wait 0.3)
            (let [ea (state.get-entity-by-id unit.entity-id)
                  eb (state.get-entity-by-id u2.entity-id)]
              (when (and ea eb)
                (self:merge-units ea eb)))))))

(λ Director.purchase [self index]
  (when (>= (length state.state.team-state) 10)
    (do (lua :return)))
  (let [shop-item (. state.state.shop-row index)]
    (when (>= state.state.money shop-item.cost)
      (set state.state.money (- state.state.money shop-item.cost))
      (self:screen-shake)
      (let [def (. data.unit-types shop-item.unit-type)
            unit {:type shop-item.unit-type
                  :level 1
                  :max-hp def.hp
                  :damage def.damage
                  :hp def.hp
                  :id (get-id)}
            ent (tiny.addEntity ecs.world
                                (new-entity Unit {:pos (/ arena-size 2)
                                                  : unit}))]
        (set unit.entity-id ent.id)
        (table.insert state.state.team-state unit)
        (set state.state.shop-row
             (icollect [ix si (ipairs state.state.shop-row)]
               (when (not= index ix) si)))
        (self:calc-classes)
        (self:check-do-merges unit)))))


(λ Director.brief-pause [self]
  (when self.pause-timeline
    (self.pause-timeline:cancel))
  (set self.pause-timeline
       (fire-timeline
        (set state.state.time-scale 0)
        (timeline.wait 0.075)
        (set state.state.time-scale 1))))

(λ Director.time-update [self dt]
  (state.state.pworld:update dt))

(λ Director.update [self dt]
  (set state.state.time
       (+ state.state.time dt))
  (input:update)
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

(λ Director.restore-unit-state [self]
  (each [_ unit (pairs state.state.team-state)]
    (set unit.hp unit.max-hp)
    (let [ent (tiny.addEntity ecs.world
                              (new-entity Unit
                                          {:pos (/ arena-size 2)
                                           : unit}))]
      (set unit.entity-id ent.id)))
  (self:muzzle-flash (/ arena-size 2) 2)
  (self:screen-shake))

(λ Director.play-win-level-sequence [self]
  (each [k v (pairs state.state.destroy-after-combat)]
    (set v.dead true))
  (set state.state.destroy-after-combat {})
  (local spin-in
         {:z-index 20000
          :t 0
          :id (get-id)
          :arena-draw-fg
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
  (timeline.wait 1))

(λ text-flash [s pos color ?font])

(λ Director.line-up-units [self]
  (each [_ team (ipairs [:player :enemy])]
    (var ix 0)
    (each [k ent (pairs (. state.state.teams team))]
      (set ix (+ ix 1))
      (set ent.targpos (ent:get-body-pos))
      (let [root (if (= team :player)
                     (vec 50 50)
                     (- arena-size (vec 130 130)))
            x (% ix 4)
            y (math.floor (/ ix 4))]
        (fire-timeline
          (timeline.tween 1 ent
                          {:targpos (+ root
                                       (* 24 (vec x y)))}
                          :outQuad)))))
  (timeline.wait 1))

(λ Director.do-shop-phase [self]
  (self:add-gold (+ 10 (or (?. state.state.class-synergies :traders :level) 0)))
  (fire-timeline
   (timeline.wait 0.25)
   (each [_ unit (ipairs state.state.team-state)]
     (let [ent (state.get-entity-by-id unit.entity-id)]
       (match unit.type
         :banker
         (do
           (self:brief-pause)
           (self:screen-shake)
           (ent:flash (rgba 1 1 0 1))
           (self:add-gold 1)
           (effects.text-flash
             (.. "+ " 1)
             (ent:get-pos)
             (rgba 1 1 0 1))
           (timeline.wait 0.3))))))
  (set state.state.phase :shop)
  (self:roll-shop)
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
         (* 0.9 arena-size)
         grp)))))

(local wall-time 5)
(λ Director.start-walls [self]
  (set self.wall-timelines [])
  ;; (table.insert self.wall-timelines
  ;;               (fire-timeline
  ;;                (timeline.tween wall-time state.state {:arena-zoom 2} :inOutQuad)))
  (each [_ k (ipairs [:top-wall :left-wall :bottom-wall :right-wall])]
    (let [wall (. self k)]
      (set wall.targpos (wall.pos:clone))
      (table.insert self.wall-timelines
                    (fire-timeline
                     (timeline.tween wall-time wall {:targpos wall.shrink-position} :inOutQuad))))))

(λ Director.reset-walls [self]
  (when self.wall-timelines
    (each [_ tl (ipairs self.wall-timelines)]
      (tl:cancel)))
  (fire-timeline)
   ;(timeline.tween 2 state.state {:arena-zoom 1} :inOutQuad))
  (each [_ k (ipairs [:top-wall :left-wall :bottom-wall :right-wall])]
    (let [wall (. self k)
          (x y) (wall.body:getPosition)]
      (set wall.targpos (vec x y))
      (fire-timeline
       (timeline.tween 2 wall {:targpos wall.pos} :outQuad)))))

(λ Director.title-screen [self]
  (local spin-in
         {:z-index 20000
          :t 0.75
          :id (get-id)
          :arena-draw-fg
          (fn [self]
            (love.graphics.push)
            (love.graphics.translate (/ arena-size.x 2)
                                     (/ arena-size.y 2))
            (love.graphics.rotate (* self.t 2 math.pi))
            (love.graphics.scale (* 3 self.t) (* 3 self.t))
            (graphics.print-centered "FLOOB" assets.f32
                                     (vec 0 0) (rgba 1 0 0 1))
            (love.graphics.pop))})
  (tiny.addEntity ecs.world spin-in)
  (timeline.tween 1 spin-in {:t 1} :outQuad)
  (while (not (input.mouse-released?))
    (coroutine.yield))
  (set state.state.started true)
  (set spin-in.dead true))
  

(λ Director.game-over [self]
  (local spin-in
         {:z-index 20000
          :t 0
          :id (get-id)
          :arena-draw-fg
          (fn [self]
            (love.graphics.push)
            (love.graphics.translate (/ arena-size.x 2)
                                     (/ arena-size.y 2))
            (love.graphics.rotate (* self.t 2 math.pi))
            (love.graphics.scale (* 3 self.t) (* 3 self.t))
            (graphics.print-centered "GAME OVER" assets.f32
                                     (vec 0 0) (rgba 1 0 0 1))
            (love.graphics.pop))})
  (tiny.addEntity ecs.world spin-in)
  (timeline.tween 1.5 spin-in {:t 1} :outQuad)
  (each [team teamlist (pairs state.state.teams)]
    (each [_ unit (pairs teamlist)]
      (unit:pop)
      (timeline.wait 0.1)))
  (timeline.wait 1)
  (self.reset-game))

(λ Director.start-combat [self]
  (set state.state.combat-started true)
  (each [_ unit (pairs state.state.teams.player)]
    (unit:start-combat))
  (each [_ unit (pairs state.state.teams.enemy)]
    (unit:start-combat)))

(λ Director.main-timeline [self]
  ;; TODO: SAUCE
  ;; (set state.state.referee
  ;;      (tiny.addEntity ecs.world (new-entity Referee)))
  (self:setup-arena-entities)
  (self:title-screen)
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
          (self:pre-combat-animation)
          (self:spawn-enemies group-options waves)
          (timeline.wait 0.5)
          (self:line-up-units)
          (timeline.wait 1)
          (self:start-combat)
          (timeline.wait 2)
          (self:start-walls)
          (while (and (> state.state.unit-count 0)
                      (> state.state.enemy-count 0))
            (coroutine.yield))
          (timeline.wait 0.5))
        {:type :upgrade}
        (do
          (self:open-upgrade-screen)
          (while state.state.upgrade-screen-open?
            (coroutine.yield))))

      (self:reset-walls)
      (set state.state.combat-started false)

      (when (and (> state.state.unit-count 0)
                 (= :combat level-def.type))
        (self:play-win-level-sequence)
        (set state.state.display-level (+ state.state.display-level 1)))

      (when (and (> state.state.enemy-count 0)
                 (= :combat level-def.type))
        (self:game-over))

      (set state.state.level (+ state.state.level 1)))))

      

(set Director.__defaults
     {:z-index 10000})

Director
