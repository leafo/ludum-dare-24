
import graphics from love

export  ^

class MoveSequence extends Sequence
  @extend {
    move: (thing, x,y, time) ->
      vx = x/time
      vy = y/time

      while time > 0
        dt = coroutine.yield!
        time -= dt

        real_dt = if time < 0 then dt + time else dt
        thing\fit_move real_dt * vx, real_dt * vy

      if time < 0
        coroutine.yield "more", -time
  }

class Enemy extends Entity
  watch_class self

  w: 6
  h: 5

  ox: -3
  oy: -6

  alive: true

  life: 100

  __tostring: => ("<Slime %s, %s>")\format @box\pos!

  new: (...) =>
    super ...
    @sprite = with Spriter imgfy"img/sprite.png", 10, 13
      .ox = 60

    @anim = @sprite\seq {0, 1}, 0.2

    @ai = MoveSequence ->
      wait 1.0
      dx, dy = unpack Vec2d.random 10
      print dx, dy
      move self, dx, dy, 1.0
      again!

  draw: =>
    @hit\before! if @hit
    @anim\draw @box.x + @ox, @box.y + @oy
    @hit\after! if @hit

  update: (dt) =>
    @ai\update dt
    @anim\update dt

    if @hit
      @hit = nil unless @hit\update dt

    super dt
    true

  hurt_player: (player) => player\take_hit self

  take_hit: (weapon) =>
    return if @hit
    @hit = Flash!
    damage = weapon\calc_damage self

    x,y = @box\center!
    @world.high_particles\add NumberParticle damage, x,y
    @world.particles\add BloodEmitter @world, x,y


