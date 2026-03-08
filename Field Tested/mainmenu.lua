local menu = {}
local buttons = {}
local font
local buttonHeight = 64
local margin = 16
local actions = {}

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

function menu.load(menuActions)
    actions = menuActions or {}
    buttons = {}

    font = love.graphics.newFont(32)
    table.insert(buttons, makeButton("Start Game", function()
        if actions.startGame then
            actions.startGame()
            return
        end
        print("Starting game")
    end))
    table.insert(buttons, makeButton("Load Game", function()
        if actions.loadGame then
            actions.loadGame()
            return
        end
        print("Loading game")
    end))
    table.insert(buttons, makeButton("Settings", function()
        if actions.settings then
            actions.settings()
            return
        end
        print("Loading settings")
    end))
    table.insert(buttons, makeButton("Quit", function() love.event.quit(0) end))
end

function menu.update(dt) 

end

function menu.draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local buttonWidth = width / 3
    local cursorY = 0
    local mouseX, mouseY = love.mouse.getPosition()

    love.graphics.setFont(font)
    for _, b in ipairs(buttons) do
        local x = (width - buttonWidth) / 2
        local y = (height - buttonHeight) / 2 + cursorY
        b.x = x
        b.y = y
        b.w = buttonWidth
        b.h = buttonHeight

        local isHovered = mouseX >= x and mouseX <= x + buttonWidth and mouseY >= y and mouseY <= y + buttonHeight

        if isHovered then
            -- Soft glow behind hovered button.
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

    love.graphics.print("Field Tested")

end

function menu.mousepressed(x, y, mouseButton)
    if mouseButton ~= 1 then
        return
    end

    for _, b in ipairs(buttons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            b.onClick()
            return
        end
    end
end

return menu
