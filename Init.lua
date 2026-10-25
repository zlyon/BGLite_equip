local AddonName, ns = ...

if not BG then
    return
end

BGE = {}

do
    local function RunFuncs(funcs)
        local i = 1
        while funcs[i] do
            local func = funcs[i]
            i = i + 1
            local ok, err = pcall(func)
            if not ok then
                print("|cffff5555[BGLite_equip] 初始化错误:|r " .. tostring(err))
            end
        end
    end

    local function RunOne(func, tag)
        local ok, err = pcall(func)
        if not ok then
            print("|cffff5555[BGLite_equip] " .. tag .. "迟到回调错误:|r " .. tostring(err))
        end
    end

    local function MakeStage(event, filterByAddon, tag)
        local funcs = {}
        local fired = false
        local f = CreateFrame("Frame")
        f:RegisterEvent(event)
        f:SetScript("OnEvent", function(self, _, arg1)
            if filterByAddon and arg1 ~= AddonName then return end
            self:UnregisterEvent(event)
            fired = true
            RunFuncs(funcs)
        end)
        return function(func)
            if fired then
                RunOne(func, tag)
            else
                tinsert(funcs, func)
            end
        end
    end

    BGE.Init = MakeStage("ADDON_LOADED", true, "")
    BGE.Init2 = MakeStage("PLAYER_ENTERING_WORLD", false, "Init2 ")
    BGE.Init3 = MakeStage("PLAYER_LOGIN", false, "Init3 ")
end

local RR = "|r"
ns.RR = RR
local NN = "\n"
ns.NN = NN
local RN = "|r\n"
ns.RN = RN

local function Size(t)
    local s = 0
    for k, v in pairs(t) do
        if v ~= nil then s = s + 1 end
    end
    return s
end
ns.Size = Size

local function RGB(hex, Alpha)
    local red = hex:sub(1, 2)
    local green = hex:sub(3, 4)
    local blue = hex:sub(5, 6)
    red = tonumber(red, 16) / 255
    green = tonumber(green, 16) / 255
    blue = tonumber(blue, 16) / 255
    if Alpha then
        return red, green, blue, Alpha
    else
        return red, green, blue
    end
end
ns.RGB = RGB

local function RGB_16(name, r, g, b)
    if not r then
        r, g, b = name:GetTextColor()
        name = name:GetText()
    end
    local r = string.format("%X", tonumber(r) * 255)
    if r and strlen(r) == 1 then r = "0" .. r end
    local g = string.format("%X", tonumber(g) * 255)
    if g and strlen(g) == 1 then g = "0" .. g end
    local b = string.format("%X", tonumber(b) * 255)
    if b and strlen(b) == 1 then b = "0" .. b end
    local c = r .. g .. b
    if name then
        return "|cff" .. c .. name .. "|r"
    else
        return c
    end
end
ns.RGB_16 = RGB_16

local function SetColorName(name, r, g, b)
    if not (r and g and b) then return name end
    local r = format("%X", tonumber(r) * 255)
    if r and strlen(r) == 1 then r = "0" .. r end
    local g = format("%X", tonumber(g) * 255)
    if g and strlen(g) == 1 then g = "0" .. g end
    local b = format("%X", tonumber(b) * 255)
    if b and strlen(b) == 1 then b = "0" .. b end
    return "|cff" .. r .. g .. b .. name .. "|r"
end
ns.SetColorName = SetColorName

