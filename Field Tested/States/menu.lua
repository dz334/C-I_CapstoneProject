local menu = {}

local buttons = {}
local font
local titleFont
local buttonHeight = 64
local margin = 16

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

local function makeButton(text, onClick)
    return { 
        text = text, 
        onClick = onClick, 
        x = 0, 
        y = 0, 
        w = 0, 
        h = 0 
    }
end

function menu:enter()
    buttons = {}
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    font = love.graphics.newFont(32)

    table.insert(buttons, makeButton("Start Game", function()
        Gamestate.switch(require 'states/game')
    end))

    table.insert(buttons, makeButton("Load Game", function()
        print("Load game - not yet implemented")
    end))

    table.insert(buttons, makeButton("Settings", function()
        Gamestate.push(require 'states/settings')
    end))

    table.insert(buttons, makeButton("Quit", function()
        love.event.quit(0)
    end))

    -- Load and play menu theme music 
  
    if love.filesystem.getInfo(assets.audio.menuMusic) then
        self.music = love.audio.newSource(assets.audio.menuMusic, 'stream')
        self.music:setLooping(true)
    end
    -- Play only if not already playing
    if self.music and not self.music:isPlaying() then
        self.music:play()
        applyVolume()
    end

end

function menu:leave()
    -- Stop game music when leaving game state
    if self.music and self.music:isPlaying() then
        self.music:stop()
    end
end

function menu:update(dt)
end

function menu:draw()
    -- Draw background (SUBJECT TO CHANGE)
    drawBackground(assets.background1.backgroundSky, 0)
    drawBackground(assets.background1.backgroundHills, 0)
    drawBackground(assets.background1.backgroundCloud2, 0)
    drawBackground(assets.background1.backgroundCloud1, 0)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local buttonWidth = width / 3
    local cursorY = 0
    local mouseX, mouseY = love.mouse.getPosition()

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0, 1, 0, 1)
    local title = "Field Tested"
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (width - titleWidth) / 2, 200)

    -- Menu buttons
    love.graphics.setFont(font)
    for _, b in ipairs(buttons) do
        local x = (width - buttonWidth) / 2
        local y = (height - buttonHeight) / 2 + cursorY
        b.x, b.y, b.w, b.h = x, y, buttonWidth, buttonHeight

        -- Check if mouse is hovering over button
        local isHovered = mouseX >= x and mouseX <= x + buttonWidth
                      and mouseY >= y and mouseY <= y + buttonHeight

        -- Adds glowing hover effect to buttons
        if isHovered then
            love.graphics.setColor(1, 1, 1, 0.18)
            love.graphics.rectangle("fill", x - 8, y - 8, buttonWidth + 16, buttonHeight + 16, 10, 10)
            love.graphics.setColor(1, 1, 1, 0.28)
            love.graphics.rectangle("fill", x - 4, y - 4, buttonWidth + 8, buttonHeight + 8, 8, 8)
            love.graphics.setColor(0.95, 0.95, 1, 0.95)
        else
            love.graphics.setColor(1, 1, 1, 0.8)
        end

        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0, 1)
        local textWidth = font:getWidth(b.text)
        love.graphics.print(b.text, (width - textWidth) / 2, y + 16)

        love.graphics.setColor(1, 1, 1, 1)
        cursorY = cursorY + buttonHeight + margin
    end
end

function menu:mousepressed(x, y, mouseButton)
    if mouseButton ~= 1 then return end
    for _, b in ipairs(buttons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            b.onClick()
            return
        end
    end
end

function menu:keypressed(key)
end

return menu
