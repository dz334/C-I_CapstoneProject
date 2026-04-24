local game = {}
local BASE_W, BASE_H = 1280, 720
local mapW = 0
local mapH = 0
local solids = {}
local gameFont
local signUIActive = false
local endUIActive = false
gameLoaded = false
elapsedTime = 0
orbs = {}
orbsCollected = 0
totalKeysCollected = 0
totalDeaths = 0
orbsRequired = 1
exitUnlocked = false
local jumpSound = love.audio.newSource('sounds/jump.mp3', 'static')
jumpSound:setVolume(0.4)
local anim8 = require 'Libraries/anim8'
local camera = require 'Libraries/camera'
local sti = require 'Libraries/sti'

-- Check for overlap and collisions between player and solids
local function rectsOverlap(a, b)
    return a.x < b.x + b.w
       and a.x + a.w > b.x
       and a.y < b.y + b.h
       and a.y + a.h > b.y
end

local function getPlayerRect(p)
    return { x = p.x - p.w/2, y = p.y - p.h, w = p.w, h = p.h }
end

-- Read rectangle objects from Tiled "Solid" map layer
function collectSolidRects(map)
    solids = {}
    local solidLayer = map.layers["Solid"]
    if not solidLayer or not solidLayer.objects then return end
    for _, obj in ipairs(solidLayer.objects) do
        if (obj.shape == "rectangle") and obj.width > 0 and obj.height > 0 then
            table.insert(solids, { x = obj.x, y = obj.y, w = obj.width, h = obj.height })
        end
    end
end

-- Resolve collisions after horizontal movement
local function resolveHorizontalCollisions(p)
    local pr = { x = p.x - p.w/2, y = p.y - p.h, w = p.w, h = p.h }
    for _, r in ipairs(solids) do
        if rectsOverlap(pr, r) then
            if p.vx > 0 then pr.x = r.x - pr.w
            elseif p.vx < 0 then pr.x = r.x + r.w end
            p.vx = 0
            p.x  = pr.x + p.w/2
        end
    end
end

-- Resolve collisions after vertical movement
local function resolveVerticalCollisions(p)
    local pr = { x = p.x - p.w/2, y = p.y - p.h, w = p.w, h = p.h }
    p.isGrounded = false
    for _, r in ipairs(solids) do
        if rectsOverlap(pr, r) then
            if p.vy > 0 then
                pr.y = r.y - pr.h
                p.isGrounded = true
            elseif p.vy < 0 then
                pr.y = r.y + r.h
            end
            p.vy = 0
            p.y  = pr.y + p.h
        end
    end
end

-- Gets spawn point from Tiled obj layer pointer
local function getSpawnPoint(map)
    local spawnLayer = map.layers["Spawn"]
    if spawnLayer and spawnLayer.objects and spawnLayer.objects[1] then
        return spawnLayer.objects[1].x, spawnLayer.objects[1].y
    end
end

local function getSignLocation(map)
    local signsLayer = map.layers["Signs"]
    if signsLayer and signsLayer.objects and signsLayer.objects[1] then
        return signsLayer.objects[1].x, signsLayer.objects[1].y
    end
end

local function getExitLocation(map)
    local exitLayer = map.layers["Exit"]
    if exitLayer and exitLayer.objects and exitLayer.objects[1] then
        return exitLayer.objects[1].x, exitLayer.objects[1].y
    end
end

local function getEndLocation(map)
    local endLayer = map.layers["EndTest"]
    if endLayer and endLayer.objects and endLayer.objects[1] then
        return endLayer.objects[1].x, endLayer.objects[1].y
    end
end

-- Find and create "orbs"/keys from tiled
function collectOrbs(map)
    orbs = {}
    local orbLayer = map.layers["Orb"]
    if not orbLayer or not orbLayer.objects then return end
    for _, obj in ipairs(orbLayer.objects) do
        table.insert(orbs, {
            x = obj.x,
            y = obj.y,
            w = 32,
            h = 32,
            collected = false
        })
    end
