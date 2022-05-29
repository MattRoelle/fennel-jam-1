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
    (when (and props.on-click hovering? mouse-down?)
      (props.on-click))
    (when (not ?state)
      (fire-timeline
       (timeline.tween 0.3 bstate {:scale 1} :outQuad)))
    (set bstate.mouse-down? mouse-down?)
    (love.graphics.push)
    ;(love.graphics.scale bstate.scale bstate.scale)
    (graphics.stroke-rectangle context.position context.size
                               4
                               (rgba 1 1 1 1) 4)
    (graphics.rectangle context.position context.size
                        (if bstate.hover
                            (rgba 0.4 0.4 0.4 1)
                            (rgba 0 0 0 1)) 4)
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print (or props.label "na") context.position.x context.position.y)
    (love.graphics.pop)
    bstate))


(λ shop-button [?state context props]
  "An immediate mode button"
  (assert props.index "Must pass index")
  (when (not (. state.state.shop-row props.index))
    (do (lua :return)))
  (let [bstate (or ?state {:hover false})
        (mouse-down? hovering?) (mouse-interaction context)]
    (set bstate.hover hovering?)
    (set state.state.hover-shop-btn
         (if hovering? bstate
             (= state.state.hover-shop-btn bstate) nil
             state.state.hover-shop-btn))
    (when (and hovering? mouse-down?)
      (state.state.director:purchase props.index))
    (set bstate.mouse-down? mouse-down?)
    (graphics.rectangle context.position context.size
                        (if (= state.state.active-shop-btn bstate)
                            (rgba 0.7 0.7 0.7 1)
                            bstate.hover
                            (rgba 0.4 0.4 0.4 1)
                            (rgba 0.2 0.2 0.2 1)))
    (love.graphics.rectangle :fill
                            (+ context.position.x props.padding.x)
                            (+ context.position.y props.padding.y)
                            (- context.size.x (* props.padding.x 2))
                            (- context.size.y (* props.padding.y 2)))
    (let [r (get-layout-rect context)]
      (graphics.print-centered (or props.label "NA") assets.f16 r.center (rgba 1 1 1 1)))
    bstate))


{: text
 : image
 : view
 : shop-button
 : button}
