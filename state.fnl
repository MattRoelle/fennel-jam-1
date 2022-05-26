(local {: vec} (require :vector))
(local {: world} (require :ecs))
(local tiny (require :lib.tiny))
(local data (require :data))

(local module {:state {}})

(local initial-state
       {:screen-scale (vec 1 1)
        :screen-offset (vec 0 0)
        :unit-count 0
        :units
        (collect [k _ (pairs data.unit-types)]
          (values k []))
        :teams {:player {} :enemy {}}
        :arena-mpos (vec 0 0)
        :shop-row []})

(λ module.reset-state []
  (when module.state.pworld
    (module.state.pworld:destroy))
  (each [k v (pairs module.state)]
    (tset module.state k nil))
  (love.physics.setMeter 32)
  (set module.state.pworld (love.physics.newWorld 0 0 true))
  (each [k v (pairs initial-state)]
    (tset module.state k 
          (let [initial-state-v (. initial-state k)
                v-type (type v)]
            (if (= :table v-type)
                (if (and (getmetatable v-type) initial-state-v.clone)
                  (initial-state-v:clone)
                  (lume.clone initial-state-v))
                initial-state-v)))))

(module.reset-state)

module
