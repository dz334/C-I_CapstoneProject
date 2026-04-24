local save = {}
local bitser = require 'Libraries/bitser-master/bitser'
save.maxSlots = 3

function save.getSaveData()
    return {
        playerX = player.x,
        playerY = player.y,
        orbsCollected = orbsCollected,
        totalKeysCollected = totalKeysCollected or 0,
        currentLevel = level or 1,
        elapsedTime = elapsedTime or 0,
        totalDeaths = totalDeaths or 0,
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

function save.getPendingLevel()
    if save.pendingData and save.pendingData.currentLevel then
        return save.pendingData.currentLevel
    end
    return nil
end

-- Apply loaded data — call AFTER the correct map, solids, and orbs are loaded
function save.applyPendingData()
    if not save.pendingData then
        return false
    end

    local data = save.pendingData

    -- Player position
    if data.playerX and data.playerY then
        player.x = data.playerX
        player.y = data.playerY
    end

    -- Orb state — mark the first N orbs as collected
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
    else
        orbsCollected = 0
        exitUnlocked = false
    end

    -- Timer
    if data.elapsedTime then
        elapsedTime = data.elapsedTime
    else
        elapsedTime = 0
    end

    if data.totalKeysCollected then
        totalKeysCollected = data.totalKeysCollected
    else
        totalKeysCollected = data.orbsCollected or 0
    end

    if data.totalDeaths then
        totalDeaths = data.totalDeaths
    else
        totalDeaths = 0
    end

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