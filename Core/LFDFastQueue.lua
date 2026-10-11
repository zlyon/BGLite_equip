local AddonName, ns = ...

local L = ns.L

local holidayDungeonIDs = { 286, 285, 287, 288 } -- 火焰节、万圣节、美酒节、情人节

local player = BG.playerName
local realmID = GetRealmID()

BGE.Init(function()
    if BG.options then
        BG.options["zhidingFBreset"] = 1
        if not BiaoGe.options["zhidingFB"] then
            BiaoGe.options["zhidingFB"] = BG.options["zhidingFBreset"]
        end
    end

    if not BG.verLess2 then
        BiaoGe.lastChooseLFD = BiaoGe.lastChooseLFD or {}
        BiaoGe.lastChooseLFD[realmID] = BiaoGe.lastChooseLFD[realmID] or {}
        if BiaoGe.lastChooseLFD[realmID][player] and type(BiaoGe.lastChooseLFD[realmID][player]) ~= "table" then
            local type = BiaoGe.lastChooseLFD[realmID][player]
            BiaoGe.lastChooseLFD[realmID][player] = {
                type = type,
            }
        end
        BiaoGe.lastChooseLFD[realmID][player] = BiaoGe.lastChooseLFD[realmID][player] or {}
        BiaoGe.lastChooseLFD[realmID][player].dungeons = BiaoGe.lastChooseLFD[realmID][player].dungeons or {}

        if not PVEFrame or not LFDQueueFrame then
            return
        end

        local isOnClick

        local function OnClick(self)
            if self.type == "zhiding" then
                for i, id in ipairs(LFDDungeonList) do
                    if id < 0 then
                        LFGDungeonList_SetHeaderEnabled(1, id, false, LFDDungeonList, LFDHiddenByCollapseList)
                    end
                end
                LFGDungeonList_SetDungeonEnabled(self.dungeonID, true)
                LFDQueueFrame_SetType("specific")
                LFG_JoinDungeon(LE_LFG_CATEGORY_LFD, "specific", LFDDungeonList, LFDHiddenByCollapseList)
            elseif self.type == "jieri" then
                LFDQueueFrame_SetType(self.dungeonID)
                LFG_JoinDungeon(LE_LFG_CATEGORY_LFD, self.dungeonID, LFDDungeonList, LFDHiddenByCollapseList)
            end
            BG.PlaySound(1)
        end

        local function OnEnter(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 0, 0)
            GameTooltip:ClearLines()
            if self.dis then
                GameTooltip:AddLine(L["副本已锁定"], 1, 0, 0, true)
            else
                GameTooltip:AddLine(self.onEnterText, 1, 1, 1, true)
                GameTooltip:AddLine(BG.STC_dis(L["你可在插件设置-BiaoGe-其他功能里关闭这个功能"]), 1, 1, 1, true)
            end
            GameTooltip:Show()
        end

        local buttons = {}
        for i = 1, 2 do
            local bt = BG.CreateButton(PVEFrame)
            bt:SetSize(150, 23)
            bt:SetPoint("BOTTOMLEFT", 35, 5)
            if i == 1 then
                bt.type = "jieri"
                bt.tbl = holidayDungeonIDs
                -- bt.tbl = { 259 }           -- 燃烧的远征test
            elseif i == 2 then
                bt.type = "zhiding"
                if BG.IsWLK then
                    bt.tbl = { 2463, } --伽马灵魂烘炉。贝塔要塞2481（已删）
                    -- bt.tbl = { 136 }  -- 地狱火test
                else
                    bt.tbl = {}
                end
            end
            bt:Hide()
            bt:SetScript("OnClick", OnClick)
            bt:SetScript("OnEnter", OnEnter)
            bt:SetScript("OnLeave", GameTooltip_Hide)
            tinsert(buttons, bt)

            bt.disframe = CreateFrame("Frame", nil, bt)
            bt.disframe:SetAllPoints()
            bt.disframe.dis = true
            bt.disframe:SetScript("OnEnter", OnEnter)
            bt.disframe:SetScript("OnLeave", GameTooltip_Hide)
        end

        local function UpdateButtons()
            local isShowButton = {}
            for i = 1, 2 do
                buttons[i].name = nil
                for _, dungeonID in ipairs(buttons[i].tbl) do
                    local isAvailableForAll, isAvailableForPlayer, hideIfNotJoinable = IsLFGDungeonJoinable(dungeonID)
                    if isAvailableForPlayer then
                        local name = GetLFGDungeonInfo(dungeonID)
                        if dungeonID == 2481 then
                            name = L["贝塔"] .. name
                        end
                        buttons[i]:SetText(name)
                        buttons[i].onEnterText = format(L["一键指定%s"], name)
                        buttons[i].dungeonID = dungeonID
                        buttons[i].name = name
                        buttons[i]:Show()
                        tinsert(isShowButton, buttons[i])

                        local playerName, lockedReason, subReason1, subReason2, secondReasonID, secondReasonString = GetLFDLockInfo(dungeonID, 1)
                        if lockedReason ~= 0 then
                            buttons[i]:Disable()
                            buttons[i].disframe:Show()
                        else
                            buttons[i]:Enable()
                            buttons[i].disframe:Hide()
                        end
                        break
                    end
                end
                if not buttons[i].name then
                    buttons[i]:Hide()
                end
            end
            if #isShowButton == 1 then
                isShowButton[1]:SetSize(150, 23)
                isShowButton[1]:ClearAllPoints()
                isShowButton[1]:SetPoint("BOTTOMLEFT", 35, 5)
                BG.ButtonTextSetWordWrap(buttons[1])
            elseif #isShowButton == 2 then
                for i = 1, 2 do
                    buttons[i]:SetSize(90, 23)
                    buttons[i]:ClearAllPoints()
                    if i == 1 then
                        buttons[i]:SetPoint("BOTTOMLEFT", 15, 5)
                    else
                        buttons[i]:SetPoint("BOTTOMLEFT", 110, 5)
                    end
                    BG.ButtonTextSetWordWrap(buttons[i])
                end
            end
        end
        LFDQueueFrame:HookScript("OnShow", function(self)
            if BiaoGe.options["zhidingFB"] ~= 1 then
                for i, bt in ipairs(buttons) do
                    bt:Hide()
                end
                return
            end
            UpdateButtons()
            if BiaoGe.lastChooseLFD[realmID][player] then
                if BiaoGe.lastChooseLFD[realmID][player].type == "specific" then
                    LFDQueueFrame_SetType(BiaoGe.lastChooseLFD[realmID][player].type)
                    BG.After(0, function()
                        for i, id in ipairs(LFDDungeonList) do
                            if id < 0 then
                                LFGDungeonList_SetHeaderEnabled(1, id, false, LFDDungeonList, LFDHiddenByCollapseList)
                            end
                        end
                        for dungeonID, isChecked in pairs(BiaoGe.lastChooseLFD[realmID][player].dungeons) do
                            LFGDungeonList_SetDungeonEnabled(dungeonID, isChecked)
                        end
                        if LFDQueueFrameSpecificList_Update then
                            LFDQueueFrameSpecificList_Update()
                        end
                        LFDQueueFrame_UpdateRoleButtons()
                    end)
                else
                    for i = 1, GetNumRandomDungeons() do
                        local id, name = GetLFGRandomDungeonInfo(i)
                        local isAvailableForAll, isAvailableForPlayer, hideIfNotJoinable = IsLFGDungeonJoinable(id)
                        if isAvailableForPlayer then
                            if id == BiaoGe.lastChooseLFD[realmID][player].type then
                                LFDQueueFrame_SetType(BiaoGe.lastChooseLFD[realmID][player].type)
                                return
                            end
                        end
                    end
                end
            end
        end)
        hooksecurefunc("LFDQueueFrame_SetTypeInternal", function(value)
            -- pt(value)
            if PVEFrame:IsVisible() then
                BiaoGe.lastChooseLFD[realmID][player].type = value
            end
        end)

        hooksecurefunc("LFGDungeonList_SetDungeonEnabled", function(dungeonID, isChecked)
            -- pt(dungeonID)
            BG.After(0, function()
                if isOnClick then
                    BiaoGe.lastChooseLFD[realmID][player].dungeons[dungeonID] = isChecked
                end
            end)
        end)
        hooksecurefunc("LFGDungeonListCheckButton_OnClick", function(button, category, dungeonList, hiddenByCollapseList)
            isOnClick = true
            BG.After(0.01, function()
                isOnClick = false
            end)
            -- local parent = button:GetParent();
            -- local dungeonID = parent.id;
            -- local isChecked = button:GetChecked();
        end)
    end
end)

