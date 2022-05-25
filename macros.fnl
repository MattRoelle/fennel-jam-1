(λ fire-timeline [...]
  `(let [{:world world#} (require :ecs)
         tiny# (require :lib.tiny)]
     (tiny#.addEntity world# 
       {:timeline ((require :timeline) #(do ,...))})))

{: fire-timeline}
