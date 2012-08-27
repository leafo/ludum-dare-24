
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
        cx, cy = thing\fit_move real_dt * vx, real_dt * vy
        vx = -vx if cx
        vy = -vy if cy

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

  life: 15

  __tostring: => ("<Slime %s, %s>")\format @box\pos!

  new: (...) =>
    super ...
    @sprite = with Spriter imgfy"img/sprite.png", 10, 13
      .ox = 60

    @anim = @sprite\seq {0, 1}, 0.2
    @make_ai!

  make_ai: =>
    @ai = MoveSequence ->
      wait 0.5
      dx, dy = unpack Vec2d.random 10
      move self, dx, dy, 1.0
      wait 0.5
      again!

  draw: =>
    @hit\before! if @hit
    @anim\draw @box.x + @ox, @box.y + @oy
    @hit\after! if @hit

  update: (dt) =>
    @ai\update dt if @box\touches_box @world.game.viewport
    @anim\update dt

    if @hit
      @hit = nil unless @hit\update dt

    super dt
    @life > 0 or @hit

  hurt_player: (player) => player\take_hit self

  take_hit: (weapon) =>
    return if @hit or @life < 0

    damage = weapon\calc_damage self

    x,y = @box\center!
    @world.high_particles\add NumberParticle damage, x,y
    @world.particles\add BloodEmitter @world, x,y

    @life -= damage

    if @life < 0
      print "DEAD"
      @hit = join_effect Flash!, Fade!
    else
      @hit = Flash!

    px, py = weapon.player.box\center!

    @velocity = Vec2d(x - px, y - py) * 5

    @ai = Sequence ->
      tween @velocity, 0.3, [1]: 0, [2]: 0
      @make_ai!


