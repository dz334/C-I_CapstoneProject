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

    assets.character1 = {
        idleLeft = love.graphics.newImage('Sprites/Character1/IdleLeft.png'),
        idleRight = love.graphics.newImage('Sprites/Character1/IdleRight.png'),

        jumpLeft = love.graphics.newImage('Sprites/Character1/JumpLeft.png'),
        jumpRight = love.graphics.newImage('Sprites/Character1/JumpRight.png'),

        runLeft = love.graphics.newImage('Sprites/Character1/RunLeft.png'),
        runRight = love.graphics.newImage('Sprites/Character1/RunRight.png'),

        fallLeft = love.graphics.newImage('Sprites/Character1/FallLeft.png'),
        fallRight = love.graphics.newImage('Sprites/Character1/FallRight.png'),
        
        doubleJumpLeft = love.graphics.newImage('Sprites/Character1/Double_Jump_Left.png'),
        doubleJumpRight = love.graphics.newImage('Sprites/Character1/Double_Jump_Right.png')
    }

    assets.character2 = {
        idleLeft = love.graphics.newImage('Sprites/Character2/IdleLeft.png'),
        idleRight = love.graphics.newImage('Sprites/Character2/IdleRight.png'),

        jumpLeft = love.graphics.newImage('Sprites/Character2/JumpLeft.png'),
        jumpRight = love.graphics.newImage('Sprites/Character2/JumpRight.png'),

        runLeft = love.graphics.newImage('Sprites/Character2/RunLeft.png'),
        runRight = love.graphics.newImage('Sprites/Character2/RunRight.png'),

        fallLeft = love.graphics.newImage('Sprites/Character2/FallLeft.png'),
        fallRight = love.graphics.newImage('Sprites/Character2/FallRight.png'),
        
        doubleJumpLeft = love.graphics.newImage('Sprites/Character2/Double_Jump_Left.png'),
        doubleJumpRight = love.graphics.newImage('Sprites/Character2/Double_Jump_Right.png')
    }

    assets.character3 = {
        idleLeft = love.graphics.newImage('Sprites/Character3/IdleLeft.png'),
        idleRight = love.graphics.newImage('Sprites/Character3/IdleRight.png'),

        jumpLeft = love.graphics.newImage('Sprites/Character3/JumpLeft.png'),
        jumpRight = love.graphics.newImage('Sprites/Character3/JumpRight.png'),

        runLeft = love.graphics.newImage('Sprites/Character3/RunLeft.png'),
        runRight = love.graphics.newImage('Sprites/Character3/RunRight.png'),

        fallLeft = love.graphics.newImage('Sprites/Character3/FallLeft.png'),
        fallRight = love.graphics.newImage('Sprites/Character3/FallRight.png'),
        
        doubleJumpLeft = love.graphics.newImage('Sprites/Character3/Double_Jump_Left.png'),
        doubleJumpRight = love.graphics.newImage('Sprites/Character3/Double_Jump_Right.png')
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
end

return assets
