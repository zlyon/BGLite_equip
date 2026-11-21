local AddonName, ns = ...

local GetItemCount = GetItemCount or C_Item.GetItemCount

local L = ns.L
local GetClassColor = ns.GetClassColor

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Maxb = ns.Maxb
local RGB = ns.RGB

local pt = print
local RealmID = GetRealmID()
BG.After = C_Timer.After

------------------函数：四舍五入------------------ 数字，小数点数
local function Round(number, decimal_places)
    local mult = 10 ^ (decimal_places or 0)
    return math.floor(number * mult + 0.5) / mult
end
ns.Round = Round

------------------函数：设置颜色（0-1代码变为16进制颜色）------------------
local function RGB_16(name, r, g, b)
    if not r then
        r, g, b = name:GetTextColor()
        name = name:GetText()
    end

    local r = string.format("%X", tonumber(r) * 255)
    if r and strlen(r) == 1 then
        r = "0" .. r
    end
    local g = string.format("%X", tonumber(g) * 255)
    if g and strlen(g) == 1 then
        g = "0" .. g
    end
    local b = string.format("%X", tonumber(b) * 255)
    if b and strlen(b) == 1 then
        b = "0" .. b
    end
    local c = r .. g .. b

    if name then
        return "|cff" .. c .. name .. "|r"
    else
        return c
    end
end
ns.RGB_16 = RGB_16

local function SetColorName(name, r, g, b)
    if not (r and g and b) then
        return name
    end
    local r = format("%X", tonumber(r) * 255)
    if r and strlen(r) == 1 then
        r = "0" .. r
    end
    local g = format("%X", tonumber(g) * 255)
    if g and strlen(g) == 1 then
        g = "0" .. g
    end
    local b = format("%X", tonumber(b) * 255)
    if b and strlen(b) == 1 then
        b = "0" .. b
    end
    return "|cff" .. r .. g .. b .. name .. "|r"
end
ns.SetColorName = SetColorName

-- 第几个BOSS
local function BossNum(FB, b, t)
    local tbl = BG.BossNumtbl[FB]
    local bb
    if tbl[t + 1] then
        bb = tbl[t + 1] - tbl[t]
    else
        bb = Maxb[FB] + 2 - tbl[t]
    end
    return b + tbl[t], bb, t, b
end
ns.BossNum = BossNum

function BG.GetBossNumInfo(FB, bossNum)
    local tbl = BG.BossNumtbl[FB]
    for i = 1, #tbl do
        if (not tbl[i + 1]) or (tbl[i] < bossNum and tbl[i + 1] >= bossNum) then
            -- 第几列，第几个
            return i, bossNum - tbl[i]
        end
    end
end

------------------在文本里插入材质图标------------------
local function AddTexture(Texture, y, coord, width)
    if not Texture then
        return ""
    end
    local x = 0
    if not y then
        y = "-0"
    end
    local tex = ""
    local coord = coord or ""
    if Texture == "MAINTANK" then                      -- 主坦克
        tex = "132064"
    elseif Texture == "MAINASSIST" then                -- 主助理
        tex = "132063"
    elseif Texture == "TANK" then                      -- 坦克职责
        return "|A:ui-lfg-roleicon-tank:0:0|a"
    elseif Texture == "HEALER" then                    -- 治疗职责
        return "|A:ui-lfg-roleicon-healer:0:0|a"
    elseif Texture == "DAMAGER" then                   -- 输出职责
        return "|A:ui-lfg-roleicon-dps:0:0|a"
    elseif Texture == 137000 or Texture == 136998 then -- 战场荣誉
        coord = ":100:100:10:60:0:55"
        local t = "|T" .. Texture .. ":0:0:0:0" .. coord .. "|t"
        return t
    elseif Texture == "QUEST" then -- 黄色感叹号
        tex = "Interface\\GossipFrame\\AvailableQuestIcon"
    elseif Texture == "logo" then
        tex = ns.Interface .. "Media\\icon\\icon"
    elseif Texture == "BOX" then
        tex = ns.Interface .. "Media\\icon\\BOX"
    elseif Texture == "DD" then
        tex = ns.Interface .. "Media\\icon\\DD"
    elseif Texture == "LEFT" then
        return "|A:NPE_LeftClick:0:0|a"
    elseif Texture == "RIGHT" then
        return "|A:NPE_RightClick:0:0|a"
    else
        tex = Texture
    end
    width = width or 0
    return "|T" .. tex .. ":" .. width .. ":" .. width .. ":" .. x .. ":" .. y .. coord .. "|t"
end
ns.AddTexture = AddTexture

local function CreateLine(parent, y, width, height, color, alpha)
    local line = parent:CreateLine()
    line:SetColorTexture(RGB(color or "808080", alpha or 1))
    line:SetStartPoint("BOTTOMLEFT", 0, y)
    line:SetEndPoint("BOTTOMLEFT", width, y)
    line:SetThickness(height or 1.5)
    return line
end
ns.CreateLine = CreateLine

local classNameTbl = {
    WARRIOR = GetClassInfo(1),
    PALADIN = GetClassInfo(2),
    HUNTER = GetClassInfo(3),
    ROGUE = GetClassInfo(4),
    PRIEST = GetClassInfo(5),
    DEATHKNIGHT = GetClassInfo(6),
    SHAMAN = GetClassInfo(7),
    MAGE = GetClassInfo(8),
    WARLOCK = GetClassInfo(9),
    MONK = GetClassInfo(10),
    DRUID = GetClassInfo(11),
    DEMONHUNTER = GetClassInfo(12),
    EVOKER = GetClassInfo(13),
}
local function GetClassName(classFile)
    return classNameTbl[classFile]
