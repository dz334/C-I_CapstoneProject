local win = {}
local leaderboard = require 'states/leaderboard'
local utf8 = require('utf8')

local titleFont
local buttonFont
local textFont
local smallFont
win.drawPreviousState = true

local uiSounds = {}

local function makeTone(frequency, duration, volume)
    local sampleRate = 44100
    local samples = math.floor(sampleRate * duration)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local envelope = 1 - (i / samples)
        local value = math.sin(2 * math.pi * frequency * t) * envelope * volume
        soundData:setSample(i, value)
    end
    return love.audio.newSource(soundData, 'static')
end

local function buildSounds()
    if next(uiSounds) ~= nil then return end
    uiSounds.type = makeTone(660, 0.05, 0.16)
    uiSounds.backspace = makeTone(440, 0.05, 0.14)
    uiSounds.save = makeTone(880, 0.16, 0.18)
    uiSounds.record = makeTone(1046, 0.24, 0.18)
end

local function playSound(name)
    local src = uiSounds[name]
    if src then
        src:stop()
        src:play()
    end
end

local function makeButton(text, onClick)
    return { text = text, onClick = onClick, x = 0, y = 0, w = 0, h = 0 }
end

local function computeRunStats()
    local timeValue = elapsedTime or 0
    local keysValue = totalKeysCollected or 0
    local deathsValue = totalDeaths or 0
    local scoreValue = leaderboard.calculateScore(timeValue, keysValue, deathsValue)
    local best = leaderboard.getBestRun()
    return {
        time = timeValue,
        keys = keysValue,
        deaths = deathsValue,
        timePenalty = math.floor((timeValue * 100) + 0.5),
        keyBonus = keysValue * 250,
        deathPenalty = deathsValue * 1000,
        score = scoreValue,
        best = best,
    }
end

local function refreshButtons(self)
    self.buttons = {
        makeButton('Replay Game', function()
            gameLoaded = false
            if game_Music then
                game_Music:stop()
                game_Music = nil
            end
            elapsedTime = 0
            orbsCollected = 0
            totalKeysCollected = 0
            totalDeaths = 0
            level = 1
            Gamestate.switch(require 'states/game')
        end),
        makeButton('Main Menu', function()
            gameLoaded = false
            if game_Music then
                game_Music:stop()
                game_Music = nil
            end
            Gamestate.switch(menuState)
        end),
        makeButton('Leaderboard', function()
            if game_Music then
                game_Music:stop()
                game_Music = nil
            end
            Gamestate.switch(require 'states/leaderboard')
        end)
    }
end

function win:enter()
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    buttonFont = love.graphics.newFont(28)
    textFont = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(18)
    buildSounds()

    self.nameInput = ''
    self.saved = false
    self.savedRank = nil
    self.savedId = nil
    self.stats = computeRunStats()
    self.qualifies = leaderboard.qualifies(self.stats.time, self.stats.keys)
    self.isNewRecord = self.qualifies and leaderboard.isNewRecord(self.stats.time, self.stats.keys)
    self.cursorTimer = 0
    self.showCursor = true
    refreshButtons(self)
end

function win:update(dt)
    self.cursorTimer = self.cursorTimer + dt
    if self.cursorTimer >= 0.5 then
        self.cursorTimer = 0
        self.showCursor = not self.showCursor
    end
end

