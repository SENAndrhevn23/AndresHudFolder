-- Created By Andre Nicholas Jr.
-- AndresJRHUD VER (V.1.1)

-- SETTINGS
local TEXT_SIZE = 28
local NPS_SIZE = 22
local TIME_SIZE = 20
local PADDING_X = 20
local PADDING_Y = 10
local BOX_ALPHA = 0.5
local BOX_COLOR = '000000'

-- VARIABLES
local playerNotes, oppNotes = 0, 0
local playerNPS, oppNPS = 0, 0
local maxPlayerNPS, maxOppNPS = 0, 0
local playerHits, oppHits = {}, {}
local stopwatchStartTime = nil
local stopwatchStr = "00:00:00"
local botHudEnabled = nil


-- VARIABLES 2
local oppNotes = 0
local playerNotes = 0
local oppNPS = 0
local playerNPS = 0


-- HELPERS
local function formatNumber(num)
    local str = tostring(math.floor(num or 0))
    while true do
        local k
        str, k = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return str
end

local function formatTime(ms)
    if ms < 0 then ms = 0 end
    local sec = math.floor(ms / 1000)
    local min = math.floor(sec / 60)
    local millis = math.floor((ms % 1000) / 10)
    return string.format("%02d:%02d.%02d", min, sec % 60, millis)
end

local function updateBox(box, text)
    setGraphicSize(box,
        getProperty(text..'.width') + PADDING_X,
        getProperty(text..'.height') + PADDING_Y)
    updateHitbox(box)
    setProperty(box..'.x', getProperty(text..'.x') - PADDING_X / 2)
    setProperty(box..'.y', getProperty(text..'.y') - PADDING_Y / 2)
end

local function centerX(tag)
    setProperty(tag..'.x', (screenWidth / 2) - (getProperty(tag..'.width') / 2))
end

local function setVisible(tag, visible)
    setProperty(tag..'.visible', visible)
end

local function setHudMode(isBot)
    if botHudEnabled == isBot then return end
    botHudEnabled = isBot

    -- Botplay ON: show the bot HUD
    for _, tag in ipairs({
        'counterBox','counterText',
        'bottomTimeBox','bottomTimeText',
        'oppBox','oppNpsText',
        'playerBox','playerNpsText',
        'speedBox','speedText',
        'bpmBox','bpmText'
    }) do
        setVisible(tag, isBot)
    end

    -- Botplay OFF: show the player HUD
    for _, tag in ipairs({
        'topTimeBox','topTimeText',
        'statsBox','statsText'
    }) do
        setVisible(tag, not isBot)
    end
end


