
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

  is_connected: (tile, other_tile) =>
    other_tile and tile.tid == other_tile.tid or false

  -- each tile needs to be encoded with it's 8 way thing
  -- true if that edge is the same sprite
  calc_corners: (t, tr, r, br, b, bl, l, tl) =>
    corners = { 26 , 27, 32, 33 }

    if not t
      corners[1] = 14
      corners[2] = 15

      if b and l and r
        corners[3] = 20
        corners[4] = 21

    if not b
      corners[3] = 44
      corners[4] = 45

      if t and l and r
        corners[1] = 38
        corners[2] = 39

    if not l
      corners[1] = 24
      corners[3] = 30

      if r and t and b
        corners[2] = 25
        corners[4] = 31


    if not r
      corners[2] = 29
      corners[4] = 35

      if l and t and b
        corners[1] = 28
        corners[3] = 34


    -- 90 corners
    if not t and not l
      corners[1] = 12

      if b and r
        corners[4] = 19


    if not t and not r
      corners[2] = 17

      if b and l
        corners[3] = 22


    if not b and not l
      corners[3] = 42

      if t and r
        corners[2] = 37


    if not b and not r
      corners[4] = 47

      if t and l
        corners[1] = 40

    -- 240 corners
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

class BorderTileSpriter extends TileSetSpriter
  is_connected: (tile, other_tile) =>
    other_tile == nil or tile.tid == other_tile.tid

class QuadTile extends Box
  new: (@tileset, @corners, ...) =>
    super ...

  draw: (_, map) =>
    @tileset\draw_cell @x, @y, @corners

class Autotile
  types: {
    floor: 1
    wall: 2
    border: 3
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
          tileset\is_connected tile, other_tile

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

  add_surrounding: (layer=1) =>
    tiles = @map.layers[layer]
    to_add = {}
    for i, tile in pairs tiles
      for k in @get_surrounding i
        if not tiles[k] and not to_add[k]
          to_add[k] = Tile @types.border, @map\pos_for_i k

    tiles[i] = t for i, t in pairs to_add

  make_solid: (from_layer=1) =>
    solid_layer = {}
    is_solid = Set { @types.wall, @types.border }

    for i, tile in pairs @map.layers[from_layer]
      if tile and is_solid[tile.tid]
        solid_layer[i] = Box @map\pos_for_i i

    @map.layers[@map.solid_layer] = solid_layer

  -- bring the border up a layer
  lift_border: (layer=1, to_layer=2) =>
    to_move = {}
    tileset = @tilesets[@types.border]

    for i, tile in pairs @map.layers[layer]
      if tile.tileset == tileset
        to_move[i] = tile

    for i, tile in pairs to_move
      @map.layers[layer][i] = nil
      @map.layers[to_layer][i] = tile

  new: (fname, @tilesets={}, color_to_tile) =>
    sprite = FakeSpriter 16, 16
    @map = TileMap.from_image fname, sprite, color_to_tile

    @add_walls!
    @add_surrounding!
    @make_solid!

    @autotile!

    @lift_border!

  draw_below: (...) => @map\draw_layer 1, ...
  draw_above: (...) => @map\draw_layer 2, ...

  collides: (thing) =>
    @map\collides thing

