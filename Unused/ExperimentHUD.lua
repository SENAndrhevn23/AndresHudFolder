
-- Created By Andre Nicholas Jr.
-- AndresJRHUD VER (V1.2 MULTIPLIER SUPPORT)


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

-- MULTIPLIER
local noteMultiplier = 1

-- Weighted hit tables
local playerHits = {} -- {time, weight}
local oppHits = {}

local stopwatchStartTime = nil
local stopwatchStr = "00:00:00"
local botHudEnabled = nil

-- =========================
-- HELPERS
-- =========================
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

-- EVENT (MULTIPLIER)
function onEvent(name, value1, value2)
    if name == "Change Note Multiplier" then
        noteMultiplier = tonumber(value1) or 1
    end
end


-- HUD MODE SWITCH
local function setHudMode(isBot)
    if botHudEnabled == isBot then return end
    botHudEnabled = isBot

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

    for _, tag in ipairs({
        'topTimeBox','topTimeText',
        'statsBox','statsText'
    }) do
        setVisible(tag, not isBot)
    end
end

-- CREATE HUD
function onCreatePost()
    for _, el in pairs({
        'healthBar','healthBarBG','iconP1','iconP2',
        'scoreTxt','timeBar','timeBarBG','timeTxt','botplayTxt'
    }) do
        setProperty(el..'.visible', false)
    end

    -- (same UI creation as before — unchanged)
    -- I kept it identical for stability

    makeLuaSprite('counterBox', nil, 0, 20)
    makeGraphic('counterBox', 10, 10, BOX_COLOR)
    setProperty('counterBox.alpha', BOX_ALPHA)
    setObjectCamera('counterBox', 'hud')
    addLuaSprite('counterBox', true)

    makeLuaText('counterText', '', 0, 0, 30)
    setTextSize('counterText', TEXT_SIZE)
    setObjectCamera('counterText', 'hud')
    addLuaText('counterText')

    makeLuaSprite('bottomTimeBox', nil, 0, screenHeight - 45)
    makeGraphic('bottomTimeBox', 10, 10, BOX_COLOR)
    setProperty('bottomTimeBox.alpha', BOX_ALPHA)
    setObjectCamera('bottomTimeBox', 'hud')
    addLuaSprite('bottomTimeBox', true)

    makeLuaText('bottomTimeText', '', 0, 0, screenHeight - 40)
    setTextSize('bottomTimeText', TIME_SIZE)
    setObjectCamera('bottomTimeText', 'hud')
    addLuaText('bottomTimeText')

    makeLuaSprite('oppBox', nil, 10, screenHeight - 45)
    makeGraphic('oppBox', 10, 10, BOX_COLOR)
    setProperty('oppBox.alpha', BOX_ALPHA)
    setObjectCamera('oppBox', 'hud')
    addLuaSprite('oppBox', true)

    makeLuaText('oppNpsText', '', 0, 20, screenHeight - 40)
    setTextSize('oppNpsText', NPS_SIZE)
    setObjectCamera('oppNpsText', 'hud')
    addLuaText('oppNpsText')

    makeLuaSprite('playerBox', nil, 0, screenHeight - 45)
    makeGraphic('playerBox', 10, 10, BOX_COLOR)
    setProperty('playerBox.alpha', BOX_ALPHA)
    setObjectCamera('playerBox', 'hud')
    addLuaSprite('playerBox', true)

    makeLuaText('playerNpsText', '', 0, 0, screenHeight - 40)
    setTextSize('playerNpsText', NPS_SIZE)
    setObjectCamera('playerNpsText', 'hud')
    addLuaText('playerNpsText')

    makeLuaSprite('speedBox', nil, 10, screenHeight / 2)
    makeGraphic('speedBox', 10, 10, BOX_COLOR)
    setProperty('speedBox.alpha', BOX_ALPHA)
    setObjectCamera('speedBox', 'hud')
    addLuaSprite('speedBox', true)

    makeLuaText('speedText', '', 0, 20, screenHeight / 2 + 5)
    setTextSize('speedText', NPS_SIZE)
    setObjectCamera('speedText', 'hud')
    addLuaText('speedText')

    makeLuaSprite('bpmBox', nil, 0, screenHeight / 2)
    makeGraphic('bpmBox', 10, 10, BOX_COLOR)
    setProperty('bpmBox.alpha', BOX_ALPHA)
    setObjectCamera('bpmBox', 'hud')
    addLuaSprite('bpmBox', true)

    makeLuaText('bpmText', '', 0, 0, screenHeight / 2 + 5)
    setTextSize('bpmText', NPS_SIZE)
    setObjectCamera('bpmText', 'hud')
    addLuaText('bpmText')

    makeLuaSprite('topTimeBox', nil, 0, 20)
    makeGraphic('topTimeBox', 10, 10, BOX_COLOR)
    setProperty('topTimeBox.alpha', BOX_ALPHA)
    setObjectCamera('topTimeBox', 'hud')
    addLuaSprite('topTimeBox', true)

    makeLuaText('topTimeText', '', 0, 0, 30)
    setTextSize('topTimeText', TIME_SIZE)
    setObjectCamera('topTimeText', 'hud')
    addLuaText('topTimeText')

    makeLuaSprite('statsBox', nil, 0, screenHeight - 45)
    makeGraphic('statsBox', 10, 10, BOX_COLOR)
    setProperty('statsBox.alpha', BOX_ALPHA)
    setObjectCamera('statsBox', 'hud')
    addLuaSprite('statsBox', true)

    makeLuaText('statsText', '', 0, 0, screenHeight - 40)
    setTextSize('statsText', TEXT_SIZE)
    setObjectCamera('statsText', 'hud')
    addLuaText('statsText')
