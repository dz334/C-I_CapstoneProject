local game = {}
local mapW = 0
local mapH = 0
local solids = {}
local elapsedTime = 0
local gameLoaded = false
local puzzleObject = nil
local puzzleUIActive = false
local puzzleInput = ""

-- Audio
isMuted = false
soundVolume = 0.1 -- range 0 to 1
themeMusic = nil

function applyVolume()
    if isMuted then
        love.audio.setVolume(0)
    else
        love.audio.setVolume(soundVolume)
    end
end

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
    return 400, 400
end

function game:enter()
    -- Only loads game when first entering gamestate
    if not gameLoaded then
        anim8 = require 'Libraries/anim8'
        camera = require 'Libraries/camera'
        sti = require 'Libraries/sti'

        love.graphics.setDefaultFilter('nearest', 'nearest') -- When art is scaled, keep it pixelated/clear

        cam = camera()
        gameMap = sti('Map/newtest1.lua')

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
        player.moveSpeed = 300
        player.jumpForce = 400
        player.gravity = 1100
        player.maxFallSpeed = 700
        player.isGrounded = false

        -- Sprite/animation setup
        player.spriteSheet = love.graphics.newImage('Sprites/player-sheet.png')
        player.grid = anim8.newGrid(12, 18, player.spriteSheet:getWidth(), player.spriteSheet:getHeight())

        player.animation = {}
        player.animation.down = anim8.newAnimation(player.grid('1-4', 1), 0.1)
        player.animation.left = anim8.newAnimation(player.grid('1-4', 2), 0.1)
        player.animation.right = anim8.newAnimation(player.grid('1-4', 3), 0.1)
        player.animation.up = anim8.newAnimation(player.grid('1-4', 4), 0.1)

        -- Load player facing right by default
        player.anim = player.animation.right

        -- Puzzle object placed near spawn (placeholder)
        local spawnX, spawnY = player.x, player.y
        puzzleObject = {
            x = spawnX + 80,
            y = spawnY - 40,
            w = 32,
            h = 32
        }
        puzzleUIActive = false
        puzzleInput = ""

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
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        moveX = 1
        player.anim = player.animation.right
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        moveX = -1
        player.anim = player.animation.left
    end

    -- Calculate horizontal velocity
    player.vx = moveX * player.moveSpeed

    -- Jump input (only if grounded)
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space"))
    and player.isGrounded then
        player.vy = -player.jumpForce
        player.isGrounded = false
    end

    -- Caculate vertical fall speed with gravity
    player.vy = math.min(player.vy + player.gravity * dt, player.maxFallSpeed)

    player.x = player.x + player.vx * dt
    resolveHorizontalCollisions(player)

    player.y = player.y + player.vy * dt
    resolveVerticalCollisions(player)

    -- Character idle animation when standing still on ground
    if moveX == 0 and player.isGrounded then
        player.anim:gotoFrame(2)
    end

    player.anim:update(dt)

    -- Follow player and clamp camera to map bounds
    cam:lookAt(player.x, player.y - player.h/2)
    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()
    cam.x = math.max(w/2, math.min(cam.x, mapW - w/2))
    cam.y = math.max(h/2, math.min(cam.y, mapH - h/2))

    -- Press "r" to reset position to spawn 
    if love.keyboard.isDown("r") then
        player.x, player.y = getSpawnPoint(gameMap)
    end    
end

function game:draw()
    cam:attach()
        drawBackgroundFixed(assets.background2.backgroundSky)
        drawBackgroundFixed(assets.background2.backgroundSand)
        drawBackgroundFixed(assets.background2.backgroundCloud3)
        drawBackgroundFixed(assets.background2.backgroundCloud2)
        drawBackgroundFixed(assets.background2.backgroundCloud1)
        gameMap:drawLayer(gameMap.layers["Ground"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 2, nil, 9, 16)

        -- Draw puzzle object placeholder
        if puzzleObject then
            love.graphics.setColor(1, 0.85, 0.2, 1)
            love.graphics.rectangle("fill", puzzleObject.x, puzzleObject.y, puzzleObject.w, puzzleObject.h)
            love.graphics.setColor(1, 1, 1, 1)
        end
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

    -- Puzzle UI placeholder
    if puzzleUIActive then
        local uiW, uiH = 420, 240
        local uiX = (love.graphics.getWidth() - uiW) / 2
        local uiY = (love.graphics.getHeight() - uiH) / 2
        love.graphics.setColor(0, 0, 0, 0.75)
        love.graphics.rectangle("fill", uiX, uiY, uiW, uiH)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("line", uiX, uiY, uiW, uiH)
        love.graphics.print("Puzzle UI (placeholder)", uiX + 16, uiY + 16)
        love.graphics.print("Input: " .. puzzleInput, uiX + 16, uiY + 64)
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