function win:draw()
    love.graphics.setColor(1, 1, 1, 1)
    gameState:draw()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panelW = math.min(960, width * 0.76)
    local panelH = 560
    local panelX = (width - panelW) / 2
    local panelY = (height - panelH) / 2

    love.graphics.setColor(0.08, 0.08, 0.12, 0.95)
    love.graphics.rectangle('fill', panelX, panelY, panelW, panelH, 20, 20)
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.rectangle('line', panelX, panelY, panelW, panelH, 20, 20)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.85, 0, 1)
    local title = 'YOU WIN!'
    love.graphics.print(title, panelX + (panelW - titleFont:getWidth(title)) / 2, panelY + 26)

    love.graphics.setFont(buttonFont)
    if self.isNewRecord then
        love.graphics.setColor(1, 0.92, 0.35, 1)
        local banner = 'NEW RECORD!'
        love.graphics.print(banner, panelX + (panelW - buttonFont:getWidth(banner)) / 2, panelY + 100)
    elseif self.qualifies then
        love.graphics.setColor(0.8, 0.95, 1, 1)
        local banner = 'Top 10 Finish!'
        love.graphics.print(banner, panelX + (panelW - buttonFont:getWidth(banner)) / 2, panelY + 100)
    end

    love.graphics.setFont(textFont)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format('Final Time: %.1f seconds', self.stats.time), panelX + 60, panelY + 150)
    love.graphics.print(string.format('Keys Collected: %d', self.stats.keys), panelX + 60, panelY + 188)
    love.graphics.print(string.format('Respawns: %d', self.stats.deaths), panelX + 60, panelY + 226)

    love.graphics.setColor(0.85, 0.92, 1, 1)
    love.graphics.print('Score Breakdown', panelX + 60, panelY + 272)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print('Base Score: 100000', panelX + 60, panelY + 310)
    love.graphics.print(string.format('Time Penalty: -%d', self.stats.timePenalty), panelX + 60, panelY + 344)
    love.graphics.print(string.format('Key Bonus: +%d', self.stats.keyBonus), panelX + 60, panelY + 378)
    love.graphics.print(string.format('Respawn Penalty: -%d', self.stats.deathPenalty), panelX + 60, panelY + 412)
    love.graphics.setColor(1, 0.95, 0.4, 1)
    love.graphics.print(string.format('Final Score: %d', self.stats.score), panelX + 60, panelY + 446)

    local best = self.stats.best
    love.graphics.setFont(smallFont)
    love.graphics.setColor(0.88, 0.9, 0.95, 1)
    if best then
        local bestText = string.format('Personal Best on this device: %.1fs • %d keys • %d deaths • %d score', best.time or 0, best.keys or 0, best.deaths or 0, best.score or leaderboard.calculateScore(best.time, best.keys, best.deaths))
        love.graphics.print(bestText, panelX + 60, panelY + 488)
    else
        love.graphics.print('Personal Best on this device: This is your first recorded finish.', panelX + 60, panelY + 488)
    end

    if self.qualifies and not self.saved then
        love.graphics.setFont(textFont)
        love.graphics.setColor(0.9, 0.95, 1, 1)
        love.graphics.print('Enter your name to save this run:', panelX + 520, panelY + 150)

        love.graphics.setColor(1, 1, 1, 0.95)
        love.graphics.rectangle('fill', panelX + 520, panelY + 192, 360, 58, 12, 12)
        love.graphics.setColor(0, 0, 0, 1)
        local displayName = self.nameInput ~= '' and self.nameInput or 'Player'
        if self.showCursor then
            displayName = displayName .. '_'
        end
        love.graphics.print(displayName, panelX + 538, panelY + 208)

        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.82, 0.82, 0.82, 1)
        love.graphics.print('Up to 12 letters, numbers, spaces, - or _. Press Enter to save.', panelX + 520, panelY + 268)
    elseif self.saved then
        love.graphics.setFont(textFont)
        love.graphics.setColor(0.82, 1, 0.82, 1)
        local msg = 'Score saved'
        if self.savedRank then
            msg = msg .. ' - Rank #' .. tostring(self.savedRank)
        end
        love.graphics.print(msg, panelX + 520, panelY + 172)
        love.graphics.setFont(smallFont)
        love.graphics.setColor(0.92, 0.92, 0.92, 1)
        love.graphics.print('Choose what you want to do next.', panelX + 520, panelY + 214)
    else
        love.graphics.setFont(textFont)
        love.graphics.setColor(0.9, 0.9, 0.9, 1)
        love.graphics.print('This run did not make the top 10.', panelX + 520, panelY + 172)
        love.graphics.setFont(smallFont)
        love.graphics.print('You can replay, go back to the menu, or view the leaderboard.', panelX + 520, panelY + 214)
    end

    local startX = panelX + 520
    local startY = panelY + 304
    local buttonW = 280
    local buttonH = 56
    local buttonGap = 18
    local mouseX, mouseY = love.mouse.getPosition()
    love.graphics.setFont(buttonFont)

    for i, button in ipairs(self.buttons) do
        button.x = startX
        button.y = startY + (i - 1) * (buttonH + buttonGap)
        button.w = buttonW
        button.h = buttonH
        local hovered = mouseX >= button.x and mouseX <= button.x + button.w and mouseY >= button.y and mouseY <= button.y + button.h
        love.graphics.setColor(hovered and 0.96 or 0.88, hovered and 0.96 or 0.88, 1, 0.94)
        love.graphics.rectangle('fill', button.x, button.y, button.w, button.h, 12, 12)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.print(button.text, button.x + (button.w - buttonFont:getWidth(button.text)) / 2, button.y + 13)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

function win:textinput(t)
    if self.saved or not self.qualifies then return end
    local currentLength = utf8.len(self.nameInput) or #self.nameInput
    if currentLength >= 12 then return end
    if t:match('^[%w%s%-%_]$') then
        if currentLength == 0 then
            t = t:upper()
        end
        self.nameInput = self.nameInput .. t
        self.cursorTimer = 0
        self.showCursor = true
        playSound('type')
    end
end

function win:keypressed(key)
    if self.qualifies and not self.saved then
        if key == 'backspace' then
            local byteoffset = utf8.offset(self.nameInput, -1)
            if byteoffset then
                self.nameInput = string.sub(self.nameInput, 1, byteoffset - 1)
                playSound('backspace')
            end
            return
        elseif key == 'return' then
            self.savedRank, self.savedId = leaderboard.addEntry(self.nameInput, self.stats.time, self.stats.keys, self.stats.deaths)
            leaderboard.lastSavedId = self.savedId
            self.saved = true
            self.stats = computeRunStats()
            if self.isNewRecord then
                playSound('record')
            else
                playSound('save')
            end
            return
        end
    end

    if key == 'r' then
        self.buttons[1].onClick()
    elseif key == 'm' or key == 'escape' then
        self.buttons[2].onClick()
    elseif key == 'tab' then
        self.buttons[3].onClick()
    end
end

function win:mousepressed(x, y, button)
    if button ~= 1 then return end
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            btn.onClick()
            return
        end
    end
end

return win
