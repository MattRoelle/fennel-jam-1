(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local {: state} (require :state))
(local lume (require :lib.lume))

(local Box2dEntity {})
(set Box2dEntity.__index Box2dEntity)

(λ Box2dEntity.arena-draw [self]
  (self:draw-world-points))

(λ Box2dEntity.draw-world-points [self]
   (graphics.set-color (or self.color (rgba 1 1 1 1)))
   (love.graphics.polygon :fill (self.body:getWorldPoints (self.shape:getPoints))))

(λ Box2dEntity.init-properties [self]
  (set self.fixture (love.physics.newFixture self.body self.shape
                                             (or self.density 1)))
  (when self.restitution
    (self.fixture:setRestitution self.restitution)))

(local Box2dRectangle (setmetatable {} Box2dEntity))
(set Box2dRectangle.__index Box2dRectangle)

(λ Box2dRectangle.init [self]
  (set self.body (love.physics.newBody
                  state.pworld
                  self.pos.x self.pos.y
                  self.body-type))
  (set self.shape (love.physics.newRectangleShape
                    self.size.x self.size.y))
  (self:init-properties))

(set Box2dRectangle.__defaults {:z-index 10
                                :pos (vec 32 32)
                                :size (vec 100 100)
                                :body-type :static})

{: Box2dEntity
 : Box2dRectangle}
