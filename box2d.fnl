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

(λ Box2dEntity.update [self dt]
  (when self.targpos
    (self.body:setPosition self.targpos.x self.targpos.y)))

(λ Box2dEntity.draw-local-points [self ?color ?scale]
  (graphics.set-color (or ?color (rgba 1 1 1 1)))
  (match self.shape-type
    :circle (love.graphics.circle :fill 0 0 self.radius)
    _ (love.graphics.polygon :fill (self.shape:getPoints))))

(λ Box2dEntity.draw-world-points [self ?color ?scale]
  (graphics.set-color (or ?color self.color (rgba 1 1 1 1)))
  (let [(x y) (self.body:getPosition)]
    (match self.shape-type
      :circle (love.graphics.circle :fill x y self.radius)
      _ (love.graphics.polygon :fill (self.body:getWorldPoints (self.shape:getPoints))))))

(λ Box2dEntity.set-filter-data [self category mask]
  (set self.category category)
  (set self.mask mask)
  (self.fixture:setFilterData
   (tonumber self.category 2)
   (tonumber self.mask 2)
   0))

(λ Box2dEntity.init-properties [self]
  (set self.fixture (love.physics.newFixture self.body self.shape
                                             (or self.density 1)))
  (self.fixture:setUserData self.id)
  (when self.linear-damping
    (self.body:setLinearDamping self.linear-damping))
  (when self.angular-damping
    (self.body:setAngularDamping self.angular-damping))
  (when self.restitution
    (self.fixture:setRestitution self.restitution))
  (when self.category
    (assert self.mask "must pass mask")
    (self:set-filter-data self.category self.mask))
  (when self.iv
    (self.body:applyLinearImpulse self.iv.x self.iv.y))
  (let [(l t r b) (self.shape:computeAABB 0 0 0 1)]
    (set self.size (vec (- r l) (- b t)))))

(set Box2dEntity.__defaults
     {:linear-damping 0.9
      :restituion 0})

(local Box2dRectangle (setmetatable {} Box2dEntity))
(set Box2dRectangle.__index Box2dRectangle)

(λ Box2dRectangle.init [self ?id]
  (set self.id (or ?id self.id))
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

(λ Box2dCircle.init [self ?id]
  (set self.id (or ?id self.id))
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

(local Box2dPolygon (setmetatable {} Box2dEntity))
(set Box2dPolygon.__index Box2dPolygon)

(λ Box2dPolygon.init [self ?id]
  (assert self.points "Must pass points")
  (set self.id (or ?id self.id))
  (self:create-body)
  (set self.shape (love.physics.newPolygonShape (unpack self.points)))
  (self:init-properties))

(set Box2dPolygon.__defaults
     (lume.merge Box2dEntity.__defaults
                 {:z-index 10
                  :pos (vec 32 32)
                  :shape-type :polygon
                  :radius 6
                  :body-type :static}))

{: Box2dEntity
 : Box2dRectangle
 : Box2dCircle
 : Box2dPolygon}
