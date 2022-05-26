(local {: vec : polar-vec2} (require :vector))
(local {: rgba : hexcolor} (require :color))

(local stage-size (vec 720 450))
(local center-stage (/ stage-size 2))
(local arena-margin (vec 100 70))
(local arena-offset (vec 0 -50))
(local arena-size (- stage-size (* arena-margin 2)))

{: stage-size
 : center-stage
 : arena-margin
 : arena-offset
 : arena-size}
