(local fennel (require :lib.fennel))
(local repl (require :lib.stdio))

(var scale 1)

;; set the first mode
(var (mode mode-name) nil)

(fn set-mode [new-mode-name ...]
  (set (mode mode-name) (values (require new-mode-name) new-mode-name))
  (when mode.activate
    (match (pcall mode.activate ...)
      (false msg) (print mode-name "activate error" msg))))

(fn love.load [args]
  (set-mode :mode-intro)
  (when (~= :web (. args 1)) (repl.start)))

(fn safely [f]
  (xpcall f #(set-mode :error-mode mode-name $ (fennel.traceback))))

;; (fn love.draw []
;;   ;; the canvas allows you to get sharp pixel-art style scaling; if you
;;   ;; don't want that, just skip that and call mode.draw directly.
;;   (love.graphics.setCanvas canvas)
;;   (love.graphics.clear)
;;   (love.graphics.setColor 1 1 1)
;;   (safely mode.draw)
;;   (love.graphics.setCanvas)
;;   (love.graphics.setColor 1 1 1)
;;   (love.graphics.draw canvas 0 0 0 scale scale))


;; Hacks because im too lazy to dig up the code for custom love
;; event plumbing and I need game logic to tick in the draw
;; phase because everything is in ECS... :)
(var DT 0)
(fn love.update [dt] (set DT dt))

(fn love.draw []
  (love.graphics.setColor 1 1 1)
  (when mode.update
    (safely #(mode.update DT set-mode)))
  (love.graphics.setCanvas))

(fn love.keypressed [key]
  (if (and (love.keyboard.isDown "lctrl" "rctrl" "capslock") (= key "q"))
      (love.event.quit)
      ;; add what each keypress should do in each mode
      (safely #(mode.keypressed key set-mode))))

(fn love.resize [w h]
  (when (and mode mode.resize)
    (safely #(mode.resize w h))))
