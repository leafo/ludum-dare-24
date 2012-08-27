
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

      coroutine.yield "more", -time if time < 0

    shake: (thing, total_time, mx=5, my=5, speed=10, decay_to=0) ->
      ox, oy = thing.ox, thing.oy

      time = total_time
      while time > 0
        time -= coroutine.yield!
        decay = math.min(math.max(time, decay_to), 1)

        dx = decay * mx * math.sin(time*10*speed)
        dy = decay * my * math.cos(time*10*speed)

        thing.ox = ox + dx
        thing.oy = oy + dy

      thing.ox, thing.oy = ox, oy
      coroutine.yield "more", -time if time < 0

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
    @make_ai!

  make_ai: => error "implement me"

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
      @hit = join_effect Flash!, Fade!
    else
      @hit = Flash!

    px, py = weapon.player.box\center!

    @velocity = Vec2d(x - px, y - py) * 5

    @ai = Sequence ->
      tween @velocity, 0.3, [1]: 0, [2]: 0
      @make_ai!


module "enemies", package.seeall

class GreenSlime extends Enemy
  new: (...) =>
    super ...
    @sprite = with Spriter imgfy"img/sprite.png", 10, 13
      .ox = 60
    @anim = @sprite\seq {0, 1}, 0.2

  make_ai: =>
    @ai = MoveSequence ->
      wait 0.5
      dx, dy = unpack Vec2d.random 10
      move self, dx, dy, 1.0
      wait 0.5
      again!


class BlueSlime extends Enemy
  new: (...) =>
    super ...
    @sprite = with Spriter imgfy"img/sprite.png", 10, 13
      .ox = 80

    @anim = @sprite\seq {0, 1}, 0.2

  make_ai: =>
    @ai = MoveSequence ->
      wait 0.5
      player = @world.game.player
      vec = @box\vector_to player.box

      if vec\len! < 55
        shake self, 0.8, 2, 1
        @velocity = vec\normalized! * 200
        tween @velocity, 0.5, [1]: 0, [2]: 0
      else
        dx, dy = unpack Vec2d.random 10
        move self, dx, dy, 1.0
        wait 0.5

      again!


