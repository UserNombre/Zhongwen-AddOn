Zhongwen = LibStub("AceAddon-3.0"):NewAddon("Zhongwen")

function Zhongwen:OnInitialize()
    self.toneColors = { [1] = "ffeb3b5a",
                        [2] = "ff20bf6b",
                        [3] = "ff5352ed",
                        [4] = "ffa55eea",
                        [5] = "ffa5b1c2" }

    self.toneVowels = { ["a"] = "āáǎàa",
                        ["e"] = "ēéěèe",
                        ["i"] = "īíǐìi",
                        ["o"] = "ōóǒòo",
                        ["u"] = "ūúǔùu",
                        ["ü"] = "ǖǘǚǜü" }

    self.maxSearchLength  = 8

    BINDING_HEADER_ZHONGWEN = "Zhongwen Dictionary"
end

function Zhongwen:OnEnable()
    self:UpdateSelection("你好世界！")
    ZhongwenSelectionBox:SetCursorPosition(0)
end

---------------------------------------------------------------------------------------------------·
-- GAME/UI CODE                                                                                    |
---------------------------------------------------------------------------------------------------·

-------------------------------------------------·
-- GAME INFORMATION CODE                         |
-------------------------------------------------·

function Zhongwen:GetTooltipText(tooltipName)
    local tooltip = _G[tooltipName]
    local text = ""
    for i = 1, tooltip:NumLines() do
        local tooltipLine = _G[tooltipName .. "TextLeft" .. tostring(i)]
        text = text .. tooltipLine:GetText() .. "\n"
    end

    return text ~= "" and text or nil
end

function Zhongwen:GetButtonText(buttonName)
    return _G[buttonName]:GetText()
end

function Zhongwen:GetGossipText()
    return GetGossipText()
end

function Zhongwen:GetQuestText()
    if QuestFrameAcceptButton:IsVisible() then
        return GetTitleText() .. "\n\n" ..
               GetQuestText() .. "\n\n" ..
               GetObjectiveText()
    elseif QuestFrameCompleteButton:IsVisible() then
        return GetProgressText()
    elseif QuestFrameCompleteQuestButton:IsVisible() then
        return GetRewardText()
    end

    return nil
end

function Zhongwen:GetQuestLogText()
    local index = GetQuestLogSelection()
    if index == 0 then
        return nil
    end

    local name = (GetQuestLogTitle(index))
    local description, objectives = GetQuestLogQuestText()
    local text = name       .. "\n\n" ..
                 objectives .. "\n\n" ..
                 description 

    return text
end

function Zhongwen:GetAchievementText(buttonName)
    buttonName = buttonName:match("AchievementFrameAchievementsContainerButton%d")
    if buttonName == nil then
        return nil
    end

    local id = _G[buttonName].id
    local info = { GetAchievementInfo(id) }
    local text = info[2] .. "\n\n" .. info[8]

    for i = 1, GetAchievementNumCriteria(id) do
        local criteria = GetAchievementCriteriaInfo(id, i)
        if criteria ~= "" then
            text = text .. "\n- " .. criteria
        end
    end

    if info[11] ~= "" then
        text = text .. "\n\n" .. info[11]
    end

    return text
end

function Zhongwen:GetEnvironmentText()
    local frameName = GetMouseFocus():GetName()

    if GameTooltip:NumLines() > 0 then
        return self:GetTooltipText("GameTooltip")
    elseif frameName == "GossipFrame" then
        return self:GetGossipText()
    elseif frameName == "QuestFrame" then
        return self:GetQuestText()
    elseif WorldMapFrame:IsVisible() and
           not QuestScrollFrame:IsVisible() then
        return self:GetQuestLogText()
    elseif frameName:find("Tooltip") then
        return self:GetTooltipText(frameName)
    elseif frameName:find("AchievementsContainerButton") then
        return self:GetAchievementText(frameName)
    elseif frameName:find("Button") or
           frameName:find("Tab") then
        return self:GetButtonText(frameName)
    end
        
    return nil
end

function Zhongwen:GetChatText()
    local chatFrame = SELECTED_CHAT_FRAME
    local index = chatFrame:GetNumMessages() - chatFrame:GetScrollOffset()
    return chatFrame:GetMessageInfo(index)
end

-------------------------------------------------·
-- WIDGET/EVENT CODE                             |
-------------------------------------------------·

function Zhongwen:Toggle()
    ZhongwenFrame:SetShown(not ZhongwenFrame:IsVisible())
end

-- PRE:  true
-- POST: If   [text] is a non-empty [string]
--       Then [ZhongwenSelectionBox] is updated with [text]
--       Else nothing is done
function Zhongwen:UpdateSelection(text)
    if type(text) ~= "string" or text == "" then
        return
    end

    text = text:gsub("%s*$", "")
    text = text:gsub("|T.*|t", "")
    text = text:gsub("|c%x%x%x%x%x%x%x%x(.*)|r", "%1")
    ZhongwenSelectionBox:SetText(text)
end

-- PRE:  [definitions] is a non-empty list of [string] containing valid dictionary entries
-- POST: [ZhongwenDefinitionBox] is updated with the contents of [definitions]
function Zhongwen:UpdateDefinition(definitions)
    local text = "<html><body>"
    for k, d in ipairs(definitions) do
        text = text .. self:FormatDefinition(d) .. "<br/>"
    end
    text = text .. "</body></html>"

    ZhongwenDefinitionBox:SetText(text)
    ZhongwenDefinitionScroll:SetVerticalScroll(0)
end