end

function game:enter()
    -- Upon enter start music
    if game_Music then
        game_Music:stop()
        game_Music = nil
    end
    game_Music = love.audio.newSource('sounds/WhiteForest.mp3', 'stream')
    game_Music:setVolume(0.2)
    game_Music:setLooping(true)

    -- Create player attributes for later creation
    function createPlayer()
        player = {}
        player.w, player.h = 24, 32
        player.vx, player.vy = 0, 0
        player.moveSpeed = 300
        player.jumpForce = 410
        player.gravity = 1100
        player.maxFallSpeed = 700
        player.isGrounded = false

        local char = assets.character4
        player.animation = {}

        player.idleRightSheet = char.idleRight
        player.idleLeftSheet  = char.idleLeft
        local idleRightGrid = anim8.newGrid(32, 32, char.idleRight:getWidth(), char.idleRight:getHeight())
        local idleLeftGrid  = anim8.newGrid(32, 32, char.idleLeft:getWidth(),  char.idleLeft:getHeight())

        player.runRightSheet = char.runRight
        player.runLeftSheet  = char.runLeft
        local runRightGrid  = anim8.newGrid(32, 32, char.runRight:getWidth(),  char.runRight:getHeight())
        local runLeftGrid   = anim8.newGrid(32, 32, char.runLeft:getWidth(),   char.runLeft:getHeight())

        player.jumpRightSheet = char.jumpRight
        player.jumpLeftSheet  = char.jumpLeft
        local jumpRightGrid = anim8.newGrid(32, 32, char.jumpRight:getWidth(), char.jumpRight:getHeight())
        local jumpLeftGrid  = anim8.newGrid(32, 32, char.jumpLeft:getWidth(),  char.jumpLeft:getHeight())

        player.fallRightSheet = char.fallRight
        player.fallLeftSheet  = char.fallLeft
        local fallRightGrid = anim8.newGrid(32, 32, char.fallRight:getWidth(), char.fallRight:getHeight())
        local fallLeftGrid  = anim8.newGrid(32, 32, char.fallLeft:getWidth(),  char.fallLeft:getHeight())

        player.animation.idleRight = anim8.newAnimation(idleRightGrid('1-11', 1), 0.08)
        player.animation.idleLeft  = anim8.newAnimation(idleLeftGrid('1-11', 1), 0.08)
        player.animation.runRight  = anim8.newAnimation(runRightGrid('1-12', 1), 0.07)
        player.animation.runLeft   = anim8.newAnimation(runLeftGrid('1-12', 1), 0.07)
        player.animation.jumpRight = anim8.newAnimation(jumpRightGrid('1-1', 1), 0.07)
        player.animation.jumpLeft  = anim8.newAnimation(jumpLeftGrid('1-1', 1), 0.07)
        player.animation.fallRight = anim8.newAnimation(fallRightGrid('1-1', 1), 0.07)
        player.animation.fallLeft  = anim8.newAnimation(fallLeftGrid('1-1', 1), 0.07)

        player.anim = player.animation.idleRight
        player.animSheet = player.idleRightSheet
        player.facingRight = true

        -- Orb/Key animation
        local orbGrid = anim8.newGrid(32, 32, assets.orb.orbIdle:getWidth(), assets.orb.orbIdle:getHeight())
        orbAnim = anim8.newAnimation(orbGrid('1-24', 1), 0.07)
    end

    -- Create UI objects for later reuse
    function createUIObjects()
        local signX, signY = getSignLocation(gameMap)
        signObject = (signX and signY) and { x = signX, y = signY, w = 32, h = 32 } or nil
        signUIActive = false

        local exitX, exitY = getExitLocation(gameMap)
        exitObject = (exitX and exitY) and { x = exitX - 16, y = exitY - 16, w = 64, h = 32 } or nil

        local endX, endY = getEndLocation(gameMap)
        endObject = (endX and endY) and { x = endX, y = endY, w = 64, h = 64 } or nil
    end

    -- If loading from previous save data run this version 
    -- Load save data
    if save.pendingData then
        game_Music:play()

        -- Read target level before applyPendingData clears pendingData
        local targetLevel = save.pendingData.currentLevel or 1

        cam = camera()
        screenW, screenH = love.graphics.getDimensions()
        cam:zoom(math.min(screenW / BASE_W, screenH / BASE_H))
        gameFont = love.graphics.newFont('Fonts/dpcomic/dpcomic.ttf', 32)

        -- Load the correct map first
        gameMap = sti('Map/Level_' .. targetLevel .. '.lua')
        level = targetLevel
        mapW = gameMap.width * gameMap.tilewidth
        mapH = gameMap.height * gameMap.tileheight

        -- Build map data so orbs[] exists before applyPendingData runs
        collectSolidRects(gameMap)
        collectOrbs(gameMap)

        -- Create player so player.x/y exist before applyPendingData writes to them
        createPlayer()
        player.x, player.y = getSpawnPoint(gameMap)  -- fallback position
  
        -- Reset state defaults before applying save
        elapsedTime = 0
        orbsCollected = 0
        totalKeysCollected = 0
        totalDeaths = 0
        exitUnlocked = false

        -- Apply saved data
        save.applyPendingData()
        player.vx, player.vy = 0, 0

        createUIObjects()
        gameLoaded = true
        gravTime = 0
        return
    end

    -- If not loading from save then load fresh start 
    exitUnlocked = false
    signUIActive = false
    if not gameLoaded then
        game_Music:play()

        cam = camera()
        screenW, screenH = love.graphics.getDimensions()
        cam:zoom(math.min(screenW / BASE_W, screenH / BASE_H))
        gameFont = love.graphics.newFont('Fonts/dpcomic/dpcomic.ttf', 32)

        gameMap = sti('Map/Level_1.lua')
        level = 1
        mapW = gameMap.width * gameMap.tilewidth
        mapH = gameMap.height * gameMap.tileheight

        collectSolidRects(gameMap)
        collectOrbs(gameMap)

        createPlayer()
        player.x, player.y = getSpawnPoint(gameMap)
        player.vx, player.vy = 0, 0

        elapsedTime = 0
        orbsCollected = 0
        totalKeysCollected = 0
        totalDeaths = 0
        createUIObjects()
        gameLoaded = true
    end