end
ns.GetClassName = GetClassName

function BG.SetButtonAtlas(bt, atlas)
    local tex = bt:CreateTexture()
    tex:SetAllPoints()
    tex:SetAtlas(atlas)
    local tex2 = bt:CreateTexture()
    tex2:SetAllPoints()
    tex2:SetAtlas(atlas)
    bt:SetNormalTexture(tex)
    bt:SetHighlightTexture(tex2)
end

function BG.CreateRoundTexture(tex, parent, w, h)
    local icon = CreateFrame("Frame", nil, parent or UIParent)
    icon:SetPoint("CENTER")
    icon:SetSize(w or 20, h or 20)

    icon.tex = icon:CreateTexture(nil, "ARTWORK")
    icon.tex:SetAllPoints()
    icon.tex:SetTexture(tex)
    icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    icon.masktex = icon:CreateMaskTexture()
    icon.masktex:SetAllPoints()
    icon.masktex:SetTexture("Interface/CharacterFrame/TempPortraitAlphaMaskSmall")

    icon.tex:AddMaskTexture(icon.masktex)
    return icon
end

------------------获取文字（删掉材质）------------------
local function GetText_T(bt)
    local text
    if type(bt) == "table" then
        text = bt:GetText()
    else
        text = bt
    end
    local t = text:gsub("|T.-|t", ""):gsub("|A.-|a", "")
    return t
end
ns.GetText_T = GetText_T

------------------函数：获取名字的职业颜色RGB------------------
local function GetClassRGB(name, player, Alpha)
    local _, class
    if player then
        _, class = UnitClass(player)
    else
        _, class = UnitClass(BG.GSN(name))
    end
    local c1, c2, c3 = 1, 1, 1
    if class then
        c1, c2, c3 = GetClassColor(class)
    end
    return c1, c2, c3, Alpha
end
ns.GetClassRGB = GetClassRGB

------------------函数：设置名字为职业颜色CFF代码（|cffFFFFFF名字|r）------------------
local function SetClassCFF(name, player, type)
    if type then return name end
    local _, class
    if player then
        _, class = UnitClass(player)
    else
        _, class = UnitClass(BG.GSN(name))
    end
    if class then
        local color = select(4, GetClassColor(class))
        return "|c" .. color .. name .. "|r"
    else
        return name
    end
end
ns.SetClassCFF = SetClassCFF

------------------函数：仅提取链接文本------------------
local function GetItemID(text)
    if not text then return end
    return tonumber(text:match("item:(%d+):"))
end
ns.GetItemID = GetItemID

------------------清除输入框的焦点------------------
function BG.ClearFocus()
    if BG.lastfocus then
        BG.lastfocus:ClearFocus()
    end
end

------------------函数：隐藏窗口------------------   -- 0：隐藏焦点+全部框架，1：隐藏全部框架，2：隐藏除历史表格外的框架
function BG.FrameHide(num)
    if num == 0 then
        if BG.lastfocus then
            BG.lastfocus:ClearFocus()
        end
    end
    if BG.FrameZhuangbeiList then
        BG.FrameZhuangbeiList:Hide()
    end
    if BG.FrameMaijiaList then
        BG.FrameMaijiaList:Hide()
    end
    if BG.FrameJineList then
        BG.FrameJineList:Hide()
    end
    if num ~= 2 then -- num是0就取消焦点，其他数字就不取消焦点
        if BG.History then
            if BG.History.List then
                BG.History.List:Hide()
            end
        end
    end
    if BG.ButtonAucitonWA and BG.ButtonAucitonWA.frame then
        BG.ButtonAucitonWA.frame:Hide()
    end
    if BG.frameExportHope then
        BG.frameExportHope:Hide()
    end
    if BG.frameImportHope then
        BG.frameImportHope:Hide()
    end
    if BG.auctionLogFrame and BG.auctionLogFrame.changeFrame then
        BG.auctionLogFrame.changeFrame:Hide()
    end
end

------------------当前表格已经有东西了------------------
function BG.BiaoGeHavedItem(FB, _type, instanceID)
    local startB = 1
    local endB = Maxb[FB] + 1
    if _type == "onlyboss" then
        endB = Maxb[FB] - 2
    elseif _type == "autoQingKong" then
        startB = BG.bossPositionStartEnd[instanceID][1]
        endB = BG.bossPositionStartEnd[instanceID][2]
    end
    for b = startB, endB do
        for i = 1, BG.GetMaxi(FB, b) do
            if BG.Frame[FB]["boss" .. b]["zhuangbei" .. i] then
                if b ~= Maxb[FB] + 1 and BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]:GetText() ~= "" then
                    return true
                end
                if BG.Frame[FB]["boss" .. b]["maijia" .. i]:GetText() ~= "" then
                    return true
                end
                if BG.Frame[FB]["boss" .. b]["jine" .. i]:GetText() ~= "" then
                    return true
                end
                if BGLite_equip[FB]["boss" .. b]["guanzhu" .. i] then
                    return true
                end
                if BGLite_equip[FB]["boss" .. b]["qiankuan" .. i] then
                    return true
                end
            end
        end
    end
    return false
end

------------------隐藏提示工具------------------
local function GameTooltip_Hide()
    GameTooltip:Hide()
end
function BG.GameTooltip_Hide(frame)
    frame:SetScript("OnLeave", GameTooltip_Hide)
end

