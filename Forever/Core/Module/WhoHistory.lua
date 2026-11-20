if BG.IsBlackListPlayer then return end
-- if BG.IsForever then return end

local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local Maxb = ns.Maxb

local pt = print
local realmID = GetRealmID()

BG.Init2(function()
    local parent
    local whoButton
    parent = LFGWhoListFrame
    whoButton = parent.WhoSearch

    BGLite_equip.whoFrame = BGLite_equip.whoFrame or {}
    BGLite_equip.whoFrame.history = BGLite_equip.whoFrame.history or {}

    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeSize = 1,
    })
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0, 0, 0, 1)
    f:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 0, 0)
    f:SetSize(100, 280)
    f:Hide()
    BG.WhoFrameList = f
    local t = f:CreateFontString()
    t:SetPoint("BOTTOM", f, "TOP", 0, 2)
    t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
    t:SetTextColor(RGB("FFFFFF"))
    t:SetText(L["查询记录"])

    -- 提示
    local bt = CreateFrame("Button", nil, f)
    bt:SetSize(30, 30)
    bt:SetPoint("LEFT", t, "RIGHT", -5, 0)
    local tex = bt:CreateTexture()
    tex:SetAllPoints()
    tex:SetTexture(616343)
    bt:SetHighlightTexture(616343)
    bt:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["查询记录"], 1, 1, 1)
        GameTooltip:AddLine(" ", 1, 0.82, 0, true)
        GameTooltip:AddLine(L["你可在插件设置-BiaoGe-其他功能里关闭这个功能。"], 0.5, 0.5, 0.5, true)
        GameTooltip:Show()
    end)
    BG.GameTooltip_Hide(bt)

    local buttons = {}
    local max = tonumber(format("%d", f:GetHeight() / 20))
    local function CreateHistory()
        for i, v in pairs(buttons) do
            v:Hide()
        end
        wipe(buttons)

        for i = #BGLite_equip.whoFrame.history, 1, -1 do
            if i > max then
                tremove(BGLite_equip.whoFrame.history)
            else
                break
            end
        end

        for i, v in ipairs(BGLite_equip.whoFrame.history) do
            local bt = CreateFrame("Button", nil, f, "BackdropTemplate")
            bt:SetNormalFontObject(BG.FontGold15)
            bt:SetDisabledFontObject(BG.FontDis15)
            bt:SetHighlightFontObject(BG.FontWhite15)
            bt:SetSize(f:GetWidth() - 10, 20)
            bt:RegisterForClicks("AnyUp")
            if i == 1 then
                bt:SetPoint("BOTTOMLEFT", 8, 5)
            else
                bt:SetPoint("BOTTOMLEFT", buttons[i - 1], "TOPLEFT", 0, 0)
            end
            bt:SetText(v)
            local string = bt:GetFontString()
            if string then
                string:SetWidth(bt:GetWidth() - 2)
                string:SetJustifyH("LEFT")
                string:SetWordWrap(false)
            end
            tinsert(buttons, bt)

            bt:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:ClearLines()
                GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
                GameTooltip:AddLine(AddTexture("LEFT") .. L["搜索该记录"], 1, 0.82, 0)
                GameTooltip:AddLine(AddTexture("RIGHT") .. L["删除该记录"], 1, 0.82, 0)
                GameTooltip:Show()
            end)
            bt:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            bt:SetScript("OnClick", function(self, enter)
                if enter == "RightButton" then
                    tremove(BGLite_equip.whoFrame.history, i)
                    CreateHistory()
                else
                    WhoFrameEditBox:SetText(v)
                    C_FriendList.SendWho(WhoFrameEditBox:GetText(), Enum.SocialWhoOrigin.Social)
                end
                BG.PlaySound(1)
            end)
        end
    end
    CreateHistory()

    local function hookfunc()
        local text = WhoFrameEditBox:GetText()
        if text ~= "" then
            for i = #BGLite_equip.whoFrame.history, 1, -1 do
                if BGLite_equip.whoFrame.history[i] == text then
                    tremove(BGLite_equip.whoFrame.history, i)
                end
            end
            tinsert(BGLite_equip.whoFrame.history, 1, text)
            CreateHistory()
        end
    end
    whoButton:HookScript("OnClick", function()
        hookfunc()
    end)
    WhoFrameEditBox:HookScript("OnEnterPressed", function()
        hookfunc()
    end)

    -- 导出并举报
    local whoText

    local function GetWhoText()
        whoText = nil
        local whoPlayersName = {}
        local numWhos, totalCount = C_FriendList.GetNumWhoResults()
        if numWhos and numWhos ~= 0 then
            for i = 1, numWhos do
                local info = C_FriendList.GetWhoInfo(i)
                if info then
                    local playerName, realmName = strsplit("-", info.fullName)
                    if not realmName then
                        realmName = BG.realmName
                    end
                    tinsert(whoPlayersName, playerName .. "/" .. realmName)
                end
            end
        end
        if BG.WhoFrameSendOutButton then
            local frame = BG.WhoFrameSendOutButton.frame
            if #whoPlayersName ~= 0 then
                whoText = table.concat(whoPlayersName, " ") .. " "
                BG.WhoFrameSendOutButton:Enable()
                if frame and frame:IsVisible() then
                    frame.edit1:SetText(whoText or "")
                end
            else
                BG.WhoFrameSendOutButton:Disable()
                if frame and frame:IsVisible() then
                    frame:Hide()
                end
            end
        end
    end

    BG.RegisterEvent("WHO_LIST_UPDATE", GetWhoText)

    parent:HookScript("OnShow", function()
        if BGLite_equip.options["searchList"] == 1 then
            BG.WhoFrameList:Show()
            if BG.WhoFrameSendOutButton then
                BG.WhoFrameSendOutButton:Show()
                BG.WhoFrameSendOutButton:SetText(L["导出名单"])
            end
            GetWhoText()
        else
            BG.WhoFrameList:Hide()
            if BG.WhoFrameSendOutButton then
                BG.WhoFrameSendOutButton:Hide()
            end
        end

        if BG.WhoFrameSendOutButton and BG.WhoFrameSendOutButton.frame then
            BG.WhoFrameSendOutButton.frame:Hide()
        end
    end)

    -- 记录最后打开的页面
    -- FriendsFrame:HookScript("OnShow", function(self)
    --     if not InCombatLockdown() then
    --         local i = BiaoGe.whoFrame.lastTab
    --         if i and _G["FriendsFrameTab" .. i] and _G["FriendsFrameTab" .. i]:IsVisible() then
    --             _G["FriendsFrameTab" .. i]:Click()
    --         end
    --     end
    -- end)

    -- local i = 1
    -- while _G["FriendsFrameTab" .. i] do
    --     local index = i
    --     _G["FriendsFrameTab" .. i]:HookScript("OnClick", function()
    --         BiaoGe.whoFrame.lastTab = index
    --     end)
    --     i = i + 1
    -- end
end)
