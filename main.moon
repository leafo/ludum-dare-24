
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
require "levels.all"

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
  speed: 80
  step_rate: 0.25

  alive: true

  __tostring: => concat { "<Player: ", tostring(@box), ">" }

  new: (...) =>
    super ...
    @sprite = Spriter imgfy"img/sprite.png", 10, 13, 3
    @last_direction = "down"
    @cur_attack = nil

    @step_time = @step_rate

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
    @weapon\try_attack! unless @stunned

  take_hit: (enemy) =>
    return if @hit
    sfx\play "player_is_hit"
    @world.game.viewport\shake!

    @hit = Sequence.join Flash!, Sequence ->
      @velocity = enemy.box\vector_to(@box) * 10
      @stunned = true
      tween @velocity, 0.3, [1]: 0, [2]: 0
      @stunned = false

  draw: =>
    if @last_direction == "up"
      @weapon\draw! if @weapon
      @draw_player!
    else
      @draw_player!
      @weapon\draw! if @weapon

  draw_player: =>
    @hit\before! if @hit
    @anim\draw @box.x - @ox, @box.y - @oy
    @hit\after! if @hit

  movement_vector: (dt) =>
    v = movement_vector @speed
    if v\is_zero!
      @step_time = @step_rate
    else
      @step_time += dt
      if @step_time >= @step_rate
        sfx\play "step"
        @step_time = 0

    v

  update: (dt) =>
    @velocity = @movement_vector dt unless @stunned

    if not @stunned
      @anim\set_state @direction_name!

    @weapon\update dt if @weapon
    @anim\update dt

    if @hit
      @hit = nil unless @hit\update dt

    super dt
    true -- still alive

hello = Printer "hello\nworld!\n\nahehfehf\n\nAHHHHHFeefh\n\n...\nhelp me"

class Game
  onload: (@dispatch) => sfx\play_music "slime"

  new: =>
    @viewport = EffectViewport scale: 3
    -- g.setLineWidth 1/@viewport.screen.scale

    @player = Player nil, 428, 401
    @set_world Level self

    @effect = ViewportFade @viewport, "in"

  set_world: (world) =>
    @world = world
    @player.world = @world
    world.entities\add @player

  draw: =>
    @viewport\apply!

    @viewport\center_on @player
    @world\draw!
    -- p "I & you Lee! Forever Yours, Leafo.", 0,0
    -- hello\draw 10, 10

    @effect\draw! if @effect
    @viewport\pop!
    p tostring(timer.getFPS!), 2, 2

  update: (dt) =>
    reloader\update dt
    return if @pause
    @viewport\update dt
    @world\update dt

    if @effect
      @effect = nil if not @effect\update dt

    hello\update dt
    snapper\tick dt if snapper

  on_key: (key, code) =>
    switch key
      when "p"
        @pause = not @pause
      when " "
        print "player is", @player.alive
        for i, e in ipairs @world.entities
          print i, e.__class.__name, e.alive

      when "x"
        @player\attack!

      when ";"
        sfx\play "step"

class Title
  onload: (@dispatch) => sfx\play_music "slime_title"
  new: =>
    @bg = imgfy "img/title.png"
    @viewport = EffectViewport scale: 1
    @effect = ViewportFade @viewport, "in"

  draw: =>
    @bg\draw 0,0
    @effect\draw! if @effect

  update: (dt) =>
    if @effect
      @effect = nil if not @effect\update dt

  on_key: (key, code) =>
    return if @effect
    if key == "return"
      sfx\play "game_start"
      @effect = ViewportFade @viewport, "out", ->
        @dispatch\push Game!

export fonts = {}
load_font = (img, chars)->
  font_image = imgfy img
  g.newImageFont font_image.tex, chars

love.load = ->
  -- g.setBackgroundColor 61, 52, 47
  g.setBackgroundColor 61/2, 52/2, 47/2

  fonts.main = load_font "img/font.png", [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]
  fonts.damage = load_font "img/font2.png", [[ 1234567890]]

  export sfx = lovekit.audio.Audio!
  sfx\preload {
    "game_start"
    "step"
    "player_is_hit"
    "player_strike"
    "enemy_is_hit"
    "player_die"
    "enemy_die"
    "spread_shot"
    "single_shot"
  }

  g.setFont fonts.main

  -- game = Game!
  dispatch = Dispatcher Title!
  dispatch\bind love

  love.mousepressed = (x,y, button) ->
    -- x, y = game.viewport\unproject x, y
    -- print "mouse", x, y, button
    -- print game.world.map