local function AddTexture(Texture, y, coord, width)
    if not Texture then return "" end
    local x = 0
    if not y then y = "-0" end
    local tex = ""
    local coord = coord or ""
    if Texture == "MAINTANK" then
        tex = "132064"
    elseif Texture == "MAINASSIST" then
        tex = "132063"
    elseif Texture == "TANK" then
        return "|A:ui-lfg-roleicon-tank:0:0|a"
    elseif Texture == "HEALER" then
        return "|A:ui-lfg-roleicon-healer:0:0|a"
    elseif Texture == "DAMAGER" then
        return "|A:ui-lfg-roleicon-dps:0:0|a"
    elseif Texture == 137000 or Texture == 136998 then
        coord = ":100:100:10:60:0:55"
        return "|T" .. Texture .. ":0:0:0:0" .. coord .. "|t"
    elseif Texture == "QUEST" then
        tex = "Interface\\GossipFrame\\AvailableQuestIcon"
    elseif Texture == "logo" then
        tex = "Interface\\AddOns\\BGLite\\Media\\icon\\icon"
    elseif Texture == "BOX" then
        tex = "Interface\\AddOns\\BGLite\\Media\\icon\\BOX"
    elseif Texture == "DD" then
        tex = "Interface\\AddOns\\BGLite\\Media\\icon\\DD"
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

local function GetItemID(text)
    if not text then return end
    return tonumber(text:match("item:(%d+):"))
end
ns.GetItemID = GetItemID

ns.GetClassColor = GetClassColor
ns.SendSystemMessage = BG.SendSystemMessage

local L = setmetatable({}, {
    __index = function(table, key)
        return tostring(key)
    end
})
ns.L = L

local LibBG
local ok, lib = pcall(LibStub.GetLibrary, LibStub, "BiaoGe-LibUIDropDownMenu-4.0")
if ok and lib then
    LibBG = lib
end
ns.LibBG = LibBG

local function Round(number, decimal_places)
    local mult = 10 ^ (decimal_places or 0)
    return math.floor(number * mult + 0.5) / mult
end
ns.Round = Round

ns.ver = BG.ver

ns.Maxb = BG.Maxb
local HopeMaxb, HopeMaxn = {}, {}
if BG.Maxb then
    for FB, maxb in pairs(BG.Maxb) do
        HopeMaxb[FB] = maxb - 1
        local diffTbl = BG.difficultyTable and BG.difficultyTable[FB]
        HopeMaxn[FB] = diffTbl and #diffTbl or 1
    end
end
ns.HopeMaxb = HopeMaxb
ns.HopeMaxn = HopeMaxn
ns.HopeMaxi = BG.IsWLK_80 and 3 or 7

BGE.Init(function()
    local BiaoGe = BiaoGe

    BiaoGe.Hope = BiaoGe.Hope or {}
    BiaoGe.HopeSendChannel = BiaoGe.HopeSendChannel or {}

    -- 装备库
    BiaoGe.ItemLib = BiaoGe.ItemLib or {}
    BiaoGe.ItemLibInvType = BiaoGe.ItemLibInvType or {}

    -- 预设价格
    BiaoGe.auctionPreset = BiaoGe.auctionPreset or {}

    if not BiaoGe.HistoryList then
        BiaoGe.HistoryList = {}
    end
    for _, FB in ipairs(BG.FBtable) do
        if not BiaoGe.HistoryList[FB] then
            BiaoGe.HistoryList[FB] = {}
        end
    end
    if not BiaoGe.History then
        BiaoGe.History = {}
    end
    for _, FB in ipairs(BG.FBtable) do
        if not BiaoGe.History[FB] then
            BiaoGe.History[FB] = {}
        end
    end

    BiaoGe.historySummary = BiaoGe.historySummary or {}
end)

if not BG.SetBestPrice then
    function BG.SetBestPrice(link, anchor)
        UIErrorsFrame:AddMessage("BGLite_equip：心理价格模块未就绪或初始化失败（请查看聊天框内的初始化错误）", 1, 0.3, 0.3)
    end
end

if not BG.GetSendBiaoGeMsg then
    function BG.GetSendBiaoGeMsg()
        if not BG.History or not BG.History.EscButton then return end
        local FB = BG.FB1
        local player, server = UnitFullName("player")
        local msg
        if not BG.History.EscButton:IsVisible() then
            -- [!BiaoGe:风行-阿拉希盆地-当前表格-ULD]
            msg = format("[!BiaoGe:%s-%s-%s-%s]", player, server, "Now", FB)
        else
            -- [!BiaoGe:风行-阿拉希盆地-历史表格-ULD-04月20日18:20:23 奥杜尔 25人 工资:15000]
            local chooseNum = BG.History.chooseNum
            local item = chooseNum and BiaoGe.HistoryList[FB] and BiaoGe.HistoryList[FB][chooseNum]
            msg = format("[!BiaoGe:%s-%s-%s-%s-%s]", player, server, "History", FB,
                item and item[2]:gsub("\n", "") or "")
        end
        return msg
    end