-- PRE:  [ZhongwenSelectionBox] is in a valid state
-- POST: If   [ZhongwenSelectionBox] contains valid matches starting at [GetUTF8CursorPosition()]
--       Then [ZhongwenDefinitionBox] is updated with the definitions of said matches
--       Else nothing is done
function ZhongwenSelectionBox_OnCursorChanged(self)
    local cursor = self:GetUTF8CursorPosition()+1 -- Since EditBox starts indexing at 0
    local text = self:GetText()
    local left = string.utf8len(text) - cursor + 1
    local max = left < Zhongwen.maxSearchLength and left or Zhongwen.maxSearchLength

    local longestMatch = 0
    local definitionList = {}
    for i = max-1, 0, -1 do
        local word = string.utf8sub(text, cursor, cursor+i)
        for k, d in ipairs(Zhongwen:GetWordDefinitions(word)) do
            table.insert(definitionList, d)
        end
        if longestMatch == 0 and next(definitionList) ~= nil then
            longestMatch = word:len()
        end
    end

    if longestMatch == 0 then
        return
    end

    cursor = self:GetCursorPosition()
    self:HighlightText(cursor, cursor+longestMatch)
    Zhongwen:UpdateDefinition(definitionList)
end

---------------------------------------------------------------------------------------------------·
-- DOMAIN CODE                                                                                     |
---------------------------------------------------------------------------------------------------·

-------------------------------------------------·
-- DICTIONARY CODE                               |
-------------------------------------------------·

-- PRE:  [word] is a valid [string]
-- POST: If   [word] is found in the dictionary
--       Then a non-empty list of [number] containing offsets into its definitions is returned
--       Else [nil] is returned
function Zhongwen:GetWordIndices(word)
    local index = ZhongwenIndexS[word] or ZhongwenIndexT[word]
    if index == nil then
        return {}
    end

    local indexList = {}
    for i in index:gmatch("%d+") do
        table.insert(indexList, tonumber(i)+1)
    end

    return indexList
end

-- PRE:  [word] is a valid [string]
-- POST: If   [word] is found in the dictionary
--       Then a non-empty list of [string] containing its definitions is returned
--       Else [nil] is returned
function Zhongwen:GetWordDefinitions(word)
    local indexList = self:GetWordIndices(word)

    local definitionList = {}
    for k, i in ipairs(indexList) do
        local lf_pos = ZhongwenDictionary:find("\n", i, true)
        local definition = ZhongwenDictionary:sub(i, lf_pos)
        table.insert(definitionList, definition)
    end

    return definitionList
end

-------------------------------------------------·
-- FORMATTING CODE                               |
-------------------------------------------------·

-- PRE:  [vowel] is a [string] containing a valid vowel
-- POST: a [string] containing the formatted version of [syllable] is returned
function Zhongwen:GetToneVowel(vowel, tone)
    return string.utf8sub(self.toneVowels[vowel], tone, tone)
end

-- PRE:  [syllable] is a [string] containing a valid pinyin syllable
-- POST: a [string] containing the formatted version of [syllable] is returned
function Zhongwen:FormatPinyinSyllable(syllable)
    if syllable:len() == 1 then
        return syllable
    elseif syllable == "r5" then
        return ("|c%sr|r"):format(self.toneColors[5])
    elseif syllable == "xx5" then
        return ("|c%sxx|r"):format(self.toneColors[5])
    end

    syllable = syllable:lower()
    local initials, vowels, finals, tone = syllable:match("^(.-)([aeiou:]+)(.-)(%d)")
    vowels = vowels:gsub("u:", "ü")
    tone = tonumber(tone)

    local replace
    if string.utf8len(vowels) == 1 then
        replace = vowels
    elseif vowels:find("a", 1, true) then
        replace = "a"
    elseif vowels:find("e", 1, true) then
        replace = "e"
    elseif vowels:find("o", 1, true) then
        replace = "o"
    else
        replace = vowels:sub(2, 2)
    end
    vowels = vowels:gsub(replace, self:GetToneVowel(replace, tone))

    syllable = initials .. vowels .. finals
    local format = ("|c%s%s|r"):format(self.toneColors[tone], syllable)

    return format
end

-- PRE:  [translation] is a [string] containing a valid translation
-- POST: a [string] containing the formatted version of [translation] is returned
function Zhongwen:FormatTranslation(translation)
    local html = "<p>"
    for t in translation:gmatch("[^/]+") do
       html = html .. t .. "; "
    end
    html = html .. "</p>"

    return html
end

-- PRE:  [pinyin] is a [string] containing valid pinyin syllables
-- POST: a [string] containing the formatted version of [pinyin] is returned
function Zhongwen:FormatPinyin(pinyin)
    local html = "<h2>"
    for p in pinyin:gmatch("%S+") do
        html = html .. self:FormatPinyinSyllable(p) .. " "
    end
    html = html .. "</h2>"

    return html
end

-- PRE:  [simplified] is a [string] containing valid hanzi
--       [traditional] is a [string] containing valid hanzi
-- POST: a [string] containing the formatted version of [syllable] is returned
function Zhongwen:FormatHanzi(simplified, traditional)
    local hanzi = simplified
    if traditional ~= simplified then
        hanzi = hanzi .. "·" .. traditional
    end
    local html = ("<h1>|cff70a1ff%s|r</h1>"):format(hanzi)

    return html
end

-- PRE:  [definition] is a [string] containing a valid definition
-- POST: a [string] containing the formatted version of [definition] is returned
function Zhongwen:FormatDefinition(definition)
    local t, s, pinyin, translation = definition:match("^(%S+) (%S+) %[(.+)%] /(.+)/")

    local html = self:FormatHanzi(s, t)    ..
                 self:FormatPinyin(pinyin) ..
                 self:FormatTranslation(translation)
    
    return html
end