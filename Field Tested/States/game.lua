local game = {}
local mapW = 0
local mapH = 0
local solids = {}
local elapsedTime = 0
local gameLoaded = false
local puzzleObject = nil
local puzzleUIActive = false
local puzzleInput = ""

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
local function collectSolidRects(map)
    solids = {}
    local solidLayer = map.layers["Solid"]
    if not solidLayer or not solidLayer.objects then return end
    for _, obj in ipairs(solidLayer.objects) do
        if obj.shape == "rectangle" and obj.width > 0 and obj.height > 0 then
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

local function getSpawnPoint(map)
    local spawnLayer = map.layers["Spawn"]
    if spawnLayer and spawnLayer.objects and spawnLayer.objects[1] then
        return spawnLayer.objects[1].x, spawnLayer.objects[1].y
    end
end

local function getPuzzleLocation(map)
    local puzzleLayer = map.layers["Puzzle"]
        if puzzleLayer and puzzleLayer.objects and puzzleLayer.objects[1] then
        return puzzleLayer.objects[1].x, puzzleLayer.objects[1].y
    end
end

local function getSignLocation(map)
    local signsLayer = map.layers["Signs"]
        if signsLayer and signsLayer.objects and signsLayer.objects[1] then
        return signsLayer.objects[1].x, signsLayer.objects[1].y
    end
end

function game:enter()
    -- Only loads game when first entering gamestate
    if not gameLoaded then
        anim8 = require 'Libraries/anim8'
        camera = require 'Libraries/camera'
        sti = require 'Libraries/sti'

        cam = camera()
        cam:zoom(1.5)
        gameMap = sti('Map/Level_1.lua')

        -- Create the game music if it doesn't exist
        if not self.music then
            if love.filesystem.getInfo(assets.audio.gameMusic) then
                self.music = love.audio.newSource(assets.audio.gameMusic, 'stream')
                self.music:setLooping(true)
            end
        end

        -- Play only if not already playing
        if self.music and not self.music:isPlaying() then
            self.music:play()
            applyVolume()
        end

        -- Get map size (pixels) for camera clamping
        mapW = gameMap.width * gameMap.tilewidth
        mapH = gameMap.height * gameMap.tileheight

        -- Load collision map data
        collectSolidRects(gameMap)

        -- Player state and physics properties
        player = {}
        player.x, player.y = getSpawnPoint(gameMap)
        player.w, player.h = 24, 60
        player.vx, player.vy = 0, 0
        player.moveSpeed = 300 -- CHANGE SPEED
        player.jumpForce = 350
        player.gravity = 1100
        player.maxFallSpeed = 700
        player.isGrounded = false

        -- Sprite/animation setup
        local char = assets.character4
        player.animation = {}

        -- Idle
        player.idleRightSheet = char.idleRight
        player.idleLeftSheet  = char.idleLeft
        local idleRightGrid = anim8.newGrid(32, 32, char.idleRight:getWidth(), char.idleRight:getHeight())
        local idleLeftGrid  = anim8.newGrid(32, 32, char.idleLeft:getWidth(),  char.idleLeft:getHeight())

        -- Running 
        player.runRightSheet = char.runRight
        player.runLeftSheet  = char.runLeft
        local runRightGrid  = anim8.newGrid(32, 32, char.runRight:getWidth(),  char.runRight:getHeight())
        local runLeftGrid   = anim8.newGrid(32, 32, char.runLeft:getWidth(),   char.runLeft:getHeight())

        -- Jumping
        player.jumpRightSheet = char.jumpRight
        player.jumpLeftSheet  = char.jumpLeft
        local jumpRightGrid = anim8.newGrid(32, 32, char.jumpRight:getWidth(), char.jumpRight:getHeight())
        local jumpLeftGrid  = anim8.newGrid(32, 32, char.jumpLeft:getWidth(),  char.jumpLeft:getHeight())

        -- Falling
        player.fallRightSheet = char.fallRight
        player.fallLeftSheet  = char.fallLeft
        local fallRightGrid = anim8.newGrid(32, 32, char.fallRight:getWidth(), char.fallRight:getHeight())
        local fallLeftGrid  = anim8.newGrid(32, 32, char.fallLeft:getWidth(),  char.fallLeft:getHeight())

        -- Build animations
        player.animation.idleRight = anim8.newAnimation(idleRightGrid('1-11', 1), 0.08)
        player.animation.idleLeft  = anim8.newAnimation(idleLeftGrid('1-11',  1), 0.08)
        player.animation.runRight  = anim8.newAnimation(runRightGrid('1-12',  1), 0.07)
        player.animation.runLeft   = anim8.newAnimation(runLeftGrid('1-12',   1), 0.07)
        player.animation.jumpRight = anim8.newAnimation(jumpRightGrid('1-1', 1), 0.07)
        player.animation.jumpLeft  = anim8.newAnimation(jumpLeftGrid('1-1',  1), 0.07)
        player.animation.fallRight = anim8.newAnimation(fallRightGrid('1-1', 1), 0.07)
        player.animation.fallLeft  = anim8.newAnimation(fallLeftGrid('1-1',  1), 0.07)
        
        -- Default State
        player.anim = player.animation.idleRight
        player.animSheet = player.idleRightSheet
        player.facingRight = true

        -- Puzzle object placed near spawn (placeholder)
        local puzzleX, puzzleY = getPuzzleLocation(gameMap)
        if puzzleX and puzzleY then
            puzzleObject = {
                x = puzzleX - 16,
                y = puzzleY - 16,
                w = 32,
                h = 32
            }
        else
            puzzleObject = nil
        end
        puzzleUIActive = false
        puzzleInput = ""

        -- Puzzle object placed near spawn (placeholder)
        local signX, signY = getSignLocation(gameMap)
           if signX and signY then
            signObject = {
                x = signX - 16,
                y = signY - 16,
                w = 32,
                h = 32
            }
        else
            signObject = nil
        end

        gameLoaded = true
    end

    elapsedTime = 0
