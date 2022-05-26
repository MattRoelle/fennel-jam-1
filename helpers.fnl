(local {: vec} (require :vector))
(local {: state} (require :state))

(λ new-entity [typ ?o]
  (let [tbl (lume.merge (or typ.__defaults {})
                        (or ?o {}))
        inst (setmetatable tbl typ)]
    inst))

(λ get-mouse-position []
  (let [(x y) (love.mouse.getPosition)
        ret (/ (- (vec x y) state.screen-offset) state.screen-scale.x)]
    ret))

{: new-entity
 : get-mouse-position}
