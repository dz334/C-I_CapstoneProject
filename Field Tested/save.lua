local save = {}
local bitser = require 'Libraries/bitser'

save.filePath = "savegame.dat"

function save.getSaveData()
    return {
        playerX = player.x,
        playerY = player.y,
        orbsCollected = orbsCollected,
        isPuzzleCompleted = isPuzzleCompleted,
        currentLevel = "Level_1",
        elapsedTime = elapsedTime or 0,
        saveDate = os.date("%Y-%m-%d %H:%M:%S")
    }
end

-- Save game state to file
function save.saveGame()
    local data = save.getSaveData()
    
    -- Bitser serializes to string, then we write bytes
    local success, serialized = pcall(bitser.dumps, data)
    if not success then
        return false
    end
    
    -- Write binary data
    local writeSuccess, message = pcall(function()
        love.filesystem.write(save.filePath, serialized)
    end)
    
    if writeSuccess then
        return true
    else
        return false
    end
end

-- Load game state from file
function save.loadGame()
    if not love.filesystem.getInfo(save.filePath) then
        print("No save file found")
        return false
    end
    
    -- Read binary data
    local contents, size = love.filesystem.read(save.filePath)
    if not contents then
        print("Failed to read save file")
        return false
    end
    
    -- Bitser deserializes from string
    local success, data = pcall(bitser.loads, contents)
    if not success or not data then
        print("Failed to parse save file: " .. tostring(data))
        return false
    end
    
    save.pendingData = data
    print("Game loaded successfully!")
    return true
end

-- Apply loaded data (same as before)
function save.applyPendingData()
    if not save.pendingData then return false end
    
    local data = save.pendingData
    
    if data.playerX and data.playerY then
        player.x = data.playerX
        player.y = data.playerY
    end
    
    if data.orbsCollected then
        orbsCollected = data.orbsCollected
        for i = 1, orbsCollected do
            if orbs[i] then orbs[i].collected = true end
        end
        if orbsCollected >= orbsRequired then
            exitUnlocked = true
        end
    end
    
    if data.isPuzzleCompleted ~= nil then
        isPuzzleCompleted = data.isPuzzleCompleted
    end
    
    if data.elapsedTime then
        elapsedTime = data.elapsedTime
    end
    
    save.pendingData = nil
    return true
end

-- Check if save exists
function save.hasSaveFile()
    return love.filesystem.getInfo(save.filePath) ~= nil
end

-- Delete save
function save.deleteSave()
    if save.hasSaveFile() then
        love.filesystem.remove(save.filePath)
        return true
    end
    return false
end

return save