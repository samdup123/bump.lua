local collision = require('bump').collision

local function rect(l,t,w,h)
  return {l=l,t=t,w=w,h=h}
end

local touch = function(itemRect, otherRect, future_l, future_t)
  future_l = future_l or itemRect.l
  future_t = future_t or itemRect.t
  local col = collision.touch(itemRect, otherRect, future_l, future_t)
  return {col.touch.l, col.touch.t, col.normal.x, col.normal.y}
end

local slide = function(itemRect, otherRect, future_l, future_t)
  future_l = future_l or itemRect.l
  future_t = future_t or itemRect.t
  return collision.slide(itemRect, otherRect, future_l, future_t)
end

local bounce = function(itemRect, otherRect, future_l, future_t)
  future_l = future_l or itemRect.l
  future_t = future_t or itemRect.t
  return collision.bounce(itemRect, otherRect, future_l, future_t)
end



describe('collision.base', function()
  describe('when item is static', function()
    describe('when itemRect does not intersect otherRect', function()
      it('returns nil', function()
        local c = collision.base(rect(0,0,1,1), rect(5,5,1,1), 0,0)
        assert.is_nil(c)
      end)
    end)
    describe('when itemRect overlaps otherRect', function()
      it('returns overlaps, normal, d, ti, diff, itemRect, otherRect', function()
        local c = collision.base(rect(0,0,7,6), rect(5,5,1,1), 0, 0)

        assert.is_true(c.overlaps)
        assert.equals(c.ti, -2)
        assert.same(c.d,{x = 0, y = -5})
        assert.same(c.itemRect, {l=0,t=0,w=7,h=6})
        assert.same(c.otherRect, {l=5,t=5,w=1,h=1})
        assert.same(c.diff, {l=-2,t=-1,w=8,h=7})
        assert.same(c.normal, {x=0, y=0})

      end)
    end)
  end)

  describe('when item is moving', function()
    describe('when itemRect does not intersect otherRect', function()
      it('returns nil', function()
        local c = collision.base(rect(0,0,1,1), rect(5,5,1,1), 0,1)
        assert.is_nil(c)
      end)
    end)
    describe('when itemRect intersects otherRect', function()
      it('detects collisions from the left', function()
        local c = collision.base(rect(1,1,1,1), rect(5,0,1,1), 6,0)
        assert.equal(c.ti, 0.6)
        assert.same(c.normal, {x=-1, y=0})
      end)
      it('detects collisions from the right', function()
        local c = collision.base(rect(6,0,1,1), rect(1,0,1,1), 1,1)
        assert.is_false(c.overlaps)
        assert.equal(c.ti, 0.8)
        assert.same(c.normal, {x=1, y=0})
      end)
      it('detects collisions from the top', function()
        local c = collision.base(rect(0,0,1,1), rect(0,4,1,1), 0,5)
        assert.is_false(c.overlaps)
        assert.equal(c.ti, 0.6)
        assert.same(c.normal, {x=0, y=-1})
      end)
      it('detects collisions from the bottom', function()
        local c = collision.base(rect(0,4,1,1), rect(0,0,1,1), 0,-1)
        assert.is_false(c.overlaps)
        assert.equal(c.ti, 0.6)
        assert.same(c.normal, {x=0, y=1})
      end)
    end)
  end)
end)

