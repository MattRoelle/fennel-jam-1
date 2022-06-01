(local {: vec} (require :vector))
(local {: state} (require :state))
(local data (require :data))

(var _id 0)
(fn get-id [] (set _id (+ _id 1)) (tostring _id))

(λ new-entity [typ ?o]
  (let [tbl (lume.merge (or typ.__defaults {})
                        (or ?o {}))
        inst (setmetatable tbl typ)]
    (set inst.id (or inst.id (tostring (get-id))))
    inst))

(λ get-mouse-position []
  (let [(x y) (love.mouse.getPosition)
        ret (/ (- (vec x y) state.screen-offset) state.screen-scale.x)]
    ret))

(λ calc-stats [unit]
  (print :ut unit.type)
  (let [def (. data.unit-types unit.type)]
    {:hp (or unit.max-hp def.hp)
     :defense def.defense
     :ability def.ability
     :bump-damage def.bump-damage}))

{: new-entity
 : get-mouse-position
 : get-id
 : calc-stats}

