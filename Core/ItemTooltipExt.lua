local AddonName, ns = ...

local L = ns.L
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID

local itemFucs = {}

do
    local function callback(itemID, maxJine, minJine, tooltip)
        BG.historyLastCallback = nil
        local name, link = tooltip:GetItem()
        if not link then return end
        if GetItemID(link) ~= itemID then return end
        for i = 1, tooltip:NumLines() do
            local leftt = _G[tooltip:GetName() .. "TextLeft" .. i]
            local rightt = _G[tooltip:GetName() .. "TextRight" .. i]
            if leftt then
                local lefttext = leftt:GetText()
                local righttext = rightt:GetText()
                if lefttext == (L["BiaoGe历史价格"]) and righttext == L["读取中"] then
                    if minJine and maxJine then
                        local text
                        if minJine == maxJine then
                            text = minJine
                        else
                            text = L["%s-%s"]:format(minJine, maxJine)
                        end
                        rightt:SetText(text .. " " .. AddTexture(237618))
                        tooltip:Show()
                    else
                        rightt:SetText(L["无"])
                    end
                    return
                end
            end
        end
    end
    local function GetMaxMinMoney(tbl)
        local maxJine, minJine
        if next(tbl) then
            for i = 1, #tbl do
                if not maxJine then
                    maxJine = tbl[i].money
                end
                if not minJine then
                    minJine = tbl[i].money
                end
                if maxJine < tbl[i].money then
                    maxJine = tbl[i].money
                end
                if minJine > tbl[i].money then
                    minJine = tbl[i].money
                end
            end
        end
        return maxJine, minJine
    end
    local function AddInfo(self, itemID, link, name)
        if not (BiaoGe.options["mouseHistoryMoney"] == 1 and IsInRaid(1)) then return end
        if BG.HistoryMoneyCache[itemID] then
            local maxJine, minJine = GetMaxMinMoney(BG.HistoryMoneyCache[itemID])
            maxJine = BG.FormatNumber(maxJine, 2)
            minJine = BG.FormatNumber(minJine, 2)
            local text = ""
            local moneyText
            if minJine and maxJine then
                if minJine == maxJine then
                    text = minJine
                else
                    text = L["%s-%s"]:format(minJine, maxJine)
                end
                moneyText = text .. " " .. AddTexture(237618)
            else
                moneyText = L["无"]
            end
            self:AddDoubleLine(L["BiaoGe历史价格"], moneyText, 1, 0.82, 0, 1, 1, 1)
        else
            self:AddDoubleLine(L["BiaoGe历史价格"], L["读取中"], 1, 0.82, 0, 1, 1, 1)
            BG.historyLastCallback = function(tbl)
                local maxJine, minJine = GetMaxMinMoney(tbl)
                maxJine = BG.FormatNumber(maxJine, 2)
                minJine = BG.FormatNumber(minJine, 2)
                callback(itemID, maxJine, minJine, self)
            end
            BG.GetHistoryMoney(itemID, nil, BG.historyLastCallback)
        end
        self:Show()
    end
    tinsert(itemFucs, AddInfo)
end

do
    local function AddInfo(self, itemID)
        if not IsAltKeyDown() then return end
        if not BiaoGe.auctionPreset then return end

        local tbl = {}
        for _, FB in pairs(BG.FBtable) do
            if FB == BG.FB1 then
                tinsert(tbl, 1, FB)
            else
                tinsert(tbl, FB)
            end
        end
        for _, FB in ipairs(tbl) do
            local preset = BiaoGe.auctionPreset[FB]
            local money = preset and preset.money and preset.money[itemID]
            if money then
                self:AddLine(L["预设起拍价：|cffffffff"] .. BG.FormatNumber(money, 2), 1, 0.82, 0, true)
                local tips = preset.money[itemID .. "tips"]
                if tips then
                    self:AddLine(L["预设起拍语：|cffffffff"] .. tips, 1, 0.82, 0, true)
                end
                self:Show()
                return
            end
        end
    end
    tinsert(itemFucs, AddInfo)
end

do
    local function AddInfo(self, itemID)
        if not BG.GetBestPrice then return end
        local money = BG.GetBestPrice(itemID)
        if not money then return end

        local tooltipName = self:GetName()
        local nextText = tooltipName and _G[tooltipName .. "TextLeft2"]
        if nextText then
            local text = nextText:GetText() or ""
            nextText:SetFormattedText("|cffFFD100%s%s|r\n%s", L["心理价格"], BG.FormatNumber(money, 2), text)
            nextText:SetWidth(max(150, nextText:GetWidth() + 5))
            self:Show()
        end
    end
    tinsert(itemFucs, AddInfo)
end

if BG.IsMOP then
    local extraItemIDs = {
        [276085] = 3416,
    }
    local function AddInfo(self, itemID)
        if BiaoGe.options["showCurrencyCount"] ~= 1 then return end
        local currency = extraItemIDs[itemID]
        if not currency then return end
        local info = C_CurrencyInfo.GetCurrencyInfo(currency)
        if not info then return end
        local name = info.name
        local count = info.quantity
        local maxCount = info.maxQuantity
        local tex = info.iconFileID
        local quality = info.quality
        local r, g, b = GetItemQualityColor(quality)
        self:AddLine(" ")
        self:AddLine("< BGLite >", 0, .75, 1)
        if not info.useTotalEarnedForMaxQty then
            self:AddDoubleLine(AddTexture(tex) .. name, BG.FormatNumber(count) .. "/" .. BG.FormatNumber(maxCount), r, g, b, 1, 1, 1)
        else
            local totalEarned = info.totalEarned
            self:AddDoubleLine(AddTexture(tex) .. name,
                format(L["%s(总上限:%s/%s)"], count, BG.FormatNumber(totalEarned), BG.FormatNumber(maxCount)), r, g, b, 1, 1, 1)
        end
        self:Show()
    end
    tinsert(itemFucs, AddInfo)
end

BGE.Init(function()
    local function ItemGo(self)
        if self ~= GameTooltip then return end
        local name, link = self:GetItem()
        if not link then return end
        local itemID = GetItemID(link)
        if not itemID then return end
        itemID = BG.GetLeiTingItem(itemID)
        for _, fuc in ipairs(itemFucs) do
            local ok, err = pcall(fuc, self, itemID, link, name)
            if not ok then
                print("|cffff5555[BGLite_equip] 工具提示错误:|r " .. tostring(err))
            end
        end
    end
    GameTooltip:HookScript("OnTooltipSetItem", ItemGo)
end)
