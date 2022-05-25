(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))

(local stage-size (vec 720 450))
(local center-stage (/ stage-size 2))
(local arena-margin (vec 40 70))
(local arena-offset (vec 0 -32))


{:draw
 (fn draw [message]
   ;; Draw arena
   (graphics.rectangle (vec 0 0) stage-size (hexcolor :212121ff))
   (let [pos (+ arena-margin arena-offset)
         sz (- stage-size (* arena-margin 2))]
     (graphics.rectangle (- pos (vec 4 -4)) sz (rgba 1 1 1 1))
     (graphics.rectangle pos sz (rgba 0 0 0 1))))
 :update (fn update [dt set-mode])
 :keypressed (fn keypressed [key set-mode])}
                 ;(love.event.quit))}
