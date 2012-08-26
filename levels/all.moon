export ^

class World
  new: (@game) =>
    @map = @make_map!
    @particles = DrawList!
    @high_particles = DrawList!
    @entities = DrawList!

  collides: (thing) => @map\collides thing

  draw: =>
    @map\draw_below @game.viewport

    @entities\sort!
    @entities\draw!

    @particles\sort_pts!
    @particles\draw!

    @map\draw_above @game.viewport

    @high_particles\draw!

  update: (dt) =>
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
      if e.hurt_player and e.box\touches_box player.box
        e\hurt_player player


class Level extends World
  floor_color: "59,57,77"

  map_file: "img/map.png"

  tilesets: {
    { TileSetSpriter, "img/tiles.png", 16, 16 } -- floor
    { TileSetSpriter, "img/tiles.png", 16, 16, 48 } -- wall
    { BorderTileSpriter, "img/tiles.png", 16, 16, 48*2 }
  }

  make_map: =>
    tilesets = for row in *@tilesets
      cls = table.remove row, 1
      cls unpack row

    Autotile @map_file, tilesets


