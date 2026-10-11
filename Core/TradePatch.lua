local AddonName, ns = ...

local L = ns.L
local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local SetClassCFF = ns.SetClassCFF
local GetClassRGB = ns.GetClassRGB
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local Maxb = ns.Maxb

local function CurrentTrade()
    return BGE.successTrade or BG.trade
end

local function CreateTradeSnapshot()
    return {
        target = BG.trade.target,
        targetmoney = BG.trade.targetmoney,
        playermoney = BG.trade.playermoney,
        targetitems = BG.Copy(BG.trade.targetitems),
        playeritems = BG.Copy(BG.trade.playeritems),
        targetinfo = BG.Copy(BG.trade.targetinfo),
        playerinfo = BG.Copy(BG.trade.playerinfo),
        autoAuction = BG.Copy(BG.trade.autoAuction or {}),
        many = {},
    }
end

local function CaptureTradeRecordOptions(trade)
    if not trade or trade.recordOptionsCaptured then return end

    local qiankuan = tonumber(BG.tradeQianKuanEdit and BG.tradeQianKuanEdit:GetText()) or 0
    local isAutoRecord = BG.tradeSeeFrame.CheckButton:GetChecked() and true or false
    local isFine = BG.tradeSeeFrame.fakuanButton.isChoose and true or false
    local isRefund = BG.tradeSeeFrame.refundButton.isChoose and true or false
    local autoAuction = BG.Copy(BG.trade.autoAuction or {})

    trade.qiankuan = qiankuan
    trade.isAutoRecord = isAutoRecord
    trade.isFine = isFine
    trade.isRefund = isRefund
    trade.autoAuction = autoAuction
    trade.recordOptionsCaptured = true
end

