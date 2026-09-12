{:joystick} = love

-- the first joystick with a gamepad mapping, keyboards and other HID devices
-- show up as joysticks too and raw button guesses cause phantom input
find_pad = ->
  for j in *joystick.getJoysticks!
    return j if j\isGamepad!

make_controller = ->
  pad = find_pad!
  controller = Controller GAME_CONFIG.keys, pad

  if pad
    controller\add_mapping {name, {joystick: btns} for name, btns in pairs GAME_CONFIG.gamepad}

  controller

has_pad = -> CONTROLLER.joystick != nil

-- button names for on screen prompts, the font is lowercase only
prompts = {
  start: -> if has_pad! then "a" else "enter"
  attack: -> if has_pad! then "a" else "x"
  move: -> if has_pad! then "dpad" else "arrows"
  pause: -> if has_pad! then "start" else "p"
  skip: -> if has_pad! then "start" else "esc"
}

-- holding select shows a menu where the face buttons run actions
menu_open = -> CONTROLLER\is_down "menu"

{ :make_controller, :has_pad, :prompts, :menu_open }
