
g = love.graphics

export ^

class HorizBar
  color: { 255, 128, 128, 128 }
  border: true
  padding: 1

  new: (@w, @h, @value=0.5)=>

  -- color is stored 0 to 255, love 11 wants 0 to 1
  rgba: =>
    r, gg, b, a = unpack @color
    r/255, gg/255, b/255, (a or 255)/255

  draw: (x, y) =>
    g.push!

    if @border
      g.setLineWidth 0.6
      g.rectangle "line", x, y, @w, @h

      g.setColor @rgba!
      w = @value * (@w - @padding*2)

      g.rectangle "fill", x + @padding, y + @padding, w, @h - @padding*2
    else
      g.setColor @rgba!
      w = @value * @w
      g.rectangle "fill", x, y, w, @h

    g.pop!
    g.setColor 1,1,1,1
