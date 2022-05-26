(local tiny (require :lib.tiny))

(local module {})

(λ module.reset-ecs []
  (set module.world (tiny.world)))

(module.reset-ecs)

module


