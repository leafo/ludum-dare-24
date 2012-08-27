export ^

class World
  new: (@game) =>
    @decorations = DrawList!
    @entities = with DrawList!
      .show_boxes = false

    @map = @make_map!

    @particles = DrawList!
    @high_particles = DrawList!

  collides: (thing) => @map\collides thing

  draw: =>
    @map\draw_below @game.viewport
    @decorations\draw!

    @entities\draw_sorted!
    @particles\draw_sorted!

    @map\draw_above @game.viewport

    @high_particles\draw!

  update: (dt) =>
    @decorations\update dt
    @entities\update dt
    @particles\update dt
    @high_particles\update dt

    player = @game.player

    -- see if player is hitting anything
    if player.weapon.is_attacking
      for e in *@entities do
        if e != player and e.take_hit and e.box\touches_box player.weapon.box
          e\take_hit player.weapon

    -- see if player is being hit by anything
    for e in *@entities do
      if e.alive and e.hurt_player and e.box\touches_box player.box
        e\hurt_player player if not e.life or e.life > 0

class Decoration extends Box
  w: 16, h: 16
  ox: 0, oy: 0

  new: (@x, @y, @cell_id) =>
    @x += @ox
    @y += @oy

    if not Decoration.__base.sprite
      Decoration.__base.sprite = with Spriter "img/tiles.png", @w, @h, 14
        .oy = 64

  update: (dt) => true
  draw: =>
    @sprite\draw_cell @cell_id, @x - @ox, @y - @oy

class UpDoor extends Decoration
  cell_id: 2

class DownDoor extends Decoration
  cell_id: 3

  ox: 2, oy: 5
  w: 13, h: 9

  on_touch: (player) => print "touching exit"


class RandomDecor extends Decoration
  cells: {}
  new: (x,y) =>
    super x,y, @cells[math.random 1, #@cells]

class FloorDecor extends RandomDecor
  cells: { 10 }

class WallDecor extends RandomDecor
  cells: { 9, 8 }

class BloodPit extends Decoration
  new: (x, y) =>
    super x, y
    @anim = @sprite\seq { 11, 12, 13 }, 0.4

  update: (dt) =>
    @anim\update dt
    super

  draw: =>
    @anim\draw @x - @ox, @y - @oy

class Level extends World
  floor_color: "59,57,77"

  map_file: "img/map.png"

  tilesets: {
    { TileSetSpriter, "img/tiles.png", 16, 16 } -- floor
    { TileSetSpriter, "img/tiles.png", 16, 16, 48 } -- wall
    { BorderTileSpriter, "img/tiles.png", 16, 16, 48*2 }
  }

  tile_colors: {
    ["59,57,77"]: => Autotile.types.floor

    ["160,62,97"]: (x,y) =>
      @decorations\add UpDoor x,y
      nil

    ["62,160,69"]: (x,y) =>
      @decorations\add DownDoor x,y
      Autotile.types.floor

    ["160,62,62"]: (x,y) =>
      @decorations\add BloodPit x,y
      Autotile.types.floor

    ["86,100,174"]: (x, y) =>
      @decorations\add WallDecor x,y
      nil

    ["41,40,54"]: (x,y) =>
      @decorations\add FloorDecor x,y
      Autotile.types.floor



    -- bad dudes below
    ["212,201,29"]: (x,y) =>
      @entities\add enemies.GreenSlime self,x,y
      Autotile.types.floor

    ["249,244,156"]: (x,y) =>
      @entities\add enemies.BlueSlime self,x,y
      Autotile.types.floor

    ["179,158,125"]: (x,y) =>
      @entities\add enemies.RedSlime self,x,y
      Autotile.types.floor

    ["219,134,0"]: (x,y) =>
      @entities\add enemies.MadDog self,x,y
      Autotile.types.floor
  }

  make_map: =>
    tilesets = for row in *@tilesets
      cls = table.remove row, 1
      cls unpack row

    -- bind all the functions in tile_colors
    bind = (fn, object) -> (...) -> fn object, ...
    tile_colors = { k, bind v, self for k,v in pairs @tile_colors }

    Autotile @map_file, tilesets, tile_colors

