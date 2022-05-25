(local {: vec : polar-vec2} (require :vector))
(local graphics (require :graphics))
(local {: rgba : hexcolor} (require :color))
(local {: state} (require :state))
(local lume (require :lib.lume))

(local Box2dEntity {})
(set Box2dEntity.__index Box2dEntity)

(λ Box2dEntity.arena-draw [self]
  (self:draw-world-points))

(λ Box2dEntity.create-body [self]
  (set self.body (love.physics.newBody
                  state.pworld
                  self.pos.x self.pos.y
                  self.body-type)))

(λ Box2dEntity.draw-world-points [self]
  (graphics.set-color (or self.color (rgba 1 1 1 1)))
  (match self.shape-type
    :circle
    (let [(x y) (self.body:getPosition)]
      (love.graphics.circle :fill x y self.radius))
    _
    (love.graphics.polygon :fill
                           (self.body:getWorldPoints
                            (self.shape:getPoints)))))

(λ Box2dEntity.init-properties [self]
  (set self.fixture (love.physics.newFixture self.body self.shape
                                             (or self.density 1)))
  (when self.linear-damping
    (self.body:setLinearDamping self.linear-damping))
  (when self.restitution
    (self.fixture:setRestitution self.restitution)))

(set Box2dEntity.__defaults
     {:linear-damping 0.9
      :restituion 0})

(local Box2dRectangle (setmetatable {} Box2dEntity))
(set Box2dRectangle.__index Box2dRectangle)

(λ Box2dRectangle.init [self]
  (self:create-body)
  (set self.shape (love.physics.newRectangleShape
                    self.size.x self.size.y))
  (self:init-properties))

(set Box2dRectangle.__defaults
     (lume.merge Box2dEntity.__defaults
       {:z-index 10
        :pos (vec 32 32)
        :size (vec 100 100)
        :shape-type :rectangle
        :body-type :static}))

(local Box2dCircle (setmetatable {} Box2dEntity))
(set Box2dCircle.__index Box2dCircle)

(λ Box2dCircle.init [self]
  (self:create-body)
  (set self.shape (love.physics.newCircleShape self.radius))
  (self:init-properties))

(set Box2dCircle.__defaults
     (lume.merge Box2dEntity.__defaults
                 {:z-index 10
                  :pos (vec 32 32)
                  :shape-type :circle
                  :radius 6
                  :body-type :static}))

{: Box2dEntity
 : Box2dRectangle
 : Box2dCircle}
