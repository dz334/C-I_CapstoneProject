local assets = require("assets") 

local mapW = 0
local mapH = 0
local solids = {}

local BG_W = 1920
local BG_H = 640

local function drawBackgroundFixed(image)
    local scaleX = BG_W / image:getWidth()
    local scaleY = BG_H / image:getHeight()
    love.graphics.draw(image, 0, BG_H, 0, scaleX, scaleY, 0, image:getHeight())
end


-- Basic overlap check for collision
local function rectsOverlap(a, b)
    return a.x < b.x + b.w
        and a.x + a.w > b.x
        and a.y < b.y + b.h
        and a.y + a.h > b.y
end

-- Read rectangle objects from the "Solid" map layer 
local function collectSolidRects(map)
    solids = {}
    local solidLayer = map.layers["Solid"]
    if not solidLayer or not solidLayer.objects then
        return
    end

    for _, obj in ipairs(solidLayer.objects) do
        if obj.shape == "rectangle" and obj.width > 0 and obj.height > 0 then
            table.insert(solids, {
                x = obj.x,
                y = obj.y,
                w = obj.width,
                h = obj.height
            })
        end
    end
end

-- Resolve collisions after horizontal movement
local function resolveHorizontalCollisions(p)
    local playerRect = { x = p.x - p.w / 2, y = p.y - p.h, w = p.w, h = p.h }

    for _, r in ipairs(solids) do
        if rectsOverlap(playerRect, r) then
            if p.vx > 0 then
                playerRect.x = r.x - playerRect.w
            elseif p.vx < 0 then
                playerRect.x = r.x + r.w
            end
            p.vx = 0
            p.x = playerRect.x + p.w / 2
        end
    end
end

-- Resolve collisions after vertical movement and update grounded state
local function resolveVerticalCollisions(p)
    local playerRect = { x = p.x - p.w / 2, y = p.y - p.h, w = p.w, h = p.h }
    p.isGrounded = false

    for _, r in ipairs(solids) do
        if rectsOverlap(playerRect, r) then
            if p.vy > 0 then
                playerRect.y = r.y - playerRect.h
                p.isGrounded = true
            elseif p.vy < 0 then
                playerRect.y = r.y + r.h
            end
            p.vy = 0
            p.y = playerRect.y + p.h
        end
    end
end

function love.load()
    -- Import libraries and core systems.
    anim8 = require 'Libraries/anim8'
    love.graphics.setDefaultFilter('nearest', 'nearest') --When art is scaled, keep it pixelated/clear


    camera = require 'Libraries/camera'
    cam = camera()

    sti = require 'Libraries/sti'
    gameMap = sti('Map/testmap3.lua')

    -- Get map size for keeping camera attached
    mapW = gameMap.width * gameMap.tilewidth
    mapH = gameMap.height * gameMap.tileheight

    -- Load collision map data and image assets
    collectSolidRects(gameMap)
    assets.load()

    -- Player state and physics
    player = {}
    player.x = 400
    player.y = 300

    player.w = 24
    player.h = 60

    player.vx = 0
    player.vy = 0
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
end

function love.update(dt)
    -- Horizontal controls 
    local moveX = 0
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        moveX = 1
        player.anim = player.animation.right
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        moveX = -1
        player.anim = player.animation.left
    end

    -- Calculate player horizontal speed
    player.vx = moveX * player.moveSpeed

    -- Jump only if while grounded.
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) and player.isGrounded then
        player.vy = -player.jumpForce
        player.isGrounded = false
    end

    -- Calculate gravity and fall speed
    player.vy = math.min(player.vy + player.gravity * dt, player.maxFallSpeed)

    player.x = player.x + player.vx * dt
    resolveHorizontalCollisions(player)

    player.y = player.y + player.vy * dt
    resolveVerticalCollisions(player)

    -- Player sprite idle animation frame 
    if moveX == 0 and player.isGrounded then
        player.anim:gotoFrame(2)
    end

    player.anim:update(dt)

    -- Attach camera to player
    cam:lookAt(player.x, player.y - player.h / 2)

    local w = love.graphics.getWidth()
    local h = love.graphics.getHeight()

    if cam.x < w / 2 then
        cam.x = w / 2
    end
    if cam.y < h / 2 then
        cam.y = h / 2
    end

    if cam.x > (mapW - w / 2) then
        cam.x = mapW - w / 2
    end
    if cam.y > (mapH - h / 2) then
        cam.y = mapH - h / 2
    end
end

function love.draw()
    cam:attach()
        -- Background layers.
        drawBackgroundFixed(assets.background.backgroundSky)
        drawBackgroundFixed(assets.background.backgroundHills)
        drawBackgroundFixed(assets.background.backgroundCloud2)
        drawBackgroundFixed(assets.background.backgroundCloud1)

        -- Foreground gameplay layers and player sprite
        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Trees"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 4, nil, 6, 9)
    cam:detach()
end
