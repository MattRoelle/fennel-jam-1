(local {: vec} (require :vector))
(local {: world} (require :ecs))
(local tiny (require :lib.tiny))

(var state {})
(local initial-state
       {:screen-scale (vec 1 1)
        :screen-offset (vec 0 0)
        :arena-mpos (vec 0 0)
        :shop-row [{} {} {}]})

(λ reset-state []
  (when state.pworld
    (state.pworld:destroy))
  (each [k v (pairs state)]
    (tset state k nil))
  (love.physics.setMeter 32)
  (set state.pworld (love.physics.newWorld 0 0 true))
  (each [k v (pairs initial-state)]
    (tset state k 
          (let [initial-state-v (. initial-state k)
                v-type (type v)]
            (if (= :table v-type)
                (if (and (getmetatable v-type) initial-state-v.clone)
                  (initial-state-v:clone)
                  (lume.clone initial-state-v))
                initial-state-v)))))

{: state : reset-state}
