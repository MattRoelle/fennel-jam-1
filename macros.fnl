(λ fire-timeline [...]
  `(let [{:world world#} (require :ecs)
         tiny# (require :lib.tiny)
         timeline# ((require :timeline) #(do ,...))]
     (tiny#.addEntity world# {:timeline timeline#})
     timeline#))

(λ imm-stateful [f state-host keys props ?children]
  `[#(tset ,state-host (unpack ,keys)
           (,f (. ,state-host (unpack ,keys)) $...))
    ,props ,?children])

;; not working....
(λ with-entities [binding ...]
  (let [add-list []
        remove-list []
        tiny (gensym)
        ecs (gensym)]
    (for [i 1 (length binding) 2]
      (let [k (. binding i)
            v (. binding (+ i 1))]
        (table.insert add-list
                      `((. ,tiny :addEntity) (. ,ecs :world) ,v))
        (table.insert remove-list
                      `(tset ,k :dead true))))
    `(let ,binding
       (let [,tiny (require :lib.tiny)
             ,ecs (require :ecs)]
         (do ,(unpack add-list))
         (do ,...)
         (do ,(unpack remove-list))))))

{: fire-timeline
 : imm-stateful
 : with-entities}
