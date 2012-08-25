
export ^

g = love.graphics

class FakeSpriter
  new: (@cell_w, @cell_h)=>
  draw_cell: (tid, x, y) =>
    g.setColor if tid == 1
      0,0,0
    else
      hsl_to_rgb tid * 47, 30, 40

    g.rectangle "fill", x,y, @cell_w, @cell_h
    g.setColor 255,255,255

class TileSetSpriter
  new: (@img, @cell_w, @cell_h=cell_w, ox=0, oy=0) ->
    @img = imgfy @img

    @half_w = @cell_w / 2
    @half_h = @cell_h / 2

    @spriter = with Spriter @img, @half_w, @half_h, 3 * 2
      .ox = ox
      .oy = oy

  -- each tile needs to be encoded with it's 8 way thing
  -- true if that edge is the same sprite
  calc_corners: (t, tr, r, br, b, bl, l, tl) =>
    corners = { 26 , 27, 32, 33 }

    if not t
      corners[1] = 14
      corners[2] = 15

    if not b
      corners[3] = 44
      corners[4] = 45

    if not l
      corners[1] = 24
      corners[3] = 30

    if not r
      corners[2] = 29
      corners[4] = 35

    if not t and not l
      corners[1] = 12

    if not t and not r
      corners[2] = 17

    if not b and not l
      corners[3] = 42

    if not b and not r
      corners[4] = 47

    if t and l and not tl
      corners[1] = 0

    if t and r and not tr
      corners[2] = 1

    if b and l and not bl
      corners[3] = 6

    if b and r and not br
      corners[4] = 7

    corners

  draw_cell: (x,y, corners) =>
    with @spriter
      \draw_cell corners[1], x, y
      \draw_cell corners[2], x + @half_w, y
      \draw_cell corners[3], x, y + @half_h
      \draw_cell corners[4], x + @half_w, y + @half_h

class QuadTile extends Box
  new: (@tileset, @corners, ...) =>
    super ...

  draw: (_, map) =>
    @tileset\draw_cell @x, @y, @corners

class Autotile
  types: {
    floor: 1
    wall: 2
  }

  get_surrounding: (i) =>
    import wrap, yield from coroutine

    x, y = @map\to_xy i
    wrap ->
      with @map
        yield \to_i x,     y - 1
        yield \to_i x + 1, y - 1
        yield \to_i x + 1, y
        yield \to_i x + 1, y + 1
        yield \to_i x    , y + 1
        yield \to_i x - 1, y + 1
        yield \to_i x - 1, y
        yield \to_i x - 1, y - 1
      nil


  autotile: (layer=1) =>
    tiles = @map.layers[layer]
    changes = {}

    for i, tile in pairs tiles
      tileset = @tilesets[tile.tid]
      if tileset
        touching = for k in @get_surrounding i
          other_tile = tiles[k]
          if other_tile and other_tile.tid == tile.tid
            true
          else
            false


        corners = tileset\calc_corners unpack touching
        changes[i] = QuadTile tileset, corners, tile\unpack!

    tiles[i] = t for i, t in pairs changes


  add_walls: (layer=1) =>
    tiles = @map.layers[layer]
    to_add = {}
    for i, tile in pairs tiles
      x, y = @map\to_xy i
      wi = @map\to_i x, y - 1

      if wi and not tiles[wi]
        to_add[wi] = Tile @types.wall, @map\pos_for_xy x, y - 1

    tiles[i] = t for i, t in pairs to_add

  new: (fname, @tilesets={}) =>
    sprite = FakeSpriter 16, 16
    @map = TileMap.from_image fname, sprite, {
      ["59,57,77"]: { tid: @types.floor }
    }
    
    @add_walls!
    @autotile!

  draw: =>
    @map\draw!
