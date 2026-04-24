- STEP 1: The "Assets" Table (Translating your LÖVE logic)
local assets = {
    character1 = 'character1', 
    character2 = 'character2', 
    character3 = 'character3',
    character4 = 'character4'
}

-- STEP 5 (Prep): Variable to hold the choice
local selectedSprite = ''
local inCharSelect = true
local allowCountdown = false

function onCreate()
    -- STEP 2 & 3: Make buttons and add pictures
    -- We'll place 4 buttons across the screen
    for i = 1, 4 do
        local tag = 'btn' .. i
        makeAnimatedLuaSprite(tag, 'androidcontrols/virtualbuttons', (i * 250) - 150, 300)
        addAnimationByPrefix(tag, 'idle', 'a', 24, true) -- Default button visual
        addAnimationByPrefix(tag, 'press', 'aPressed', 24, false)
        setObjectCamera(tag, 'other')
        addLuaSprite(tag, true)
    end
    
    -- Optional: Text to show who you are picking
    makeLuaText('desc', 'Select Your Character', 0, 0, 100)
    setTextSize('desc', 40)
    screenCenter('desc', 'x')
    addLuaText('desc')
end

function onUpdate(dt)
    if not inCharSelect then return end

    -- STEP 4: Function to take in button click input
    if mouseClicked('left') then
        for i = 1, 4 do
            local tag = 'btn' .. i
            if mouseOver(tag) then
                objectPlayAnimation(tag, 'press', false)
                
                -- STEP 5: Set var of sprite selected
                selectedSprite = assets['character' .. i] 
                
                confirmSelection()
            end
        end
    end
end

function confirmSelection()
    -- STEP 6: Call that function/variable for game.lua
    setVar('playerSelectedSprite', selectedSprite)
    
    -- Clean up and start the game
    inCharSelect = false
    playSound('confirmMenu', 1)
    
    -- Remove UI
    for i = 1, 4 do removeLuaSprite('btn' .. i, true) end
    removeLuaText('desc', true)
    
    startCountdown()
end

-- STEP 1 (Logic): Block the game start until selection is made
function onStartCountdown()
    if not allowCountdown then
        allowCountdown = true
        return Function_Stop
    end
    return Function_Continue
end

-- HELPER: Detection logic
function mouseOver(tag)
    local x, y = getProperty(tag .. '.x'), getProperty(tag .. '.y')
    local w, h = getProperty(tag .. '.width'), getProperty(tag .. '.height')
    return (getMouseX('other') > x and getMouseX('other') < x + w and
            getMouseY('other') > y and getMouseY('other') < y + h)
end
