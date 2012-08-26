
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


class MoveSequence extends Sequence
  @extend {
    move: (x,y, time) ->
      print "cool!"
  }


class Enemy extends Entity
  watch_class self

  w: 7
  h: 7

  ox: -2
  oy: -5

  alive: true

  __tostring: => ("<Slime %s, %s>")\format @box\pos!

  new: (...) =>
    super ...
    @sprite = with Spriter imgfy"img/sprite.png", 10, 13
      .ox = 60

    @anim = @sprite\seq {0, 1}, 0.2

    @ai = MoveSequence ->
      wait 1.0
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

    true

  take_hit: (weapon) =>
    print "trying hit", @hit
    return if @hit
    print "taking hit!"
    @hit = Flash!

