
import graphics from love
export  ^

class Flash extends Sequence
  new: (duration=0.2, color={255,100,100}) =>
    half = duration/2
    super ->
      r,g,b = graphics.getColor!
      @color = {:r, :g, :b}
      tween @color, half, r: color[1], g: color[2], b: color[3]
      tween @color, half, :r, :g, :b

  before: =>
    @tmp_color = {graphics.getColor!}
    graphics.setColor @color.r, @color.g, @color.b if @color

  after: =>
    graphics.setColor @tmp_color

class Emitter extends Sequence
  y: 0 -- so it can be sorted *_*
  alive: true

  new: (@world, x, y, duration=0.2, count=5, @make_particle) =>
    dt = duration / count
    super ->
      while count > 0
        count -= 1
        @world.particles\add @make_particle x,y
        wait dt

  draw: =>

class BloodEmitter extends Emitter
  make_particle: (x,y) => BloodParticle x,y

class Particle
  life: 1.0

  r: 255
  g: 255
  b: 255
  a: 1

  new: (@x, @y) =>
    @velocity = Vec2d 0,0
    @accel = Vec2d 0,0

  update: (dt) =>
    @life -= dt
    @velocity\adjust unpack @accel * dt
    @x += @velocity.x * dt
    @y += @velocity.y * dt
    @life > 0

  draw: =>

class PixelParticle extends Particle
  size: 2
  draw: =>
    half = @size/2
    with graphics
      r,g,b,a = .getColor!
      .setColor @r, @g, @b, @a * 255
      .rectangle "fill", @x - half, @y - half, @size, @size
      .setColor r,g,b,a

class NumberParticle extends Particle
  life: 0.8
  ox: 0
  oy: 0

  spead: 20

  alive: true

  new: (number, @x, @y) =>
    @y -= 10
    @number = tostring number
    @velocity = Vec2d.from_angle(math.random(270-@spead/2, 270+@spead/2)) * 100
    @accel = Vec2d 0, 200

    @s = 0.5
    @drot = math.random() + 0.5
    @rot = 0
    @a = 1

  update: (dt) =>
    t = 1 - @life / @@life
    @rot += dt * @drot

    if t < 0.2
      @s += dt * 5
    elseif t > 0.8
      @s -= dt
    
    if t > 0.5
      @a = 1 - (t - 0.5) / 0.5

    super dt

  draw: =>
    with graphics
      .setFont fonts.damage
      r,g,b,a = .getColor!

      .setColor @r, @g, @b, @a * 255

      .push!
      .translate @x, @y
      .print @number, 0,0, @rot, @s, @s, 4, 4
      .pop!

      .setColor r,g,b,a
      .setFont fonts.main
    
class BloodParticle extends PixelParticle
  spead: 40
  life: 0.4
  r: 150, g: 50, b: 50

  new: (@x, @y) =>
    @velocity = Vec2d.from_angle(math.random(270-@spead/2, 270+@spead/2)) * math.random(20,60)
    @accel = Vec2d 0, 200

