
local settings = {}
local buttons = {}
local titleFont
local buttonFont
local buttonHeight = 36
local margin = 20

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

function settings:enter()

    buttons = {}
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    buttonFont = love.graphics.newFont(16)

    table.insert(buttons, makeButton("Back", function()
        Gamestate.pop()
    end))

    -- Volume buttons
    table.insert(buttons, makeButton("Volume: +", function()
        local currentVolume = love.audio.getVolume()
        love.audio.setVolume(math.min(1, currentVolume + 0.1))
    end))
    table.insert(buttons, makeButton("Volume: -", function()
        local currentVolume = love.audio.getVolume()
        love.audio.setVolume(math.max(0, currentVolume - 0.1))
    end))

    -- Mute button
    table.insert(buttons, makeButton("Mute/Unmute", function()
        if love.audio.getVolume() > 0 then
            love.audio.setVolume(0)
        else
            love.audio.setVolume(0.5) -- Default volume when unmuting
        end
    end))

-- Fullscreen
    table.insert(buttons, makeButton("Toggle Fullscreen", function()
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    end))
end

function settings:update(dt)
end

function settings:draw()

    drawBackground(assets.background1.backgroundSky, 0.05)
    drawBackground(assets.background1.backgroundSand, 0.1)
    drawBackground(assets.background1.backgroundCloud3, 0.2)
    drawBackground(assets.background1.backgroundCloud2, 0.3)
    drawBackground(assets.background1.backgroundCloud1, 0.4)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local buttonWidth = width / 3
    local mouseX, mouseY = love.mouse.getPosition()

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(love.math.colorFromBytes(135, 206, 235))
    local title  = "Settings"
    local titleW = titleFont:getWidth(title)
    love.graphics.print(title, (width - titleW) / 2, height * 0.22)


    -- Placeholder
    love.graphics.setColor(1, 1, 1, 0.95)
    love.graphics.setFont(buttonFont)
    love.graphics.print("Add your options here (audio, controls, graphics).", width * 0.22, height * 0.38)
    -- print the current volume level
    local volumeText = string.format("Current Volume: %d%%", love.audio.getVolume() * 100)
    love.graphics.print(volumeText, width * 0.22, height * 0.44)

    -- Buttons
    local startY = height * 0.5
    for i, b in ipairs(buttons) do
        local x = (width - buttonWidth) / 2
        local y = startY + (i - 1) * (buttonHeight + margin)
        b.x, b.y, b.w, b.h = x, y, buttonWidth, buttonHeight

        local isHovered = mouseX >= x and mouseX <= x + buttonWidth
                      and mouseY >= y and mouseY <= y + buttonHeight

        if isHovered then
            love.graphics.setColor(1, 1, 1, 0.18)
            love.graphics.rectangle("fill", x-8, y-8, buttonWidth+16, buttonHeight+16, 10, 10)
            love.graphics.setColor(1, 1, 1, 0.28)
            love.graphics.rectangle("fill", x-4, y-4, buttonWidth+8,  buttonHeight+8,  8,  8)
            love.graphics.setColor(0.95, 0.95, 1, 0.95)
        else
            love.graphics.setColor(1, 1, 1, 0.8)
        end

        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight)
        love.graphics.setColor(0, 0, 0, 1)
        local textWidth = buttonFont:getWidth(b.text)
        love.graphics.print(b.text, (width - textWidth) / 2, y + 16)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function settings:mousepressed(x, y, mouseButton)
    if mouseButton ~= 1 then return end
    for _, b in ipairs(buttons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            b.onClick()
            return
        end
    end
end

function settings:keypressed(key)
    if key == "escape" then
        Gamestate.pop()
    end
end

return settings
