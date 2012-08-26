
g = love.graphics
import timer, keyboard, audio from love

-- attacks as sequences

export ^

-- a factor for attacks
class Spear
  watch_class self

  ox: 0, oy: 0

  offsets: {
    left:   {-5, -3}
    right:  {2, -3}
    up:     {0, -10}
    down:   {3, -1}
  }

  new: (@player) =>
    @sprite = with Spriter "img/sprite.png"
      @anim = StateAnim "down", {
        left:   \seq {"40,5,11,5"}, 0, true
        up:     \seq {"43,13,5,11"}

        right:  \seq {"40,5,11,5"}
        down:   \seq {"43,13,5,11"}, 0, true, true
      }

  -- draw on player
  draw: =>
    direction = @player.last_direction
    return unless direction
    @anim\set_state direction

    ox, oy = unpack @offsets[direction]
    @anim\draw @player.box.x + @ox + ox, @player.box.y + @oy + oy

  update: (dt) =>
    if @attack
      alive = @attack\update dt
      @attack = nil unless alive

  try_attack: =>
    return if @attack
    direction = @player.last_direction
    @attack = Sequence ->
      tween self, 0.05, switch direction
        when "right"
          ox: 4
        when "left"
          ox: -4
        when "down"
          oy: 4
        when "up"
          oy: -4

      wait 0.05
      tween self, 0.1, ox: 0, oy: 0

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

    speed = 20
    @velocity = Vec2d switch @direction
      when "left"
        -speed, 0
      when "right"
        speed, 0
      when "up"
        0, -speed
      when "down"
        0, speed

  draw: =>
    @animation\draw @box.x, @box.y
    -- @box\outline!

  update: (dt) =>
    @box\move unpack @velocity * dt
    @animation\update dt
    @life -= dt
    @life >= 0


