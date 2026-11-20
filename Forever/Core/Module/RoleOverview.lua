if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor

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
local Round = ns.Round

local pt = print

local realmID = GetRealmID()

BG.Init(function()
    -- 牌子拾取增强
    local text1, text2, text3
    text1 = CURRENCY_GAINED_MULTIPLE:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
    text2 = CURRENCY_GAINED:gsub("%%s", "(.+)")
    local function func(self, event, msg, player, l, cs, t, flag, channelId, ...)
        if BGLite_equip.options["showCurrencyCount"] ~= 1 then return end
        local link = strmatch(msg, text1)
        if not link then
            link = strmatch(msg, text2)
        end
        if link then
            local currencyID = link:match("currency:(%d+)")
            if currencyID then
                local info = C_CurrencyInfo.GetCurrencyInfo(tonumber(currencyID))
                local maxCount = info.maxQuantity
                local count = info.quantity
                local color = "00BFFF"
                local isFull
                local newMsg
                if not info.useTotalEarnedForMaxQty and maxCount > 0 then -- （2500/4000）例如正义点数
                    if count >= maxCount then
                        isFull = true
                        color = "FF0000"
                    end
                    newMsg = format(L["|cff%s（|cffffffff%s|r/%s）|r"], color,
                        BG.FormatNumber(count), BG.FormatNumber(maxCount))
                else
                    local weekText = ""
                    if info.useTotalEarnedForMaxQty and maxCount > 0 then -- MOP勇气点数
                        local totalEarned = info.totalEarned
                        if totalEarned >= maxCount then
                            isFull = true
                            color = "FF0000"
                        end
                        weekText = format(L["（总上限%s/%s）"],
                            BG.FormatNumber(totalEarned), BG.FormatNumber(maxCount))
                    end
                    local weekMax = info.maxWeeklyQuantity -- 时光服泰坦余烬
                    if weekMax and weekMax > 0 then
                        local weekCount = info.quantityEarnedThisWeek
                        weekText = format(L["（本周%s/%s）"],
                            BG.FormatNumber(weekCount), BG.FormatNumber(weekMax))
                        if weekCount >= weekMax then
                            isFull = true
                            color = "FF0000"
                        end
                    end
                    newMsg = format(L["|cff%s（|cffffffff%s|r）%s|r"], color, count, weekText)
                end
                if isFull then
                    BG.PlaySound("currencyfull")
                end
                return false, msg .. newMsg, player, l, cs, t, flag, channelId, ...
            end
        end
    end
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CURRENCY", func)

    -- 更新集结号密语装等
    do
        local function GetPlayerAverageItemLevel()
            local _, avgLevel = GetAverageItemLevel()
            local avgLevel0 = Round(avgLevel, 0)
            if BG.isFullLevel and BG.MeetingHorn and BG.MeetingHorn.iLevelCheckButton then
                BG.MeetingHorn.iLevelCheckButton.Text:SetText(avgLevel0)
            end
        end

        local delay
        local again
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_ENTERING_WORLD" then
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                delay = 3
                again = true
                BG.After(delay, function()
                    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
                end)
            else
                delay = 1
            end
            self.t = 0
            self:SetScript("OnUpdate", function(_, t)
                self.t = self.t + t
                if self.t > delay then
                    self:SetScript("OnUpdate", nil)
                    GetPlayerAverageItemLevel()
                    if again then
                        again = nil
                        BG.After(5, function()
                            GetPlayerAverageItemLevel()
                        end)
                    end
                end
            end)
        end)
    end

    -- 一键排灵魂烘炉
    local holidayDungeonIDs = { 286, 285, 287, 288 } -- 火焰节、万圣节、美酒节、情人节
end)
