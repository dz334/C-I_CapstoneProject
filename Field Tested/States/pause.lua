local pause = {}

local buttons = {}
local titleFont
local buttonFont
local smallFont
local buttonHeight = 64
local margin = 16

-- Slot picker state
local slotPickerActive = false
local slotButtons = {}

local function makeButton(text, onClick)
    return { text = text, onClick = onClick, x = 0, y = 0, w = 0, h = 0 }
end

function pause:enter()
    buttons = {}
    slotPickerActive = false
    slotButtons = {}

    titleFont  = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    buttonFont = love.graphics.newFont(32)
    smallFont  = love.graphics.newFont(16)

    table.insert(buttons, makeButton("Resume", function()
        Gamestate.pop()
    end))

    -- Save opens slot picker instead of saving directly
    table.insert(buttons, makeButton("Save", function()
        slotPickerActive = true
        slotButtons = {}
        for i = 1, save.maxSlots do
            local hasSave = save.hasSaveFile(i)
            local label = hasSave and ("Slot " .. i .. " (Overwrite)") or ("Slot " .. i .. " (Empty)")
            table.insert(slotButtons, makeButton(label, function()
                local success = save.saveGame(i)
                pause.saveMessage = success and ("Saved to Slot " .. i .. "!") or "Save Failed!"
                pause.saveMessageTimer = 2
                slotPickerActive = false
                slotButtons = {}
            end))
        end
        table.insert(slotButtons, makeButton("Cancel", function()
            slotPickerActive = false
            slotButtons = {}
        end))
    end))

    table.insert(buttons, makeButton("Settings", function()
        Gamestate.push(require 'states/settings')
    end))

    table.insert(buttons, makeButton("Main Menu", function()
        gameLoaded = false
        Gamestate.switch(require 'states/menu')
    end))

    table.insert(buttons, makeButton("Quit", function()
        love.event.quit(0)
    end))
end

function pause:update(dt)
    if pause.saveMessageTimer then
        pause.saveMessageTimer = pause.saveMessageTimer - dt
        if pause.saveMessageTimer <= 0 then
            pause.saveMessage = nil
            pause.saveMessageTimer = nil
        end
    end
end

function pause:draw()
    drawBackground(assets.background1.backgroundSky, 0.05)
    drawBackground(assets.background1.backgroundSand, 0.1)
    drawBackground(assets.background1.backgroundCloud3, 0.2)
    drawBackground(assets.background1.backgroundCloud2, 0.3)
    drawBackground(assets.background1.backgroundCloud1, 0.4)

    local width  = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local buttonWidth = width / 3
    local mouseX, mouseY = love.mouse.getPosition()

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 1, 1, 1)
    local title  = slotPickerActive and "Save to Slot" or "PAUSED"
    local titleW = titleFont:getWidth(title)
    love.graphics.print(title, (width - titleW) / 2, height * 0.18)

    -- Draw either slot picker or main buttons
    local activeButtons = slotPickerActive and slotButtons or buttons
    local startY = height * 0.38

    love.graphics.setFont(buttonFont)
    for i, b in ipairs(activeButtons) do
        local x = (width - buttonWidth) / 2
        local y = startY + (i - 1) * (buttonHeight + margin)
        b.x, b.y, b.w, b.h = x, y, buttonWidth, buttonHeight

        local isHovered = mouseX >= x and mouseX <= x + buttonWidth
                      and mouseY >= y and mouseY <= y + buttonHeight

        if isHovered then
            love.graphics.setColor(1, 1, 1, 0.18)
            love.graphics.rectangle("fill", x-8, y-8, buttonWidth+16, buttonHeight+16, 10, 10)
            love.graphics.setColor(1, 1, 1, 0.28)
            love.graphics.rectangle("fill", x-4, y-4, buttonWidth+8, buttonHeight+8, 8, 8)
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

    if pause.saveMessage then
        love.graphics.setFont(buttonFont)
        local msgW = buttonFont:getWidth(pause.saveMessage)
        love.graphics.print(pause.saveMessage, (width - msgW) / 2, height * 0.85)
    end
end

function pause:mousepressed(x, y, mouseButton)
    if mouseButton ~= 1 then return end
    local activeButtons = slotPickerActive and slotButtons or buttons
    for _, b in ipairs(activeButtons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            b.onClick()
            return
        end
    end
end

function pause:keypressed(key)
    if key == "escape" then
        if slotPickerActive then
            slotPickerActive = false
            slotButtons = {}
        else
            Gamestate.pop()
        end
    end
end

return pause