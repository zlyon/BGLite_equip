local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local Maxb = ns.Maxb

local LibCustomGlow = LibStub and LibStub("LibCustomGlow-1.0", true)

BGE.Init(function()
    BiaoGe.Auction = BiaoGe.Auction or {}
    BiaoGe.Auction.autoStartMax = max(4, min(10, tonumber(BiaoGe.Auction.autoStartMax) or 6))
    BiaoGe.Auction.autoStartOnlySingle = BiaoGe.Auction.autoStartOnlySingle ~= 0 and 1 or 0

    local auctionLogFrame = BG.auctionLogFrame
    if not auctionLogFrame then return end

    local frame
    for _, child in ipairs({ auctionLogFrame:GetChildren() }) do
        if child.scroll then
            frame = child
            break
        end
    end
    if not frame then return end

    local dropDown = LibBG and LibBG.Create_UIDropDownMenu and LibBG:Create_UIDropDownMenu(nil, auctionLogFrame)


local bt = BG.CreateButton(frame)
bt:SetPoint("BOTTOMLEFT", frame, 2, 2)
bt:SetPoint("TOPRIGHT", frame, 'BOTTOMRIGHT', -24, 25)
bt:SetFrameLevel(110)
bt:SetText(L["全自动发起拍卖"])
bt:RegisterForClicks("AnyUp")
bt:Hide()
BG.auctionLogFrame.ButtonAutoStartAuction = bt
bt:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        BG.ShowAutoStartAuctionMenu(self)
    else
        if not BG.IsML then return end
        BG.ToggleAutoStartAuction()
    end
end)
bt:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
    GameTooltip:ClearLines()
    GameTooltip:AddLine(self:GetText(), 1, 1, 1, true)
    GameTooltip:AddLine(L["对未拍列表中有预设价格的装备，从前往后，全自动发起拍卖。"], 1, .82, 0, true)
    GameTooltip:AddLine(' ', 1, 0, 0, true)
    GameTooltip:AddLine(L["当前最大同时拍卖数：%s件"]:format(BiaoGe.Auction.autoStartMax), 1, .82, 0, true)
    GameTooltip:AddLine(L["右键：打开菜单选项"], 1, .82, 0, true)
    if BG.IsML then
        local FB = BG.FB1
        local moneyDB = BiaoGe.auctionPreset and BiaoGe.auctionPreset[FB] and BiaoGe.auctionPreset[FB].money
        local hasPresetPrice
        for _, button in ipairs(BG.auctionLogFrame.buttons) do
            if moneyDB and moneyDB[BG.GetLeiTingItem(button.itemID, FB)] then
                hasPresetPrice = true
                break
            end
        end
        if #BG.auctionLogFrame.buttons > 0 and not hasPresetPrice then
            GameTooltip:AddLine(' ', 1, 0, 0, true)
            GameTooltip:AddLine(L["未拍列表里没有预设价格的装备，在表格底部预设价格标签里设价格。"], 1, 0, 0, true)
        end
    else
        GameTooltip:AddLine(' ', 1, 0, 0, true)
        GameTooltip:AddLine(L["该功能只有团长或物品分配者可用。"], 1, 0, 0, true)
    end
    GameTooltip:Show()
end)
bt:SetScript("OnLeave", GameTooltip_Hide)

-- 全自动发起拍卖
local function UpdateAutoStartAuctionButton()
    local bt = BG.auctionLogFrame.ButtonAutoStartAuction
    if not bt then return end
    local show = BiaoGe.options.auctionLogChoose == 4 and not BG.History.chooseNum and not (BG.HistoryMainFrame and BG.HistoryMainFrame:IsVisible())
    bt:SetShown(show)
    if show and not BG.IsML then
        BG.auctionLogFrame.autoStartAuction = nil
        BG.auctionLogFrame.autoStartAuctionFB = nil
    end
    local glowKey = "AutoStartAuction"
    local shouldGlow = show and BG.auctionLogFrame.autoStartAuction
    if shouldGlow and not bt.autoStartAuctionGlow and LibCustomGlow then
        LibCustomGlow.PixelGlow_Start(bt, nil, 8, 0.15, nil, 1, 0, 0, true, glowKey)
        bt.autoStartAuctionGlow = true
    elseif not shouldGlow and bt.autoStartAuctionGlow then
        LibCustomGlow.PixelGlow_Stop(bt, glowKey)
        bt.autoStartAuctionGlow = nil
    end
    if not show then return end

    bt:SetText(BG.auctionLogFrame.autoStartAuction and L["停止自动发起拍卖"] or AddTexture('QUEST') .. L["全自动发起拍卖"])
end

local function StopAutoStartAuction(showMessage)
    BG.auctionLogFrame.autoStartAuction = nil
    BG.auctionLogFrame.autoStartAuctionFB = nil
    UpdateAutoStartAuctionButton()
    if showMessage then
        BG.SendSystemMessage(L["由于切换了其他表格，已停止全自动发起拍卖。"])
    end
end

