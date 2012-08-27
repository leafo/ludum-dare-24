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

    for d in *@decorations do
      if d.hurt_player and d\touches_box player.box
        d\hurt_player player, self

      if d.on_touch and d\touches_box player.box
        d\on_touch player, self


class Decoration extends Box
  w: 16, h: 16
  ox: 0, oy: 0

  new: (@x, @y, @cell_id) =>
    @x += @ox
    @y += @oy

    if not Decoration.__base.sprite
      Decoration.__base.sprite = with Spriter "img/tiles.png", @w, @h, 16
        .oy = 64

  update: (dt) => true
  draw: =>
    @sprite\draw_cell @cell_id, @x - @ox, @y - @oy
    -- @outline!

class UpDoor extends Decoration
  cell_id: 2

class DownDoor extends Decoration
  cell_id: 3

  ox: 2, oy: 5
  w: 13, h: 9

  on_touch: (player, world) =>
    return if @touched
    @touched = true
    world\goto_next_level!

class ExitSwitch extends Decoration
  cell_id: 2
  off: 14, on: 15

  w: 8, h: 5
  ox: 4, oy: 7

  new: (x,y) =>
    super x,y, @off

  on_touch: (player, world) =>
    return if @touched
    sfx\play "hit_switch"
    @touched = true
    @cell_id = @on

    world.exit_door.show = true if world.exit_door


class HiddenDoor extends DownDoor
  show: false

  on_touch: (...) =>
    return unless @show
    super ...

  draw: =>
    super! if @show

class RandomDecor extends Decoration
  cells: {}
  new: (x,y) =>
    super x,y, @cells[math.random 1, #@cells]

class FloorDecor extends RandomDecor
  cells: { 10, 17, 18, 19, 20, 21, 22 }

class FloorDecorBlood extends RandomDecor
  cells: { 7 }

class WallDecor extends RandomDecor
  cells: { 9, 8 }

class WallDecorBlood extends RandomDecor
  cells: { 4,5,6 }

class BloodPit extends Decoration
  w: 10, h: 7
  ox: 3, oy: 4

  new: (x, y) =>
    super x, y
    @anim = @sprite\seq { 11, 12, 13 }, 0.4

  update: (dt) =>
    @anim\update dt
    super

  hurt_player: (player) =>
    player\take_hit box: self

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
      @start_pos = {x + 4 , y + 20} -- hehe
      nil

    ["62,160,69"]: (x,y) =>
      @decorations\add DownDoor x,y
      Autotile.types.floor

    ["59,255,73"]: (x,y) =>
      @exit_door = HiddenDoor x,y
      @decorations\add @exit_door
      Autotile.types.floor

    ["255,59,242"]: (x,y) =>
      @decorations\add ExitSwitch x,y
      Autotile.types.floor

    ["160,62,62"]: (x,y) =>
      @decorations\add BloodPit x,y
      Autotile.types.floor

    ["86,100,174"]: (x, y) =>
      @decorations\add WallDecor x,y
      nil

    ["66,96,255"]: (x, y) =>
      @decorations\add WallDecorBlood x,y
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

    ["255,255,255"]: (x,y) =>
      @entities\add enemies.HugeSlime self,x,y
      Autotile.types.floor
  }

  goto_next_level: =>
    @game.player.locked = true
    next_level = @next_level! @game

    @game.effect = ViewportFade @game.viewport, "out", ->
      @game.player.locked = false
      @game\set_world next_level
      @game.effect = ViewportFade @game.viewport, "in"

  make_map: =>
    tilesets = for row in *@tilesets
      cls = row[1]
      cls unpack [item for i, item in ipairs row when i > 1]

    -- bind all the functions in tile_colors
    bind = (fn, object) -> (...) -> fn object, ...
    tile_colors = { k, bind v, self for k,v in pairs @tile_colors }

    Autotile @map_file, tilesets, tile_colors

module "levels", package.seeall

-- so much for DRY
class Floor1 extends Level
  map_file: "img/floor1.png"
  next_level: -> levels.Floor2

class Floor2 extends Level
  map_file: "img/floor2.png"
  next_level: -> levels.Floor3

class Floor3 extends Level
  map_file: "img/floor3.png"
  next_level: -> levels.Floor4

class Floor4 extends Level
  map_file: "img/floor4.png"
  next_level: -> levels.Floor5

class Floor5 extends Level
  map_file: "img/floor5.png"
  next_level: -> levels.Floor6

class Floor6 extends Level
  map_file: "img/floor6.png"
  next_level: -> levels.Floor7

class Floor7 extends Level
  map_file: "img/floor7.png"
  next_level: -> levels.Floor8

class Floor8 extends Level
  map_file: "img/floor8.png"
  next_level: -> levels.Floor9

class Floor9 extends Level
  map_file: "img/floor9.png"
  next_level: ->
    error "umm"


