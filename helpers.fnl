(local {: vec} (require :vector))
(local {: state} (require :state))

(var _id 0)
(fn get-id [] (set _id (+ _id 1)) _id)

(λ new-entity [typ ?o]
  (let [tbl (lume.merge (or typ.__defaults {})
                        (or ?o {}))
        inst (setmetatable tbl typ)]
    (set inst.id (tostring (get-id)))
    inst))

(λ get-mouse-position []
  (let [(x y) (love.mouse.getPosition)
        ret (/ (- (vec x y) state.screen-offset) state.screen-scale.x)]
    ret))

{: new-entity
 : get-mouse-position
 : get-id}