local function GetAutoStartAuctionItem()
    local FB = BG.FB1
    local preset = BiaoGe.auctionPreset and BiaoGe.auctionPreset[FB]
    local moneyDB = preset and preset.money
    if not moneyDB then return end

    local auctioned = {}
    for _, info in ipairs(BiaoGe[FB].auctionLog or {}) do
        local itemID = GetItemID(info.zhuangbei)
        if itemID then
            auctioned[itemID] = (auctioned[itemID] or 0) + 1
        end
    end

    local notAuctionedCounts = {}
    local countedAuctioned = BG.Copy(auctioned)
    for b = 1, Maxb[FB] do
        for i = 1, BG.GetMaxi(FB, b) do
            local item = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
            local itemID = item and GetItemID(item:GetText())
            if itemID and countedAuctioned[itemID] and countedAuctioned[itemID] > 0 then
                countedAuctioned[itemID] = countedAuctioned[itemID] - 1
            elseif itemID then
                notAuctionedCounts[itemID] = (notAuctionedCounts[itemID] or 0) + 1
            end
        end
    end
    for _, itemID in ipairs(BG.auctionLogFrame.auctioning) do
        auctioned[itemID] = (auctioned[itemID] or 0) + 1
    end

    for b = 1, Maxb[FB] do
        for i = 1, BG.GetMaxi(FB, b) do
            local item = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
            local link = item and item:GetText()
            local itemID = link and GetItemID(link)
            if itemID and auctioned[itemID] and auctioned[itemID] > 0 then
                auctioned[itemID] = auctioned[itemID] - 1
            elseif itemID then
                local money = moneyDB[BG.GetLeiTingItem(itemID, FB)]
                if money and (BiaoGe.Auction.autoStartOnlySingle ~= 1 or notAuctionedCounts[itemID] == 1) then
                    return itemID, link, money
                end
            end
        end
    end
end

local function AutoStartAuctionCheck()
    if not BG.auctionLogFrame.autoStartAuction then return end
    if BG.auctionLogFrame.autoStartAuctionFB ~= BG.FB1 then
        StopAutoStartAuction(true)
        return
    end
    if not BG.IsML then
        StopAutoStartAuction()
        return
    end

    local maxCount = BiaoGe.Auction.autoStartMax
    local windowCount = 0
    if BGA and BGA.Frames then
        for _ in pairs(BGA.Frames) do
            windowCount = windowCount + 1
        end
    end
    if windowCount >= maxCount then return end

    local itemID, link, money = GetAutoStartAuctionItem()
    if not itemID then
        StopAutoStartAuction()
        return
    end

    local duration = tonumber(BiaoGe.Auction.duration) or 0
    if duration <= 1 then
        duration = 40
    end
    local isGen2 = BiaoGe.Auction.gen == 2
    local mod = BiaoGe.Auction.mod
    local resetThreshold = max(tonumber(BiaoGe.Auction.resetThreshold) or 0, 10)
    BG.SendStartAuctionMsg(isGen2, itemID, money, duration, mod, link, resetThreshold)
end

local function GetDelayTime()
    return BiaoGe.Auction.gen == 2 and 1 or 1.5
end
local function ScheduleAutoStartAuctionCheck()
    BG.After(GetDelayTime(), function()
        if not BG.auctionLogFrame.autoStartAuction then return end
        AutoStartAuctionCheck()
        ScheduleAutoStartAuctionCheck()
    end)
end

function BG.ToggleAutoStartAuction()
    if not BG.IsML then return end
    BG.PlaySound(1)
    if BG.auctionLogFrame.autoStartAuction then
        StopAutoStartAuction()
        return
    end
    BG.auctionLogFrame.autoStartAuction = true
    BG.auctionLogFrame.autoStartAuctionFB = BG.FB1
    UpdateAutoStartAuctionButton()
    AutoStartAuctionCheck()
    ScheduleAutoStartAuctionCheck()
end

hooksecurefunc(BG, "ClickFBbutton", function(FB)
    if BG.auctionLogFrame.autoStartAuction and BG.auctionLogFrame.autoStartAuctionFB ~= FB then
        StopAutoStartAuction(true)
    end
end)

function BG.ShowAutoStartAuctionMenu(self)
    local menu = {
        {
            isTitle = true,
            text = L["最大同时拍卖数"],
            notCheckable = true,
        },
    }
    for i = 4, 10 do
        local count = i
        tinsert(menu, {
            text = count,
            checked = BiaoGe.Auction.autoStartMax == count,
            func = function()
                BiaoGe.Auction.autoStartMax = count
                LibBG:CloseDropDownMenus()
            end,
        })
    end
    tinsert(menu, {
        text = "   ",
        isTitle = true,
        notCheckable = true,
    })
    tinsert(menu, {
        text = L["只拍卖数量为1的装备"],
        checked = BiaoGe.Auction.autoStartOnlySingle == 1,
        classicChecks = true,
        tooltipTitle = L["只拍卖数量为1的装备"],
        tooltipText = L["若同一装备在未拍列表中有2件或以上，则不会自动拍卖。例如：战猎萨套装一共掉落了2件，则不会拍卖该装备。"],
        tooltipOnButton = true,
        func = function()
            BiaoGe.Auction.autoStartOnlySingle = BiaoGe.Auction.autoStartOnlySingle == 1 and 0 or 1
            LibBG:CloseDropDownMenus()
        end,
    })
    tinsert(menu, {
        text = CANCEL,
        notCheckable = true,
        func = LibBG.CloseDropDownMenus,
    })
    LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOPLEFT", self, "TOPRIGHT")
    LibBG:EasyMenu(menu, dropDown, self, 0, 0, "MENU", 2)
    BG.PlaySound(1)
end

    hooksecurefunc(BG, "UpdateAuctionLogFrame", function()
        UpdateAutoStartAuctionButton()
    end)
end)