describe('collision.touch', function()
  local other = rect(0,0,8,8)

  describe('on overlaps', function()
    describe('when there is no movement', function()
      it('#focus returns the left,top coordinates of the minimum displacement on static items', function()

        --       -1     3     7
        --     -1 +---+ +---+ +---+
        --        | +-+-+---+-+-+ |    1     2     3
        --        +-+-+ +---+ +-+-+
        --          |           |
        --      3 +-+-+ +---+ +-+-+
        --        | | | |   | | | |    4     5     6
        --        +-+-+ +---+ +-+-+
        --          |           |
        --      7 +-+-+ +---+ +-+-+
        --        | +-+-+---+-+-+ |    7     8     9
        --        +-+-+ +---+ +-+-+

        assert.same(touch(rect(-1,-1,2,2), other), {-1,-2, 0, -1}) -- 1
        assert.same(touch(rect( 3,-1,2,2), other), { 3,-2, 0, -1}) -- 2
        assert.same(touch(rect( 7,-1,2,2), other), { 7,-2, 0, -1}) -- 3

        assert.same(touch(rect(-1, 3,2,2), other), {-2, 3, -1, 0}) -- 4
        assert.same(touch(rect( 3, 3,2,2), other), { 3, 8,  0, 1}) -- 5
        assert.same(touch(rect( 7, 3,2,2), other), { 8, 3,  1, 0}) -- 6

        assert.same(touch(rect(-1, 7,2,2), other), {-1, 8,  0, 1}) -- 1
        assert.same(touch(rect( 3, 7,2,2), other), { 3, 8,  0, 1}) -- 2
        assert.same(touch(rect( 7, 7,2,2), other), { 7, 8,  0, 1}) -- 3

      end)
    end)

    describe('when the item is moving', function()
      it('returns the left,top coordinates of the overlaps with the movement line, opposite direction', function()
        assert.same(touch(rect( 3, 3,2,2), other, 4, 3), { -2,  3, -1,  0})
        assert.same(touch(rect( 3, 3,2,2), other, 2, 3), {  8,  3,  1,  0})
        assert.same(touch(rect( 3, 3,2,2), other, 2, 3), {  8,  3,  1,  0})
        assert.same(touch(rect( 3, 3,2,2), other, 3, 4), {  3, -2,  0, -1})
        assert.same(touch(rect( 3, 3,2,2), other, 3, 2), {  3,  8,  0,  1})
      end)
    end)
  end)

  describe('on tunnels', function()
    it('returns the coordinates of the item when it starts touching the other, and the normal', function()
      assert.same(touch(rect( -3,  3,2,2), other, 3,3), { -2,  3, -1,  0})
      assert.same(touch(rect(  9,  3,2,2), other, 3,3), {  8,  3,  1,  0})
      assert.same(touch(rect(  3, -3,2,2), other, 3,3), {  3, -2,  0, -1})
      assert.same(touch(rect(  3,  9,2,2), other, 3,3), {  3,  8,  0,  1})
    end)
  end)
end)

describe(':getSlide', function()
  local other = rect(0,0,8,8)

  describe('when there is no movement', function()
    it('behaves like :getTouch(), plus safe info', function()
      local c = resolve(rect(3,3,2,2), other)
      assert.same({c:getSlide()}, {3,8, 0,1, 3,8})
    end)
  end)
  describe('when there is movement, it slides', function()
    it('slides on overlaps', function()
      assert.same({resolve(rect( 3, 3,2,2), other, 4, 5):getSlide()}, { 0.5, -2, 0,-1, 4, -2})
      assert.same({resolve(rect( 3, 3,2,2), other, 5, 4):getSlide()}, { -2, 0.5, -1,0, -2, 4})
      assert.same({resolve(rect( 3, 3,2,2), other, 2, 1):getSlide()}, { 5.5, 8, 0,1, 2, 8})
      assert.same({resolve(rect( 3, 3,2,2), other, 1, 2):getSlide()}, { 8, 5.5, 1,0, 8, 2})
    end)

    it('slides over tunnels', function()
      assert.same({resolve(rect(10,10,2,2), other, 1, 4):getSlide()}, { 7, 8, 0, 1, 1, 8})
      assert.same({resolve(rect(10,10,2,2), other, 4, 1):getSlide()}, { 8, 7, 1, 0, 8, 1})

      -- perfect corner case:
      assert.same({resolve(rect(10,10,2,2), other, 1, 1):getSlide()}, { 8, 8, 1, 0, 8, 1})
    end)
  end)
end)

describe(':getBounce', function()
  local other = rect(0,0,8,8)

  describe('when there is no movement', function()
    it('behaves like :getTouch(), plus safe info', function()
      local c = resolve(rect(3,3,2,2), other)
      assert.same({c:getBounce()}, {3,8, 0,1, 3,8})
    end)
  end)
  describe('when there is movement, it bounces', function()
    it('bounces on overlaps', function()
      assert.same({resolve(rect( 3, 3,2,2), other, 4, 5):getBounce()}, { 0.5, -2, 0,-1, 4, -9})
      assert.same({resolve(rect( 3, 3,2,2), other, 5, 4):getBounce()}, { -2, 0.5, -1,0, -9, 4})
      assert.same({resolve(rect( 3, 3,2,2), other, 2, 1):getBounce()}, { 5.5, 8, 0,1, 2, 15})
      assert.same({resolve(rect( 3, 3,2,2), other, 1, 2):getBounce()}, { 8, 5.5, 1,0, 15,2})
    end)

    it('bounces over tunnels', function()
      assert.same({resolve(rect(10,10,2,2), other, 1, 4):getBounce()}, { 7, 8, 0, 1, 1, 12})
      assert.same({resolve(rect(10,10,2,2), other, 4, 1):getBounce()}, { 8, 7, 1, 0, 12, 1})

      -- perfect corner case:
      assert.same({resolve(rect(10,10,2,2), other, 1, 1):getBounce()}, { 8, 8, 1, 0, 15, 1})
    end)
  end)
end)

