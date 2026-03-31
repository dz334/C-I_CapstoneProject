-- Load Hump Gamestate library and assets
Gamestate = require 'Libraries/hump/gamestate'
menuState = require 'states/menu'
settingsState = require 'states/settings'
gameState = require 'states/game'
pauseState = require 'states/pause'
assets = require 'assets'

-- Audio [CURRENTLY MUTED CHANGE LATER!!]
isMuted = false
soundVolume = 0 -- range 0 to 1
themeMusic = nil

function applyVolume()
    if isMuted then
        love.audio.setVolume(0)
    else
        love.audio.setVolume(soundVolume)
    end
end

-- Global Draw Background Function With Parallax
function drawBackground(image, parallaxSpeed)
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Scale to fill height so there are no bars at the top/bottom
    local scale = screenH / image:getHeight()
    local imgW = image:getWidth() * scale
    
    -- Calculate Offset
    local offsetX = 0
    if cam and parallaxSpeed then
        offsetX = (cam.x * parallaxSpeed) % imgW
    end
    
    -- Draw the image TWICE
    -- The first copy starts at negative offset X
    love.graphics.draw(image, -offsetX, 0, 0, scale, scale)
    
    -- The second copy starts exactly one image-width after the first
    love.graphics.draw(image, -offsetX + imgW, 0, 0, scale, scale)
end

function love.load()
    love.window.setFullscreen(true)
    love.graphics.setDefaultFilter('nearest', 'nearest') -- When art is scaled, keep it clear
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
