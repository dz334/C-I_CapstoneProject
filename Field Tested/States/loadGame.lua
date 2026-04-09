local load = {}

local buttons = {}
local font
local titleFont
local buttonHeight = 64
local margin = 16

local function makeButton(text, onClick)
    return { 
        text = text, 
        onClick = onClick, 
        slot = slot,
        x = 0, 
        y = 0, 
        w = 0, 
        h = 0
    }
end

function load:enter()
    buttons = {}
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    font = love.graphics.newFont(32)

    menu_Music = love.audio.newSource('sounds/theme.mp3', 'stream')
    menu_Music:setVolume(0.5)
    menu_Music:play()

    -- Create 3 save slot buttons
    for i = 1, 3 do
        local hasSave = save.hasSaveFile(i)
        local buttonText = hasSave and ("SAVE " .. i) or "EMPTY"
        
        table.insert(buttons, makeButton(buttonText, function()
            if save.hasSaveFile(i) then
                save.loadGame(i)
                Gamestate.switch(require 'states/game')
            end
        end, i))
        
        buttons[i].hasSave = hasSave
    end

    -- Back button (no slot)
    table.insert(buttons, makeButton("Back", function()
        Gamestate.switch(require 'states/menu')
    end, nil))
end
function load:leave()
    if menu_Music then
        menu_Music:stop()
    end
end

function load:draw()
    drawBackground(assets.background1.backgroundSky, 0.05)
    drawBackground(assets.background1.backgroundSand, 0.1)
    drawBackground(assets.background1.backgroundCloud3, 0.2)
    drawBackground(assets.background1.backgroundCloud2, 0.3)
    drawBackground(assets.background1.backgroundCloud1, 0.4)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local buttonWidth = width / 3
    local cursorY = 0
    local mouseX, mouseY = love.mouse.getPosition()

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(0, 1, 0, 1)
    local title = "Select A Save File"
    local titleWidth = titleFont:getWidth(title)
    love.graphics.print(title, (width - titleWidth) / 2, 200)

    -- Save buttons
    love.graphics.setFont(font)
    for _, b in ipairs(buttons) do
        local x = (width - buttonWidth) / 2
        local y = (height - buttonHeight) / 2 + cursorY
        b.x, b.y, b.w, b.h = x, y, buttonWidth, buttonHeight

        -- Check if mouse is hovering over button
        local isHovered = mouseX >= x and mouseX <= x + buttonWidth
                      and mouseY >= y and mouseY <= y + buttonHeight

        -- Empty slots are grayed out and not hoverable
        local isEmptySlot = b.slot and not b.hasSave
        
        if isEmptySlot then
            -- Grayed out empty slot
            love.graphics.setColor(0.3, 0.3, 0.3, 0.5)
        elseif isHovered then
            -- Hover effect for valid buttons
            love.graphics.setColor(1, 1, 1, 0.18)
            love.graphics.rectangle("fill", x - 8, y - 8, buttonWidth + 16, buttonHeight + 16, 10, 10)
            love.graphics.setColor(1, 1, 1, 0.28)
            love.graphics.rectangle("fill", x - 4, y - 4, buttonWidth + 8, buttonHeight + 8, 8, 8)
            love.graphics.setColor(0.95, 0.95, 1, 0.95)
        else
            -- Normal button
            love.graphics.setColor(1, 1, 1, 0.8)
        end

        -- Draw button background
        love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight)
        
        -- Draw text
        if isEmptySlot then
            love.graphics.setColor(0.15, 0.15, 0.15, 0.6)
        else
            love.graphics.setColor(0, 0, 0, 1)
        end
        
        local textWidth = font:getWidth(b.text)
        love.graphics.print(b.text, (width - textWidth) / 2, y + 16)

        love.graphics.setColor(1, 1, 1, 1)
        cursorY = cursorY + buttonHeight + margin
    end
end

function load:mousepressed(x, y, mouseButton)
    if mouseButton ~= 1 then return end
    for _, b in ipairs(buttons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            b.onClick()
            return
        end
    end
end



function load:keypressed(key)
end

return load