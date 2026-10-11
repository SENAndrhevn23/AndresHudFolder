-- Configuration for positions
local boxHeight = 35
local boxGap = 8 

-- Y positions
local botplayBoxY = 10
local normalBoxY = 640 -- Adjusted for near the bottom of the screen (default screen height is usually 720)

local fontSize = 16
local MAX_INITIAL_WIDTH = 500 

-- Stats tracking variables
local playerCombo = 0
local opponentCombo = 0
local totalCombo = 0

local playerHitTimes = {}
local opponentHitTimes = {}
local maxPlayerNPS = 0
local maxOpponentNPS = 0

-- Color definitions (Player dark blue background, light blue for borders/text highlights)
local playerBgColor = '1A4D66' 
local playerBorderColor = '33CCFF'
local defaultOppColor = 'A349A4'

function onCreatePost()
    local initialY = botplay and botplayBoxY or normalBoxY

    -- 1. Create the graphic boxes and brackets FIRST so they sit underneath
    createTargetHudBox('boxLeft', initialY)
    createTargetHudBox('boxMidLeft', initialY)
    createTargetHudBox('boxMiddle', initialY)
    createTargetHudBox('boxMidRight', initialY)
    createTargetHudBox('boxRight', initialY)

    -- 2. Create the text layers LAST so they render on top of the boxes
    createHudText('textLeft', '0 / 0', initialY)
    createHudText('textMidLeft', '0', initialY)
    createHudText('textMiddle', '0', initialY)
    createHudText('textMidRight', '0', initialY)
    createHudText('textRight', '0 / 0', initialY)
end

-- Formats numbers to include commas (e.g., 11884 -> 11,884)
function formatWithCommas(amount)
    local formatted = tostring(amount)
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k==0) then
            break
        end
    end
    return formatted
end

function createTargetHudBox(tag, currentY)
    local targetCam = 'other'

    -- Graphic base
    makeLuaSprite(tag, '', 0, currentY)
    makeGraphic(tag, MAX_INITIAL_WIDTH, boxHeight, 'FFFFFF')
    setObjectCamera(tag, targetCam)
    setProperty(tag .. '.alpha', 0.75) -- Slightly higher alpha for rich dark tones
    addLuaSprite(tag, true)
    
    -- Underline graphic
    makeLuaSprite(tag .. 'Line', '', 0, currentY + boxHeight - 8)
    makeGraphic(tag .. 'Line', MAX_INITIAL_WIDTH, 2, 'FFFFFF') 
    setObjectCamera(tag .. 'Line', targetCam)
    addLuaSprite(tag .. 'Line', true)

    -- Static Thickness / Size config for brackets
    local bracketSize = 8
    local thickness = 2
    
    local function drawLine(name, lw, lh)
        makeLuaSprite(name, '', 0, 0)
        makeGraphic(name, lw, lh, 'FFFFFF')
        setObjectCamera(name, targetCam)
        addLuaSprite(name, true)
    end

    -- Create bracket lines
    drawLine(tag .. 'TL_H', bracketSize, thickness)
    drawLine(tag .. 'TL_V', thickness, bracketSize)
    drawLine(tag .. 'TR_H', bracketSize, thickness)
    drawLine(tag .. 'TR_V', thickness, bracketSize)
    drawLine(tag .. 'BL_H', bracketSize, thickness)
    drawLine(tag .. 'BL_V', thickness, bracketSize)
    drawLine(tag .. 'BR_H', bracketSize, thickness)
    drawLine(tag .. 'BR_V', thickness, bracketSize)
end

function createHudText(tag, defaultText, currentY)
    makeLuaText(tag, defaultText, 0, 0, currentY + 5)
    setTextSize(tag, fontSize)
    setTextFont(tag, 'vcr.ttf')
    setTextAlignment(tag, 'center')
    setObjectCamera(tag, 'other')
    addLuaText(tag) 
end

