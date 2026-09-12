-- the lovekit Entity this game was written against, lovekit master's Entity
-- is now a Box itself with a `vel` field
import floor, ceil from math

export ^

class Entity
  w: 20
  h: 20

  loc: => Vec2d @box.x, @box.y
  center: => @box\center!

  new: (@world, x, y) =>
    @box = Box x, y, @w, @h
    @velocity = Vec2d 0, 0

  draw: =>
    @box\draw!

  update: (dt) =>
    @fit_move unpack @velocity * dt

  -- printing every frame is slow on the handheld, say it once
  on_stuck: =>
    return if @stuck_reported
    @stuck_reported = true
    print "on_stuck: " .. @@__name

  direction_name: (default_dir="down", v=@velocity) =>
    base = if v\is_zero! then
      "stand"
    else
      @last_direction = v\direction_name!
      "walk"

    dir = @last_direction or default_dir
    base .. "_" .. dir

  -- move by dx, dy stopping at world collisions, returns collided_x, collided_y
  fit_move: (dx, dy) =>
    collided_x = false
    collided_y = false

    -- if you are collided before you move then the world changed, PANIC
    if @world\collides self
      return @on_stuck!

    if dx > 0
      @box.x += dx
      if @world\collides self
        collided_x = true
        @box.x = floor @box.x
        while @world\collides self
          @box.x -= 1
    elseif dx < 0
      @box.x += dx
      if @world\collides self
        collided_x = true
        @box.x = ceil @box.x
        while @world\collides self
          @box.x += 1

    if dy > 0
      @box.y += dy
      if @world\collides self
        collided_y = true
        @box.y = floor @box.y
        while @world\collides self
          @box.y -= 1
    elseif dy < 0
      @box.y += dy
      if @world\collides self
        collided_y = true
        @box.y = ceil @box.y
        while @world\collides self
          @box.y += 1

    collided_x, collided_y
