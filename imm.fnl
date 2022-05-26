(local state (require :state))
(local {: layout : get-layout-rect} (require :imgui))
(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))
(local graphics (require :graphics))
(local {: new-entity : get-mouse-position} (require :helpers))
(local aabb (require :aabb))
(local input (require :input))
(local assets (require :assets))

(λ text [context props]
  "Basic text component"
  (let [rect (get-layout-rect context)
        alignment (or props.align :center)]
    (when props.color
      (graphics.print-centered (or props.text "nil")
                               assets.f16
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
  (let [bstate (or ?state {:hover false})
        (mouse-down? in-range?) (mouse-interaction context)]
    (set bstate.hover in-range?)
    (when (and props.on-click in-range? mouse-down?)
      (props.on-click))
    (set bstate.mouse-down? mouse-down?)
    (graphics.rectangle context.position context.size
                        (if bstate.hover
                            (rgba 0.4 0.4 0.4 1)
                            (rgba 0.2 0.2 0.2 1)))
    (love.graphics.rectangle :fill
                            (+ context.position.x props.padding.x)
                            (+ context.position.y props.padding.y)
                            (- context.size.x (* props.padding.x 2))
                            (- context.size.y (* props.padding.y 2)))
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print (or props.label "na") context.position.x context.position.y)
    bstate))


(λ shop-button [?state context props]
  "An immediate mode button"
  (let [bstate (or ?state {:hover false})
        (mouse-down? in-range?) (mouse-interaction context)]
    (set bstate.hover in-range?)
    (when (and in-range? mouse-down?)
      (set state.state.active-shop-btn
           (if (= state.state.active-shop-btn bstate) nil bstate)))
      ;(props.on-click))
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
    (love.graphics.setColor 1 1 1 1)
    (love.graphics.print (or props.label "na") context.position.x context.position.y)
    bstate))


{: text
 : image
 : view
 : shop-button
 : button}
