local leaderboard = {}
local bitser = require 'Libraries/bitser-master/bitser'

local FILE_PATH = 'leaderboard.dat'
local BEST_RUN_PATH = 'best_run.dat'
local MAX_ENTRIES = 10

local titleFont
local headerFont
local rowFont
local smallFont
local medalFont
local buttons = {}

local function defaultStore()
    return { entries = {}, nextId = 1 }
end

local function sanitizeStore(data)
    if type(data) == 'table' and data.entries then
        data.entries = data.entries or {}
        data.nextId = tonumber(data.nextId) or (#data.entries + 1)
        return data
    end

    if type(data) == 'table' then
        local looksLikeList = true
        for _, entry in ipairs(data) do
            if type(entry) ~= 'table' then
                looksLikeList = false
                break
            end
        end
        if looksLikeList then
            return { entries = data, nextId = #data + 1 }
        end
    end

    return defaultStore()
end

local function getStore()
    if leaderboard.store then
        return leaderboard.store
    end

    if not love.filesystem.getInfo(FILE_PATH) then
        leaderboard.store = defaultStore()
        return leaderboard.store
    end

    local contents = love.filesystem.read(FILE_PATH)
    if not contents then
        leaderboard.store = defaultStore()
        return leaderboard.store
    end

    local ok, data = pcall(bitser.loads, contents)
    if ok then
        leaderboard.store = sanitizeStore(data)
    else
        leaderboard.store = defaultStore()
    end

    return leaderboard.store
end

local function getEntries()
    return getStore().entries
end

local function saveStore(store)
    leaderboard.store = store
    local ok, serialized = pcall(bitser.dumps, store)
    if ok and serialized then
        love.filesystem.write(FILE_PATH, serialized)
    end
end

local function sortEntries(entries)
    table.sort(entries, function(a, b)
        if (a.time or math.huge) ~= (b.time or math.huge) then
            return (a.time or math.huge) < (b.time or math.huge)
        end
        if (a.keys or -math.huge) ~= (b.keys or -math.huge) then
            return (a.keys or -math.huge) > (b.keys or -math.huge)
        end
        return (a.id or math.huge) < (b.id or math.huge)
    end)
end

local function clampScore(score)
    return math.max(0, math.floor(score + 0.5))
end

function leaderboard.calculateScore(timeValue, keysValue, deathCount)
    local safeTime = tonumber(timeValue) or 0
    local safeKeys = tonumber(keysValue) or 0
    local safeDeaths = tonumber(deathCount) or 0
    local deathPenalty = safeDeaths * 1000
    return clampScore(100000 - (safeTime * 100) + (safeKeys * 250) - deathPenalty)
end

function leaderboard.getBestRun()
    if not love.filesystem.getInfo(BEST_RUN_PATH) then
        return nil
    end

    local contents = love.filesystem.read(BEST_RUN_PATH)
    if not contents then
        return nil
    end

    local ok, data = pcall(bitser.loads, contents)
    if ok and type(data) == 'table' then
        return data
    end
    return nil
end

local function saveBestRun(timeValue, keysValue, scoreValue, deathCount)
    local current = leaderboard.getBestRun()
    local safeTime = tonumber(timeValue) or math.huge
    local safeKeys = tonumber(keysValue) or 0
    local safeDeaths = tonumber(deathCount) or 0
    local safeScore = tonumber(scoreValue) or leaderboard.calculateScore(timeValue, keysValue, deathCount)

    local shouldUpdate = false
    if not current then
        shouldUpdate = true
    elseif safeTime < (current.time or math.huge) then
        shouldUpdate = true
    elseif safeTime == (current.time or math.huge) and safeKeys > (current.keys or 0) then
        shouldUpdate = true
    end

    if shouldUpdate then
        local payload = { time = safeTime, keys = safeKeys, deaths = safeDeaths, score = safeScore }
        local ok, serialized = pcall(bitser.dumps, payload)
        if ok and serialized then
            love.filesystem.write(BEST_RUN_PATH, serialized)
        end
    end
end

function leaderboard.loadEntries()
    return getEntries()
end

function leaderboard.qualifies(timeValue, keysValue)
    local entries = getEntries()
    sortEntries(entries)
    if #entries < MAX_ENTRIES then
        return true
    end

    local last = entries[#entries]
    if not last then
        return true
    end

    if timeValue < (last.time or math.huge) then
        return true
    end
    if timeValue == (last.time or math.huge) and (keysValue or 0) > (last.keys or 0) then
        return true
    end
    return false
end

function leaderboard.isNewRecord(timeValue, keysValue)
    local entries = getEntries()
    if #entries == 0 then
        return true
    end

    local first = entries[1]
    if not first then
        return true
    end

    if timeValue < (first.time or math.huge) then
        return true
    end
    if timeValue == (first.time or math.huge) and (keysValue or 0) > (first.keys or 0) then
        return true
    end
    return false
end

function leaderboard.addEntry(name, timeValue, keysValue, deathCount)
    local store = getStore()
    local entries = store.entries
    local normalizedName = ((name or ''):gsub('^%s+', ''):gsub('%s+$', ''))
    if normalizedName == '' then
        normalizedName = 'Player'
    end
    normalizedName = normalizedName:sub(1, 12)

    local scoreValue = leaderboard.calculateScore(timeValue, keysValue, deathCount)
    local newEntry = {
        id = store.nextId,
        name = normalizedName,
        time = tonumber(timeValue) or 0,
        keys = tonumber(keysValue) or 0,
        deaths = tonumber(deathCount) or 0,
        score = scoreValue,
        date = os.date('%Y-%m-%d %H:%M:%S')
    }
    store.nextId = store.nextId + 1

    table.insert(entries, newEntry)
    sortEntries(entries)
    while #entries > MAX_ENTRIES do
        table.remove(entries)
    end
    saveStore(store)
    saveBestRun(newEntry.time, newEntry.keys, newEntry.score, newEntry.deaths)

    leaderboard.lastSavedId = newEntry.id

    for i, entry in ipairs(entries) do
        if entry.id == newEntry.id then
            return i, newEntry.id
        end
    end

    return nil, newEntry.id
end

function leaderboard.clearEntries()
    leaderboard.store = defaultStore()
    saveStore(leaderboard.store)
    leaderboard.lastSavedId = nil
end

local function makeButton(text, onClick)
    return { text = text, onClick = onClick, x = 0, y = 0, w = 0, h = 0 }
end

local function drawMedal(x, y, place)
    local colors = {
        [1] = {1, 0.84, 0, 1},
        [2] = {0.82, 0.84, 0.92, 1},
        [3] = {0.8, 0.5, 0.2, 1}
    }
    local ribbonColors = {
        [1] = {0.95, 0.2, 0.2, 1},
        [2] = {0.2, 0.45, 0.95, 1},
        [3] = {0.2, 0.75, 0.35, 1}
    }
    local medalColor = colors[place]
    if not medalColor then
        return false
    end

    local ribbon = ribbonColors[place]
    love.graphics.setColor(ribbon)
    love.graphics.polygon('fill', x - 12, y - 10, x - 2, y - 10, x - 8, y + 10)
    love.graphics.polygon('fill', x + 2, y - 10, x + 12, y - 10, x + 8, y + 10)

    love.graphics.setColor(medalColor)
    love.graphics.circle('fill', x, y + 10, 16)
    love.graphics.setColor(1, 1, 1, 0.92)
    love.graphics.circle('line', x, y + 10, 16)
    love.graphics.setColor(0.14, 0.12, 0.08, 1)
    love.graphics.setFont(medalFont)
    local text = tostring(place)
    love.graphics.print(text, x - medalFont:getWidth(text) / 2, y)
    return true
end

function leaderboard:enter()
    titleFont = love.graphics.newFont('Fonts/Chango/Chango-Regular.ttf', 64)
    headerFont = love.graphics.newFont(26)
    rowFont = love.graphics.newFont(24)
    smallFont = love.graphics.newFont(18)
    medalFont = love.graphics.newFont(16)

    buttons = {
        makeButton('Back', function()
            Gamestate.switch(require 'states/menu')
        end),
        makeButton('Clear Scores', function()
            self.confirmClear = true
        end)
    }

    self.confirmClear = false
    self.entries = getEntries()
    sortEntries(self.entries)
    self.highlightId = leaderboard.lastSavedId
end

function leaderboard:draw()
    love.graphics.clear(0, 0, 0, 1)
    love.graphics.setColor(1, 1, 1, 1)
    drawBackground(assets.background1.backgroundSky, 0.05)
    drawBackground(assets.background1.backgroundSand, 0.1)
    drawBackground(assets.background1.backgroundCloud3, 0.2)
    drawBackground(assets.background1.backgroundCloud2, 0.3)
    drawBackground(assets.background1.backgroundCloud1, 0.4)

    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()
    local panelW = math.min(width * 0.8, 1180)
    local panelH = math.min(height * 0.82, 780)
    local panelX = (width - panelW) / 2
    local panelY = 70

    love.graphics.setColor(0, 0, 0, 0.62)
    love.graphics.rectangle('fill', panelX, panelY, panelW, panelH, 22, 22)
    love.graphics.setColor(1, 1, 1, 0.12)
    love.graphics.rectangle('line', panelX, panelY, panelW, panelH, 22, 22)

    love.graphics.setFont(titleFont)
    love.graphics.setColor(1, 0.95, 0.35, 1)
    local title = 'Leaderboard'
    love.graphics.print(title, panelX + (panelW - titleFont:getWidth(title)) / 2, panelY + 24)

    love.graphics.setFont(smallFont)
    love.graphics.setColor(1, 1, 1, 0.9)
    local subtitle = 'Top 10 full-game runs • Fastest time wins • More keys break ties • Fewer deaths help score'
    love.graphics.print(subtitle, panelX + (panelW - smallFont:getWidth(subtitle)) / 2, panelY + 98)

    local headerY = panelY + 144
    love.graphics.setFont(headerFont)
    love.graphics.setColor(0.9, 0.95, 1, 1)
    love.graphics.print('Rank', panelX + 58, headerY)
    love.graphics.print('Name', panelX + 180, headerY)
    love.graphics.print('Final Time', panelX + panelW - 560, headerY)
    love.graphics.print('Keys', panelX + panelW - 410, headerY)
    love.graphics.print('Deaths', panelX + panelW - 280, headerY)
    love.graphics.print('Score', panelX + panelW - 140, headerY)

    local entries = self.entries or getEntries()
    local startY = headerY + 46
    local rowH = 48
    love.graphics.setFont(rowFont)

    if #entries == 0 then
        love.graphics.setColor(1, 1, 1, 0.9)
        local msg = 'No scores saved yet. Finish a run and enter your name on the win screen.'
        love.graphics.print(msg, panelX + (panelW - rowFont:getWidth(msg)) / 2, startY + 70)
    else
        for i, entry in ipairs(entries) do
            local y = startY + (i - 1) * rowH
            local baseAlpha = 0.72
            local shade = 0.08 + ((i % 2 == 0) and 0.05 or 0)

            if self.highlightId and entry.id == self.highlightId then
                love.graphics.setColor(0.2, 0.55, 0.95, 0.32)
                love.graphics.rectangle('fill', panelX + 24, y - 8, panelW - 48, rowH - 2, 12, 12)
            end

            if i == 1 then
                love.graphics.setColor(1, 0.86, 0.2, 0.16)
            elseif i == 2 then
                love.graphics.setColor(0.9, 0.9, 0.96, 0.12)
            elseif i == 3 then
                love.graphics.setColor(0.85, 0.65, 0.4, 0.12)
            else
                love.graphics.setColor(shade, shade, shade + 0.05, baseAlpha)
            end
            love.graphics.rectangle('fill', panelX + 28, y - 6, panelW - 56, rowH - 4, 12, 12)

            if not drawMedal(panelX + 92, y - 2, i) then
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.print(tostring(i), panelX + 74, y)
            end

            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(rowFont)
            love.graphics.print(entry.name or 'Player', panelX + 180, y)
            love.graphics.print(string.format('%.1fs', entry.time or 0), panelX + panelW - 500, y)
            love.graphics.print(tostring(entry.keys or 0), panelX + panelW - 380, y)
            love.graphics.print(tostring(entry.deaths or 0), panelX + panelW - 260, y)
            local entryScore = entry.score or leaderboard.calculateScore(entry.time, entry.keys, entry.deaths)
            love.graphics.print(tostring(entryScore), panelX + panelW - 140, y)
        end
    end

    local backButton = buttons[1]
    backButton.w, backButton.h = 220, 58
    backButton.x = panelX + 70
    backButton.y = panelY + panelH - 84

    local clearButton = buttons[2]
    clearButton.w, clearButton.h = 220, 58
    clearButton.x = panelX + panelW - clearButton.w - 70
    clearButton.y = panelY + panelH - 84

    local mx, my = love.mouse.getPosition()
    for _, button in ipairs(buttons) do
        local hovered = mx >= button.x and mx <= button.x + button.w and my >= button.y and my <= button.y + button.h
        love.graphics.setColor(hovered and 0.96 or 0.88, hovered and 0.96 or 0.88, 1, 0.95)
        love.graphics.rectangle('fill', button.x, button.y, button.w, button.h, 12, 12)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.setFont(headerFont)
        love.graphics.print(button.text, button.x + (button.w - headerFont:getWidth(button.text)) / 2, button.y + 14)
    end

    if self.confirmClear then
        local confirmW, confirmH = 560, 190
        local confirmX = (width - confirmW) / 2
        local confirmY = (height - confirmH) / 2
        love.graphics.setColor(0.05, 0.05, 0.08, 0.96)
        love.graphics.rectangle('fill', confirmX, confirmY, confirmW, confirmH, 18, 18)
        love.graphics.setColor(1, 1, 1, 0.12)
        love.graphics.rectangle('line', confirmX, confirmY, confirmW, confirmH, 18, 18)
        love.graphics.setFont(headerFont)
        love.graphics.setColor(1, 0.9, 0.9, 1)
        local q = 'Clear all saved leaderboard scores?'
        love.graphics.print(q, confirmX + (confirmW - headerFont:getWidth(q)) / 2, confirmY + 42)
        love.graphics.setFont(smallFont)
        love.graphics.setColor(1, 1, 1, 0.92)
        local hint = 'Press Y to confirm or N / Esc to cancel.'
        love.graphics.print(hint, confirmX + (confirmW - smallFont:getWidth(hint)) / 2, confirmY + 100)
    end
end

function leaderboard:mousepressed(x, y, button)
    if button ~= 1 then return end
    if self.confirmClear then return end
    for _, b in ipairs(buttons) do
        if x >= b.x and x <= b.x + b.w and y >= b.y and y <= b.y + b.h then
            b.onClick()
            return
        end
    end
end

function leaderboard:keypressed(key)
    if self.confirmClear then
        if key == 'y' then
            leaderboard.clearEntries()
            self.entries = getEntries()
            self.confirmClear = false
        elseif key == 'n' or key == 'escape' then
            self.confirmClear = false
        end
        return
    end

    if key == 'escape' or key == 'return' then
        Gamestate.switch(require 'states/menu')
    end
end

return leaderboard
