
require "lovekit.all"
g = love.graphics
import timer, keyboard, audio from love

class Player extends Entity
  w: 10
  h: 10

  alive: true

  update: (...) =>
    super ...
    true -- still alive

class World
  collides: => false

class Game
  new: =>
    @viewport = Viewport scale: 4

    @entities = DrawList!

    @world = World!
    @player = Player @world, 20, 20

    @entities\add @player

  draw: =>
    @viewport\apply!
    @entities\draw!

  update: (dt) =>
    @player.velocity = movement_vector 100
    @entities\update dt

love.load = ->
  dispatch = Dispatcher Game!
  dispatch\bind love