-- Helper logic to scale, snap, and colorize elements with separate BG and Border colors
function updateBoxPositionAndWidth(tag, x, width, bgHex, borderHex, isBlackBg, currentY)
    local bracketSize = 8
    local thickness = 2
    local linePadding = 12

    -- Scale background
    setProperty(tag .. '.scale.x', width / MAX_INITIAL_WIDTH)
    updateHitbox(tag)
    setProperty(tag .. '.x', x)
    setProperty(tag .. '.y', currentY)
    
    if isBlackBg then
        setProperty(tag .. '.color', getColorFromHex('000000'))
        setProperty(tag .. '.alpha', 0.6)
    else
        setProperty(tag .. '.color', getColorFromHex(bgHex))
        setProperty(tag .. '.alpha', 0.75)
    end

    -- Scale and color underline
    local targetLineWidth = width - (linePadding * 2)
    setProperty(tag .. 'Line.scale.x', targetLineWidth / MAX_INITIAL_WIDTH)
    updateHitbox(tag .. 'Line')
    setProperty(tag .. 'Line.x', x + linePadding)
    setProperty(tag .. 'Line.y', currentY + boxHeight - 8)
    setProperty(tag .. 'Line.color', getColorFromHex(borderHex))

    -- Reposition and color Brackets
    local brackets = {'TL_H', 'TL_V', 'TR_H', 'TR_V', 'BL_H', 'BL_V', 'BR_H', 'BR_V'}
    for _, b in ipairs(brackets) do
        setProperty(tag .. b .. '.color', getColorFromHex(borderHex))
    end

    setProperty(tag .. 'TL_H.x', x)
    setProperty(tag .. 'TL_H.y', currentY)
    setProperty(tag .. 'TL_V.x', x)
    setProperty(tag .. 'TL_V.y', currentY)

    setProperty(tag .. 'TR_H.x', x + width - bracketSize)
    setProperty(tag .. 'TR_H.y', currentY)
    setProperty(tag .. 'TR_V.x', x + width - thickness)
    setProperty(tag .. 'TR_V.y', currentY)

    setProperty(tag .. 'BL_H.x', x)
    setProperty(tag .. 'BL_H.y', currentY + boxHeight - thickness)
    setProperty(tag .. 'BL_V.x', x)
    setProperty(tag .. 'BL_V.y', currentY + boxHeight - bracketSize)

    setProperty(tag .. 'BR_H.x', x + width - bracketSize)
    setProperty(tag .. 'BR_H.y', currentY + boxHeight - thickness)
    setProperty(tag .. 'BR_V.x', x + width - thickness)
    setProperty(tag .. 'BR_V.y', currentY + boxHeight - bracketSize)
end

-- Converts RGB array to Hexadecimal string format
function rgbToHex(rgb)
    return string.format('%02x%02x%02x', rgb[1], rgb[2], rgb[3])
end

-- Darkens an RGB color array so it serves as a nice dark background tone
function getDarkenedColorHex(rgb)
    local r = math.floor(rgb[1] * 0.35)
    local g = math.floor(rgb[2] * 0.35)
    local b = math.floor(rgb[3] * 0.35)
    return string.format('%02x%02x%02x', r, g, b)
end

-- Gets current opponent color array safely
function getActiveOpponentColorArray()
    if mustHitSections then
        if gfSection and getProperty('gf') then
            return getProperty('gf.healthColorArray')
        end
    else
        if gfSection and getProperty('gf') then
            return getProperty('gf.healthColorArray')
        elseif getProperty('dad') then
            return getProperty('dad.healthColorArray')
        end
    end
    
    local success, currentDadColor = pcall(getProperty, 'dad.healthColorArray')
    if success and currentDadColor then
        return currentDadColor
    end
    return {163, 73, 164} -- Fallback purple RGB
end

function goodNoteHit(id, noteData, noteType, isSustainNote)
    if not isSustainNote then
        playerCombo = playerCombo + 1
        totalCombo = totalCombo + 1
        table.insert(playerHitTimes, getSongPosition())
    end
end

function noteMiss(id, noteData, noteType, isSustainNote)
    playerCombo = 0
end

function opponentNoteHit(id, noteData, noteType, isSustainNote)
    if not isSustainNote then
        opponentCombo = opponentCombo + 1
        totalCombo = totalCombo + 1
        table.insert(opponentHitTimes, getSongPosition())
    end
end

