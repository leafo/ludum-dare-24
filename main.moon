
export disable_reloader = true
export watch_class = ->

require "lovekit.all"
-- reloader = require "lovekit.reloader"

g = love.graphics
import timer, keyboard, audio from love

import concat from table

export CONTROLLER, SHOW_FPS
controls = require "controls"
import open_window from require "lovekit.window"

require "entity"
require "autotile"
require "attack"
require "enemy"
require "effects"
require "ui"
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
      wait 1.0

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
  max_life: 100

  alive: true

  __tostring: => concat { "<Player: ", tostring(@box), ">" }

  new: (...) =>
    super ...
    @sprite = Spriter imgfy"img/sprite.png", 10, 13, 3
    @last_direction = "down"
    @cur_attack = nil

    @step_time = @step_rate

    @weapon = Spear self
    @life = @max_life

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
    return if @hit or @locked or @life <= 0
    sfx\play "player_is_hit"
    @world.game.viewport\shake!

    @life = @life - 12
    if @life <= 0
      @life = 0
      @on_die!

    @hit = Sequence.join Flash!, Sequence ->
      @velocity = enemy.box\vector_to(@box) * 10
      @stunned = true
      tween @velocity, 0.3, [1]: 0, [2]: 0
      @stunned = false

  on_die: =>
    @locked = true
    sfx\play "player_die"
    x, y = @box\center!
    @world.particles\add BloodEmitter @world, x, y, nil, 100, nil, ->
      @world\restart!

  draw: =>
    if @last_direction == "up"
      @weapon\draw! if @weapon
      @draw_player!
    else
      @draw_player!
      @weapon\draw! if @weapon

  draw_player: =>
    return if @life <= 0
    @hit\before! if @hit
    @anim\draw @box.x - @ox, @box.y - @oy
    @hit\after! if @hit

  movement_vector: (dt) =>
    return Vec2d 0,0 if @locked

    v = CONTROLLER\movement_vector @speed
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
  on_show: (@dispatch) => sfx\play_music "slime"

  new: =>
    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }

    -- cheat to last level
    level = if love.keyboard.isDown"1" and love.keyboard.isDown"2"
      levels.Floor9
    else
      levels.Floor1

    @player = Player nil, 428, 401
    @set_world level self

    @health_bar = HorizBar 45, 8

    @effect = ViewportFade @viewport, "in"

    -- start both skips the intro and pauses, swallow the press that got us here
    CONTROLLER\downed "pause"

  set_world: (world) =>
    @world = world
    @player.world = @world
    @player.box.x, @player.box.y = unpack @world.start_pos
    world.entities\add @player

  draw: =>
    @viewport\center_on @player
    @viewport\apply!
    @world\draw!
    -- p "I & you Lee! Forever Yours, Leafo.", 0,0
    -- hello\draw 10, 10

    @health_bar.value = @player.life / @player.max_life
    @health_bar\draw @viewport.x + 2, @viewport.y + @viewport.h - 10

    @effect\draw! if @effect
    @viewport\pop!

    if @pause
      draw_overlay { "paused", "press #{controls.prompts.pause!} to resume" }

  update: (dt) =>
    return if dt > 1.0 -- o well

    @pause = not @pause if CONTROLLER\downed "pause"
    return if @pause

    @player\attack! if CONTROLLER\downed "attack"
    @viewport\update dt
    @world\update dt

    if @effect
      e = @effect
      @effect = nil if not @effect\update(dt) and e == @effect

    hello\update dt

class Intro
  text: {
    "Slimes!\n\nthey're everywhere!"
    "they've invaded the castle,\n    and are living in\n     the catacombs."
    "they're attacking our\n    soldiers.\n\nthey've stolen our princess."
    "you must get them!    "
  }

  on_show: (@dispatch) => sfx.music\stop!

  new: =>
    @i = 1
    @viewport = EffectViewport {
      pixel_scale: true
      scale: GAME_CONFIG.scale
    }
    @effect = ViewportFade @viewport, "in"
    @time = 0

  begin: =>
    @dispatch\pop!
    @dispatch\push Game!

  update: (dt) =>
    -- real time, before the attack speed up. a skip press is only honored
    -- after a second so the press that got us here can't blow past the intro
    @time += dt
    skip = CONTROLLER\downed "skip"

    if CONTROLLER\is_down "attack"
      dt = dt * 6

    if skip and @time >= 1
      @begin!
      return

    if @effect
      @effect = nil if not @effect\update dt
    else
      if not @writer
        if @text[@i] == nil
          @begin!
          return

        @writer = Printer @text[@i]
        @i += 1

      @writer = nil if not @writer\update dt

  -- escape is polled as skip above, stop the dispatcher from quitting on it
  on_key: (key, code) =>
    key == "escape"

  draw: =>
    @viewport\apply!
    @writer\draw 10, 10 if @writer

    @effect\draw! if @effect
    @viewport\pop!


