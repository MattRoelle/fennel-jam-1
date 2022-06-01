(import-macros {: fire-timeline : imm-stateful} :macros)

(local state (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local graphics (require :graphics))
(local {: new-entity : get-mouse-position} (require :helpers))
(local aabb (require :aabb))
(local input (require :input))
(local assets (require :assets))
(local timeline (require :timeline))

(λ text [context props]
  "Basic text component"
  (let [rect (get-layout-rect context)
        alignment (or props.align :center)]
    (when props.color
      (graphics.print-centered (or props.text "nil")
                               (or props.font assets.f16)
                               (. rect alignment)
                               props.color))))

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

(λ mouse-interaction [context]
  "Returns values indicating mouse-down? and hovering? state"
  (let [mpos (get-mouse-position)
        mouse-down? (input:mouse-released?)
        rect (aabb context.position context.size)
        hovering? (rect:contains-point? mpos)]
    (values mouse-down? hovering?)))

(λ button [?state context props]
  "An immediate mode button"
  (let [bstate (or ?state {:hover false :scale 0.85})
        (mouse-down? hovering?) (mouse-interaction context)]
    (set bstate.hover hovering?)
    (when props.disabled (do (lua :return)))
    (when (and props.on-click hovering? mouse-down?)
      (props.on-click))
    (when (not ?state)
      (fire-timeline
       (timeline.tween 0.3 bstate {:scale 1} :outQuad)))
    (set bstate.mouse-down? mouse-down?)
    (love.graphics.push)
    ;(love.graphics.scale bstate.scale bstate.scale)
    (graphics.rectangle context.position context.size
                        (if bstate.hover
                            (rgba 0.4 0.4 0.4 1)
                            (rgba 0.2 0.2 0.2 1)))
    (let [r (get-layout-rect context)]
      (graphics.print-centered (or props.label "NA") assets.f16
                               r.center
                               (rgba 1 1 1 1)))
    (love.graphics.pop)
    bstate))

(λ unit-display [?state context props]
  (assert props.unit "Must pass unit")
  (let [bstate (or ?state {:hover false})
        (mouse-down? hovering?) (mouse-interaction context)]
    (set bstate.hover hovering?)
    (when (and hovering? mouse-down?)
      (state.state.director:sell-unit props.unit))
    (when hovering?
      (set state.state.hover-unit
           {:unit-type props.unit.type
            :t (+ state.state.time 0.05)
            :level props.unit.level}))
    (graphics.rectangle context.position context.size
                        (if bstate.hover
                            (rgba 0.4 0.4 0.4 1)
                            (rgba 0.2 0.2 0.2 1)))
    (graphics.rectangle (+ context.position (vec 0 20)) (vec context.size.x 10)
                        (rgba 0 0 0 1))
    (graphics.rectangle (+ context.position (vec 0 20))
                        (vec (* context.size.x (/ props.unit.hp props.unit.max-hp))
                             10)
                        (rgba 1 0 0 1))
    (set props.unit.hovering hovering?)
    (let [r (get-layout-rect context)]
      (graphics.print-centered
        (if hovering?
           "SELL"
           (.. "Lv. " props.unit.level " " props.unit.type))
        assets.f16 (- r.center (vec 0 8))
        (rgba 1 1 1 1))
      (graphics.print-centered
        (.. props.unit.hp "/" props.unit.max-hp)
        assets.f16 (+ r.center (vec 0 8))
        (rgba 1 1 1 1)))))

(λ shop-button [?state context props]
  "An immediate mode button"
  (assert props.index "Must pass index")
  (when (not (. state.state.shop-row props.index))
    (do (lua :return)))
  (let [bstate (or ?state {:hover false})
        (mouse-down? hovering?) (mouse-interaction context)]
    (set bstate.hover hovering?)
    (when hovering?
      (set state.state.hover-unit
           {:unit-type (. state.state.shop-row props.index :unit-type)
            :t (+ state.state.time 0.05)
            :level 1})
      (set state.state.hover-shop-btn bstate))
    (when (and hovering? mouse-down?)
      (state.state.director:purchase props.index))
    (set bstate.mouse-down? mouse-down?)
    (graphics.rectangle context.position context.size
                        (if (= state.state.active-shop-btn bstate)
                            (rgba 0.7 0.7 0.7 1)
                            bstate.hover
                            (rgba 0.4 0.4 0.4 1)
                            (rgba 0.2 0.2 0.2 1)))
    (let [r (get-layout-rect context)]
      (graphics.print-centered (or props.label "NA") assets.f16
                               (+ r.center (vec 0 -16))
                               (rgba 1 1 1 1))
      (graphics.print-centered
       (.. "$" props.cost)
       assets.f16
       (+ r.center (vec 0 8))
       (rgba 1 1 1 1)))
    bstate))


{: text
 : image
 : view
 : shop-button
 : unit-display
 : button}
