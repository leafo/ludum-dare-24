
g = love.graphics
import timer, keyboard, audio from love

export ^

-- a factor for attacks
class Spear
  offsets: {
    left:   {0,0}
    right:  {0,0}
    up:     {0,0}
    down:   {0,0}
  }

  new: =>
    @sprite = Spriter "img/sprite.png"
    with @sprite
      @states = {
        left:   \seq {"40,5,11,5"}, 0, true
        up:     \seq {"43,13,5,11"}

        right:  \seq {"40,5,11,5"}
        down:   \seq {"43,13,5,11"}, 0, true
      }
    print "made spear"

  attack: (player) =>
    Attack player, self, @states

class Attack
  w: 10
  h: 3
  life: 0.2

  new: (@player, weapon, states) =>
    @alive = true

    @direction = @player.last_direction
    @animation = StateAnim @direction, states

    ox, oy = unpack weapon.offsets[@direction]
    @box = Box @player.box.x + ox, @player.box.y + oy, @w, @h

    speed = 10
    @velocity = Vec2d switch @direction
      when "left"
        -speed, 0
      when "right"
        speed, 0
      when "up"
        0, -speed
      when "down"
        0, speed

    print @velocity

  draw: =>
    @animation\draw @box.x, @box.y
    -- @box\outline!

  update: (dt) =>
    -- @box\move @velocity * dt
    @animation\update dt
    @life -= dt
    @life >= 0


