
require "lovekit.all"
reloader = require "lovekit.reloader"

g = love.graphics
import timer, keyboard, audio from love

import concat from table

require "lovekit.screen_snap"
-- snapper = ScreenSnap!

require "autotile"
require "attack"
require "enemy"
require "effects"

p = (str, ...) -> g.print str\lower!, ...

-- prints lines of text over time
class Printer extends Sequence
  rate: 0.1
  line_height: 8

  new: (str) =>
    @line = 1
    @char = 1
    @lines = split str, "\n"

    super ->
      while @line <= #@lines
        wait @rate
        @char += 1
        if @char > #@lines[@line]
          @char = 1
          @line += 1

      -- all done
      @line = #@lines
      @char = #@lines[@line]

  draw: (x, y) =>
    for i=1,@line
      text = @lines[i]
      text = text\sub 1, @char if i == @line

      p text, x, y + i * @line_height

class Player extends Entity
  watch_class self
  w: 8, h: 4
  ox: 1, oy: 8

  alive: true

  __tostring: => concat { "<Player: ", tostring(@box), ">" }

  state_names: {
    walk: {"walk_up", "walk_up", "walk_down", "walk_down"}
    stand: {"stand_up", "stand_up", "stand_down", "stand_down"}
  }

  new: (...) =>
    super ...
    @sprite = Spriter imgfy"img/sprite.png", 10, 13, 3
    @last_direction = "down"
    @cur_attack = nil

    @weapon = Spear self

    with @sprite
      @anim = StateAnim "stand_down", {
        stand_down:   \seq {5}
        stand_up:     \seq {8}

        stand_right:  \seq {11}
        stand_left:   \seq {11}, 0, true

        walk_down:    \seq {3, 4}, 0.25
        walk_up:      \seq {6, 7}, 0.25

        walk_right:   \seq {9, 10}, 0.25
        walk_left:    \seq {9, 10}, 0.25, true
      }

  attack: =>
    print "attack", @last_direction
    @weapon\try_attack!

  take_hit: (enemy) =>
    return if @hit
    print "hitting.."
    @hit = Flash!

  draw: =>
    if @last_direction == "up"
      @weapon\draw! if @weapon
      @draw_player!
    else
      @weapon\draw! if @weapon
      @draw_player!

  draw_player: =>
    @hit\before! if @hit
    @anim\draw @box.x - @ox, @box.y - @oy
    @hit\after! if @hit

  update: (dt) =>
    base = if @velocity\is_zero! then
      "stand"
    else
      @last_direction = @velocity\direction_name!
      "walk"

    dir = @last_direction or "down"
    @anim\set_state base .. "_" .. dir

    @weapon\update dt if @weapon
    @anim\update dt

    if @hit
      @hit = nil unless @hit\update dt

    super dt
    true -- still alive

class World
  new: (@game) =>
    @map = Autotile "img/map.png", {
      [1]: TileSetSpriter "img/tiles.png", 16, 16
      [2]: TileSetSpriter "img/tiles.png", 16, 16, 48
      [3]: BorderTileSpriter "img/tiles.png", 16, 16, 48*2
    }

    @particles = DrawList!
    @entities = with DrawList!
      -- .show_boxes = true
      \add Enemy self, 56, 100

  collides: (thing) => @map\collides thing

  draw: =>
    @map\draw!
    @entities\sort!
    @entities\draw!

    @particles\sort_pts!
    @particles\draw!

  update: (dt) =>
    @entities\update dt
    @particles\update dt

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

hello = Printer "hello\nworld!\n\nahehfehf\n\nAHHHHHFeefh\n\n...\nhelp me"

class Game
  new: =>
    @viewport = Viewport scale: 3
    -- g.setLineWidth 1/@viewport.screen.scale

    @world = World self
    @player = Player @world, 42, 64
    @world.entities\add @player

  draw: =>
    @viewport\apply!

    @viewport\center_on @player
    @world\draw!
    -- p "I & you Lee! Forever Yours, Leafo.", 0,0
    -- hello\draw 10, 10

    @viewport\pop!
    p tostring(timer.getFPS!), 2, 2

  update: (dt) =>
    reloader\update dt
    @player.velocity = movement_vector 60
    @world\update dt

    hello\update dt
    snapper\tick dt if snapper

  on_key: (key, code) =>
    switch key
      when " "
        print @player
      when "x"
        @player\attack!

export fonts = {}
load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  -- g.setBackgroundColor 61, 52, 47
  g.setBackgroundColor 61/2, 52/2, 47/2

  fonts.main = load_font "img/font.png", [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]
  fonts.damage = load_font "img/font2.png", [[ 1234567890]]

  g.setFont fonts.main

  game = Game!
  dispatch = Dispatcher game
  dispatch\bind love

  love.mousepressed = (x,y, button) ->
    x, y = game.viewport\unproject x, y
    print "mouse", x, y, button