end

-- SONG START
function onSongStart()
    stopwatchStartTime = os.time()
end


-- UPDATE LOOP
function onUpdate(elapsed)
    local curPos = getSongPosition()
    local isBot = getProperty('cpuControlled') or botPlay

    setHudMode(isBot)

    -- Stopwatch
    if stopwatchStartTime then
        local t = os.time() - stopwatchStartTime
        stopwatchStr = string.format("%02d:%02d:%02d",
            math.floor(t / 3600),
            math.floor((t % 3600) / 60),
            t % 60)
    end

    -- PLAYER NPS (weighted)
    local totalP = 0
    while #playerHits > 0 and curPos - playerHits[1].time > 1000 do
        table.remove(playerHits, 1)
    end
    for i = 1, #playerHits do
        totalP = totalP + playerHits[i].weight
    end
    playerNPS = totalP

    -- OPP NPS (weighted)
    local totalO = 0
    while #oppHits > 0 and curPos - oppHits[1].time > 1000 do
        table.remove(oppHits, 1)
    end
    for i = 1, #oppHits do
        totalO = totalO + oppHits[i].weight
    end
    oppNPS = totalO

    maxPlayerNPS = math.max(maxPlayerNPS, playerNPS)
    maxOppNPS = math.max(maxOppNPS, oppNPS)

    if isBot then
        local total = playerNotes + oppNotes

        setTextString('counterText',
            formatNumber(oppNotes).." + "..formatNumber(playerNotes).." = "..formatNumber(total).." | x"..noteMultiplier
        )

        setTextString('bottomTimeText',
            formatTime(songLength - curPos).." | "..formatTime(curPos).." | "..stopwatchStr
        )

        setTextString('oppNpsText', formatNumber(oppNPS).." | "..formatNumber(maxOppNPS))
        setTextString('playerNpsText', formatNumber(playerNPS).." | "..formatNumber(maxPlayerNPS))

        setTextString('speedText', 'Speed: '..string.format("%.2f", getProperty('songSpeed')))
        setTextString('bpmText', 'BPM: '..math.floor(curBpm))

        centerX('counterText')
        updateBox('counterBox','counterText')

        centerX('bottomTimeText')
        updateBox('bottomTimeBox','bottomTimeText')

        updateBox('oppBox','oppNpsText')

        setProperty('playerNpsText.x', screenWidth - getProperty('playerNpsText.width') - 20)
        updateBox('playerBox','playerNpsText')

        updateBox('speedBox','speedText')

        setProperty('bpmText.x', screenWidth - getProperty('bpmText.width') - 20)
        updateBox('bpmBox','bpmText')

    else
        local sScore = getProperty('songScore') or 0
        local sMiss = getProperty('songMisses') or 0
        local sAcc = math.floor((getProperty('ratingPercent') or 0) * 100)
        local sHealth = math.floor((getHealth() or 1) * 50)

        setTextString('topTimeText',
            formatTime(songLength - curPos).." | "..formatTime(curPos).." | "..stopwatchStr
        )

        setTextString('statsText',
            "Score: "..formatNumber(sScore)..
            " | Misses: "..formatNumber(sMiss)..
            " | Accuracy: "..formatNumber(sAcc).."%"..
            " | Health: "..formatNumber(sHealth).."%"
        )

        centerX('topTimeText')
        updateBox('topTimeBox','topTimeText')

        centerX('statsText')
        updateBox('statsBox','statsText')
    end
end

-- NOTE TRACKING (WEIGHTED)
function goodNoteHit(id, direction, noteType, isSustain)
    if not isSustain then
        local t = getSongPosition()
        playerNotes = playerNotes + noteMultiplier
        table.insert(playerHits, {time = t, weight = noteMultiplier})
    end
end

function opponentNoteHit(id, direction, noteType, isSustain)
    if not isSustain then
        local t = getSongPosition()
        oppNotes = oppNotes + noteMultiplier
        table.insert(oppHits, {time = t, weight = noteMultiplier})
    end
end