------------------查找或匹配table里的字符------------------
do
    function BG.FindTableString(text, table)
        local num
        for key, value in pairs(table) do
            num = strfind(text, value)
            if num then
                return num
            end
        end
    end

    function BG.MatchTableString(text, table)
        local str
        for key, value in pairs(table) do
            str = strmatch(text, value)
            if str then
                return str
            end
        end
    end
end
------------------返回字符串里每个字符的位置------------------
function BG.getCharacterPositions(str)
    local positions = {}
    local position = 1

    while position <= #str do
        local byte = string.byte(str, position)

        if byte >= 0xC0 and byte <= 0xDF then
            -- 处理两个字节的UTF-8字符
            positions[string.sub(str, position, position + 1)] = position
            position = position + 2
        elseif byte >= 0xE0 and byte <= 0xEF then
            -- 处理三个字节的UTF-8字符
            positions[string.sub(str, position, position + 2)] = position
            position = position + 3
        elseif byte >= 0xF0 and byte <= 0xF7 then
            -- 处理四个字节的UTF-8字符
            positions[string.sub(str, position, position + 3)] = position
            position = position + 4
        else
            -- 处理单字节字符和非法字节
            positions[string.sub(str, position, position)] = position
            position = position + 1
        end
    end

    return positions
end

------------------隐藏全部Tab按钮------------------
function BG.HideTab(Buttons, Show)
    for i, v in ipairs(Buttons) do
        v:Hide()
        v:GetParent():SetEnabled(true)
    end
    Show:Show()
    Show:GetParent():SetEnabled(false)
end

------------------计时器------------------
function BG.OnUpdateTime(func)
    local updateFrame = CreateFrame("Frame")
    updateFrame.timeElapsed = 0
    updateFrame:SetScript("OnUpdate", func)
    return updateFrame
end

--[[
BG.OnUpdateTime(function(self,elapsed)
    self.timeElapsed=self.timeElapsed+elapsed
    if self.timeElapsed then
        self:SetScript("OnUpdate",nil)
        self:Hide()
    end
end)
 ]]

------------------设置按钮文本的宽度------------------
function BG.SetButtonStringWidth(bt)
    local t = bt:GetFontString()
    if not t then return end -- 12.0：匿名按钮可能还没有内建字体
    t:SetWidth(bt:GetWidth())
    t:SetWordWrap(false)
end

------------------按钮适应文本的宽度------------------
function BG.SetButtonWidthForString(bt)
    local t = bt:GetFontString()
    if not t then return end
    bt:SetWidth(t:GetWidth())
end

------------------是国服或亚服吗------------------
function BG.IsCN()
    if GetCurrentRegionName() == "CN" or GetCurrentRegionName() == "TW" or GetCurrentRegionName() == "KR" then
        return true
    end
end

------------------按键声音------------------
function BG.PlaySound(id)
    if BGLite_equip.options['buttonSound'] == 1 and type(id) == "number" then
        if BG["sound" .. id] then
            if id == 2 then
                PlaySoundFile(BG["sound" .. id])
            else
                PlaySound(BG["sound" .. id])
            end
        end
    elseif BGLite_equip.options['tipsSound'] == 1 and type(id) == "string" then
        local path = BG["sound_" .. id .. BGLite_equip.options.Sound]
        if path then
            if PlaySoundFile(path .. ".ogg", "Master") then return end
            if PlaySoundFile(path .. ".mp3", "Master") then return end
        end
        if BGLite_equip.options.Sound ~= "AI" then
            local fallback = BG["sound_" .. id .. "AI"]
            if fallback and not PlaySoundFile(fallback .. ".ogg", "Master") then
                PlaySoundFile(fallback .. ".mp3", "Master")
            end
        end
    end
end

------------------按钮的文本截断------------------
function BG.ButtonTextSetWordWrap(bt)
    local t = bt:GetFontString()
    if not t then return end
    t:SetWidth(bt:GetWidth())
    t:SetWordWrap(false)
end

------------------按钮的文本颜色------------------
function BG.ButtonTextColor(bt, color)
    local t = bt:GetFontString()
    if not t then return end
    t:SetTextColor(RGB(color))
end