local function GetTradeSeeText(saved, trade)
    trade = trade or BG.trade
    local FB = BG.FB1
    local target = trade.target
    local player = BG.trade.player
    local targetmoney = trade.targetmoney
    local playermoney = trade.playermoney
    local targetitems = trade.targetitems
    local playeritems = trade.playeritems
    local returntext = ""
    BG.tradeSeeFrame.frame:SetNormalColor()
    local isAutoRecord = trade.isAutoRecord
    if isAutoRecord == nil then
        isAutoRecord = BG.tradeSeeFrame.CheckButton:GetChecked()
    end
    if not isAutoRecord then
        return returntext
    end
    if BG.IsAutoCreateBill() then
        return returntext
    end
    local qiankuan = trade.qiankuan
    if qiankuan == nil then
        qiankuan = tonumber(BG.tradeQianKuanEdit and BG.tradeQianKuanEdit:GetText()) or 0
    end
    local qiankuantext = ""
    if qiankuan ~= 0 then
        qiankuantext = format("|cffFF0000" .. L["（欠款%d）"] .. RR, qiankuan)
    end
    -- 双方都给出装备
    if targetitems[1] and playeritems[1] and targetmoney == 0 and playermoney == 0 then --双方都有装备，但没金额，这种是交易失败
        returntext = ("|cffDC143C" .. L["< 交易记账失败 >"] .. RN .. L["双方都给了装备，但没金额"] .. NN .. L["我不知道谁才是买家"] .. NN .. NN .. L["如果有金额我就能识别了"])
        BG.tradeSeeFrame.frame:SetFalseColor()
        return returntext
    end
    -- 记为罚款
    local isFine = trade.isFine
    if isFine == nil then
        isFine = BG.tradeSeeFrame.fakuanButton.isChoose
    end
    if isFine and (targetmoney ~= 0 or playermoney ~= 0) then
        local Player, Money
        if targetmoney ~= 0 then
            Player = target
            Money = targetmoney
        elseif playermoney ~= 0 then
            Player = player
            Money = playermoney
        end
        returntext = (format("|cff00BFFF" ..
            L["< 交易记账成功 >|r\n项目：|cffff0000罚款|r\n玩家：%s\n金额：%s%d|rg"],
            SetClassCFF(Player), "|cffFFD700",
            Money + qiankuan,
            qiankuantext))
        if saved then
            local hasGZ
            BG.PairFBItem(function(item, buyer, money, b, i)
                if item:GetText() == "" and buyer:GetText() == "" and money:GetText() == ""
                    and not BiaoGe[FB]["boss" .. b]["qiankuan" .. i] then
                    hasGZ = true
                    local _r, _g, _b = GetClassRGB(Player)
                    item:SetText(L["罚款"])
                    buyer:SetText(Player)
                    buyer:SetTextColor(_r, _g, _b)
                    money:SetText(Money + qiankuan)
                    BiaoGe[FB]["boss" .. b]["zhuangbei" .. i] = L["罚款"]
                    BiaoGe[FB]["boss" .. b]["maijia" .. i] = Player
                    BiaoGe[FB]["boss" .. b]["jine" .. i] = Money + qiankuan
                    for k, v in pairs(BG.playerClass) do
                        BiaoGe[FB]["boss" .. b][k .. i] = select(v.select, v.func(Player))
                    end
                    if qiankuan ~= 0 then
                        BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = qiankuan
                        BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                    end
                    return true
                end
            end, Maxb[FB])
            if not hasGZ then
                returntext = ("|cffDC143C" .. L["< 交易记账失败 >"] .. RN .. L["罚款格子满了。。"])
                BG.PlaySound("fakuanFull")
            end
        end
        return returntext
    end
    -- 记为退货
    local isRefund = trade.isRefund
    if isRefund == nil then
        isRefund = BG.tradeSeeFrame.refundButton.isChoose
    end
    if isRefund and (next(trade.targetitems) or next(trade.playeritems)) then
        local Player, items
        if next(trade.targetitems) then
            Player = target
            items = trade.targetitems
        elseif next(trade.playeritems) then
            Player = player
            items = trade.playeritems
        end
        if #items > 1 then
            returntext = L["|cffDC143C< 退货失败 >|r\n只能对1件装备进行退货处理"]
            BG.tradeSeeFrame.frame:SetFalseColor()
            return returntext
        end
        local targetItem = items[1]
        local itemID = GetItemID(targetItem.link)
        local hasItem
        BG.PairFBItem(function(item, buyer, money, b, i)
            local _item = item:GetText()
            local _buyer = buyer:GetText()
            local _money = money:GetText()
            if itemID == GetItemID(_item) and Player == _buyer then
                local QKmoney = tonumber(BiaoGe[FB]["boss" .. b]["qiankuan" .. i]) or 0
                local __money = _money - QKmoney
                local QKText = ""
                if QKmoney > 0 then
                    QKText = L["（|cffFFD700%s|r-|cffff0000%s|r）"]:format(_money, QKmoney)
                end
                returntext = L["|cff00BFFF< 退货成功 >|r\n装备：%s\n退货人：%s\n应退金额：|cffFFD700%s|rg%s\nBoss：|cff%s%s"]:format(
                    _item, SetClassCFF(_buyer), __money, QKText, BG.Boss[FB]["boss" .. b]["color"], BG.Boss[FB]["boss" .. b]["name2"])
                hasItem = true
                if saved then
                    buyer:Clear()
                    money:Clear()
                    money:ClearQK()
                    if BiaoGe[FB].auctionLog then
                        for i, v in ipairs(BiaoGe[FB].auctionLog) do
                            if v.type == 1 and v.maijia == _buyer and v.jine == _money
                                and v.trade and BG.IsSameItem(v.zhuangbei, _item) then
                                BG.SendSystemMessage(L['%s的拍卖记录已被改为未拍。']:format(v.zhuangbei))
                                if BG.ImML() and IsInRaid(1) then
                                    C_ChatInfo.SendAddonMessage("BiaoGe2",
                                        format("RefundAuctionToFailed^%s^%s^%s^%s", GetItemID(v.zhuangbei), v.zhuangbei, v.maijia, v.jine),
                                        "RAID")
                                end
                                tremove(BiaoGe[FB].auctionLog, i)
                                local name = "BiaoGe_TuiHuoReAuction"
                                if not StaticPopupDialogs[name] then
                                    StaticPopupDialogs[name] = {
                                        text = L["重新拍卖%s吗？\n\n起拍价：%s"],
                                        button1 = L["是"],
                                        button2 = L["否"],
                                        OnShow = function(self)
                                            self:SetHyperlinksEnabled(true)
                                            self:SetScript("OnHyperlinkEnter", function(self, link, text, button)
                                                local itemID = GetItemID(link)
                                                if itemID then
                                                    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM", 0, 0)
                                                    GameTooltip:ClearLines()
                                                    GameTooltip:SetHyperlink(BG.SetSpecIDToLink(link))
                                                end
                                            end)
                                            self:SetScript("OnHyperlinkLeave", GameTooltip_Hide)
                                        end,
                                        OnAccept = function(self, data)
                                            local isGen2 = BiaoGe.Auction.gen == 2
                                            local mod = BiaoGe.Auction.mod
                                            local resetThreshold = max(tonumber(BiaoGe.Auction.resetThreshold) or 0, 10)
                                            BG.SendStartAuctionMsg(isGen2, data.itemID, data.money, 20, mod, data.link, resetThreshold)
                                        end,
                                        OnCancel = function()
                                        end,
                                        timeout = 0,
                                        whileDead = true,
                                        hideOnEscape = true,
                                        showAlert = true,
                                    }
                                end
                                StaticPopup_Show(name, v.zhuangbei, _money,
                                    { link = v.zhuangbei, itemID = GetItemID(v.zhuangbei), money = _money })
                                break
                            end
                        end
                    end
                end
                return true
            end
        end)
        if not hasItem then
            returntext = L["|cffDC143C< 退货失败 >|r\n表格里没找到此件装备"]
            BG.tradeSeeFrame.frame:SetFalseColor()
        else
            BG.tradeSeeFrame.frame:SetGreenColor()
        end
        return returntext
    end

    -- 使用自动拍卖的记账
    if next(trade.autoAuction) then
        local returnText = ""
        for _, v in ipairs(trade.autoAuction) do
            local b = v.b
            local i = v.i
            local link = v.link
            local itemID = GetItemID(link)
            local player = v.player
            local money = v.money
            local qiankuan = v.qiankuan
            local icon = select(5, GetItemInfoInstant(itemID))
            local qiankuanText = ""
            if qiankuan > 0 then
                qiankuanText = format(L["|cffFF0000（欠款%d）|r"], qiankuan)
            end
            returnText = returnText .. AddTexture(icon) .. " |cffFFD700" .. money .. "|rg" .. qiankuanText .. "\n"
            if saved then
                -- 保存买家信息
                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetText(player)
                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetCursorPosition(0)
                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(GetClassRGB(player))
                BiaoGe[FB]["boss" .. b]["maijia" .. i] = player
                for k in pairs(BG.playerClass) do
                    if player == BG.trade.player then
                        BiaoGe[FB]["boss" .. b][k .. i] = trade.playerinfo[k]
                    else
                        BiaoGe[FB]["boss" .. b][k .. i] = trade.targetinfo[k]
                    end
                end
                -- 金额和欠款
                BG.Frame[FB]["boss" .. b]["jine" .. i]:SetText(money)
                BiaoGe[FB]["boss" .. b]["jine" .. i] = (money)
                if qiankuan ~= 0 then
                    BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = qiankuan
                    BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                end
                -- 取消关注
                if player == BG.trade.player then
                    BG.CancelGuanZhuAndHopeInTrade(itemID)
                end
                -- 打包交易
                local a = {
                    FB = FB,
                    itemID = itemID,
                    link = link,
                    b = b,
                    i = i
                }
                tinsert(trade.many, a)
            end
        end
        BG.tradeSeeFrame.frame:SetGreenColor()
        return returnText
    end

    -- 非自动拍卖的记账
    local Items, Money, Items2, Money2, Player
    for ii = 1, 2 do
        if ii == 1 then -- 玩家给出金额，得到装备（玩家买装备情景）
            Items = targetitems
            Items2 = playeritems
            Money = playermoney
            Money2 = targetmoney
            Player = player
        elseif ii == 2 then -- 玩家给出装备，得到金钱（团长情景）
            Items = playeritems
            Items2 = targetitems
            Money = targetmoney
            Money2 = playermoney
            Player = target
        end

        if (targetitems[1] and playeritems[1] and Money ~= 0)                 -- 双方都有装备，但玩家出了金
            or (Items[1] and not Items2[1] and (Money ~= 0 or qiankuan ~= 0)) -- 其中一方有装备且金额不等于0
        then
            local isFirstItem = true
            for items = 1, #Items do
                local done
                for b = 1, Maxb[FB] do
                    for i = 1, BG.GetMaxi(FB, b) do
                        local bt = BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]
                        if bt and GetItemID(bt:GetText()) == GetItemID(Items[items].link) and
                            BG.Frame[FB]["boss" .. b]["maijia" .. i]:GetText() == "" and
                            BG.Frame[FB]["boss" .. b]["jine" .. i]:GetText() == "" and
                            not BiaoGe[FB]["boss" .. b]["qiankuan" .. i]
                        then
                            if saved then
                                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetText(Player)
                                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetCursorPosition(0)
                                BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetTextColor(GetClassRGB(Player))
                                BiaoGe[FB]["boss" .. b]["maijia" .. i] = Player
                                for k in pairs(BG.playerClass) do
                                    if Player == BG.trade.player then
                                        BiaoGe[FB]["boss" .. b][k .. i] = trade.playerinfo[k]
                                    else
                                        BiaoGe[FB]["boss" .. b][k .. i] = trade.targetinfo[k]
                                    end
                                end
                                if isFirstItem then
                                    BG.Frame[FB]["boss" .. b]["jine" .. i]:SetText(Money + qiankuan)
                                    BiaoGe[FB]["boss" .. b]["jine" .. i] = (Money + qiankuan)
                                    if qiankuan ~= 0 then
                                        BiaoGe[FB]["boss" .. b]["qiankuan" .. i] = qiankuan
                                        BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Show()
                                    end
                                else
                                    BG.Frame[FB]["boss" .. b]["jine" .. i]:SetText(L["打包交易"])
                                    BiaoGe[FB]["boss" .. b]["jine" .. i] = (L["打包交易"])
                                end
                                -- 取消关注
                                if Player == BG.trade.player then
                                    local itemID = GetItemID(bt:GetText())
                                    BG.CancelGuanZhuAndHopeInTrade(itemID)
                                end
                                if #Items > 1 then
                                    local a = {
                                        FB = FB,
                                        itemID = GetItemID(Items[items].link),
                                        link = Items[items].link,
                                        b = b,
                                        i = i
                                    }
                                    tinsert(trade.many, a)
                                end
                            end
                            if isFirstItem then
                                local Texture = select(10, GetItemInfo(Items[items].link))
                                returntext = (format("|cff00BFFF" ..
                                    L["< 交易记账成功 >|r\n装备：%s\n买家：%s\n金额：%s%d|rg%s\nBoss：%s%s|r"],
                                    (AddTexture(Texture) .. Items[items].link),
                                    SetClassCFF(Player), "|cffFFD700",
                                    Money + qiankuan,
                                    qiankuantext,
                                    "|cff" .. BG.Boss[FB]["boss" .. b]["color"],
                                    BG.Boss[FB]["boss" .. b]["name2"]))
                            elseif not strfind(returntext, L["（剩余装备记录为打包交易）"]) then
                                returntext = returntext .. NN .. BG.STC_dis(L["（剩余装备记录为打包交易）"])
                            end
                            isFirstItem = nil
                            done = true
                            break
                        end
                    end
                    if done then break end
                end
            end
            if returntext ~= "" then
                return returntext
            end

            returntext = ("|cffDC143C" .. L["< 交易记账失败 >"] .. RN .. L["表格里没找到此次交易的装备，或者该装备已记过账"])
            BG.tradeSeeFrame.frame:SetFalseColor()
            return returntext
        end
    end
    return returntext