export class Outro extends Intro
  text: {
    "Upon slaying the Huge Slime,\n    you discover the castle\n    toilets."
    "Excrement falls down and\n    festers in a pile.\n\nWhat is this!?"
    "The slimes have evolved\n    from our own waste.\n\nAnd now they torment us."
    "What will become of this\n    kingdom?",
    "The slimes are at last dead.\n\n\nBut at what cost?"
  }

  begin: =>
    @dispatch\pop 2

class Title
  -- the art is one fixed picture, not game pixels, so it gets its own scale
  art_w: 600
  art_h: 400

  on_show: (@dispatch) => sfx\play_music "slime_title"
  new: =>
    @bg = imgfy "img/title.png"
    @viewport = EffectViewport {
      pixel_scale: true
      -- 1x at 640x480, 2x at 1024x768
      scale: pixel_scale_for @art_w, @art_h, crop: true
    }
    @effect = ViewportFade @viewport, "in"

  -- centered, but anchored left once the art is wider than the screen so the
  -- crop takes the slime's edge instead of the logo
  art_origin: =>
    x = math.floor (@viewport.w - @art_w) / 2
    y = math.floor (@viewport.h - @art_h) / 2
    x = 0 if x < 0
    x, y

  draw: =>
    @viewport\apply!
    @bg\draw @art_origin!
    @draw_pad_prompts! if controls.has_pad!
    @effect\draw! if @effect
    @viewport\pop!

  -- the art has keyboard prompts baked in, cover them when a pad is plugged in
  draw_pad_prompts: =>
    ox, oy = @art_origin!
    x, y, w, h = ox + 55, oy + 222, 220, 96
    COLOR\push 30, 26, 23
    g.rectangle "fill", x, y, w, h
    COLOR\pop!

    g.push!
    g.translate x, y + 6
    g.scale 2
    g.printf "press #{controls.prompts.start!} to start", 0, 0, w / 2, "center"
    g.printf "#{controls.prompts.move!} move", 0, 24, w / 2, "center"
    g.printf "#{controls.prompts.attack!} attacks", 0, 36, w / 2, "center"
    g.pop!

  update: (dt) =>
    if @effect
      @effect = nil if not @effect\update dt
      return

    if CONTROLLER\downed "confirm"
      sfx\play "game_start"
      @effect = ViewportFade @viewport, "out", ->
        @dispatch\push Intro!


TITLE = "ExoSlime"

export fonts = {}
load_font = (img, chars)->
  with g.newImageFont img, chars
    \setFilter "nearest", "nearest"

love.load = (args) ->
  open_window {
    title: TITLE
    env: "EXOSLIME_WINDOW"
    :args
    design_w: GAME_CONFIG.viewport_width * GAME_CONFIG.scale
    design_h: GAME_CONFIG.viewport_height * GAME_CONFIG.scale
  }

  -- integer pixel scale closest to the design size: 3 at 600 and 640 wide, 5 at 1024x768
  GAME_CONFIG.scale = pixel_scale_for GAME_CONFIG.viewport_width, GAME_CONFIG.viewport_height, crop: true

  g.setBackgroundColor 61/2/255, 52/2/255, 47/2/255

  fonts.main = load_font "img/font.png", [[ abcdefghijklmnopqrstuvwxyz-1234567890!.,:;'"?$&]]
  fonts.damage = load_font "img/font2.png", [[ 1234567890]]

  export sfx = Audio!
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
    "hit_switch"
  }

  g.setFont fonts.main

  CONTROLLER = controls.make_controller!
  love.joystickadded = -> CONTROLLER = controls.make_controller!
  love.joystickremoved = -> CONTROLLER = controls.make_controller!

  dispatch = Dispatcher Title!
  dispatch\bind love

  menu_actions = {
    {"menu_quit", "a: quit", -> love.event.push "quit"}
    {"menu_fps", "x: toggle fps", -> SHOW_FPS = not SHOW_FPS}
  }

  -- the menu pauses everything underneath while select is held
  dispatch_update = love.update
  love.update = (dt) ->
    if controls.menu_open!
      for {name, _, fn} in *menu_actions
        fn! if CONTROLLER\downed name
      return

    dispatch_update dt

  dispatch_draw = love.draw
  love.draw = ->
    dispatch_draw!

    if SHOW_FPS
      g.push!
      g.origin!
      g.scale GAME_CONFIG.scale
      p tostring(timer.getFPS!), 2, 2
      g.pop!

    if controls.menu_open!
      draw_overlay [label for {_, label} in *menu_actions]

  love.mousepressed = (x,y, button) ->
    -- x, y = game.viewport\unproject x, y
    -- print "mouse", x, y, button
    -- print game.world.map

