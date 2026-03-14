-- Load Hump Gamestate library and assets
Gamestate = require 'Libraries/hump/gamestate'
local menuState = require 'states/menu'
local settingsState = require 'states/settings'
local gameState = require 'states/game'
local pauseState = require 'states/pause'
assets = require 'assets'

-- Audio
isMuted = false
soundVolume = 0.1 -- range 0 to 1
themeMusic = nil

function applyVolume()
    if isMuted then
        love.audio.setVolume(0)
    else
        love.audio.setVolume(soundVolume)
    end
end

-- Global helper function 
function drawBackgroundFixed(image)
    local BG_W = 1920
    local BG_H = 640
    local scaleX = BG_W / image:getWidth()
    local scaleY = BG_H / image:getHeight()
    love.graphics.draw(image, 0, BG_H, 0, scaleX, scaleY, 0, image:getHeight())
end

function love.load()
    assets.load()
    Gamestate.switch(menuState)

    -- Load and play theme music 
        if love.filesystem.getInfo(assets.audio.menuMusic) then
            themeMusic = love.audio.newSource(assets.audio.menuMusic, 'stream')
        end
        themeMusic:setLooping(true)
        themeMusic:play()
    applyVolume()

end

function love.update(dt)
    Gamestate.update(dt)
end

function love.draw()
    Gamestate.draw()
end

function love.mousepressed(x, y, button)
    Gamestate.mousepressed(x, y, button)
end

function love.keypressed(key)
    Gamestate.keypressed(key)
end