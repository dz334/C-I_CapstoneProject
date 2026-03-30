-- Load Hump Gamestate library and assets
Gamestate = require 'Libraries/hump/gamestate'
menuState = require 'states/menu'
settingsState = require 'states/settings'
gameState = require 'states/game'
pauseState = require 'states/pause'
assets = require 'assets'

-- Audio
isMuted = false
soundVolume = 1 -- range 0 to 1
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
    --local BG_W = 4800
    --local BG_H =  960 -- 800 original value
    local BG_W, BG_H = love.window.getDesktopDimensions( displayindex )
    local scaleX = BG_W / image:getWidth()
    local scaleY = BG_H / image:getHeight()
    love.graphics.draw(image, 0, BG_H, 0, scaleX, scaleY, 0, image:getHeight())
end

function love.load()
    love.window.setFullscreen(true)
    assets.load()
    Gamestate.switch(menuState)

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

function love.textinput(t)
    Gamestate.textinput(t)
end
