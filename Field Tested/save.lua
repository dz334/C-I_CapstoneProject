local save = {}
local bitser = require 'Libraries/bitser-master/bitser'
save.maxSlots = 3

function save.getSaveData()
    return {
        playerX = player.x,
        playerY = player.y,
        orbsCollected = orbsCollected,
        currentLevel = level or 1,
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
 
    local success, serialized = pcall(bitser.dumps, data)
    if not success then
        return false
    end

    local writeSuccess, err = pcall(function()
        love.filesystem.write(filePath, serialized)
    end)

    -- Write binary data 
    if writeSuccess then
        return true
    else
        return false
    end
end

-- Load game state from file
function save.loadGame(slot)
    slot = slot or 1
    if slot < 1 or slot > save.maxSlots then
        return false
    end
 
    local filePath = save.getFilePath(slot)
 
    if not love.filesystem.getInfo(filePath) then
        print("No save file found at: " .. filePath)
        return false
    end
 
    local contents, size = love.filesystem.read(filePath)
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

    if data.currentLevel then
        level = data.currentLevel
    end

    save.pendingPlayerX = data.playerX
    save.pendingPlayerY = data.playerY
    
    if data.orbsCollected then
        orbsCollected = data.orbsCollected
    else
        orbsCollected = 0
    end
    
    if data.elapsedTime then
        elapsedTime = data.elapsedTime
    else
        elapsedTime = 0
    end
    
    -- Clear pending data
    save.pendingData = nil
    save.pendingSlot = nil
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