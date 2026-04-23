local menu = {}

local buttons = {}
local font
local titleFont
local subtitleFont
local buttonHeight = 64
local margin = 18

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
    if game_Music then
        game_Music:stop()
    end
    menu_Music = love.audio.newSource('sounds/theme.mp3', 'stream')
    menu_Music:setVolume(0.5)
    menu_Music:play()

    love.window.setFullscreen(true)

    buttons = {}
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 108)
    subtitleFont = love.graphics.newFont(24)
    font = love.graphics.newFont(30)

    table.insert(buttons, makeButton('Start Game', function()
        Gamestate.switch(require 'states/game')
    end))

    table.insert(buttons, makeButton('Load Game', function()
        Gamestate.switch(require 'states/loadGame')
    end))

    table.insert(buttons, makeButton('Leaderboard', function()
        Gamestate.switch(require 'states/leaderboard')
    end))

    table.insert(buttons, makeButton('Settings', function()
        Gamestate.push(require 'states/settings')
    end))

    table.insert(buttons, makeButton('Quit', function()
        love.event.quit(0)
    end))

    gameloaded = false
end

function menu:leave()
    if menu_Music then
        menu_Music:stop()
    end
end

function menu:draw()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    drawBackground(assets.background1.backgroundSky, 0.05)
    drawBackground(assets.background1.backgroundSand, 0.1)
    drawBackground(assets.background1.backgroundCloud3, 0.2)
    drawBackground(assets.background1.backgroundCloud2, 0.3)
    drawBackground(assets.background1.backgroundCloud1, 0.4)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local buttonWidth = math.min(440, width * 0.34)
    local totalHeight = (#buttons * buttonHeight) + ((#buttons - 1) * margin)
    local startX = (width - buttonWidth) / 2
    local startY = math.max(height * 0.34, (height - totalHeight) / 2)
    local mouseX, mouseY = love.mouse.getPosition()

    love.graphics.setFont(titleFont)
    love.graphics.setColor(0.1, 0.95, 0.35, 1)
    local title = 'Field Tested'
    love.graphics.print(title, (width - titleFont:getWidth(title)) / 2, 95)

    love.graphics.setFont(subtitleFont)
    love.graphics.setColor(1, 1, 1, 0.88)
    local subtitle = 'Escape the world. Collect every key. Finish with your best time.'
    love.graphics.print(subtitle, (width - subtitleFont:getWidth(subtitle)) / 2, 205)

    love.graphics.setColor(0, 0, 0, 0.45)
    love.graphics.rectangle('fill', startX - 34, startY - 30, buttonWidth + 68, totalHeight + 60, 18, 18)

    love.graphics.setFont(font)
    for i, b in ipairs(buttons) do
        local x = startX
        local y = startY + (i - 1) * (buttonHeight + margin)
        b.x, b.y, b.w, b.h = x, y, buttonWidth, buttonHeight

        local isHovered = mouseX >= x and mouseX <= x + buttonWidth and mouseY >= y and mouseY <= y + buttonHeight
        love.graphics.setColor(isHovered and 0.98 or 0.88, isHovered and 0.98 or 0.88, 1, 0.94)
        love.graphics.rectangle('fill', x, y, buttonWidth, buttonHeight, 12, 12)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(b.text, x + (buttonWidth - font:getWidth(b.text)) / 2, y + 16)
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
