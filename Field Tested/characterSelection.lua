

function onUpdate(dt)
    if not inCharSelect then return end

    function onUpdate(dt)
    if not inCharSelect then return end

    -- RIGHT BUTTON
    if mouseClicked('left') and mouseOver('right') then
        navigate(1)
        objectPlayAnimation('right', 'rightPress', false)
    else
        objectPlayAnimation('right', 'right', true)
    end

    -- LEFT BUTTON
    if mouseClicked('left') and mouseOver('left') then
        navigate(-1)
        objectPlayAnimation('left', 'leftPress', false)
    else
        objectPlayAnimation('left', 'left', true)
    end

    -- ACCEPT CLICK (A Button)
    if mouseClicked('left') and mouseOver('a') then
        confirmSelection() -- Calls the helper function below
    end

    -- CANCEL CLICK (B Button)
    if mouseClicked('left') and mouseOver('b') then
        exitSelector('cancelMenu') -- Calls the exit helper
    end
    
    -- HOVER EFFECTS (Optional visual juice)
    local buttons = {'left', 'right', 'a', 'b'}
    for _, btn in ipairs(buttons) do
        if mouseOver(btn) then
            setProperty(btn .. '.alpha', 1.0)
        else
            setProperty(btn .. '.alpha', 0.7)
        end
    end
end

function onUpdatePost(elapsed)
    if inCharSelect then
        -- Update the display text and icon based on current data
        local currentSet = charData.variations[variation]
        setTextString('char', currentSet.name[page])
        objectPlayAnimation('iconGrid', currentSet.json[page], false)
        screenCenter('char', 'x')
    end
end

function navigate(dir)
    page = page + dir
    if page > 3 then page = 1 elseif page < 1 then page = 3 end
    playSound('scrollMenu', 1)
end

function confirmSelection()
    local finalChar = charData.variations[variation].json[page]
    triggerEvent('Change Character', 0, finalChar)
    exitSelector('confirmMenu')
end

function exitSelector(sound)
    inCharSelect = false
    setProperty('camHUD.visible', true)
    playSound(sound, 1)
    startCountdown()
end

-- Boilerplate to start the whole process
function onStartCountdown()
    if not allowCountdown then
        loadSelector()
        runTimer('charSelector', 0.8)
        allowCountdown = true
        return Function_Stop
    end
    return Function_Continue
end

function onTimerCompleted(tag)
    if tag == 'charSelector' then inCharSelect = true end
end

function mouseOver(tag)
    -- Get sprite properties
    local x = getProperty(tag .. '.x')
    local y = getProperty(tag .. '.y')
    local w = getProperty(tag .. '.width')
    local h = getProperty(tag .. '.height')

    -- Check if Mouse is within the boundaries
    if getMouseX('other') > x and getMouseX('other') < (x + w) and
       getMouseY('other') > y and getMouseY('other') < (y + h) then
        return true
    end
    return false
end