-- CREATE HUD
function onCreatePost()
    -- Hide default FNF UI
    for _, el in pairs({
        'healthBar','healthBarBG','iconP1','iconP2',
        'scoreTxt','timeBar','timeBarBG','timeTxt','botplayTxt'
    }) do
        setProperty(el..'.visible', false)
    end

    -- BOTPLAY TOP COUNTER
    makeLuaSprite('counterBox', nil, 0, 20)
    makeGraphic('counterBox', 10, 10, BOX_COLOR)
    setProperty('counterBox.alpha', BOX_ALPHA)
    setObjectCamera('counterBox', 'hud')
    addLuaSprite('counterBox', true)

    makeLuaText('counterText', '', 0, 0, 30)
    setTextSize('counterText', TEXT_SIZE)
    setObjectCamera('counterText', 'hud')
    addLuaText('counterText')

    -- BOTPLAY BOTTOM TIME
    makeLuaSprite('bottomTimeBox', nil, 0, screenHeight - 45)
    makeGraphic('bottomTimeBox', 10, 10, BOX_COLOR)
    setProperty('bottomTimeBox.alpha', BOX_ALPHA)
    setObjectCamera('bottomTimeBox', 'hud')
    addLuaSprite('bottomTimeBox', true)

    makeLuaText('bottomTimeText', '', 0, 0, screenHeight - 40)
    setTextSize('bottomTimeText', TIME_SIZE)
    setObjectCamera('bottomTimeText', 'hud')
    addLuaText('bottomTimeText')

    -- BOTPLAY NPS LEFT
    makeLuaSprite('oppBox', nil, 10, screenHeight - 45)
    makeGraphic('oppBox', 10, 10, BOX_COLOR)
    setProperty('oppBox.alpha', BOX_ALPHA)
    setObjectCamera('oppBox', 'hud')
    addLuaSprite('oppBox', true)

    makeLuaText('oppNpsText', '', 0, 20, screenHeight - 40)
    setTextSize('oppNpsText', NPS_SIZE)
    setObjectCamera('oppNpsText', 'hud')
    addLuaText('oppNpsText')

    -- BOTPLAY NPS RIGHT
    makeLuaSprite('playerBox', nil, 0, screenHeight - 45)
    makeGraphic('playerBox', 10, 10, BOX_COLOR)
    setProperty('playerBox.alpha', BOX_ALPHA)
    setObjectCamera('playerBox', 'hud')
    addLuaSprite('playerBox', true)

    makeLuaText('playerNpsText', '', 0, 0, screenHeight - 40)
    setTextSize('playerNpsText', NPS_SIZE)
    setObjectCamera('playerNpsText', 'hud')
    addLuaText('playerNpsText')

    -- BOTPLAY SPEED LEFT
    makeLuaSprite('speedBox', nil, 10, screenHeight / 2)
    makeGraphic('speedBox', 10, 10, BOX_COLOR)
    setProperty('speedBox.alpha', BOX_ALPHA)
    setObjectCamera('speedBox', 'hud')
    addLuaSprite('speedBox', true)

    makeLuaText('speedText', '', 0, 20, screenHeight / 2 + 5)
    setTextSize('speedText', NPS_SIZE)
    setObjectCamera('speedText', 'hud')
    addLuaText('speedText')

    -- BOTPLAY BPM RIGHT
    makeLuaSprite('bpmBox', nil, 0, screenHeight / 2)
    makeGraphic('bpmBox', 10, 10, BOX_COLOR)
    setProperty('bpmBox.alpha', BOX_ALPHA)
    setObjectCamera('bpmBox', 'hud')
    addLuaSprite('bpmBox', true)

    makeLuaText('bpmText', '', 0, 0, screenHeight / 2 + 5)
    setTextSize('bpmText', NPS_SIZE)
    setObjectCamera('bpmText', 'hud')
    addLuaText('bpmText')

    -- PLAYER TOP TIME
    makeLuaSprite('topTimeBox', nil, 0, 20)
    makeGraphic('topTimeBox', 10, 10, BOX_COLOR)
    setProperty('topTimeBox.alpha', BOX_ALPHA)
    setObjectCamera('topTimeBox', 'hud')
    addLuaSprite('topTimeBox', true)

    makeLuaText('topTimeText', '', 0, 0, 30)
    setTextSize('topTimeText', TIME_SIZE)
    setObjectCamera('topTimeText', 'hud')
    addLuaText('topTimeText')

    -- PLAYER BOTTOM STATS BAR
    makeLuaSprite('statsBox', nil, 0, screenHeight - 45)
    makeGraphic('statsBox', 10, 10, BOX_COLOR)
    setProperty('statsBox.alpha', BOX_ALPHA)
    setObjectCamera('statsBox', 'hud')
    addLuaSprite('statsBox', true)

    makeLuaText('statsText', '', 0, 0, screenHeight - 40)
    setTextSize('statsText', TEXT_SIZE)
    setObjectCamera('statsText', 'hud')
    addLuaText('statsText')

    -- Hide everything first
    for _, tag in ipairs({
        'counterBox','counterText',
        'bottomTimeBox','bottomTimeText',
        'oppBox','oppNpsText',
        'playerBox','playerNpsText',
        'speedBox','speedText',
        'bpmBox','bpmText',
        'topTimeBox','topTimeText',
        'statsBox','statsText'
    }) do
        setVisible(tag, false)
    end

    -- Fix rendering order
    local ui = {
        'counterBox','counterText',
        'bottomTimeBox','bottomTimeText',
        'oppBox','oppNpsText',
        'playerBox','playerNpsText',
        'speedBox','speedText',
        'bpmBox','bpmText',
        'topTimeBox','topTimeText',
        'statsBox','statsText'
    }

    for i, tag in ipairs(ui) do
        setObjectOrder(tag, getObjectOrder('strumLineNotes') + 100 + i)
    end
