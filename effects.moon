
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