------------------团队标记材质------------------
local tex = [[Interface\TargetingFrame\UI-RaidTargetingIcons]]
local y = -3
local RaidTargetingIcons = {
    ["xingxing"] = { num = 1, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:0:25:0:25" .. "|t" },
    ["dabing"] = { num = 2, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:25:50:0:25" .. "|t" },
    ["ziling"] = { num = 3, tex = "|T" .. tex .. ":0:0:2:" .. y .. ":100:100:55:75:0:25" .. "|t" },
    ["sanjiao"] = { num = 4, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:75:100:0:25" .. "|t" },
    ["yueliang"] = { num = 5, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:0:25:25:50" .. "|t" },
    ["fangkuai"] = { num = 6, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:25:50:25:50" .. "|t" },
    ["chacha"] = { num = 7, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:50:75:25:50" .. "|t" },
    ["kulou"] = { num = 8, tex = "|T" .. tex .. ":0:0:0:" .. y .. ":100:100:75:100:25:50" .. "|t" },
}
function BG.SetRaidTargetingIcons(type, name)
    if type then
        return "{rt" .. RaidTargetingIcons[name].num .. "}"
    else
        return RaidTargetingIcons[name].tex
    end
end

function BG.GsubRaidTargetingIcons(text)
    for k, v in pairs(RaidTargetingIcons) do
        text = text:gsub("{rt" .. v.num .. "}", v.tex)
    end
    return text
end

----------滚动到最末----------
function BG.SetScrollBottom(scroll, child)
    local offset = child:GetHeight() - scroll:GetHeight()
    if offset > 0 then
        scroll:SetVerticalScroll(offset)
    end
end

----------右键菜单切换开/关----------
function BG.DropDownListIsVisible(self)
    local _, parent = ns.Menu:GetPanel(1):GetPoint()
    if parent == self and ns.Menu:GetPanel(1):IsVisible() then
        return true
    end
end

----------高亮按钮----------
function BG.SetTextHighlightTexture(bt)
    local tex = bt:CreateTexture()
    tex:SetPoint("TOPLEFT", bt, "TOPLEFT", -8, 0)
    tex:SetPoint("BOTTOMRIGHT", bt, "BOTTOMRIGHT", 8, 0)
    tex:SetTexture("Interface/PaperDollInfoFrame/UI-Character-Tab-Highlight")
    bt:SetHighlightTexture(tex)
end

----------鼠标/按钮是否在右边----------
do
    function BG.CursorIsInRight()
        local uiScale = UIParent:GetEffectiveScale()
        if GetCursorPosition() / uiScale > UIParent:GetWidth() * 0.5 then
            return true
        end
    end

    function BG.ButtonIsInRight(self)
        if self:GetCenter() > UIParent:GetWidth() * 0.5 then
            return true
        end
    end

    function BG.ButtonIsInTop(self)
        if self:GetTop() > UIParent:GetHeight() * 0.5 then
            return true
        end
    end
end

----------把time转换为时或分----------
function BG.SecondsToTime(second, short)
    local h = floor(second / 3600)
    if h >= 1 then
        return h .. (short and "h" or L["小时"])
    end

    local m = floor(second / 60)
    if m >= 1 then
        return m .. (short and 'm' or L["分钟"])
    end

    local s = floor(second)
    if s then
        return s .. (short and 's' or L["秒"])
    end
end

----------是否已经拥有某物品----------
function BG.GetItemCount(itemIDorLink)
    local itemID = itemIDorLink
    if not tonumber(itemIDorLink) then
        itemID = tonumber(itemIDorLink:match("item:(%d+)"))
    end
    for _, FB in pairs(BG.FBtable) do
        local items = BG.Loot[FB].ExchangeItems[itemID]
        if items then
            for _, itemID3 in ipairs(items) do
                local count = GetItemCount(itemID3, true)
                if count ~= 0 then
                    return count
                end
            end
        end
    end
    return GetItemCount(itemID, true)
end

function BG.SendSystemMessage(msg)
    SendSystemMessage(BG.STC_b1("<" .. AddonName .. ">") .. " " .. msg)
end

ns.SendSystemMessage = BG.SendSystemMessage

function BG.SetBorderAlpha(self)
    self.Left:SetAlpha(BG.otherEditAlpha)
    self.Right:SetAlpha(BG.otherEditAlpha)
    self.Middle:SetAlpha(BG.otherEditAlpha)
end

function BG.FormatNumber(num, type)
    if not tonumber(num) or num % 1 ~= 0 then return num end
    num = tonumber(num)
    type = type or 1
    if type == 0 or type == 5 then -- 添加分隔符
        local formatted = tostring(num)
        formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
        return formatted
    end
    if ns.enUS then
        if type == 1 then
            if num >= 1000000 then
                return format("%.1fm", floor(num / 1000000 * 10) / 10)
            elseif num >= 1000 then
                return format("%.1fk", floor(num / 1000 * 10) / 10)
            else
                return num
            end
        elseif type == 2 then -- 添加分隔符
            local formatted = tostring(num)
            formatted = formatted:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
            return formatted
        elseif type == 3 then
            if num >= 1000000 then
                return format("%.1fm", floor(num / 1000000 * 10) / 10)
            elseif num >= 10000 then
                return format("%dk", floor(num / 1000 * 10) / 10)
            elseif num >= 1000 then
                return format("%.1fk", floor(num / 1000 * 10) / 10)
            else
                return num
            end
        end
    else
        if type == 1 then -- 省略百十个位
            if num >= 10000 then
                return format(L["%.1f万"], floor(num / 10000 * 10) / 10)
            else
                return num
            end
        elseif type == 2 then -- 输出所有小数点
            if num >= 10000 then
                local wanNum = num / 10000
                if num % 10000 == 0 then
                    return format("%d" .. L["万"], wanNum)
                elseif num % 1000 == 0 then
                    return format("%.1f" .. L["万"], wanNum)
                elseif num % 100 == 0 then
                    return format("%.2f" .. L["万"], wanNum)
                elseif num % 10 == 0 then
                    return format("%.3f" .. L["万"], wanNum)
                else
                    return format("%.4f" .. L["万"], wanNum)
                end
            else
                return num
            end
        elseif type == 3 then -- 省略十个位
            if num >= 10000 then
                return format(L["%.1f万"], floor(num / 10000 * 10) / 10)
            elseif num >= 1000 then
                return format(L["%.1fk"], floor(num / 1000 * 10) / 10)
            else
                return num
            end
        end
    end
    return num
end

function BG.Copy(table)
    if type(table) == "table" then
        local t = {}
        for k, v in pairs(table) do
            if type(v) == "table" then
                t[k] = BG.Copy(v) -- 递归拷贝子表
            else
                t[k] = v
            end
        end
        return t
    else
        return table
    end
end

local info = {
    "Hope",
    "FilterClassItemDB",
    "filterClassNum",
    "MeetingHorn",
    "MeetingHornWhisper",
    "FBCD",
    "RaidCD",
    "QuestCD",
    "Money",
    "MONEY",
    "tradeSkillCooldown",
    "PlayerItemsLevel",
    "playerInfo",
    "equip",
    "bag",
    "worldBossCD",
    "roleOverviewNote",
    "buffCD",
    "legendaryCloak",
    "bestPrice",
    "mailHistory",
    "tradeHistory",
    "lastChooseLFD",
    -- "",
}
-- 删除某个角色的全部数据。存档分两层：顶层（金团表格）与 ZL 子表（角色总览），两边都要清
function BG.DeletePlayerData(realmID, player)
    if not realmID or not player then return end
    local function wipeLayer(tbl)
        if type(tbl) ~= "table" then return end
        for _, key in pairs(info) do
            local t = tbl[key]
            if type(t) == "table" and type(t[realmID]) == "table" then
                t[realmID][player] = nil
            end
        end
        local sortDB = tbl.RoleOverviewSort and tbl.RoleOverviewSort[realmID]
        if type(sortDB) == "table" then
            for i = #sortDB, 1, -1 do
                if sortDB[i].player == player then
                    tremove(sortDB, i)
                end
            end
        end
    end
    wipeLayer(BGLite_equip)
    wipeLayer(BGLite_equip.ZL)
end

--获取副本tbl某个value
function BG.GetFBinfo(FB, info)
    for i, v in ipairs(BG.FBtable2) do
        if FB == v.FB then
            if v[info] then
                return v[info]
            elseif info == "shortName" then
                return v.localName
            end
        end
    end
end

function BG.GetSpecID()
    return GetSpecializationInfo(GetSpecialization())
end

function BG.SetSpecIDToLink(link)
    return link
end

-- function BG.GsubLink(link1,link2)
--     return link1:gsub("(item:)%d+:[%d-:]+","%1"..link2)
-- end

local function Get(link)
    link = link:match("item:(%d+:[%d-:]+)")
    if not link then return end
    link = link:gsub(":+$", "")
    local tbl = { strsplit(":", link) }
    local itemID = tbl[1]
    local bonus = {}
    for i = 13, #tbl do
        tinsert(bonus, tbl[i])
    end
    return itemID, bonus
end
function BG.IsSameItem(link1, link2)
    return GetItemID(link1) == GetItemID(link2)
end

local function GetID(link)
    if type(link) == "number" or tonumber(link) then
        return link
    elseif type(link) == "string" then
        return GetItemID(link)
    elseif type(link) == "table" then
        return GetID(link:GetText())
    end
end
function BG.IsSame(link1, link2)
    return GetID(link1) == GetID(link2)
end

function BG.OnItemLoad(item)
    if type(item) == "number" then
        return Item:CreateFromItemID(item)
    elseif type(item) == "string" then
        return Item:CreateFromItemLink(item)
    end
end

function BG.ClearColorCode(text)
    return text:gsub("|c........", ""):gsub("|r", "")
end

function BG.ClearCode(text)
    return text:gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|cff......", ""):gsub("|r", "")
end

function BG.ValueInTable(tbl, value)
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
end

function BG.GetNpcID(guid)
    if guid then
        local npcType, _, _, _, _, npcID = strsplit("-", guid)
        return tonumber(npcID) or 0, npcType
    else
        return "", ""
    end
end

function BG.OnEnterDelay(self, func, delay, isHook)
    delay = delay or .4
    local script = isHook and self.HookScript or self.SetScript
    script(self, "OnEnter", function(self)
        self.isOnEnter = true
        if func then
            self.t = 0
            self:SetScript("OnUpdate", function(self, t)
                self.t = self.t + t
                if self.t >= delay then
                    self:SetScript("OnUpdate", nil)
                    func(self)
                end
            end)
        end
    end)
end

function BG.OnLeaveDelay(self, func)
    self:SetScript("OnLeave", function(self)
        self.isOnEnter = false
        self:SetScript("OnUpdate", nil)
        GameTooltip:Hide()
        if func then
            func(self)
        end
    end)
end

function BG.IsMe(realmID, player)
    return realmID == BG.realmID and player == BG.myName
end

function BG.SetCD(self, time)
    if self.cd then return true end
    self.cd = true
    BG.After(time, function()
        self.cd = nil
    end)
end

function BG.GetNextWeekTime() -- 距离下周四还有多少秒
    local resetDay = 2
    if BG.IsCN() then
        resetDay = 4
    end

    local currentTimestamp = GetServerTime()
    local currentWeekday = date("%w", currentTimestamp)
    local daysToThursday = resetDay - currentWeekday
    local nextThursdayTimestamp

    local today = date("*t", currentTimestamp)
    if daysToThursday == 0 and today.hour < 7 then
        -- 如果时间小于当天凌晨7点
        today.hour = 7
        today.min = 0
        today.sec = 0
        nextThursdayTimestamp = time(today)
    else
        -- 如果已经是周四了，则日期+7
        if daysToThursday <= 0 then
            daysToThursday = daysToThursday + 7
        end
        nextThursdayTimestamp = currentTimestamp + daysToThursday * 86400

        local nextThursdayDateTable = date("*t", nextThursdayTimestamp)
        nextThursdayDateTable.hour = 7
        nextThursdayDateTable.min = 0
        nextThursdayDateTable.sec = 0
        nextThursdayTimestamp = time(nextThursdayDateTable)
    end
    return nextThursdayTimestamp - currentTimestamp, nextThursdayTimestamp
end

function BG.GetNextDayTime() -- 距离明天7点还有多少秒
    local currentTimestamp = GetServerTime()
    local tomorrow7amTimestamp
    local today = date("*t", currentTimestamp)
    -- 如果时间小于当天凌晨7点
    if today.hour < 7 then
        today.hour = 7
        today.min = 0
        today.sec = 0
        tomorrow7amTimestamp = time(today)
    else
        -- 获取明天凌晨7点的时间戳
        local tomorrow = date("*t", currentTimestamp + 86400) -- 加上一天的秒数
        tomorrow.hour = 7
        tomorrow.min = 0
        tomorrow.sec = 0
        tomorrow7amTimestamp = time(tomorrow)
    end
    return tomorrow7amTimestamp - currentTimestamp, tomorrow7amTimestamp
end

function BG.Split(delimiter, str)
    local result = {}
    local delimiterLen = string.len(delimiter)
    local startPos = 1                                              -- 每次切割的起始位置
    while true do
        local findPos = string.find(str, delimiter, startPos, true) -- true表示纯文本匹配（不转义）
        if not findPos then
            local part = string.sub(str, startPos)
            table.insert(result, part)
            break
        end
        local part = string.sub(str, startPos, findPos - 1)
        table.insert(result, part)
        startPos = findPos + delimiterLen
    end
    return unpack(result)
end

function BG.SetMixin(f, mixin)
    if type(f) == "table" then
        for k, v in pairs(mixin) do
            if f.HasScript and f:HasScript(k) then
                f:SetScript(k, v)
            else
                f[k] = v
            end
        end
    end
end

function BG.CreateCloseButton(f, x, y, point)
    f.CloseButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.CloseButton:SetPoint(point or "TOPRIGHT", x or BG.CloseButtonOffset, y or BG.CloseButtonOffset)
    f.CloseButton:SetScript("OnClick", function(self)
        f:Hide()
    end)
end

function BG.GetDiffShortName(diff)
    if diff == 14 then
        return "|cff00BFFFN|r"
    elseif diff == 15 then
        return "|cffFF0000H|r"
    elseif diff == 16 or diff == 233 then
        return "|cffa335eeM|r"
    end
end

function BG.ShowNotLootTips(bossID)
    local text = BG.notLootBossIDs[bossID]
    local loot = C_PartyInfo.GetLootMethod()
    if text and (loot == "master" or loot == 2) and not IsMasterLooter() then
        BG.FrameLootMsg:AddMessage(BG.STC_y1(text))
    end
end

function BG.IsSecret(value)
    return issecretvalue and value and issecretvalue(value)
end

function BG.InBoss()
    return issecretvalue and BG.IsNewUI and C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress()
end

-- 创建右下角可拖动的缩放按钮
do
    local btMixin = {}
    local ag = 0.002 -- 灵敏度可调整
    local function SetValue(optionName, newScale)
        BGLite_equip.options[optionName] = newScale
        BG.options["button" .. optionName]:SetValue(newScale)
        BG.options["button" .. optionName].edit:SetText(newScale)
    end
    function btMixin:OnMouseDown(btn)
        if btn == "LeftButton" then
            self.isDragging = true
            self.startX = GetCursorPosition()
            self.startScale = self:GetParent():GetScale()
        elseif btn == "RightButton" then
            local newScale = BG.options[self.optionName .. "reset"]
            self:GetParent():SetScale(newScale)
            SetValue(self.optionName, newScale)
        end
    end

    function btMixin:OnMouseUp()
        self.isDragging = false
    end

    function btMixin:OnUpdate()
        if not self.isDragging then return end
        local uiScale = UIParent:GetScale()
        local curX = GetCursorPosition()
        local deltaX = (curX - self.startX) / uiScale
        local newScale = self.startScale + deltaX * ag
        newScale = format("%.3f", math.max(self.minValue, math.min(newScale, self.maxValue)))
        self:GetParent():SetScale(newScale)
        SetValue(self.optionName, newScale)
    end

    function BG.CreateFrameResizeHandle(parent, optionName, minValue, maxValue, size, x, y)
        size = size or 20
        x = x or 0
        y = y or 0
        local bt = CreateFrame("Button", nil, parent)
        bt:SetSize(size, size)
        bt:SetPoint("BOTTOMRIGHT", x, y)
        bt:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
        bt:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
        bt:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
        bt.optionName = optionName
        bt.minValue = minValue
        bt.maxValue = maxValue
        BG.SetMixin(bt, btMixin)
        return bt
    end
end

function BG.IsHideTooltipKeyDown()
    return IsShiftKeyDown() and IsControlKeyDown()
end

function BG.IsSetBestPriceKeyDown(isRightClick)
    if BG.SetBestPrice then
        if BG.IsML then
            return IsAltKeyDown() and IsControlKeyDown()
        else
            return isRightClick and IsAltKeyDown()
        end
    end
end

function BG.GetAddonChannelName(channel, i)
    return channel .. ((i - 1) % BG.addonChannelCount + 1)
end

function BG.GetTargetBiaoGeVerIsOver(target, ver)
    local targetVer = BG.raidBiaoGeVersion[target]
    if targetVer and BG.GetVerNum(targetVer) >= ver then
        return true
    end
    return false
end

function BG.TargetVerOver(name, verNum)
    local ver = BG.raidBiaoGeVersion[name]
    return ver and BG.GetVerNum(ver) >= verNum
end

function BG.GetPresetMoney(item, FB)
    if not BGLite_equip.auctionPreset then return end
    local itemID, retailKey
    if type(item) == "number" then
        itemID = item
    elseif type(item) == "string" then
        itemID = GetItemID(item)
        local itemText
        if itemText then
            itemText = itemText:gsub(":+$", "")
            local fieldIndex = 0
            retailKey = itemText:gsub(":([^:]*)", function(value)
                fieldIndex = fieldIndex + 1
                if fieldIndex == 9 or fieldIndex == 10 then
                    return ":"
                end
                return ":" .. value
            end)
        end
    end
    if not itemID then return end
    local function GetFromFB(fb)
        local preset = BGLite_equip.auctionPreset[fb]
        local moneyDB = preset and preset.money
        if not moneyDB then return end

        local key = retailKey and moneyDB[retailKey] and retailKey
        if not key then
            key = BG.GetLeiTingItem(itemID, fb) or itemID
        end
        local money = moneyDB[key]
        if money then
            return money, moneyDB[key .. "tips"]
        end
    end

    if FB then
        return GetFromFB(FB)
    end

    local money, tips = GetFromFB(BG.FB1)
    if money then
        return money, tips
    end
    for _, fb in pairs(BG.FBtable) do
        if fb ~= BG.FB1 then
            money, tips = GetFromFB(fb)
            if money then
                return money, tips
            end
        end
    end
end

-- 无限服"大服务"会把若干同规则集的子服并成一个大服，
-- 但 GetRealmName() 拿到的是服务端 realmlist 里的原文（CN1Realm9RPPvP、CAMWOWCN1Realm12PvP 这种），
-- 又长又不统一，还夹杂着 CAMWOW 之类的构建前缀。这里把原始串解析成规则集，列表按规则集归组。
local REALM_RULESET = {
    -- 顺序不能改：带 RP 的必须排在 PVP/PVE 前面，否则会被抢先匹配
    { "RPPVP", "RP-PVP" },
    { "RPPVE", "RP-PVE" },
    { "PVP", "PVP" },
    { "PVE", "PVE" },
    { "NORMAL", "PVE" },
    -- 只写 RP 的是角色扮演服，规则底子是 PVE
    { "RP", "RP-PVE" },
}

function BG.GetRawRealmName(realmID)
    local name = BGLite_equip.realmName and BGLite_equip.realmName[realmID]
    if name then
        return name
    end
    local zlRealm = BGLite_equip.ZL and BGLite_equip.ZL.realmName
    return zlRealm and zlRealm[realmID]
end

-- 输入 realm 原始串，返回：规则集（PVP / PVE / RP-PVP / RP-PVE）、子服编号
function BG.ParseRealmRuleSet(raw)
    if type(raw) ~= "string" or raw == "" then
        return nil
    end
    local up = string.upper(raw)
    for _, v in ipairs(REALM_RULESET) do
        if string.find(up, v[1], 1, true) then
            return v[2], tonumber(string.match(raw, "[Rr]ealm%s*(%d+)"))
        end
    end
end

-- 把 realm 原始串换成好认的显示名；解析不出规则集的（别的服、多战网数据）原样返回
function BG.FormatRealmName(raw)
    local set, num = BG.ParseRealmRuleSet(raw)
    if not set then
        return raw
    end
    if num then
        return string.format("%s · %d区", set, num)
    end
    return set
end

-- 自定义规则集 -------------------------------------------------------------
-- 这个客户端不再下发规则集（GetRealmName 只回「无限服」这种统一串），玩家自己知道
-- 哪台是 PVP、哪台是 RP，于是允许在「角色配置」里右键服名手工指定。
-- 存在存档 BGLite_equip.ZL.realmRule[realmID]（字符串），nil = 跟随客户端自动识别。
BG.REALM_RULES = { "PVP", "PVE", "RP", "RP-PVP" }

function BG.IsRealmRule(v)
    for _, x in ipairs(BG.REALM_RULES) do
        if x == v then return true end
    end
    return false
end

local function RealmRuleTable(create)
    local db = type(BGLite_equip) == "table" and BGLite_equip
    if not db then return nil end
    local zl = db.ZL
    if type(zl) ~= "table" then
        if not create then return nil end
        zl = {}
        db.ZL = zl
    end
    local t = zl.realmRule
    if type(t) ~= "table" then
        if not create then return nil end
        t = {}
        zl.realmRule = t
    end
    return t
end

function BG.GetCustomRealmRule(realmID)
    local id = tonumber(realmID)
    if not id or id == 0 then return nil end
    local t = RealmRuleTable()
    local v = t and t[id]
    if BG.IsRealmRule(v) then return v end
end

-- rule 传 nil = 清除（恢复自动识别）。返回 true 表示已写进存档。
function BG.SetRealmRule(realmID, rule)
    local id = tonumber(realmID)
    if not id or id == 0 then return false end
    if rule ~= nil and not BG.IsRealmRule(rule) then return false end
    local t = RealmRuleTable(true)
    if not t then return false end
    t[id] = rule
    return true
end
function BG.GetRealmRuleSet(realmID)
    local custom = BG.GetCustomRealmRule(realmID)
    if custom then return custom end
    return BG.ParseRealmRuleSet(BG.GetRawRealmName(realmID))
end

-- 服务器位次命名 -------------------------------------------------------------
-- 这个客户端某次更新后不再下发真服名（GetRealmName 只返回「无限服」这种统一串），
-- 于是同一玩家名下的多台服务器在界面上全叫一个名字，分组也分不开。
-- 规则：第一台遇到的用原名，第二台叫「原名二」，第三台「原名三」……
-- 位次记在存档 BGLite_equip.ZL.realmOrder 里（数组），跨角色、跨会话都稳定。
local CN_NUM = { "一", "二", "三", "四", "五", "六", "七", "八", "九" }
local function CnNum(n)
    n = tonumber(n) or 0
    if n <= 0 then return "" end
    if n < 10 then return CN_NUM[n] end
    if n < 20 then return "十" .. (n % 10 == 0 and "" or CN_NUM[n % 10]) end
    local t, r = math.floor(n / 10), n % 10
    if t > 9 then return tostring(n) end
    return CN_NUM[t] .. "十" .. (r == 0 and "" or CN_NUM[r])
end
BG.CnNum = CnNum

local function RealmOrder()
    if type(BGLite_equip) ~= "table" then return nil end
    if type(BGLite_equip.ZL) ~= "table" then BGLite_equip.ZL = {} end
    if type(BGLite_equip.ZL.realmOrder) ~= "table" then BGLite_equip.ZL.realmOrder = {} end
    return BGLite_equip.ZL.realmOrder
end

-- 服务器编号 → 第几台（1 起）。没记过就追加到末尾。
function BG.RealmSeq(realmID)
    realmID = tonumber(realmID)
    if not realmID or realmID == 0 then return nil end
    local list = RealmOrder()
    if not list then return nil end
    for i = 1, #list do
        if list[i] == realmID then return i end
    end
    list[#list + 1] = realmID
    return #list
end

-- 登录时调一次：当前服务器排第一（先玩到的叫原名），其余按编号升序补齐。
-- 用排序而不是 pairs，名字才不会每次进游戏都跳。
function BG.SyncRealmOrder(cur)
    local list = RealmOrder()
    if not list then return end
    local seen = {}
    for _, v in ipairs(list) do
        if type(v) == "number" then seen[v] = true end
    end
    cur = tonumber(cur) or tonumber(BG.realmID)
    if cur and cur ~= 0 and not seen[cur] then
        list[#list + 1] = cur
        seen[cur] = true
    end
    local extra = {}
    for _, src in ipairs({ BGLite_equip.playerInfo, BGLite_equip.ZL and BGLite_equip.ZL.playerInfo }) do
        if type(src) == "table" then
            for k in pairs(src) do
                local n = tonumber(k)
                if n and n ~= 0 and not seen[n] then extra[#extra + 1] = n end
            end
        end
    end
    table.sort(extra)
    for _, n in ipairs(extra) do
        list[#list + 1] = n
        seen[n] = true
    end
end

-- 不带位次的原名（保密值/拼接异常一律放弃，交给调用方兜底）
local function RealmBaseName(realmID)
    local raw = BG.GetRawRealmName(realmID)
    if type(raw) ~= "string" or raw == "" then return nil end
    local ok, name = pcall(BG.FormatRealmName, raw)
    if not ok or type(name) ~= "string" or name == "" then return nil end
    return name
end

-- 需要区分同一规则集下不同子服的地方用这个（邮件记录、交易记录、角色配置的服务器分组等）
-- 能解析出规则集的（PVP · 3区）天然唯一，直接用；否则一律「无限服」的按位次加 二/三/四。
-- 0 号键 = 老存档里认不出属于哪台服务器的数据。
function BG.GetRealmDisplay(realmID)
    local id = tonumber(realmID)
    if not id then
        local raw = BG.GetRawRealmName(realmID) or tostring(realmID)
        return BG.FormatRealmName(raw)
    end
    local unknown = (L and L["未知服务器"]) or "未知服务器"
    if id == 0 then return unknown end

    -- 玩家手工指定的规则集优先：分组名直接用它（这个客户端不给子服编号，拼不出「3区」）
    local custom = BG.GetCustomRealmRule(id)
    if custom then return custom end

    local raw = BG.GetRawRealmName(id)
    if type(raw) == "string" and BG.ParseRealmRuleSet(raw) then
        return BG.FormatRealmName(raw)
    end
    local base = RealmBaseName(id)
    if not base then
        -- 这台服务器还没记到名字：沿用第一台的名字（无限服 → 无限服二），顺手记进存档，下次不用再推
        local list0 = RealmOrder()
        local first = list0 and list0[1]
        if first and first ~= id then base = RealmBaseName(first) end
        if base then
            if type(BGLite_equip.realmName) == "table" then BGLite_equip.realmName[id] = base end
            if type(BGLite_equip.ZL.realmName) == "table" then BGLite_equip.ZL.realmName[id] = base end
        end
    end
    base = base or unknown
    -- 确保它在位次表里（RealmSeq 没记过会追加），再按「同名的一共几台、我排第几」编号。
    -- 已经手工指定规则集的不占号，免得剩下的人变成「无限服、无限服三」这种跳号。
    BG.RealmSeq(id)
    local list = RealmOrder()
    local total, seq = 0, 0
    if list then
        for _, k in ipairs(list) do
            if not BG.GetCustomRealmRule(k) and (RealmBaseName(k) or unknown) == base then
                total = total + 1
                if k == id then seq = total end
            end
        end
    end
    if total <= 1 or seq <= 1 then return base end
    return base .. CnNum(seq)
end

----------12.0 兼容：匿名按钮的字体对象----------
-- 12.0/Midnight 客户端里，CreateFrame("Button", nil, parent) 建的匿名按钮在尚未显示过时
-- 不会生成内建 $parentText，SetText 之后 GetFontString() 仍返回 nil（老客户端会立即创建）。
-- 缺字体时自建一个交给按钮，已有内建字体时原样返回，不影响老客户端。
function BG.EnsureButtonFontString(bt, fontObject)
    if not bt then return nil end
    local t = bt:GetFontString()
    if t then return t end
    t = bt:CreateFontString(nil, "OVERLAY")
    t:SetFontObject(fontObject or _G.GameFontNormal)
    t:SetJustifyH("LEFT")
    t:SetPoint("LEFT")
    if bt.SetFontString then bt:SetFontString(t) end
    local text = bt:GetText()
    if text then t:SetText(text) end
    return t
end
