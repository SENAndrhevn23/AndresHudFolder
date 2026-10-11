-- Configuration for positions
local boxHeight = 35
local boxGap = 8 
local boxY = 10
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
    -- 1. Create the graphic boxes and brackets FIRST so they sit underneath
    createTargetHudBox('boxLeft')
    createTargetHudBox('boxMidLeft')
    createTargetHudBox('boxMiddle')
    createTargetHudBox('boxMidRight')
    createTargetHudBox('boxRight')

    -- 2. Create the text layers LAST so they render on top of the boxes
    createHudText('textLeft', '0 / 0')
    createHudText('textMidLeft', '0')
    createHudText('textMiddle', '0')
    createHudText('textMidRight', '0')
    createHudText('textRight', '0 / 0')
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

function createTargetHudBox(tag)
    local targetCam = 'other'

    -- Graphic base
    makeLuaSprite(tag, '', 0, boxY)
    makeGraphic(tag, MAX_INITIAL_WIDTH, boxHeight, 'FFFFFF')
    setObjectCamera(tag, targetCam)
    setProperty(tag .. '.alpha', 0.75) -- Slightly higher alpha for rich dark tones
    addLuaSprite(tag, true)
    
    -- Underline graphic
    makeLuaSprite(tag .. 'Line', '', 0, boxY + boxHeight - 8)
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

function createHudText(tag, defaultText)
    makeLuaText(tag, defaultText, 0, 0, boxY + 5)
    setTextSize(tag, fontSize)
    setTextFont(tag, 'vcr.ttf')
    setTextAlignment(tag, 'center')
    setObjectCamera(tag, 'other')
    addLuaText(tag) 
end

-- Helper logic to scale, snap, and colorize elements with separate BG and Border colors
function updateBoxPositionAndWidth(tag, x, width, bgHex, borderHex, isBlackBg)
    local bracketSize = 8
    local thickness = 2
    local linePadding = 12

    -- Scale background
    setProperty(tag .. '.scale.x', width / MAX_INITIAL_WIDTH)
    updateHitbox(tag)
    setProperty(tag .. '.x', x)
    
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
    setProperty(tag .. 'Line.color', getColorFromHex(borderHex))

    -- Reposition and color Brackets
    local brackets = {'TL_H', 'TL_V', 'TR_H', 'TR_V', 'BL_H', 'BL_V', 'BR_H', 'BR_V'}
    for _, b in ipairs(brackets) do
        setProperty(tag .. b .. '.color', getColorFromHex(borderHex))
    end

    setProperty(tag .. 'TL_H.x', x)
    setProperty(tag .. 'TL_H.y', boxY)
    setProperty(tag .. 'TL_V.x', x)
    setProperty(tag .. 'TL_V.y', boxY)

    setProperty(tag .. 'TR_H.x', x + width - bracketSize)
    setProperty(tag .. 'TR_H.y', boxY)
    setProperty(tag .. 'TR_V.x', x + width - thickness)
    setProperty(tag .. 'TR_V.y', boxY)

    setProperty(tag .. 'BL_H.x', x)
    setProperty(tag .. 'BL_H.y', boxY + boxHeight - thickness)
    setProperty(tag .. 'BL_V.x', x)
    setProperty(tag .. 'BL_V.y', boxY + boxHeight - bracketSize)

    setProperty(tag .. 'BR_H.x', x + width - bracketSize)
    setProperty(tag .. 'BR_H.y', boxY + boxHeight - thickness)
    setProperty(tag .. 'BR_V.x', x + width - thickness)
    setProperty(tag .. 'BR_V.y', boxY + boxHeight - bracketSize)
end

-- Converts RGB array to Hexadecimal string format
function rgbToHex(rgb)
    return string.format('%02x%02x%02x', rgb[1], rgb[2], rgb[3])
end

-- Darkens an RGB color array so it serves as a nice dark background tone
function getDarkenedColorHex(rgb)
    -- Multiplies RGB by 0.35 to make it a deep dark shade
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
    
    while #playerHitTimes > 0 and songPos - playerHitTimes[1] > 1000 do table.remove(playerHitTimes, 1) end
    local playerNPS = #playerHitTimes
    if playerNPS > maxPlayerNPS then maxPlayerNPS = playerNPS end

    while #opponentHitTimes > 0 and songPos - opponentHitTimes[1] > 1000 do table.remove(opponentHitTimes, 1) end
    local opponentNPS = #opponentHitTimes
    if opponentNPS > maxOpponentNPS then maxOpponentNPS = opponentNPS end

    -- 1. Format numbers with commas and update text fields
    setTextString('textLeft', formatWithCommas(opponentNPS) .. ' / ' .. formatWithCommas(maxOpponentNPS))
    setTextString('textMidLeft', formatWithCommas(opponentCombo))
    setTextString('textMiddle', formatWithCommas(totalCombo))
    setTextString('textMidRight', formatWithCommas(playerCombo))
    setTextString('textRight', formatWithCommas(playerNPS) .. ' / ' .. formatWithCommas(maxPlayerNPS))

    -- 2. Measure widths
    local padding = 28
    local leftWidth = getProperty('textLeft.fieldWidth') + padding
    local midLeftWidth = getProperty('textMidLeft.fieldWidth') + padding
    local midWidth = getProperty('textMiddle.fieldWidth') + padding
    local midRightWidth = getProperty('textMidRight.fieldWidth') + padding
    local rightWidth = getProperty('textRight.fieldWidth') + padding

    -- 3. Layout centering math for 5 boxes
    local midX = (screenWidth / 2) - (midWidth / 2)
    local midLeftX = midX - midLeftWidth - boxGap
    local leftX = midLeftX - leftWidth - boxGap
    
    local midRightX = midX + midWidth + boxGap
    local rightX = midRightX + midRightWidth + boxGap

    -- 4. Get active opponent color information
    local oppColorArr = getActiveOpponentColorArray()
    local oppBorderHex = rgbToHex(oppColorArr)
    local oppBgHex = getDarkenedColorHex(oppColorArr)

    -- 5. Apply layout color updates (Dark purple BG for opponent side, dark blue BG for player side)
    updateBoxPositionAndWidth('boxLeft', leftX, leftWidth, oppBgHex, oppBorderHex, false)
    updateBoxPositionAndWidth('boxMidLeft', midLeftX, midLeftWidth, oppBgHex, oppBorderHex, false)
    updateBoxPositionAndWidth('boxMiddle', midX, midWidth, 'FFFFFF', 'FFFFFF', true) -- Pure black middle box
    updateBoxPositionAndWidth('boxMidRight', midRightX, midRightWidth, playerBgColor, playerBorderColor, false)
    updateBoxPositionAndWidth('boxRight', rightX, rightWidth, playerBgColor, playerBorderColor, false)

    -- 6. Set text positions cleanly centered over their boxes
    setProperty('textLeft.x', leftX + (leftWidth / 2) - (getProperty('textLeft.fieldWidth') / 2))
    setProperty('textMidLeft.x', midLeftX + (midLeftWidth / 2) - (getProperty('textMidLeft.fieldWidth') / 2))
    setProperty('textMiddle.x', midX + (midWidth / 2) - (getProperty('textMiddle.fieldWidth') / 2))
    setProperty('textMidRight.x', midRightX + (midRightWidth / 2) - (getProperty('textMidRight.fieldWidth') / 2))
    setProperty('textRight.x', rightX + (rightWidth / 2) - (getProperty('textRight.fieldWidth') / 2))
end