end

if not BG.CreateBossModel then
    function BG.CreateBossModel() end
end

if not BG.CreateDisableButton then
    function BG.CreateDisableButton(parent, key, defaultDisabled)
        if not parent.backBiaoGeButton then return end
        local L = ns.L
        if defaultDisabled and BiaoGe.disabledModules[key] == nil then
            BiaoGe.disabledModules[key] = true
        end
        local bt = BG.CreateButton(parent)
        bt:SetSize(150, 25)
        bt:SetPoint("RIGHT", parent.backBiaoGeButton, "LEFT", -20, 0)
        local t = bt:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        t:SetPoint("BOTTOM", bt, "TOP", 0, 3)
        bt.text = t
        if BiaoGe.disabledModules[key] then
            local t2 = parent:CreateFontString()
            t2:SetPoint("TOP", BG.MainFrame, "TOP", 0, -50)
            t2:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
            t2:SetTextColor(1, 0, 0)
            t2:SetText(L["该模块已被禁用，右下角可以启用模块"])
            bt.topText = t2
        end
        bt:SetScript("OnClick", function(self)
            BG.PlaySound(1)
            self.clicked = true
            if BiaoGe.disabledModules[key] then
                BiaoGe.disabledModules[key] = false
            else
                BiaoGe.disabledModules[key] = true
            end
            bt:UpdateText()
        end)
        function bt:UpdateText()
            self:SetText(BiaoGe.disabledModules[key] and L["启用该模块"] or L["禁用该模块"])
            if self.clicked then
                if BiaoGe.disabledModules[key] then
                    bt.text:SetText(L["该模块已禁用（重载后生效）"])
                    bt.text:SetTextColor(1, 0, 0)
                else
                    bt.text:SetText(L["该模块已启用（重载后生效）"])
                    bt.text:SetTextColor(0, 1, 0)
                end
            end
        end

        bt:UpdateText()
        parent.disableButton = bt
    end
end

function BGE.Once(name, dt, func)
    if BGLite_equip and BGLite_equip.options and BGLite_equip.options.SearchHistory then
        if not BGLite_equip.options.SearchHistory[name .. dt] then
            func()
            BGLite_equip.options.SearchHistory[name .. dt] = true
        end
    end
end

--             end
--         end
BGE.DeletePlayerDataKeys = {
    "RaidCD",
    "MONEY",
    "QuestCD",
    "worldBossCD",
    "buffCD",
    "legendaryCloak",
    "tradeSkillCooldown", -- 专业CD
    "playerInfo",
    "equip",              -- 装备
    "bag",
    "PlayerItemsLevel",
    "roleOverviewNote",
    "FBCD",
    "Money",
}
function BGE.DeletePlayerData(realmID, player)
    if type(realmID) ~= "number" or player == nil then return end
    -- 同时从自己的存档表和旧共享表删除，避免旧表数据经过渡期回退重新显示
    for _, db in ipairs({ BGLite_equip, MyUnderpants }) do
        if type(db) == "table" then
            for _, key in ipairs(BGE.DeletePlayerDataKeys) do
                local t = db[key]
                if type(t) == "table" and type(t[realmID]) == "table" then
                    t[realmID][player] = nil
                end
            end
            local sortDB = db.MyUnderpantsSort
            if type(sortDB) == "table" and type(sortDB[realmID]) == "table" then
                local list = sortDB[realmID]
                for i = #list, 1, -1 do
                    if type(list[i]) == "table" and list[i].player == player then
                        table.remove(list, i)
                    end
                end
            end
        end
    end
end

