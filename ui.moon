
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

-- dim the screen and print lines centered in a box, in screen space at the
-- pixel scale so it sits on top of any scene
export draw_overlay
draw_overlay = (lines) ->
  scale = GAME_CONFIG.scale
  g.push!
  g.origin!
  g.scale scale
  w, h = g.getWidth! / scale, g.getHeight! / scale
  COLOR\push 0, 0, 0, 180
  g.rectangle "fill", 0, 0, w, h
  COLOR\pop!

  line_h = 12
  font = g.getFont!
  lines = [line\lower! for line in *lines]
  box_w = math.max unpack [font\getWidth line for line in *lines]
  box_h = #lines * line_h
  y = math.floor h / 2 - box_h / 2

  COLOR\push 0, 0, 0
  g.rectangle "fill", math.floor(w / 2 - box_w / 2) - 6, y - 6, box_w + 12, box_h + 12
  COLOR\pop!

  for line in *lines
    g.printf line, 0, y, w, "center"
    y += line_h

  g.pop!
