local AddonName, ns = ...

if type(BG) ~= "table" or type(BGE) ~= "table" then
    return
end

local LibBG = ns.LibBG
local L = ns.L
local RGB = ns.RGB
local AddTexture = ns.AddTexture
local Maxb = BG.Maxb
------------------罚款增强------------------
local SetFineEnhancementBossName
do
    local function ClearFine(FB)
        local boss = Maxb[FB]
        for i = 1, BG.Maxi + 10 do
            local frames = BG.Frame[FB]["boss" .. boss]
            if frames["zhuangbei" .. i] then
                frames["zhuangbei" .. i]:SetText("")
                frames["maijia" .. i]:SetText("")
                frames["jine" .. i]:SetText("")
                if frames["qiankuan" .. i] then
                    frames["qiankuan" .. i]:Hide()
                end
                if frames["guanzhu" .. i] then
                    frames["guanzhu" .. i]:Hide()
                end
            end

            local data = BiaoGe[FB]["boss" .. boss]
            data["zhuangbei" .. i] = nil
            data["maijia" .. i] = nil
            data["jine" .. i] = nil
            data["qiankuan" .. i] = nil
            data["guanzhu" .. i] = nil
            data["color" .. i] = nil
            data["loot" .. i] = nil
            data["itemLevel" .. i] = nil
            data["bindOnEquip" .. i] = nil
            for class in pairs(BG.playerClass) do
                data[class .. i] = nil
            end

            local duiZhangFB = BG.DuiZhangFrame and BG.DuiZhangFrame[FB]
            local duiZhangBoss = duiZhangFB and duiZhangFB["boss" .. boss]
            if duiZhangBoss and duiZhangBoss["zhuangbei" .. i] then
                duiZhangBoss["zhuangbei" .. i]:SetText("")
                duiZhangBoss["myjine" .. i]:SetText("")
            end
        end

        local frames = BG.Frame[FB]["boss" .. boss]
        if frames.time then
            frames.time:SetText("")
        end
        local data = BiaoGe[FB]["boss" .. boss]
        data.time = nil
        data.difficultyID = nil
    end

    local function MergeFine(FB)
        local boss = Maxb[FB]
        local merged = {}
        local withoutPlayer = {}

        for i = 1, BG.Maxi + 10 do
            local frames = BG.Frame[FB]["boss" .. boss]
            local nameFrame = frames["zhuangbei" .. i]
            if nameFrame then
                local description = nameFrame:GetText()
                local playerFrame = frames["maijia" .. i]
                local playerName = playerFrame:GetText()
                local money = tonumber(frames["jine" .. i]:GetText()) or 0
                local debt = tonumber(BiaoGe[FB]["boss" .. boss]["qiankuan" .. i]) or 0
                local color = { playerFrame:GetTextColor() }

                if playerName ~= "" then
                    local record = merged[playerName]
                    if not record then
                        merged[playerName] = {
                            description = description,
                            playerName = playerName,
                            money = money,
                            debt = debt,
                            color = color,
                        }
                    else
                        if description ~= "" and description ~= L["罚款"] then
                            record.description = record.description .. " " .. description
                        end
                        record.money = record.money + money
                        record.debt = record.debt + debt
                    end
                elseif description ~= "" or money ~= 0 or debt ~= 0 then
                    tinsert(withoutPlayer, {
                        description = description,
                        playerName = "",
                        money = money,
                        debt = debt,
                        color = color,
                    })
                end
            end
        end

        local records = {}
        for _, record in pairs(merged) do
            tinsert(records, record)
        end
        sort(records, function(a, b)
            if a.money == b.money then
                return a.playerName < b.playerName
            end
            return a.money > b.money
        end)
        for _, record in ipairs(withoutPlayer) do
            tinsert(records, record)
        end

        ClearFine(FB)
        for index, record in ipairs(records) do
            local frames = BG.Frame[FB]["boss" .. boss]
            local nameFrame = frames["zhuangbei" .. index]
            if not nameFrame then break end

            local playerFrame = frames["maijia" .. index]
            local moneyFrame = frames["jine" .. index]
            local money = record.money ~= 0 and record.money or ""
            nameFrame:SetText(record.description)
            playerFrame:SetText(record.playerName)
            playerFrame:SetTextColor(unpack(record.color))
            moneyFrame:SetText(money)

            local data = BiaoGe[FB]["boss" .. boss]
            data["zhuangbei" .. index] = record.description
            data["maijia" .. index] = record.playerName
            data["jine" .. index] = money
            data["color" .. index] = record.playerName ~= "" and record.color or nil
            if record.debt ~= 0 then
                data["qiankuan" .. index] = record.debt
                if frames["qiankuan" .. index] then
                    frames["qiankuan" .. index]:Show()
                end
            end
        end
        BG.PlaySound(2)
    end

    local function ShowClearFineDialog(FB)
        local dialogName = "BiaoGe_ClearFine"
        StaticPopupDialogs[dialogName] = {
            text = L["确定清空全部罚款？"],
            button1 = L["是"],
            button2 = L["否"],
            OnAccept = function()
                ClearFine(FB)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
        StaticPopup_Show(dialogName)
    end

    SetFineEnhancementBossName = function(FB, f)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                local menu = {
                    {
                        text = L["罚款"],
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = L["合并罚款"],
                        notCheckable = true,
                        tooltipTitle = L["合并罚款"],
                        tooltipText = L["把相同玩家的多项罚款合并为一项，罚款内容、罚款金额和欠款都会合并一起。"],
                        tooltipOnButton = true,
                        func = function()
                            MergeFine(FB)
                        end,
                    },
                    {
                        text = L["清空罚款"],
                        notCheckable = true,
                        func = function()
                            ShowClearFineDialog(FB)
                        end,
                    },
                    {
                        text = "   ",
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = CANCEL,
                        notCheckable = true,
                        func = LibBG.CloseDropDownMenus,
                    },
                }
                LibBG:EasyMenu(menu, BG.dropDown, f, f:GetWidth(), f:GetHeight(), "MENU", 2)
                GameTooltip:Hide()
            end
            local onMouseUp = BG.MainFrame:GetScript("OnMouseUp")
            if onMouseUp then
                onMouseUp(BG.MainFrame)
            end
        end)
        f:SetScript("OnMouseDown", function()
            local onMouseDown = BG.MainFrame:GetScript("OnMouseDown")
            if onMouseDown then
                onMouseDown(BG.MainFrame)
            end
        end)
        f:SetScript("OnEnter", function()
            GameTooltip:SetOwner(f, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["罚款"], 0, 1, 0)
            GameTooltip:AddLine(AddTexture("RIGHT") .. L["打开罚款菜单"], 1, .82, 0)
            GameTooltip:Show()
            f.text:SetTextColor(1, 1, 1)
        end)
        f:SetScript("OnLeave", function()
            GameTooltip:Hide()
            f.text:SetTextColor(RGB(BG.Boss[FB]["boss" .. Maxb[FB]].color))
        end)
    end
end

local function AttachFineMenu(FB)
    local maxb = Maxb[FB]
    if not maxb then
        return
    end
    local tbl = BG.Frame[FB] and BG.Frame[FB]["boss" .. maxb]
    local f = tbl and tbl.bossName
    if f and not f.BGEFineMenu then
        f.BGEFineMenu = true
        SetFineEnhancementBossName(FB, f)
    end
end

BGE.Init(function()
    if type(BG.BossNameUI) == "function" then
        hooksecurefunc(BG, "BossNameUI", function(FB, t, b, bb, i, ii, frameName)
            if frameName == "Frame" then
                AttachFineMenu(FB)
            end
        end)
    end
    if type(BG.FBtable) == "table" then
        for _, FB in pairs(BG.FBtable) do
            local ok, err = pcall(AttachFineMenu, FB)
            if not ok then
                print("|cffff5555[BGLite_equip]|r 罚款增强挂载失败（" .. tostring(FB) .. "）：" .. tostring(err))
            end
        end
    end
end)
