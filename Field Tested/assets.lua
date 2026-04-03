local assets = {}

function assets.load()
    assets.background1 = {
        backgroundCloud1 = love.graphics.newImage('Tiles/Seaside/Background/Clouds_big.png'),
        backgroundCloud2 = love.graphics.newImage('Tiles/Seaside/Background/Clouds_medium.png'),
        backgroundCloud3 = love.graphics.newImage('Tiles/Seaside/Background/Clouds_small.png'),
        backgroundSand = love.graphics.newImage('Tiles/Seaside/Background/Sand.png'),
        backgroundSky = love.graphics.newImage('Tiles/Seaside/Background/Sky.png'),
        backgroundOcean = love.graphics.newImage('Tiles/Seaside/Background/Ocean.png')
    }
    
    assets.audio = {
        menuMusic = 'Sounds/theme.mp3',
        gameMusic = 'Sounds/AccumulaTown.mp3'
    }

    assets.sprite1 = {

    }

    assets.character1 = {

    }

    assets.character2 = {
        
    }

    assets.character3 = {
        idle = love.graphics.newImage('Sprites/Character3/Idle.png'),
        jump = love.graphics.newImage('Sprites/Character3/Jump.png'),
        run = love.graphics.newImage('Sprites/Character3/Run.png'),
        fall = love.graphics.newImage('Sprites/Character3/Fall.png'),
        doubleJump = love.graphics.newImage('Sprites/Character3/Double_Jump.png')
    }

    assets.character4 = {
        idleLeft = love.graphics.newImage('Sprites/Character4/IdleLeft.png'),
        idleRight = love.graphics.newImage('Sprites/Character4/IdleRight.png'),

        jumpLeft = love.graphics.newImage('Sprites/Character4/JumpLeft.png'),
        jumpRight = love.graphics.newImage('Sprites/Character4/JumpRight.png'),

        runLeft = love.graphics.newImage('Sprites/Character4/RunLeft.png'),
        runRight = love.graphics.newImage('Sprites/Character4/RunRight.png'),

        fallLeft = love.graphics.newImage('Sprites/Character4/FallLeft.png'),
        fallRight = love.graphics.newImage('Sprites/Character4/FallRight.png'),
        
        doubleJumpLeft = love.graphics.newImage('Sprites/Character4/Double_Jump_Left.png'),
        doubleJumpRight = love.graphics.newImage('Sprites/Character4/Double_Jump_Right.png')
    }

    assets.ui = {
        panel = love.graphics.newImage('Tiles/4.png')
    }

    assets.orb = {
        orbIdle = love.graphics.newImage('Tiles/key.png')
        --orbCollected = love.graphics.newImage('Tiles/vfx_effect_orb.png')
    }
end

return assets
