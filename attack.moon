
g = love.graphics
import timer, keyboard, audio from love

export ^

class Spear
  watch_class self

  ox: 0, oy: 0

  w: 9
  h: 9

  box_offsets: {
    left:   {-8, -5}
    right:  {8, -5}
    up:     {-1, -13}
    down:   {2, 5
  }

  sprite_offsets: {
    left:   {-7,-3}
    right:  {3,-3}
    up:     {0,-12}
    down:   {3,0}
  }

  new: (@player) =>
    @counter = 0
    @box = Box @player.box.x, @player.box.y, @w, @h

    @sprite = with Spriter "img/sprite.png"
      @anim = StateAnim "down", {
        left:   \seq {"39,5,12,5"}, 0, true
        up:     \seq {"43,13,5,12"}

        right:  \seq {"39,5,12,5"}
        down:   \seq {"43,13,5,12"}, 0, true, true
      }

  -- draw on player
  draw: =>
    direction = @player.last_direction
    return unless direction
    @anim\set_state direction

    ox, oy = unpack @sprite_offsets[direction]
    @anim\draw @player.box.x + ox + @ox, @player.box.y + oy + @oy
    -- @box\outline! -- if @is_attacking

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
    sfx\play "player_strike"
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

