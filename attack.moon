
g = love.graphics
import timer, keyboard, audio from love

export ^

class Spear
  watch_class self

  ox: 0, oy: 0

  w: 6
  h: 5

  box_offsets: {
    left:   {-5, -3}
    right:  {8, -3}
    up:     {0, -10}
    down:   {3, 5}
  }

  sprite_offsets: {
    left:   {-1,0}
    right:  {-5,0}
    up:     {0,0}
    down:   {0,-6}
  }

  new: (@player) =>
    @counter = 0
    @box = Box @player.box.x, @player.box.y, @w, @h

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

    ox, oy = unpack @sprite_offsets[direction]
    @anim\draw @box.x + ox, @box.y + oy
    -- @box\outline! if @is_attacking

  update: (dt) =>
    direction = @player.last_direction
    if direction
      ox, oy = unpack @box_offsets[direction]
      @box\set_pos @player.box.x + @ox + ox, @player.box.y + @oy + oy

    if @attack
      alive = @attack\update dt
      @attack = nil unless alive

  try_attack: =>
    return if @attack
    direction = @player.last_direction
    @counter += 1
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

      @is_attacking = true
      wait 0.05
      @is_attacking = false
      tween self, 0.1, ox: 0, oy: 0

  calc_damage: (entity) =>
    math.random 8,10

