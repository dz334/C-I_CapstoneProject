local menu = require("mainmenu")
local settingsMenu = require("settingsmenu")
local gameState = "menu"

local assets = require("assets") 

local mapW = 0
local mapH = 0
local solids = {}
local gameLoaded = false
local elapsedTime = 0

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

-- Resolve collisions after vertical movement
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

local function loadGame()
    -- Libraries and core systems.
    anim8 = require 'Libraries/anim8'
    love.graphics.setDefaultFilter('nearest', 'nearest') -- When art is scaled, keep it pixelated/clear


    camera = require 'Libraries/camera'
    cam = camera()

    sti = require 'Libraries/sti'
    gameMap = sti('Map/testmap3.lua')

    -- Cached map size (pixels) for camera clamping
    mapW = gameMap.width * gameMap.tilewidth
    mapH = gameMap.height * gameMap.tileheight

    -- Load collision map data
    collectSolidRects(gameMap)

    -- Player state and platformer physics tuning
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
    gameLoaded = true
end

function love.load()
    assets.load()

    menu.load({
        startGame = function()
            gameState = "game"
            elapsedTime = 0
            if not gameLoaded then
                loadGame()
            end
        end,
        loadGame = function()
            print("Loading game")
        end,
        settings = function()
            gameState = "settings"
        end
    })

    settingsMenu.load({
        back = function()
            gameState = "menu"
        end
    })
end

function love.update(dt)
    if gameState == "menu" then
        menu.update(dt)
        return
    end

    if gameState == "settings" then
        settingsMenu.update(dt)
        return
    end

    elapsedTime = elapsedTime + dt


    -- Horizontal input
    local moveX = 0
    if love.keyboard.isDown("right") or love.keyboard.isDown("d") then
        moveX = 1
        player.anim = player.animation.right
    elseif love.keyboard.isDown("left") or love.keyboard.isDown("a") then
        moveX = -1
        player.anim = player.animation.left
    end

    -- calculate horizontal velocity from input
    player.vx = moveX * player.moveSpeed

    -- Jump only while grounded
    if (love.keyboard.isDown("up") or love.keyboard.isDown("w") or love.keyboard.isDown("space")) and player.isGrounded then
        player.vy = -player.jumpForce
        player.isGrounded = false
    end

    -- Gravity integration with fall speed
    player.vy = math.min(player.vy + player.gravity * dt, player.maxFallSpeed)

    player.x = player.x + player.vx * dt
    resolveHorizontalCollisions(player)

    player.y = player.y + player.vy * dt
    resolveVerticalCollisions(player)

    -- Idle animation frame when standing still on ground
    if moveX == 0 and player.isGrounded then
        player.anim:gotoFrame(2)
    end

    player.anim:update(dt)

    -- Follow player and clamp camera to map bounds
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

function love.mousepressed(x, y, button)
    if gameState == "menu" then
        menu.mousepressed(x, y, button)
        return
    end

    if gameState == "settings" then
        settingsMenu.mousepressed(x, y, button)
        return
    end
end

function love.draw()
    if gameState == "menu" then
        drawBackgroundFixed(assets.background.backgroundSky)
        drawBackgroundFixed(assets.background.backgroundHills)
        drawBackgroundFixed(assets.background.backgroundCloud2)
        drawBackgroundFixed(assets.background.backgroundCloud1)
        menu.draw()
        return
    end

    if gameState == "settings" then
        drawBackgroundFixed(assets.background.backgroundSky)
        drawBackgroundFixed(assets.background.backgroundHills)
        drawBackgroundFixed(assets.background.backgroundCloud2)
        drawBackgroundFixed(assets.background.backgroundCloud1)
        settingsMenu.draw()
        return
    end
    
    cam:attach()
        -- Background layers.
        drawBackgroundFixed(assets.background.backgroundSky)
        drawBackgroundFixed(assets.background.backgroundHills)
        drawBackgroundFixed(assets.background.backgroundCloud2)
        drawBackgroundFixed(assets.background.backgroundCloud1)

        -- Foreground gameplay layers and player sprite.
        gameMap:drawLayer(gameMap.layers["Ground"])
        gameMap:drawLayer(gameMap.layers["Trees"])
        player.anim:draw(player.spriteSheet, player.x, player.y, nil, 4, nil, 6, 9)
    cam:detach()

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(string.format("Time: %.1f", elapsedTime), 16, 16)
end
