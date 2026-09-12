export GAME_CONFIG = {
  -- design size of the pixel viewport, the original game ran a 600x400
  -- window at 3x. scale is replaced at startup by what fits the screen
  viewport_width: 200
  viewport_height: 400 / 3
  scale: 3
}

love.conf = (t) ->
  t.version = "11.5"
  t.identity = "exoslime"
  -- the window is opened in love.load once the display size is known
  t.window = nil