end

function game:leave()
    if game_Music then
        game_Music:stop()
        game_Music = nil
    end
end

local function respawnPlayer()
    totalDeaths = (totalDeaths or 0) + 1
    player.x, player.y = getSpawnPoint(gameMap)
    player.vx, player.vy = 0, 0
end

gravTime = 0
function game:update(dt)
    elapsedTime = elapsedTime + dt

    if signUIActive then
        player.vx = 0
        player.vy = 0
        if player.isGrounded then
            player.anim:gotoFrame(2)
        end
        player.anim:update(dt)
        return
    end

    -- Horizontal movement input
    local moveX = 0
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then
        moveX = 1
        player.facingRight = true
    elseif love.keyboard.isDown("a") or love.keyboard.isDown("left") then
        moveX = -1
        player.facingRight = false
    end

    -- Calculate horizontal velocity
    player.vx = moveX * player.moveSpeed

    -- Jump input (only if grounded)
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) and player.isGrounded then
        player.vy = -player.jumpForce
        player.isGrounded = false
        if player.jumpRequested then
            jumpSound:stop()
            jumpSound:play()
            player.jumpRequested = false
        end
    player.jumpRequested = false
        jumping = true
    end

    -- Animation Change Logic
    if not player.isGrounded then
        if player.vy < 0 then -- If player is not falling
            player.anim = player.facingRight and player.animation.jumpRight or player.animation.jumpLeft
            player.animSheet = player.facingRight and player.jumpRightSheet or player.jumpLeftSheet
            else -- If player is falling
                player.anim = player.facingRight and player.animation.fallRight or player.animation.fallLeft
                player.animSheet = player.facingRight and player.fallRightSheet or player.fallLeftSheet
        end
        elseif moveX ~= 0 then -- If player is not moving
            player.anim = player.facingRight and player.animation.runRight or player.animation.runLeft
            player.animSheet = player.facingRight and player.runRightSheet or player.runLeftSheet
        else -- If player is moving
            player.anim = player.facingRight and player.animation.idleRight or player.animation.idleLeft
            player.animSheet = player.facingRight and player.idleRightSheet or player.idleLeftSheet
    end

    -- Calculate vertical fall speed with gravity
    gravTime = gravTime + dt -- When loading stops player from falling through blocks
    if gravTime > 0.5 then
        player.vy = math.min(player.vy + player.gravity * dt, player.maxFallSpeed)
    end

    player.x = player.x + player.vx * dt
    resolveHorizontalCollisions(player)

    player.y = player.y + player.vy * dt
    resolveVerticalCollisions(player)

    player.anim:update(dt)
    orbAnim:update(dt)

    -- Follow player and clamp camera to map bounds
    cam:lookAt(player.x, player.y)
    local w = love.graphics.getWidth() / cam.scale
    local h = love.graphics.getHeight() / cam.scale
    cam.x = math.max(w/2, math.min(cam.x, mapW - w/2))
    cam.y = math.max(h/2, math.min(cam.y, mapH - h/2))

    -- X-Axis Clamp (Centers the map if the map is smaller than the screen)
    if mapW < w then
        cam.x = mapW / 2
    else
        cam.x = math.max(w/2, math.min(cam.x, mapW - w/2))
    end
    
    -- Y-Axis Clamp (Centers the map if the map is smaller than the screen)
    if mapH < h then
        cam.y = mapH / 2
    else
        cam.y = math.max(h/2, math.min(cam.y, mapH - h/2))
    end

    -- Orb/Key Collection
    for _, orb in ipairs(orbs) do
    if not orb.collected then
        local playerRect = getPlayerRect(player)
        local orbRect = { x = orb.x, y = orb.y, w = orb.w, h = orb.h }
        if rectsOverlap(playerRect, orbRect) then
            orb.collected = true
            orbsCollected = orbsCollected + 1
            totalKeysCollected = (totalKeysCollected or 0) + 1
                if orbsCollected >= orbsRequired then
                    exitUnlocked = true
                end
            end
        end
    end

    -- Death zone resets
    local hitDeathZone =
        (level == 2 and player.y > 773)
        or (level == 2 and player.x > 385 and player.x < 512 and player.y > 507)
        or (level == 2 and player.x > 1932 and player.x < 1972 and player.y > 340 and player.y < 369)
        or (level == 2 and player.x > 2060 and player.x < 2102 and player.y > 340 and player.y < 369)
        or (level == 3 and player.y > 773)
        or (level == 4 and player.y > 850)
    if hitDeathZone then
        respawnPlayer()
    end
