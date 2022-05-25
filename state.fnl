(local {: vec} (require :vector))

(var state {})
(local initial-state
       {:screen-scale (vec 1 1)})

(λ reset-state []
  (each [k v (pairs state)]
    (tset state k nil))
  (each [k v (pairs initial-state)]
    (tset state k 
          (let [initial-state-v (. initial-state k)
                v-type (type v)]
            (if (= :table v-type)
                (lume.clone initial-state-v)
                initial-state-v)))))

{: state : reset-state}
