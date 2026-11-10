local itemDropRates
local privateServerDropRates
local dropCorrections
local correctionKeys

local function LoadLuaTable(source, description)
    if type(source) == "table" then
        return source
    end
    if type(source) ~= "string" then
        error("Quest Drop Rates: missing " .. description .. " data from QuestieDB")
    end

    local loader = loadstring or load
    local chunk, errorMessage = loader(source, "Quest Drop Rates: " .. description)
    if not chunk then
        error("Quest Drop Rates: could not load " .. description .. ": " .. tostring(errorMessage))
    end

    local data = chunk()
    if type(data) ~= "table" then
        error("Quest Drop Rates: invalid " .. description .. " data from QuestieDB")
    end
    return data
end

local function LoadDropData()
    if itemDropRates then
        return
    end

    local support = LibQuestieDB.Support
    local itemDrops = support.Get("QuestieClassicItemDrops")
    local corrections = support.Get("QuestieItemDropCorrections")
    local dropDB = support.Get("DropDB")

    itemDropRates = LoadLuaTable(itemDrops and itemDrops.wowheadData, "item drop rates")
    privateServerDropRates = LoadLuaTable(itemDrops and itemDrops.cmangosData, "Forever quest-only drop rates")
    dropCorrections = corrections and corrections.Era or {}
    correctionKeys = dropDB and dropDB.correctionKeys or {}
end

local function GetItemDropRate(itemID, npcID)
    LoadDropData()

    local itemCorrections = dropCorrections[itemID]
    local correction = itemCorrections and itemCorrections[npcID]
    local useWowheadOnly = false
    if type(correction) == "number" then
        if correction >= 0 then
            return correction
        elseif correction == correctionKeys.WOWHEAD then
            useWowheadOnly = true
        elseif correction ~= correctionKeys.PSERVER then
            return nil
        end
    end

    local privateServerRates = privateServerDropRates[itemID]
    if not useWowheadOnly and privateServerRates and privateServerRates[npcID] then
        return privateServerRates[npcID]
    end

    local ratesForItem = itemDropRates[itemID]
    return ratesForItem and ratesForItem[npcID]
end

local function GetNPCID(unit)
    if not unit then
        return nil
    end

    local guid = UnitGUID(unit)
    if not guid then
        return nil
    end

    local npcID = guid:match("^Creature%-%d+%-%d+%-%d+%-%d+%-(%d+)%-")
    return tonumber(npcID)
end

local function GetItemName(lineText)
    local text = lineText
        :gsub("|c%x%x%x%x%x%x%x%x", "")
        :gsub("|r", "")
        :gsub("^%s*%d+/%d+%s+", "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")

    if text == "" or text:find("%d+%.?%d*%%") then
        return nil
    end
    return text
end

local function AppendDropRates(tooltip)
    if not tooltip or not tooltip.GetUnit or not tooltip.NumLines or not LibQuestieDB then
        return
    end

    local tooltipName = tooltip:GetName()
    if not tooltipName then
        return
    end

    local _, unit = tooltip:GetUnit()
    local npcID = GetNPCID(unit)
    if not npcID then
        return
    end

    local lineCount = tooltip:NumLines()
    for lineIndex = 1, lineCount do
        local line = _G[tooltipName .. "TextLeft" .. lineIndex]
        local lineText = line and line:GetText()
        local itemName = lineText and GetItemName(lineText)
        local itemIDs = itemName and LibQuestieDB.Item.IdsByName(itemName)
        if itemIDs then
            for _, itemID in ipairs(itemIDs) do
                local chance = GetItemDropRate(itemID, npcID)
                if type(chance) == "number" and chance >= 0 and chance <= 100 then
                    line:SetText(lineText .. ("  |cffaaaaaa[%.1f%%]|r"):format(chance))
                    break
                end
            end
        end
    end
end

if TooltipDataProcessor and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and Enum and Enum.TooltipDataType and Enum.TooltipDataType.Unit then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, AppendDropRates)
else
    GameTooltip:HookScript("OnTooltipSetUnit", AppendDropRates)
end