end

function game:draw()
    local function drawBackgroundLevel1() 
        drawBackground(assets.background1.backgroundSky, 0.05)
        drawBackground(assets.background1.backgroundSand, 0.1)
        drawBackground(assets.background1.backgroundCloud3, 0.2)
        drawBackground(assets.background1.backgroundCloud2, 0.3)
        drawBackground(assets.background1.backgroundCloud1, 0.4)
    end

    local function drawBackgroundLevel3()
        drawBackground(assets.background3.backgroundColor1, 0.05)
        drawBackground(assets.background3.backgroundTree1, 0.1)
        drawBackground(assets.background3.backgroundTree2, 0.2)
    end

    local function drawBackgroundLevel4()
        drawBackground(assets.background2.backgroundSky, 0.05)
        drawBackground(assets.background2.backgroundCloud2, 0.1)
        drawBackground(assets.background2.backgroundCloud1, 0.15)
    end

    if level == 1 then
            drawBackgroundLevel1()
        elseif level == 3 then
            drawBackgroundLevel3()
        elseif level == 4 then
            drawBackgroundLevel4()
    end
    
    cam:attach()
        -- Level 1
        if level == 1 then
            gameMap:drawLayer(gameMap.layers["Ground"])
            gameMap:drawLayer(gameMap.layers["Player Jump Platforms"])
            gameMap:drawLayer(gameMap.layers["SignsIMG"])
            gameMap:drawLayer(gameMap.layers["CaveExit"])

        -- Level 2
        elseif level == 2 then
            gameMap:drawLayer(gameMap.layers["Background"])
            gameMap:drawLayer(gameMap.layers["smoke"])
            gameMap:drawLayer(gameMap.layers["platforms"])
            gameMap:drawLayer(gameMap.layers["lava"])

        -- Level 3
        elseif level == 3 then
            gameMap:drawLayer(gameMap.layers["bg"])
            gameMap:drawLayer(gameMap.layers["ground"])
            gameMap:drawLayer(gameMap.layers["props"])
            gameMap:drawLayer(gameMap.layers["grass"])
        elseif level == 4 then
            gameMap:drawLayer(gameMap.layers["Background"])
            gameMap:drawLayer(gameMap.layers["Ground"])
        end

        player.anim:draw(player.animSheet, player.x, player.y, nil, 1.25, nil, 16, 32)

        for _, orb in ipairs(orbs) do
            if not orb.collected then
                love.graphics.setColor(1, 1, 1, 1)
                orbAnim:draw(assets.orb.orbIdle, orb.x + 16, orb.y + 16, nil, 1, nil, 32/2, assets.orb.orbIdle:getHeight()/2)
            end
        end
    cam:detach()

    -- Misc information in top left corner
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Time: %.1f", elapsedTime), 10, 16)
    love.graphics.print("ESC = Pause", 10, 40)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 64)
    love.graphics.print("Press R to reset", 10, 88)
    love.graphics.setFont(gameFont)
    local orbDisplay= "Keys: "
    local orbTitle = gameFont:getWidth(orbDisplay)
    love.graphics.print("Keys: " .. (totalKeysCollected or 0), ((love.graphics.getWidth() - orbTitle) / 2) + 16, 16)
    if exitUnlocked then
        love.graphics.print("Exit: Unlocked", ((love.graphics.getWidth() - orbTitle) / 2) - 16, 48)
    else 
        love.graphics.print("Exit: Locked", ((love.graphics.getWidth() - orbTitle) / 2) - 16, 48)
    end

    -- UI prompt when near sign object
    if signObject and not signUIActive then
        local playerRect = getPlayerRect(player)
        local signRect = { x = signObject.x, y = signObject.y, w = signObject.w, h = signObject.h }
        if rectsOverlap(playerRect, signRect) then
            love.graphics.print("Press E to read sign", 10, 112)
        end
    end

    -- UI prompt when near exit object
    if exitObject then
        local playerRect = getPlayerRect(player)
        local exitRect = { x = exitObject.x, y = exitObject.y, w = exitObject.w, h = exitObject.h }
        if rectsOverlap(playerRect, exitRect) then
            love.graphics.print("Press E to Advance", 10, 112)
        end
    end

    -- UI prompt for end screen
   if endObject then
        local playerRect = getPlayerRect(player)
        local endRect = { x = endObject.x, y = endObject.y, w = endObject.w, h = endObject.h }
        if rectsOverlap(playerRect, endRect) then
            love.graphics.print(level == 4 and "Press E to finish" or "Press E to continue", 10, 112)
        end
    end

    -- Sign UI 
    if signUIActive then
        local scale = 2 
        local imgW = assets.ui.panel:getWidth()
        local imgH = assets.ui.panel:getHeight()
        local uiW = imgW * scale
        local uiH = imgH * scale
        local uiX = (love.graphics.getWidth() - uiW) / 2
        local uiY = (love.graphics.getHeight() - uiH) / 2   
        local textFont = love.graphics.newFont('Fonts/dpcomic/dpcomic.ttf', 20)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(assets.ui.panel, uiX, uiY, 0, scale, scale)

        -- Print instructions on screen
        love.graphics.setFont(textFont)
        love.graphics.print("To move side to side press:", uiX + 45, uiY + 52)
        love.graphics.print("A or Left Arrow to move Left", uiX + 45, uiY + 95)
        love.graphics.print("D or Right Arrow to move Right", uiX + 45, uiY + 138)
        love.graphics.print("W or Up Arrow to Jump", uiX + 45, uiY + 181)
        love.graphics.print("Press E to exit", uiX + 150, uiY + 430)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