BGE.Init(function()
    pcall(function()
        local others = BG["FrameOptions_others"]
        if not others or BG.options["buttonzhidingFB"] then
            return
        end

        local lowest
        for _, child in ipairs({ others:GetChildren() }) do
            if child and child:IsShown() then
                local bottom = child:GetBottom()
                if bottom and (not lowest or bottom < lowest) then
                    lowest = bottom
                end
            end
        end
        if not lowest then
            return
        end
        local y = lowest - 30 - others:GetTop()

        local fbID = 632
        local text1
        if BG.IsWLK_80 then
            text1 = L["节日副本和"] .. GetRealZoneText(fbID)
        else
            text1 = L["节日副本"]
        end
        local text = format(L["一键指定%s"], text1)
        local ontext = {
            text,
            format(L["在地下城和团队副本界面增加一键指定%s按钮。"], text1),
            " ",
            L["打开随机本界面时，会自动选择上一次的随机本类型，而不是傻傻地在默认类型。"],
        }

        local bt = CreateFrame("CheckButton", nil, others, "ChatConfigCheckButtonTemplate")
        bt:SetSize(30, 30)
        bt:SetPoint("TOPLEFT", others, 15, y)
        if BIAOGE_TEXT_FONT then
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        end
        bt.Text:SetText(text)
        bt.Text:SetWordWrap(false)
        bt.Text:SetWidth(min(bt.Text:GetStringWidth() + 20, 500))
        bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
        bt.name = "zhidingFB"
        bt.ontext = ontext
        BG.options["buttonzhidingFB"] = bt
        bt:SetChecked(BiaoGe.options["zhidingFB"] == 1)
        bt:SetScript("OnClick", function(self)
            BiaoGe.options[self.name] = self:GetChecked() and 1 or 0
            BG.PlaySound(1)
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            for i, tipText in ipairs(self.ontext) do
                if i == 1 then
                    GameTooltip:AddLine(tipText, 1, 1, 1, true)
                else
                    GameTooltip:AddLine(tipText, 1, .82, 0, true)
                end
            end
            GameTooltip:Show()
        end)
        bt:SetScript("OnLeave", GameTooltip_Hide)
        bt:SetScript("OnShow", function(self)
            self:SetChecked(BiaoGe.options[self.name] == 1)
        end)
    end)
end)
