local save = {}
local bitser = require 'Libraries/bitser-master/bitser'
save.maxSlots = 3
save.filePath = "savegame.dat"

function save.getSaveData()
    return {
        playerX = player.x,
        playerY = player.y,
        orbsCollected = orbsCollected,
        currentLevel = level,
        elapsedTime = elapsedTime or 0,
        saveDate = os.date("%Y-%m-%d %H:%M:%S")
    }
end

function save.getFilePath(slot)
    return "savegame_slot" .. slot .. ".dat"
end

-- Save game state to file
function save.saveGame(slot)
    slot = slot or 1
    if slot < 1 or slot > save.maxSlots then
        return false
    end
    
    local filePath = save.getFilePath(slot)
    local data = save.getSaveData()
    
    -- Bitser serializes to string, then we write bytes
    local success, serialized = pcall(bitser.dumps, data)
    if not success then
        return false
    end
    
    -- Write binary data
    local writeSuccess, message = pcall(function()
        love.filesystem.write(filePath, serialized)
    end)
    
    if writeSuccess then
        return true
    else
        return false
    end
end

-- Load game state from file
function save.loadGame()
    slot = slot or 1
    if slot < 1 or slot > save.maxSlots then
        return false
    end

    local filePath = save.getFilePath(slot)

    if not love.filesystem.getInfo(save.filePath) then
        return false
    end
    
    local contents, size = love.filesystem.read(save.filePath)
    if not contents then
        return false
    end
    
    local success, data = pcall(bitser.loads, contents)
    if not success or not data then
        return false
    end
    
    save.pendingData = data
    save.pendingSlot = slot
    return true
end

-- Apply loaded data
function save.applyPendingData()
    if not save.pendingData then 
        return false 
    end

    local data = save.pendingData
    
    if data.playerX and data.playerY then
        player.x = data.playerX
        player.y = data.playerY
    end
    
    if data.orbsCollected then
        orbsCollected = data.orbsCollected
        for i = 1, orbsCollected do
            if orbs[i] then 
                orbs[i].collected = true 
            end
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
function save.hasSaveFile(slot)
    slot = slot or 1
    return love.filesystem.getInfo(save.getFilePath(slot)) ~= nil
end

-- Delete save
function save.deleteSave(slot)
    slot = slot or 1
    local filePath = save.getFilePath(slot)
    if save.hasSaveFile(slot) then
        love.filesystem.remove(filePath)
        print("Save slot " .. slot .. " deleted")
        return true
    end
    return false
end

return save