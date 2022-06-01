(import-macros {: fire-timeline : imm-stateful} :macros)

(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local lume (require :lib.lume))
(local {: new-entity : get-mouse-position} (require :helpers))
(local {: Box2dCircle : Box2dRectangle : Box2dPolygon} (require :box2d))
(local state (require :state))
(local data (require :data))
(local timeline (require :timeline))
(local assets (require :assets))
(local {: new-entity} (require :helpers))
(local tiny (require :lib.tiny))
(local ecs (require :ecs))
(local Projectile (require :projectile))
(local effects (require :effects))
(local palette (require :palette))
(local aseprite (require :aseprite))
(local input (require :input))
(local {: stage-size : center-stage : arena-margin : arena-offset : arena-size} (require :constants))

(local Referee {})
(set Referee.__index Referee)

(λ Referee.init [self])

(λ Referee.update [self dt])

(λ Referee.play-intro [self]
  (when self.tl
    (self.tl:cancel))
  (set self.tl
      (fire-timeline
       (self:go-home)
       (self:speak "Welcome to DOINK!#I am king doink.")
       (timeline.wait 0.5)
       (self:speak "If you already know#how to play.....# #....just start buying crap")
       (timeline.wait 0.5)
       (table.insert timelines
                     (fire-timeline
                      (timeline.tween 0.5 self {:pos (- stage-size (vec 350 150))
                                                :angle -0.3})))
       (self:speak "This is MY shop#I make the rules...#So, everything costs $3" 2)
       (self:go-home)
       (set self.eye-state :angry)
       (self:speak "IF YOU DO NOT#LIKE MY SHOP!?#...That is disrespectful")
       (set self.eye-state :normal)
       (self:speak "However, I like money#So, If you pay me $1#you can have new stuff" 3)
       (table.insert timelines
                     (fire-timeline
                      (timeline.tween 0.5 self {:pos (- stage-size (vec 300 150))
                                                :angle -0.3})))
       (self:speak "Once you buy a team#Click this button to#end your turn" 3)
       (self:go-home)
       (self:speak "That's all for now,#you can figure the#rest out yourself#" 3)
       (timeline.wait 0.5)
       (self:speak "GLHF"))))

(λ Referee.go-home [self]
  (timeline.tween 0.5 self {:pos self.home
                            :angle 0.2} :outQuad))

(λ Referee.speak! [self text ?hold]
  (when self.tl
    (self.tl:cancel))
  (set self.tl
       (fire-timeline)
       (self:speak text ?hold)))

(λ Referee.speak [self text ?hold]
    (set self.talking true)
    (set self.mouth-state :o)
    (set self.text "")
    (for [i 1 (string.len text)]
        (set self.text (string.sub text 1 i))
        (timeline.wait 0.02))
    (timeline.wait (or ?hold 1))
    (set self.mouth-state :flat)
    (set self.talking false))

(λ Referee.draw [self]
  (love.graphics.push)
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.translate self.pos.x self.pos.y)
  (love.graphics.rotate self.angle)
  (graphics.image aseprite.king-doink)

  ;; mouth
  (graphics.image (. aseprite (.. :king-doink-mouth- self.mouth-state))
                  (vec 0 20))

  ;; left eye
  (let [mpos (get-mouse-position)
        dist-to-mouse (/ (mpos:distance-to self.pos) stage-size.x)
        angle-to-mouse (mpos:angle-to self.pos)
        pupil-pos (polar-vec2 angle-to-mouse (* dist-to-mouse -5))]
    (let [p (vec -15 5)]
      (graphics.image (. aseprite (.. :king-doink-eye-base- self.eye-state)) p)
      (graphics.circle (+ p pupil-pos) 4 (rgba 0 0 0 1)))

    ;; right eye
    (let [p (vec 15 -5)]
      (graphics.image (. aseprite (.. :king-doink-eye-base- self.eye-state)) p)
      (graphics.circle (+ p pupil-pos) 4 (rgba 0 0 0 1))))

  (love.graphics.rotate (- self.angle))
  (when self.talking
    (graphics.image aseprite.text-bubble (vec 150 -50))
    (graphics.print-centered self.text assets.f16
                             (vec 150 -60)
                             (rgba 0 0 0 1)))
  (love.graphics.pop))

(set Referee.__defaults
     {:z-index 100000
      :pos (vec -500 290)
      :home (vec 60 290)
      :mouth-state :o
      :talking false
      :eye-state :normal
      :angle 0.2})

{: Referee}
