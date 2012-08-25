
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

    corners

  draw_cell: (x,y, ...) =>
    corners = @calc_corners ...
    with @spriter
      \draw_cell corners[1], x, y
      \draw_cell corners[2], x + @half_w, y
      \draw_cell corners[3], x, y + @half_h
      \draw_cell corners[4], x + @half_w, y + @half_h

class Autotile
  types: {
    floor: 1
    wall: 2
  }


  -- clockwise from top, 8 directions
  -- nil: don't care, true: is same, false: is not same
  filters: {
    -- top right bottom left

    [1]: {
      { false, nil, true,  nil, true,  nil, true,  nil, => 3 } -- top
      { true,  nil, false, nil, true,  nil, true,  nil, => 4 } -- right
      { true,  nil, true,  nil, false, nil, true,  nil, => 5 } -- bottom
      { true,  nil, true,  nil, true,  nil, false, nil, => 6 } -- left

      -- the parallel
      { false, nil, true, nil, false, nil, true, nil, => 7 } -- top & bottom
      { true, nil, false, nil, true, nil, false, nil, => 8 } -- left & right

      -- the 90 deg corners
      { false, nil, false, nil, true, nil, true, nil, => 9 } -- bottom & left
      { true, nil, false, nil, false, nil, true, nil, => 10 } -- top & left
      { true, nil, true, nil, false, nil, false, nil, => 11 } -- top & right
      { false, nil, true, nil, true, nil, false, nil, => 12 } -- bottom & right
    }
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

  match_filter: (layer, filter, tid, i) =>
    p = 1
    for si in @get_surrounding i
      target = si and layer[si]

      switch filter[p]
        when true -- tiles are the same
          return false unless target and target.tid == tid
        when false -- tiles are different
          return false unless not target or target.tid != tid

      p += 1

    true

  apply_filters: (layer=1) =>
    tiles = @map.layers[layer]

    to_change = {}
    for i, tile in pairs tiles
      tid = tile.tid
      filters = @filters[tid]
      if filters
        for filter in *filters
          if @match_filter tiles, filter, tid, i
            to_change[i] = filter[9]!
            break

    tiles[i].tid = tid for i, tid in pairs to_change

  add_walls: (layer=1) =>
    tiles = @map.layers[layer]
    to_add = {}
    for i, tile in pairs tiles
      x, y = @map\to_xy i
      wi = @map\to_i x, y - 1

      if wi and not tiles[wi]
        to_add[wi] = Tile @types.wall, @map\pos_for_xy x, y - 1

    tiles[i] = t for i, t in pairs to_add

  new: (fname) =>
    sprite = FakeSpriter 12, 12
    @map = TileMap.from_image fname, sprite, {
      ["59,57,77"]: { tid: @types.floor }
    }
    
    @add_walls!
    @apply_filters!

  draw: =>
    @map\draw!
