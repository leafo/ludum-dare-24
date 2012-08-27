
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

        thing\set_direction Vec2d vx, vy if thing.set_direction

        real_dt = if time < 0 then dt + time else dt
        cx, cy = thing\fit_move real_dt * vx, real_dt * vy
        vx = -vx if cx
        vy = -vy if cy

      thing\set_direction! if thing.set_direction
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

    charge: (thing, dir, speed=200, decay=0.5) ->
      thing.velocity = dir\normalized! * speed
      Sequence.default_scope.tween thing.velocity, decay, [1]: 0, [2]: 0
      thing\set_direction dir
  }

class Enemy extends Entity
  watch_class self

  blood_color: {}

  w: 6
  h: 5

  ox: 0, oy: 0

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
    @world.particles\add with BloodEmitter @world, x,y
      .blood_color = @blood_color

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

-- wanders around
class GreenSlime extends Enemy
  ox: -3, oy: -6

  life: 15
  blood_color: {267,244,129}

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


class Bullet extends Entity
  watch_class self
  ox: -3, oy: -3
  size: 2

  @id =  0

  __tostring: => "<Bullet " .. tostring(@@id) .. ">"

  new: (@world, x, y, @anim, @velocity) =>
    @@id += 1
    @box = Box x,y, @size, @size

  update: (dt) =>
    @anim\update dt
    colx, coly = super dt
    not @hit and not colx and not coly

  draw: =>
    blend = graphics.getBlendMode!
    graphics.setBlendMode "multiplicative"
    @anim\draw @box.x + @ox, @box.y + @oy
    graphics.setBlendMode blend

  hurt_player: (player) =>
    @hit = true
    player\take_hit self


class BounceBullet extends Bullet
  time: 1.3

  update: (dt) =>
    @time -= dt

    @anim\update dt
    colx, coly = Entity.update self, dt

    @velocity[1] = -@velocity[1] if colx
    @velocity[2] = -@velocity[2] if coly

    not @hit and @time > 0

  draw: =>
    -- fade out
    if @time < 0.3
      r,g,b,a = graphics.getColor!
      graphics.setColor r,g,b, 255 * @time / 0.3
      super!
      graphics.setColor r,g,b,a
    else
      super!

-- charges
class BlueSlime extends Enemy
  ox: -3, oy: -6
  life: 21

  blood_color: {65,141,255}

  new: (...) =>
    super ...
    @sprite = with Spriter "img/sprite.png", 10, 13
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

class RedSlime extends Enemy
  ox: -3, oy: -6
  bullet_cls: Bullet
  life: 31

  blood_color: {255,200,200}

  new: (...) =>
    super ...
    @sprite = with Spriter imgfy"img/sprite.png", 10, 13
      .ox = 100

    @anim = @sprite\seq {0, 1}, 0.2
    @bullet_sprite = Spriter "img/sprite.png"

  shoot: (vec) =>
    anim = @bullet_sprite\seq { "101,28,8,9", "111,29,8,9" }, 0.1
    x,y = @box\center!
    vel = vec\normalized! * 50

    @world.entities\add self.bullet_cls @world, x,y, anim, vel

  spray: (vec) =>
    for deg=0,360,30
      @shoot Vec2d.from_angle deg

  make_ai: =>
    @ai = MoveSequence ->
      wait 0.5
      player = @world.game.player
      vec = @box\vector_to player.box
      len = vec\len!

      if math.random() < 0.5 and len < 65
        if len < 40
          shake self, 1.5, 2, 1
          @spray!
          wait 0.5
        else
          @shoot vec
      else
        dx, dy = unpack Vec2d.random 10
        move self, dx, dy, 1.0

      wait 0.5
      again!

class BadRedSlime extends RedSlime
  bullet_cls: BounceBullet


class MadDog extends Enemy
  life: 25

  new: (...) =>
    super ...

    with Spriter"img/sprite.png"
      stand_left_right = { "60,65,17,12", "60,78,17,12" }
      stand_up_down = { "82,52,5,13", "82,65,5,13" }

      left_right = {  "60,65,17,12", "60,52,17,12" }
      up_down = { "82,52,5,13", "93,52,5,13" }

      @anim = StateAnim "stand_left", {
        stand_down:   \seq stand_up_down, 0.25, true, true
        stand_up:     \seq stand_up_down, 0.25

        stand_right:  \seq stand_left_right, 0.25, true
        stand_left:   \seq stand_left_right, 0.25

        walk_down:    \seq up_down, 0.25, false, true
        walk_up:      \seq up_down, 0.25

        walk_right:   \seq left_right, 0.25, true
        walk_left:    \seq left_right, 0.25
      }

  set_direction: (other_vel) =>
    v = @velocity
    v += other_vel if other_vel
    @anim\set_state @direction_name "left", v

    if @last_direction == "left" or @last_direction == "right"
      @ox, @oy = -5, -2
    else
      @ox, @oy = 0, -3

  update: (dt) =>
    super dt

  make_ai: =>
    @ai = MoveSequence ->
      wait 0.5
      player = @world.game.player
      vec = @box\vector_to player.box

      if math.random() < 0.3
        shake self, 0.3, 2, 1
        wait 1.0
      elseif vec\len! < 60
        shake self, 1.0, 1, 1
        charge self, vec, 150, 0.3
        wait 0.1
        charge self, @box\vector_to(player.box), 150, 0.3
      else
        dx, dy = unpack Vec2d.random 25
        move self, dx, dy, 0.6

      again!



