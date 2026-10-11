
-- Created By Andre Nicholas Jr.
-- base off of haxepixel hud script xd

-- SETTINGS
local COMBO_TEXT_SIZE = 28
local NPS_TEXT_SIZE = 26
local PADDING_X = 30
local PADDING_Y = 14

-- VARIABLES
local oppNotes = 0
local playerNotes = 0
local oppNPS = 0
local playerNPS = 0

-- Rolling Window Tables
local playerHitTimestamps = {}
local oppHitTimestamps = {}

local maxOppNPS = 0
local maxPlayerNPS = 0
local maxBothNPS = 0

local notesBeingPlayedAtOnce = 0

-- REAL-TIME STOPWATCH
local stopwatchStartTime = nil
local stopwatchStr = "00:00:00"

-- =========================
-- HELPER: Format numbers with commas
-- =========================
local function formatNumber(num)
    local str = tostring(math.floor(num))
    local k
    while true do
        str, k = str:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return str
end


-- CREATE HUD ELEMENTS
function onCreatePost()
    local hudElements = {'healthBar','healthBarBG','iconP1','iconP2','scoreTxt','timeBar','timeBarBG','timeTxt','botplayTxt'}
    for _, el in pairs(hudElements) do
        setProperty(el..'.visible', false)
    end

    makeLuaSprite('comboBox', nil, 0, 20)
    makeGraphic('comboBox', 10, 10, '000000')
    setProperty('comboBox.alpha', 0.5)
    setObjectCamera('comboBox', 'hud')
    addLuaSprite('comboBox', true)

    makeLuaText('comboText', '0 / 0 / 0', 0, 0, 35)
    setTextAlignment('comboText', 'center')
    setTextSize('comboText', COMBO_TEXT_SIZE)
    setObjectCamera('comboText', 'hud')
    addLuaText('comboText')

    makeLuaSprite('npsBox', nil, 0, screenHeight - 95)
    makeGraphic('npsBox', 10, 10, '000000')
    setProperty('npsBox.alpha', 0.5)
    setObjectCamera('npsBox', 'hud')
    addLuaSprite('npsBox', true)

    makeLuaText('npsText', '0 / 0 / 0 | 0 / 0 / 0 | 0:00.00 / 00:00:00 | 0', 0, 0, screenHeight - 80)
    setTextAlignment('npsText', 'center')
    setTextSize('npsText', NPS_TEXT_SIZE)
    setObjectCamera('npsText', 'hud')
    addLuaText('npsText')
end


-- NOTE HIT EVENTS (Rolling Window)
function goodNoteHit(id, direction, noteType, isSustainNote)
    if not isSustainNote then
        playerNotes = playerNotes + 1
        table.insert(playerHitTimestamps, getSongPosition())
    end
end

function opponentNoteHit(id, direction, noteType, isSustainNote)
    if not isSustainNote then
        oppNotes = oppNotes + 1
        table.insert(oppHitTimestamps, getSongPosition())
    end
end


-- MAIN UPDATE LOOP
function onUpdate(elapsed)
    setProperty('botplayTxt.visible', false)

    -- 1. Update Stopwatch
    if stopwatchStartTime then
        local realElapsed = os.time() - stopwatchStartTime
        local hours = math.floor(realElapsed / 3600)
        local minutes = math.floor((realElapsed % 3600) / 60)
        local seconds = realElapsed % 60
        stopwatchStr = string.format("%02d:%02d:%02d", hours, minutes, seconds)
    end

    -- 2. Rolling NPS Logic (The Fix)
    local curSongPos = getSongPosition()

    -- Clean up old Player hits (older than 1000ms)
    while #playerHitTimestamps > 0 and curSongPos - playerHitTimestamps[1] > 1000 do
        table.remove(playerHitTimestamps, 1)
    end
    playerNPS = #playerHitTimestamps

    -- Clean up old Opponent hits
    while #oppHitTimestamps > 0 and curSongPos - oppHitTimestamps[1] > 1000 do
        table.remove(oppHitTimestamps, 1)
    end
    oppNPS = #oppHitTimestamps

    -- Update Peak NPS
    if playerNPS > maxPlayerNPS then maxPlayerNPS = playerNPS end
    if oppNPS > maxOppNPS then maxOppNPS = oppNPS end
    local totalNPS = playerNPS + oppNPS
    if totalNPS > maxBothNPS then maxBothNPS = totalNPS end

    -- 3. Calculate Song Time
    local songPos = curSongPos / 1000
    local songMin = math.floor(songPos / 60)
    local songSec = songPos % 60
    local songTimeStr = string.format("%d:%05.2f", songMin, songSec)

    -- 4. Update HUD Text
    setTextString('comboText', formatNumber(oppNotes).." / "..formatNumber(playerNotes).." / "..formatNumber(oppNotes + playerNotes))

    setTextString(
        'npsText',
        formatNumber(oppNPS).." / "..formatNumber(playerNPS).." / "..formatNumber(totalNPS).." | "..
        formatNumber(maxOppNPS).." / "..formatNumber(maxPlayerNPS).." / "..formatNumber(maxBothNPS).." | "..
        songTimeStr.." / "..stopwatchStr.." | "..
        formatNumber(notesBeingPlayedAtOnce)
    )

    -- 5. Auto-Size Boxes
    local cW = getProperty('comboText.width') + PADDING_X
    local cH = getProperty('comboText.height') + PADDING_Y
    setGraphicSize('comboBox', cW, cH)
    screenCenter('comboText', 'x')
    screenCenter('comboBox', 'x')
    setProperty('comboBox.y', getProperty('comboText.y') - PADDING_Y / 2)

    local nW = getProperty('npsText.width') + PADDING_X
    local nH = getProperty('npsText.height') + PADDING_Y
    setGraphicSize('npsBox', nW, nH)
    screenCenter('npsText', 'x')
    screenCenter('npsBox', 'x')
    setProperty('npsBox.y', getProperty('npsText.y') - PADDING_Y / 2)
end

function onUpdatePost(elapsed)
    notesBeingPlayedAtOnce = 0
    local notesLength = getProperty('notes.length')
    for i = 0, notesLength-1 do
        if getPropertyFromGroup('notes', i, 'active') then
            notesBeingPlayedAtOnce = notesBeingPlayedAtOnce + 1
        end
    end
end

function onSongStart()
    stopwatchStartTime = os.time()
end