BGE.Init(function()
    if not BG.MainFrame then return end

    BG.ItemLibMainFrameTabNum = 2
    BG.HopeMainFrameTabNum = 3
    BG.ChannelHistoryMainFrameTabNum = 103
    BG.AuctionPresetMainFrameTabNum = 104
    BG.WelcomeMainFrameTabNum = 105

    local L = ns.L
    local LibBG = ns.LibBG
    local Maxb = ns.Maxb
    local HopeMaxn = ns.HopeMaxn
    local RGB = ns.RGB
    local AddTexture = ns.AddTexture
    local GetClassRGB = ns.GetClassRGB

    local onEnterDelay = .6

    BG.HopeMainFrame = CreateFrame("Frame", nil, BG.MainFrame)
    do
        BG.HopeMainFrame:Hide()
        for i, FB in ipairs(BG.FBtable) do
            BG["HopeFrame" .. FB] = CreateFrame("Frame", "BG.HopeFrame" .. FB, BG.HopeMainFrame)
            BG["HopeFrame" .. FB]:Hide()
        end
        BG.BackBiaoGe(BG.HopeMainFrame)
        BG.HopeMainFrame:SetScript("OnShow", function(self)
            local FB = BG.FB1
            BG.FrameHide(0)
            for i, FB in ipairs(BG.FBtable) do
                BG["HopeFrame" .. FB]:Hide()
            end
            BG["HopeFrame" .. FB]:Show()
            BiaoGe.lastFrame = "Hope"

            BG.HistoryMainFrame:Hide()

            BG.TabButtonsFB:Show()
            for i, FB in ipairs(BG.FBtable) do
                BG["Button" .. FB]:SetEnabled(true)
            end
            BG["Button" .. BG.FB1]:SetEnabled(false)

            if BG.NanDuDropDown then
                BG.NanDuDropDown.DropDown:Show()
                LibBG:UIDropDownMenu_EnableDropDown(BG.NanDuDropDown.DropDown)
            end

            BG.UpdateBiaoGeAllIsHaved()

            BG.FilterClassItemMainFrame.Buttons2:SetParent(self)
            BG.FilterClassItemMainFrame:Hide()
            BG.FilterClassItemMainFrame.Buttons2:UpdatePoint()

            if BG.ButtonImportHope then
                BG.ButtonImportHope:SetParent(self)
                BG.ButtonExportHope:SetParent(self)
            end
        end)
        -- 左下角文字介绍
        do
            local t = BG.HopeMainFrame:CreateFontString()
            t:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 35, 75)
            t:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
            t:SetTextColor(RGB(BG.g1))
            t:SetText(L["心愿清单："])
            local tt = t
            local t = BG.HopeMainFrame:CreateFontString()
            t:SetPoint("LEFT", tt, "RIGHT", 0, 0)
            t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            t:SetTextColor(RGB(BG.g2))
            t:SetText(L["你可以设置一些装备，这些装备只要掉落就会提醒，并且自动关注团长拍卖"])
        end
    end

    BG.ItemLibMainFrame = CreateFrame("Frame", nil, BG.MainFrame)
    do
        BG.ItemLibMainFrame:Hide()
        BG.BackBiaoGe(BG.ItemLibMainFrame)
        BG.ItemLibMainFrame:SetScript("OnShow", function(self)
            local FB = BG.FB1
            BG.FrameHide(0)
            BiaoGe.lastFrame = "ItemLib"

            BG.HistoryMainFrame:Hide()

            BG.TabButtonsFB:Show()
            for i, FB in ipairs(BG.FBtable) do
                BG["Button" .. FB]:SetEnabled(true)
            end
            BG["Button" .. BG.FB1]:SetEnabled(false)

            if BG.NanDuDropDown then
                BG.NanDuDropDown.DropDown:Hide()
            end

            BG.FilterClassItemMainFrame.Buttons2:SetParent(self)
            BG.FilterClassItemMainFrame:Hide()
            BG.FilterClassItemMainFrame.Buttons2:ClearAllPoints()
            BG.FilterClassItemMainFrame.Buttons2:SetPoint("LEFT", BG.ItemLibMainFrame.filtleText, "RIGHT", 10, 0)

            if BG.ButtonImportHope then
                BG.ButtonImportHope:SetParent(self)
                BG.ButtonExportHope:SetParent(self)
            end
        end)

        -- 左下角文字介绍
        do
            local t = BG.ItemLibMainFrame:CreateFontString()
            t:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 35, 45)
            t:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
            t:SetTextColor(RGB(BG.g1))
            t:SetText(L["装备库："])
            local tt = t
            local t = BG.ItemLibMainFrame:CreateFontString()
            t:SetPoint("LEFT", tt, "RIGHT", 0, 0)
            t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
            t:SetTextColor(RGB(BG.g2))
            t:SetText(L["查看所有适合你的装备"])
            local tt = t
            local t = BG.ItemLibMainFrame:CreateFontString()
            t:SetPoint("LEFT", tt, "RIGHT", 0, 0)
            t:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            t:SetText(format(L["（ALT+%s设为心愿装备。部位按钮支持使用滚轮切换）"], AddTexture("LEFT")))
        end
    end

    BG.ChannelHistoryMainFrame = CreateFrame("Frame", "BiaoGeChannelHistoryMainFrame", BG.MainFrame)
    do
        local mainFrame = BG.ChannelHistoryMainFrame
        mainFrame:Hide()
        BG.BackBiaoGe(mainFrame)
        BG.CreateDisableButton(mainFrame, "ChannelHistory")
        mainFrame:SetScript("OnShow", function()
            BG.FrameHide(0)
            BiaoGe.lastFrame = "ChannelHistory"
            BG.HistoryMainFrame:Hide()
            BG.TabButtonsFB:Hide()
            if BG.NanDuDropDown then
                BG.NanDuDropDown.DropDown:Hide()
            end
        end)
        mainFrame:SetScript("OnHide", function(self)
            if not self:IsShown() and BiaoGe.lastFrame == "ChannelHistory" then
                BiaoGe.lastFrame = nil
            end
        end)

        local title = mainFrame:CreateFontString()
        title:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 35, 45)
        title:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
        title:SetTextColor(0, 1, 0)
        title:SetText(L["团长历史喊话："])
        local description = mainFrame:CreateFontString()
        description:SetPoint("LEFT", title, "RIGHT")
        description:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        description:SetTextColor(RGB(BG.g2))
        description:SetText(L["查看团长在公共频道和集结号最近5小时的喊话内容，便于团员核对账单的补贴是否跟喊话一致"])
    end

    BG.AuctionPresetMainFrame = CreateFrame("Frame", "BiaoGeAuctionPresetMainFrame", BG.MainFrame)
    do
        local mainFrame = BG.AuctionPresetMainFrame
        mainFrame:Hide()
        BG.BackBiaoGe(mainFrame)
        mainFrame:SetScript("OnShow", function()
            BG.FrameHide(0)
            BG.After(0, function()
                BiaoGe.lastFrame = "AuctionPreset"
            end)
            BG.HistoryMainFrame:Hide()
            BG.TabButtonsFB:Show()
            if BG.NanDuDropDown then
                BG.NanDuDropDown.DropDown:Hide()
            end
        end)
        mainFrame:SetScript("OnHide", function(self)
            if not self:IsShown() and BiaoGe.lastFrame == "AuctionPreset" then
                BiaoGe.lastFrame = nil
            end
        end)

        local text = mainFrame:CreateFontString()
        text:SetPoint("BOTTOM", BG.MainFrame, "BOTTOM", 0, 10)
        text:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        text:SetTextColor(RGB(BG.g2))
        text:SetText(BG.STC_g1(L["预设起拍价："]) ..
            format(L["ALT+%s点击表格/背包/聊天框装备时，直接按你的预设价开拍。"], AddTexture("RIGHT")))
    end

    if not BG.IsRetail then
        BG.WelcomeMainFrame = CreateFrame("Frame", "BiaoGeWelcomeMainFrame", BG.MainFrame)
        do
            local mainFrame = BG.WelcomeMainFrame
            mainFrame:Hide()
            BG.BackBiaoGe(mainFrame)
            BG.CreateDisableButton(mainFrame, "Welcome")
            mainFrame:SetScript("OnShow", function()
                BG.FrameHide(0)
                BiaoGe.lastFrame = "Welcome"
                BG.HistoryMainFrame:Hide()
                BG.TabButtonsFB:Hide()
                if BG.NanDuDropDown then
                    BG.NanDuDropDown.DropDown:Hide()
                end
            end)
            mainFrame:SetScript("OnHide", function(self)
                if not self:IsShown() and BiaoGe.lastFrame == "Welcome" then
                    BiaoGe.lastFrame = nil
                end
            end)

            local text = mainFrame:CreateFontString()
            text:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 35, 45)
            text:SetFont(BIAOGE_TEXT_FONT, 20, "OUTLINE")
            text:SetTextColor(0, 1, 0)
            text:SetText(L["进组欢迎语"])
        end
    end

    BG.HistoryMainFrame = CreateFrame("Frame", "BG.HistoryMainFrame", BG.MainFrame)
    do
        BG.HistoryMainFrame:Hide()
        for i, FB in ipairs(BG.FBtable) do
            BG["HistoryFrame" .. FB] = CreateFrame("Frame", "BG.HistoryFrame" .. FB, BG.HistoryMainFrame)
            BG["HistoryFrame" .. FB]:Hide()
        end
        BG.HistoryMainFrame:SetScript("OnShow", function(self)
            local FB = BG.FB1
            for i, FB in ipairs(BG.FBtable) do
                BG["HistoryFrame" .. FB]:Hide()
            end
            BG["HistoryFrame" .. FB]:Show()
            BG.FBMainFrame:Hide()
            BG.Title:Hide()
            BG.VerText:Hide()
            if BGE.VerText then
                BGE.VerText:Hide()
            end

            BG.History.SaveButton:SetEnabled(false)

            BG.History.List:SetParent(self)
            BG.History.List:SetFrameLevel(BG.History.List.frameLevel)

            BG.History.HistoryButton:SetParent(self)
            BG.History.SaveButton:SetParent(self)
            BG.History.SendButton:SetParent(self)
            BG.History.DaoChuButton:SetParent(self)

            if BG.ButtonZhangDan then
                BG.ButtonZhangDan:SetParent(self)
            end
            if BG.TongBaoButtons then
                for i, bt in ipairs(BG.TongBaoButtons) do
                    bt:Disable()
                end
            end

            for i, FB in ipairs(BG.FBtable) do
                BG["Button" .. FB]:SetEnabled(false)
            end

            if BG.ButtonQingKong then
                BG.ButtonQingKong:SetParent(self)
                BG.ButtonQingKong:SetEnabled(false)
            end

            if BG.NanDuDropDown then
                LibBG:UIDropDownMenu_DisableDropDown(BG.NanDuDropDown.DropDown)
            end

            BG.UpdateBiaoGeAllIsHaved()

            BG.FilterClassItemMainFrame.Buttons2:SetParent(self)
            BG.FilterClassItemMainFrame:Hide()

            if BG.ButtonNewBee then
                BG.ButtonNewBee:Hide()
            end
        end)
        BG.HistoryMainFrame:SetScript("OnHide", function(self)
            BG.Title:Show()
            BG.VerText:Show()
            if BGE.VerText then
                BGE.VerText:Show()
            end

            if BG.ButtonNewBee then
                BG.ButtonNewBee:Show()
            end
            if not self:IsShown() then
                BG.History.chooseNum = nil
            end
        end)
    end

    do
        local bt = BG.Create_TabButton(BG.ItemLibMainFrameTabNum, L["装备库"], BG.ItemLibMainFrame)
        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["< 装备库 >"], 1, 1, 1, true)
            GameTooltip:AddLine(L["查看所有适合你的装备"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end, onEnterDelay, true)

        local bt = BG.Create_TabButton(BG.HopeMainFrameTabNum, L["心愿清单"], BG.HopeMainFrame)
        BG.OnEnterDelay(bt, function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["< 心愿清单 >"], 1, 1, 1, true)
            GameTooltip:AddLine(L["你可以设置一些装备，这些装备只要掉落就会提醒，并且自动关注团长拍卖"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end, onEnterDelay, true)

        BG.Create_TabButton(BG.AuctionPresetMainFrameTabNum, L["预设价格"], BG.AuctionPresetMainFrame)

        if BG.ChannelHistoryMainFrame then
            BG.Create_TabButton(BG.ChannelHistoryMainFrameTabNum, L["历史喊话"], BG.ChannelHistoryMainFrame)
        end

        if BG.WelcomeMainFrame then
            BG.Create_TabButton(BG.WelcomeMainFrameTabNum, L["进组欢迎语"], BG.WelcomeMainFrame, 100)
        end

        if BG.TradeHistoryMainFrame and BG.TradeHistoryMainFrameTabNum then
            BG.Create_TabButton(BG.TradeHistoryMainFrameTabNum, L["交易记录"], BG.TradeHistoryMainFrame)
        end

        do
            local order = {
                BG.FBMainFrameTabNum,          -- 表格
                BG.DuiZhangMainFrameTabNum,    -- 对账
                BG.MailHistoryMainFrameTabNum, -- 邮件记录
                BG.TradeHistoryMainFrameTabNum, -- 交易记录
                BG.ItemLibMainFrameTabNum,     -- 装备库
                BG.HopeMainFrameTabNum,        -- 心愿清单
                BG.AuctionPresetMainFrameTabNum, -- 预设价格
                BG.ChannelHistoryMainFrameTabNum,
                BG.WelcomeMainFrameTabNum,     -- 进组欢迎语
            }
            local newTbl = {}
            for _, num in ipairs(order) do
                if num then
                    for i = #BG.tabButtons, 1, -1 do
                        if BG.tabButtons[i].num == num then
                            tinsert(newTbl, tremove(BG.tabButtons, i))
                            break
                        end
                    end
                end
            end
            for _, v in ipairs(BG.tabButtons) do
                tinsert(newTbl, v)
            end
            BG.tabButtons = newTbl
            local TAB_START_X = -280
            for i, v in ipairs(BG.tabButtons) do
                local bt = v.button
                bt:ClearAllPoints()
                if i == 1 then
                    bt:SetPoint("TOPLEFT", BG.MainFrame, "BOTTOM", TAB_START_X, 1)
                else
                    bt:SetPoint("LEFT", BG.tabButtons[i - 1].button, "RIGHT", 3, 0)
                end
            end
        end
    end

    do
        function BG.UpdateBiaoGeAllIsHaved()
            local FB = BG.FB1
            if BG.FBMainFrame:IsVisible() then
                for b = 1, Maxb[FB] do
                    for i = 1, BG.GetMaxi(FB, b) do
                        local bt = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
                        if bt then
                            BG.IsHave(bt)
                        end
                    end
                end
            elseif BG.HistoryMainFrame:IsVisible() then
                for b = 1, Maxb[FB] do
                    for i = 1, BG.GetMaxi(FB, b) do
                        local bt = BG.HistoryFrame[FB]["boss" .. b]["zhuangbei" .. i]
                        if bt then
                            BG.IsHave(bt)
                        end
                    end
                end
            elseif BG.HopeMainFrame:IsVisible() then
                for n = 1, HopeMaxn[FB] do
                    for b = 1, Maxb[FB] do
                        for i = 1, BG.GetMaxi(FB, b) do
                            local bt = BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]
                            if bt then
                                BG.IsHave(bt)
                            end
                        end
                    end
                end
            elseif BG.DuiZhangMainFrame:IsVisible() then
                for b = 1, Maxb[FB] do
                    for i = 1, BG.GetMaxi(FB, b) do
                        local bt = BG.DuiZhangFrame[FB]["boss" .. b]["zhuangbei" .. i]
                        if bt then
                            BG.IsHave(bt)
                        end
                    end
                end
            end
        end
    end
end)
