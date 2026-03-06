local assets = {}

function assets.load()
    assets.background = {
        backgroundCloud1 = love.graphics.newImage('Map/Background/Cloud_cover_1.png'),
        backgroundCloud2 = love.graphics.newImage('Map/Background/Cloud_cover_2.png'),
        backgroundHills = love.graphics.newImage('Map/Background/Hills.png'),
        backgroundSky = love.graphics.newImage('Map/Background/Sky_color.png'),
    }

    assets.tilesets = {
        grassEntities = love.graphics.newImage('Tiles/Grassland_entities.png'),
        terrain = love.graphics.newImage('Tiles/Terrain.png'),
        extraPlants = love.graphics.newImage('Tiles/Extra_plants.png'),
        tileset = love.graphics.newImage('Tiles/tileset.png'),
    }
end

return assets
