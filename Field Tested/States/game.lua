local game = {}
local mapW = 0
local mapH = 0
local solids = {}
local elapsedTime = 0
local gameLoaded = false

-- Check for overlap and collisions between player and solids
local function rectsOverlap(a, b)
    return a.x < b.x + b.w
       and a.x + a.w > b.x
       and a.y < b.y + b.h
       and a.y + a.h > b.y
end

-- Read rectangle objects from Tilted "Solid" map layer
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

function game:enter()
    -- Only loads game when first entering gamestate
    if not gameLoaded then
        anim8 = require 'Libraries/anim8'
        camera = require 'Libraries/camera'
        sti = require 'Libraries/sti'

        love.graphics.setDefaultFilter('nearest', 'nearest') -- When art is scaled, keep it pixelated/clear

        cam = camera()
        gameMap = sti('Map/testmap3.lua')

        -- Stop menu music when entering game
        if themeMusic then
            themeMusic:stop()
        end

        -- Start gameplay background music
        if love.filesystem.getInfo(assets.audio.gameMusic) then
            gameMusic = love.audio.newSource("Sounds/AccumulaTown.mp3", "stream")
        end 
        gameMusic:setLooping(true)
        gameMusic:play()
        applyVolume()
        

        -- Get map size (pixels) for camera clamping
        mapW = gameMap.width * gameMap.tilewidth
        mapH = gameMap.height * gameMap.tileheight

        -- Load collision map data
        collectSolidRects(gameMap)

        -- Player state and physics properties
        player = {}
        player.x, player.y = 400, 300
        player.w, player.h = 24, 60
        player.vx, player.vy = 0, 0
        player.moveSpeed = 180
        player.jumpForce = 420
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

        player.anim = player.animation.right
        gameLoaded = true
    end

    elapsedTime = 0
end

function game:update(dt)
    elapsedTime = elapsedTime + dt

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
end

function game:draw()
    cam:attach()
        drawBackgroundFixed(assets.background.backgroundSky)
        drawBackgroundFixed(assets.background.backgroundHills)
        drawBackgroundFixed(assets.background.backgroundCloud2)
        drawBackgroundFixed(assets.background.backgroundCloud1)
        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Trees"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 4, nil, 6, 9)
    cam:detach()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Time: %.1f", elapsedTime), 16, 16)
    love.graphics.print("ESC = Pause", 16, 40)
end

function game:keypressed(key)
    if key == "escape" then
        Gamestate.push(require 'states/pause')
    end
end

function game:mousepressed(x, y, button)
end

return game
