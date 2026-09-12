export GAME_CONFIG = {
  -- design size of the pixel viewport, the original game ran a 600x400
  -- window at 3x. scale is replaced at startup by what fits the screen
  viewport_width: 200
  viewport_height: 400 / 3
  scale: 3

  keys: {
    up: "up"
    down: "down"
    left: "left"
    right: "right"

    attack: "x"
    confirm: { "return", "x" }
    skip: "escape"
    pause: "p"
  }

  -- gamepad button names, either row of the diamond attacks
  gamepad: {
    attack: { "a", "x" }
    confirm: { "a", "x", "start" }
    skip: "start"
    pause: "start"

    -- holding select opens the menu, the face buttons pick an action
    menu: "back"
    menu_quit: "a"
    menu_fps: "x"
  }
}

love.conf = (t) ->
  t.version = "11.5"
  t.identity = "exoslime"
  -- the window is opened in love.load once the display size is known
  t.window = nil
