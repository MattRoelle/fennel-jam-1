(λ fire-timeline [...]
  `(let [{:world world#} (require :ecs)
         tiny# (require :lib.tiny)]
     (tiny#.addEntity world# 
                      {:timeline ((require :timeline) #(do ,...))})))

(λ imm-stateful [f state-host keys props ?children]
  `[#(tset ,state-host (unpack ,keys)
           (,f (. ,state-host (unpack ,keys)) $...))
     ,props ,?children])
  
{: fire-timeline
 : imm-stateful}