end

function onSongStart()
    stopwatchStartTime = os.time()
end


-- UPDATE LOOP
function onUpdate(elapsed)
    local curPos = getSongPosition()
    local isBot = getProperty('cpuControlled') or botPlay

    -- Switch HUD mode
    setHudMode(isBot)

    -- STOPWATCH
    if stopwatchStartTime then
        local t = os.time() - stopwatchStartTime
        stopwatchStr = string.format("%02d:%02d:%02d", math.floor(t / 3600), math.floor((t % 3600) / 60), t % 60)
    end

    -- NPS CALCULATION
    while #playerHits > 0 and curPos - playerHits[1] > 1000 do
        table.remove(playerHits, 1)
    end
    while #oppHits > 0 and curPos - oppHits[1] > 1000 do
        table.remove(oppHits, 1)
    end

    playerNPS = #playerHits
    oppNPS = #oppHits
    maxPlayerNPS = math.max(maxPlayerNPS, playerNPS)
    maxOppNPS = math.max(maxOppNPS, oppNPS)

    if isBot then
        -- BOTPLAY HUD

        local total = playerNotes + oppNotes
        setTextString('counterText', formatNumber(oppNotes).." + "..formatNumber(playerNotes).." = "..formatNumber(total))

        setTextString('bottomTimeText', formatTime(songLength - curPos).." | "..formatTime(curPos).." | "..stopwatchStr)

        setTextString('oppNpsText', formatNumber(oppNPS).." | "..formatNumber(maxOppNPS))
        setTextString('playerNpsText', formatNumber(playerNPS).." | "..formatNumber(maxPlayerNPS))

        setTextString('speedText', 'Speed: '..string.format("%.2f", getProperty('songSpeed')))
        setTextString('bpmText', 'BPM: '..math.floor(curBpm))

        centerX('counterText')
        updateBox('counterBox', 'counterText')

        centerX('bottomTimeText')
        updateBox('bottomTimeBox', 'bottomTimeText')

        updateBox('oppBox', 'oppNpsText')

        setProperty('playerNpsText.x', screenWidth - getProperty('playerNpsText.width') - 20)
        updateBox('playerBox', 'playerNpsText')

        updateBox('speedBox', 'speedText')

        setProperty('bpmText.x', screenWidth - getProperty('bpmText.width') - 20)
        updateBox('bpmBox', 'bpmText')

    else
        -- PLAYER HUD

        local sScore = getProperty('songScore') or 0
        local sMiss = getProperty('songMisses') or 0
        local sAcc = math.floor((getProperty('ratingPercent') or 0) * 100)
        local sHealth = math.floor((getHealth() or 1) * 50)

        setTextString('topTimeText', formatTime(songLength - curPos).." | "..formatTime(curPos).." | "..stopwatchStr)

        setTextString('statsText',
            "Score: "..formatNumber(sScore)..
            " | Misses: "..formatNumber(sMiss)..
            " | Accuracy: "..formatNumber(sAcc).."%"..
            " | Health: "..formatNumber(sHealth).."%"
        )

        centerX('topTimeText')
        updateBox('topTimeBox', 'topTimeText')

        centerX('statsText')
        updateBox('statsBox', 'statsText')
    end
end


-- NOTE TRACKING
function goodNoteHit(id, direction, noteType, isSustain)
    if not isSustain then
        playerNotes = playerNotes + 1
        table.insert(playerHits, getSongPosition())
    end
end

function opponentNoteHit(id, direction, noteType, isSustain)
    if not isSustain then
        oppNotes = oppNotes + 1
        table.insert(oppHits, getSongPosition())
    end
end