end


function game:leave()
    -- Stop game music when leaving game state
    if self.music and self.music:isPlaying() then
        self.music:stop()
    end
end

function game:update(dt)
    elapsedTime = elapsedTime + dt

    if puzzleUIActive then
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
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space"))
    and player.isGrounded then
        player.vy = -player.jumpForce
        player.isGrounded = false
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

    -- Caculate vertical fall speed with gravity
    player.vy = math.min(player.vy + player.gravity * dt, player.maxFallSpeed)

    player.x = player.x + player.vx * dt
    resolveHorizontalCollisions(player)

    player.y = player.y + player.vy * dt
    resolveVerticalCollisions(player)

    player.anim:update(dt)

    -- Follow player and clamp camera to map bounds
    cam:lookAt(player.x, player.y - player.h/2)
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

    -- Press "r" to reset position to spawn 
    if love.keyboard.isDown("r") then
        player.x, player.y = getSpawnPoint(gameMap)
    end    
end

function game:draw()
    drawBackground(assets.background2.backgroundSky, 0.05)
    drawBackground(assets.background2.backgroundSand, 0.1)
    drawBackground(assets.background2.backgroundCloud3, 0.2)
    drawBackground(assets.background2.backgroundCloud2, 0.3)
    drawBackground(assets.background2.backgroundCloud1, 0.4)
    
    cam:attach()
        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Player Jump Platforms"])
        gameMap:drawLayer(gameMap.layers["SignsIMG"])
        gameMap:drawLayer(gameMap.layers["PuzzleIMG"])
        player.anim:draw(player.animSheet, player.x, player.y, nil, 1.5, nil, 16, 32)

        -- Draw puzzle object placeholder
        -- if puzzleObject then
        --     love.graphics.setColor(1, 0.85, 0.2, 1)
        --     love.graphics.rectangle("fill", puzzleObject.x, puzzleObject.y, puzzleObject.w, puzzleObject.h)
        --     love.graphics.setColor(1, 1, 1, 1)
        -- end
    cam:detach()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Time: %.1f", elapsedTime), 10, 16)
    love.graphics.print("ESC = Pause", 10, 40)
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 64)
    love.graphics.print("Press R to reset", 10, 88)

    -- UI prompt when near puzzle object
    if puzzleObject and not puzzleUIActive then
        local playerRect = getPlayerRect(player)
        local objRect = { x = puzzleObject.x, y = puzzleObject.y, w = puzzleObject.w, h = puzzleObject.h }
        if rectsOverlap(playerRect, objRect) then
            love.graphics.print("Press E to open puzzle UI", 10, 112)
        end
    end

    -- UI prompt when near sign object
    if signObject and not signUIActive then
        local playerRect = getPlayerRect(player)
        local signRect = { x = signObject.x, y = signObject.y, w = signObject.w, h = signObject.h }
        if rectsOverlap(playerRect, signRect) then
            love.graphics.print("Press E to read sign", 10, 112)
        end
    end

    -- Puzzle UI placeholder
    if puzzleUIActive or signUIActive then
        local uiW, uiH = 420, 240
        local uiX = (love.graphics.getWidth() - uiW) / 2
        local uiY = (love.graphics.getHeight() - uiH) / 2
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", uiX, uiY, uiW, uiH)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", uiX, uiY, uiW, uiH)

        if puzzleUIActive then
            love.graphics.print("Puzzle UI (placeholder)", uiX + 16, uiY + 16)
            love.graphics.print("Input: " .. puzzleInput, uiX + 16, uiY + 64)
        else
            love.graphics.print("Sign UI (placeholder)", uiX + 16, uiY + 16)
        end
    end
end

function game:keypressed(key)
    if key == "escape" then
        --Gamestate.push(require 'states/pause')
        Gamestate.switch(require 'states/pause')

    elseif puzzleUIActive then
        if key == "backspace" then
            puzzleInput = puzzleInput:sub(1, -2)
        elseif key == "return" then
            if puzzleInput:lower() == "done" then
                puzzleUIActive = false
                puzzleInput = ""
            end
        end
    elseif key == "e" then
        if puzzleObject then
            local playerRect = getPlayerRect(player)
            local objRect = { x = puzzleObject.x, y = puzzleObject.y, w = puzzleObject.w, h = puzzleObject.h }
            if rectsOverlap(playerRect, objRect) then
                puzzleUIActive = true
                puzzleInput = ""
            end
        elseif signObject then
            local playerRect = getPlayerRect(player)
            local signRect = { x = signObject.x, y = signObject.y, w = signObject.w, h = signObject.h }
            if rectsOverlap(playerRect, signRect) then
                signUIActive = true
            end
        end
    end
end

function game:textinput(t)
    if puzzleUIActive then
        puzzleInput = puzzleInput .. t
    end
end

function game:mousepressed(x, y, button)
end

return game
