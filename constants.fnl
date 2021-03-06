(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))

(local stage-size (/ (vec 1920 1080) 2))
(local center-stage (/ stage-size 2))
(local arena-margin (vec 140 70))
(local arena-offset (vec 0 -30))
(local arena-size (- stage-size (* arena-margin 2)))

(print :as arena-size)

{: stage-size
 : center-stage
 : arena-margin
 : arena-offset
 : arena-size}