end

local function SaveMoney(self, trade)
    trade = trade or CurrentTrade()
    if BiaoGe.options["autoTrade"] == 1 and IsInRaid(1) then
        if BG.IsAutoCreateBill() then
            for i, v in ipairs(trade.targetitems) do
                local itemID = GetItemID(v.link)
                BG.CancelGuanZhuAndHopeInTrade(itemID)
            end
        else
            local text = GetTradeSeeText("saved", trade)
            -- 保存打包交易
            if #trade.many > 1 then
                local FBs = {}
                for i, v in ipairs(trade.many) do
                    FBs[v.FB] = true
                end
                for FB in pairs(FBs) do
                    tinsert(BiaoGe[FB].tradeTbl, trade.many)
                end
            end
            if BiaoGe.options["tradeNotice"] == 1 then
                BG.FrameTradeMsg:AddMessage(text)
            end
        end
    end
end

local function SetItemTradeState(trade)
    trade = trade or BG.trade
    local FB = BG.FB2 or BG.FB1
    if IsInRaid(1) and BiaoGe[FB].auctionLog then
        local tradeName, tradeTbl
        if BG.ImMLorLeader() then
            tradeName = trade.target
            tradeTbl = trade.playeritems
        else
            tradeName = BG.trade.player
            tradeTbl = trade.targetitems
        end
        for _, vv in ipairs(tradeTbl) do
            for _, v in ipairs(BiaoGe[FB].auctionLog) do
                if v.type == 1 and not v.trade and v.maijia == tradeName and
                    GetItemID(v.zhuangbei) == GetItemID(vv.link) then
                    v.trade = true
                    break
                end
            end
        end
        BG.UpdateAuctionLogFrame(true, true)
    end
end

BGE.Init(function()
    BG.GetTradeSeeText = GetTradeSeeText

    if BG.tradeSeeFrame and BG.tradeSeeFrame.frame then
        BG.tradeSeeFrame.frame.SaveMoney = SaveMoney
    end

    BG.RegisterEvent("TRADE_ACCEPT_UPDATE", function(self, event, playerAccepted, targetAccepted)
        if playerAccepted == 1 or targetAccepted == 1 then
            BG.GetTradeInfo()
            BGE.successTrade = CreateTradeSnapshot()
            CaptureTradeRecordOptions(BGE.successTrade)
        end
    end)

    BG.RegisterEvent("UI_INFO_MESSAGE", function(self, event, _, text)
        if text ~= ERR_TRADE_COMPLETE then return end
        local trade = BGE.successTrade
        BGE.successTrade = nil
        if trade then
            CaptureTradeRecordOptions(trade)
            SetItemTradeState(trade)
        end
    end)
end)