function onUpdate(elapsed)
    local songPos = getSongPosition()
    local currentY = botplay and botplayBoxY or normalBoxY
    
    while #playerHitTimes > 0 and songPos - playerHitTimes[1] > 1000 do table.remove(playerHitTimes, 1) end
    local playerNPS = #playerHitTimes
    if playerNPS > maxPlayerNPS then maxPlayerNPS = playerNPS end

    while #opponentHitTimes > 0 and songPos - opponentHitTimes[1] > 1000 do table.remove(opponentHitTimes, 1) end
    local opponentNPS = #opponentHitTimes
    if opponentNPS > maxOpponentNPS then maxOpponentNPS = opponentNPS end

    -- Check if Botplay is active
    if botplay then
        -- Botplay layout: show NPS and Combo counters across all 5 boxes
        setTextString('textLeft', formatWithCommas(opponentNPS) .. ' / ' .. formatWithCommas(maxOpponentNPS))
        setTextString('textMidLeft', formatWithCommas(opponentCombo))
        setTextString('textMiddle', formatWithCommas(totalCombo))
        setTextString('textMidRight', formatWithCommas(playerCombo))
        setTextString('textRight', formatWithCommas(playerNPS) .. ' / ' .. formatWithCommas(maxPlayerNPS))
    else
        -- Regular play layout: only use the middle box for Score/Misses/Accuracy, hide the side boxes
        local score = getProperty('songScore') or 0
        local misses = getProperty('songMisses') or 0
        local ratingPercent = math.floor((getProperty('ratingPercent') or 0) * 100 + 0.5)

        setTextString('textLeft', '')
        setTextString('textMidLeft', '')
        setTextString('textMiddle', string.format('[Score: %s] [Misses: %d] [Accuracy: %d%%]', formatWithCommas(score), misses, ratingPercent))
        setTextString('textMidRight', '')
        setTextString('textRight', '')
    end

    -- 2. Measure widths
    local padding = 28
    local leftWidth = (botplay and getProperty('textLeft.fieldWidth') or 0) + padding
    local midLeftWidth = (botplay and getProperty('textMidLeft.fieldWidth') or 0) + padding
    local midWidth = getProperty('textMiddle.fieldWidth') + padding
    local midRightWidth = (botplay and getProperty('textMidRight.fieldWidth') or 0) + padding
    local rightWidth = (botplay and getProperty('textRight.fieldWidth') or 0) + padding

    -- 3. Layout centering math for 5 boxes (or single middle box if not botplay)
    local midX = (screenWidth / 2) - (midWidth / 2)
    local midLeftX = midX - midLeftWidth - boxGap
    local leftX = midLeftX - leftWidth - boxGap
    
    local midRightX = midX + midWidth + boxGap
    local rightX = midRightX + midRightWidth + boxGap

    -- 4. Get active opponent color information
    local oppColorArr = getActiveOpponentColorArray()
    local oppBorderHex = rgbToHex(oppColorArr)
    local oppBgHex = getDarkenedColorHex(oppColorArr)

    -- 5. Apply layout color updates and visibility depending on botplay status
    if botplay then
        updateBoxPositionAndWidth('boxLeft', leftX, leftWidth, oppBgHex, oppBorderHex, false, currentY)
        updateBoxPositionAndWidth('boxMidLeft', midLeftX, midLeftWidth, oppBgHex, oppBorderHex, false, currentY)
        updateBoxPositionAndWidth('boxMiddle', midX, midWidth, 'FFFFFF', 'FFFFFF', true, currentY)
        updateBoxPositionAndWidth('boxMidRight', midRightX, midRightWidth, playerBgColor, playerBorderColor, false, currentY)
        updateBoxPositionAndWidth('boxRight', rightX, rightWidth, playerBgColor, playerBorderColor, false, currentY)
        
        -- Make side boxes visible
        setProperty('boxLeft.visible', true)
        setProperty('boxLeftLine.visible', true)
        setProperty('boxMidLeft.visible', true)
        setProperty('boxMidLeftLine.visible', true)
        setProperty('boxMidRight.visible', true)
        setProperty('boxMidRightLine.visible', true)
        setProperty('boxRight.visible', true)
        setProperty('boxRightLine.visible', true)
    else
        -- Only show the middle box when playing normally
        updateBoxPositionAndWidth('boxMiddle', midX, midWidth, 'FFFFFF', 'FFFFFF', true, currentY)
        
        -- Hide side boxes completely
        setProperty('boxLeft.visible', false)
        setProperty('boxLeftLine.visible', false)
        setProperty('boxMidLeft.visible', false)
        setProperty('boxMidLeftLine.visible', false)
        setProperty('boxMidRight.visible', false)
        setProperty('boxMidRightLine.visible', false)
        setProperty('boxRight.visible', false)
        setProperty('boxRightLine.visible', false)
    end

    -- 6. Set text positions cleanly centered over their boxes
    setProperty('textLeft.x', leftX + (leftWidth / 2) - (getProperty('textLeft.fieldWidth') / 2))
    setProperty('textLeft.y', currentY + 5)
    
    setProperty('textMidLeft.x', midLeftX + (midLeftWidth / 2) - (getProperty('textMidLeft.fieldWidth') / 2))
    setProperty('textMidLeft.y', currentY + 5)
    
    setProperty('textMiddle.x', midX + (midWidth / 2) - (getProperty('textMiddle.fieldWidth') / 2))
    setProperty('textMiddle.y', currentY + 5)
    
    setProperty('textMidRight.x', midRightX + (midRightWidth / 2) - (getProperty('textMidRight.fieldWidth') / 2))
    setProperty('textMidRight.y', currentY + 5)
    
    setProperty('textRight.x', rightX + (rightWidth / 2) - (getProperty('textRight.fieldWidth') / 2))
    setProperty('textRight.y', currentY + 5)
end
