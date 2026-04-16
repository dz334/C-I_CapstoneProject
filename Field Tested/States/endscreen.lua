local win = {}

local titleFont
local buttonFont
win.drawPreviousState = true

function win:enter()
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    buttonFont = love.graphics.newFont(32)
end

function win:draw()
    gameState:draw()

    -- Draw a semi-transparent dark overlay over the game underneath
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    -- Title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.85, 0, 1)  -- gold color
    local title = "YOU WIN!"
    love.graphics.print(title, (width - titleFont:getWidth(title)) / 2, height * 0.25)

    -- Stats
    love.graphics.setFont(buttonFont)
    love.graphics.setColor(1, 1, 1, 1)
    local timeText = string.format("Time: %.1f seconds", elapsedTime)
    local orbText  = "Keys Collected: " .. orbsCollected .. "/" .. orbsRequired
    love.graphics.print(timeText, (width - buttonFont:getWidth(timeText)) / 2, height * 0.42)
    love.graphics.print(orbText,  (width - buttonFont:getWidth(orbText))  / 2, height * 0.50)

    -- Prompt
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    local prompt = "Press Enter to return to menu"
    love.graphics.print(prompt, (width - buttonFont:getWidth(prompt)) / 2, height * 0.65)

    love.graphics.setColor(1, 1, 1, 1)
end

function win:keypressed(key)
    if key == "return" or key == "escape" then
        gameLoaded = false
        Gamestate.switch(menuState)
    end
end

function win:mousepressed(x, y, button)
end

function win:update(dt)
end

return win