local function loadLevel(mapPath)
    gameMap = sti(mapPath)

    collectSolidRects(gameMap)
    collectOrbs(gameMap)

    player.x, player.y = getSpawnPoint(gameMap)
    exitUnlocked = false
    orbsCollected = 0

    -- reload sign
    local signX, signY = getSignLocation(gameMap)
    signObject = (signX and signY) and { x = signX - 16, y = signY - 16, w = 32, h = 32 } or nil
    signUIActive = false

    -- reload exit
    local exitX, exitY = getExitLocation(gameMap)
    exitObject = (exitX and exitY) and { x = exitX - 16, y = exitY - 16, w = 64, h = 32 } or nil

    -- reload end trigger
    local endX, endY = getEndLocation(gameMap)
    endObject = (endX and endY) and { x = endX, y = endY, w = 64, h = 64 } or nil
end

function game:keypressed(key)
    -- Extra controls
    if (key == "space" or key == "up" or key == "w") then
        player.jumpRequested = true
    end

    if key == "r" then
        respawnPlayer()
        return
    end

    if key == "m" then
        if love.audio.getVolume() > 0 then
            love.audio.setVolume(0)
        else
            love.audio.setVolume(0.5) -- Default volume when unmuting
        end
    end

    if key == "-" then
        local currentVolume = love.audio.getVolume()
        love.audio.setVolume(math.max(0, currentVolume - 0.1))
    end

    if key == "=" then
        local currentVolume = love.audio.getVolume()
        love.audio.setVolume(math.min(1, currentVolume + 0.1))
    end

    if key == "escape" then
        Gamestate.push(pauseState)

    elseif signUIActive then
        if key == "e" or key == "return" or key == "space" then
            signUIActive = false
        end
        
    elseif key == "e" then
        if signObject then
            local playerRect = getPlayerRect(player)
            local signRect = { x = signObject.x, y = signObject.y, w = signObject.w, h = signObject.h }
            if rectsOverlap(playerRect, signRect) then
                signUIActive = true
                return
            end
        end
        if endObject then
            local playerRect = getPlayerRect(player)
            local endRect = { x = endObject.x, y = endObject.y, w = endObject.w, h = endObject.h }
            if rectsOverlap(playerRect, endRect) then
                if level == 4 then
                    Gamestate.push(endState)
                else
                    if level == 1 then
                        loadLevel('Map/Level_2.lua')
                        level = 2
                    elseif level == 2 then
                        loadLevel('Map/Level_3.lua')
                        level = 3
                    elseif level == 3 then
                        loadLevel('Map/Level_4.lua')
                        level = 4
                    end
                end
                return
            end
        end
        if exitObject and exitUnlocked then
            local playerRect = getPlayerRect(player)
            local exitRect = { x = exitObject.x, y = exitObject.y, w = exitObject.w, h = exitObject.h }
            if rectsOverlap(playerRect, exitRect) then
                -- Advance to next level or end game
                if level == 1 then
                    loadLevel('Map/Level_2.lua')
                    level = 2
                elseif level == 2 then
                    loadLevel('Map/Level_3.lua')
                    level = 3
                elseif level == 3 then
                    loadLevel('Map/Level_4.lua')
                    level = 4
                end
            end
        end
    end
end

function game:mousepressed(x, y, button)
end

function game:resize(w, h)
    if cam then
        cam:zoom(math.min(w / BASE_W, h / BASE_H))
    end
end

return game
