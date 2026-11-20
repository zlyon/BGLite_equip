if BG.IsBlackListPlayer then return end
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
local Round = ns.Round

local Maxb = ns.Maxb
local HopeMaxn = ns.HopeMaxn
local HopeMaxi = ns.HopeMaxi

local pt = print
local realmID = GetRealmID()
local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local GetLootMethod = GetLootMethod or C_PartyInfo.GetLootMethod

function BG.ClearBiaoGeUI()
    function BG.ClearBiaoGeByIndex(FB, b)
        if b == Maxb[FB] + 1 then
            for i = 1, BG.Maxi + 10 do -- 清空支出
                if BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i] then
                    if BGLite_equip.options["retainExpenses"] ~= 1 then
                        BG.Frame[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i]:SetText("")
                        BGLite_equip[FB]["boss" .. Maxb[FB] + 1]["zhuangbei" .. i] = nil
                    end
                    if not (BGLite_equip.options["retainExpenses"] == 1 and BGLite_equip.options["retainExpensesMoney"] == 1) then
                        BG.Frame[FB]["boss" .. Maxb[FB] + 1]["jine" .. i]:SetText("")
                        BGLite_equip[FB]["boss" .. Maxb[FB] + 1]["jine" .. i] = nil
                    end
                    BG.Frame[FB]["boss" .. Maxb[FB] + 1]["maijia" .. i]:SetText("")
                    BGLite_equip[FB]["boss" .. Maxb[FB] + 1]["maijia" .. i] = nil
                end
            end
        elseif b <= Maxb[FB] then
            for i = 1, BG.Maxi + 10 do
                -- 表格
                if BG.Frame[FB]["boss" .. b]["zhuangbei" .. i] then
                    BG.Frame[FB]["boss" .. b]["zhuangbei" .. i]:SetText("")
                    BG.Frame[FB]["boss" .. b]["maijia" .. i]:SetText("")
                    BG.Frame[FB]["boss" .. b]["jine" .. i]:SetText("")
                    BG.Frame[FB]["boss" .. b]["qiankuan" .. i]:Hide()
                    BG.Frame[FB]["boss" .. b]["guanzhu" .. i]:Hide()
                end
                BGLite_equip[FB]["boss" .. b]["zhuangbei" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["maijia" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["jine" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["qiankuan" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["guanzhu" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["loot" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["itemLevel" .. i] = nil
                BGLite_equip[FB]["boss" .. b]["bindOnEquip" .. i] = nil
                for k, v in pairs(BG.playerClass) do
                    BGLite_equip[FB]["boss" .. b][k .. i] = nil
                end
                -- 对账
                if BG.DuiZhangFrame[FB]["boss" .. b]["zhuangbei" .. i] then
                    BG.DuiZhangFrame[FB]["boss" .. b]["zhuangbei" .. i]:SetText("")
                    BG.DuiZhangFrame[FB]["boss" .. b]["myjine" .. i]:SetText("")
                end
            end
        end
    end

    function BG.ClearBiaoGe(_type, FB)
        if not FB then return end
        if _type == "biaoge" then
            for b = 1, Maxb[FB] + 1 do
                BG.ClearBiaoGeByIndex(FB, b)
            end
            BGLite_equip[FB].tradeTbl = {}
            BGLite_equip[FB].raidRoster = nil
            BGLite_equip[FB].auctionLog = nil
            BGLite_equip[FB].leaderInfo = nil
            BG.UpdateAuctionLogFrame()
            BG.auctionLogFrame.changeFrame:Hide()

            local num -- 分钱人数
            num = BG.GetFBinfo(FB, "maxplayers") or 40
            if num then
                BG.Frame[FB]["boss" .. Maxb[FB] + 2]["jine4"]:SetText(num)
                BGLite_equip[FB]["boss" .. Maxb[FB] + 2]["jine4"] = num
            end

            local money = floor(GetMoney() / 1e4)
            BGLite_equip.clearBiaoGeMoney = BGLite_equip.clearBiaoGeMoney or {}
            BGLite_equip.clearBiaoGeMoney[FB] = {
                FB = FB,
                realmID = realmID,
                name = BG.myName,
                money = money,
                time = GetServerTime()
            }
            BG.UpdateButtonClearBiaoGeMoney()
            return num
        elseif _type == "hope" then
            for n = 1, HopeMaxn[FB] do
                for b = 1, Maxb[FB] - 1 do
                    for i = 1, HopeMaxi do
                        if BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] then
                            BG.HopeFrame[FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i]:SetText("")
                            BGLite_equip.Hope[realmID][BG.myName][FB]["nandu" .. n]["boss" .. b]["zhuangbei" .. i] = nil
                        end
                    end
                end
            end
            BG.UpdateItemLib_LeftHope_HideAll()
            BG.UpdateItemLib_RightHope_HideAll()
        end
    end

    -- 清空按钮
    do
        local bt = BG.CreateButton(BG.FBMainFrame)
        bt:SetSize(120, 25)
        bt:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 30, 38)
        bt:SetText(L["清空表格"])
        bt:RegisterForClicks("AnyUp")
        BG.ButtonQingKong = bt
        -- 按钮触发
        bt:SetScript("OnClick", function(self, button)
            BG.PlaySound(1)
            if button == "LeftButton" then
                StaticPopup_Show("QINGKONGBIAOGE")
            elseif button == "RightButton" then
                GameTooltip:Hide()
                BG.CreateFreeClearBiaoGeFrame()
            end
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["清空表格"], 1, 1, 1, true)
            GameTooltip:AddLine(L["一键清空全部装备、买家、金额，同时还清空关注和欠款。如果有自动拍卖记录，则也会被清空。"], 1, 0.82, 0, true)
            GameTooltip:AddLine(" ", 1, 0.82, 0, true)
            GameTooltip:AddLine(AddTexture("LEFT") .. L["清空全部"], 1, 0.82, 0, true)
            GameTooltip:AddLine(AddTexture("RIGHT") .. L["清空部分内容（自选）"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(bt)

        StaticPopupDialogs["QINGKONGBIAOGE"] = {
            text = L["确定清空表格？"],
            button1 = L["是"],
            button2 = L["否"],
            OnAccept = function()
                local num = BG.ClearBiaoGe("biaoge", BG.FB1)
                if num then
                    BG.SendSystemMessage(BG.STC_b1(format(
                        L["已清空表格< %s >，分钱人数已改为%s人。"], BG.GetFBinfo(BG.FB1, "shortName"), num)))
                else
                    BG.SendSystemMessage(BG.STC_b1(format(
                        L["已清空表格< %s >。"], BG.GetFBinfo(BG.FB1, "shortName"))))
                end
                BG.PlaySound(2)
            end,
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
    end

    -- 自动清空表格
    do
        local teamText = ''
        local function IsNotSameTeam(FB)
            FB = FB or BG.FB1
            if not IsInRaid(1) then
                teamText = L['不在团队里。']
                return true
            end
            -- 没有历史成员名单
            if not BGLite_equip[FB].raidRoster then
                teamText = L['表格没有历史成员名单。']
                return true
            end
            -- 超过x天了
            if GetServerTime() - BGLite_equip[FB].raidRoster.time >= 86400 * 1 then
                teamText = L['表格的历史成员名单的创建时间已超过1天，判断为现在是新团队。']
                return true
            end
            -- 服务器不同
            if BG.realmName ~= BGLite_equip[FB].raidRoster.realm then
                teamText = L['表格的历史成员名单服务器是[%s]，与当前服务器[%s]不同，判断为现在是新团队。']:format(BG.FormatRealmName(BGLite_equip[FB].raidRoster.realm or ''), BG.FormatRealmName(BG.realmName or ''))
                return true
            end
            local maxCount = max(#BG.raidRosterInfo, #BGLite_equip[FB].raidRoster.roster)
            local sameCount = 0
            for _, vv in ipairs(BG.raidRosterInfo) do
                for _, name in ipairs(BGLite_equip[FB].raidRoster.roster) do
                    if vv.name == name then
                        sameCount = sameCount + 1
                    end
                end
            end
            if sameCount / maxCount < 0.6 then
                teamText = L['表格的历史成员人数为%s，当前团队人数为%s，相同成员的占比低于60%%，判断为现在是新团队。']:format(#BGLite_equip[FB].raidRoster.roster, #BG.raidRosterInfo)
                return true
            end
            return false
        end
        BG.IsNotSameTeam = IsNotSameTeam
        local function SendTips(FB)
        end

        local notCheckMaxPlayer = false
        local notCheckDiff = true
        local needCheck
        local function CheckCD()
            BG.After(3, function()
                local _, _, diffID, _, maxPlayers, _, _, instanceID = GetInstanceInfo()
                local FB = BG.FBIDtable[instanceID]
                if BG.IsForever and FB == "UBRSforever" then return end
                SendTips(FB)
                if BG.IsTBCFB(FB) and not ns.canShowTBC then return end
                if not (FB and IsInInstance()) then return end
                local newCD = true
                for i = 1, GetNumSavedInstances() do
                    local _, _, _, _diffID, locked, _, _, _, _maxPlayers, _, _, _, _, _instanceID = GetSavedInstanceInfo(i)
                    if locked and (instanceID == _instanceID)
                        and (notCheckMaxPlayer or maxPlayers == _maxPlayers)
                        and (notCheckDiff or diffID == _diffID)
                    then
                        newCD = false
                        break
                    end
                end
                -- 如果是新CD
                if newCD then
                    BG.ClickFBbutton(FB)
                    -- 有这些场景：1 打完NAXX，然后进黑龙（不要清空表格）。2 上CD打过黑龙 这CD进NAXX

                    -- 如果当前副本对应的BOSS格子有东西（除了杂项） 就清空整个表格
                    -- 如果当前副本对应的BOSS格子没东西但其他格子有东西，且当前团队成员跟当前副本的历史成员名单不同 就清空整个表格
                    local clearType
                    local startB = BG.bossPositionStartEnd[instanceID][1]
                    local endB = BG.bossPositionStartEnd[instanceID][2]
                    if BG.BiaoGeHavedItem(FB, "autoQingKong", instanceID) then
                        clearType = 1
                    end
                    if not clearType and BG.BiaoGeHavedItem(FB, "onlyboss") and IsNotSameTeam(FB) then
                        clearType = 2
                    end

                    if clearType then
                        if BGLite_equip.options.autoQingKongSaveHistory == 1 then
                            BG.SaveBiaoGe(FB)
                            local num = BG.ClearBiaoGe("biaoge", FB)
                            local link = "|cff00FF00|Hgarrmission:" .. "BiaoGe:" .. L["撤回清空"] .. ":" .. FB .. ":" .. GetServerTime() ..
                                "|h[" .. L["撤回清空"] .. "]|h|r"
                            BG.SendSystemMessage(format(L["已自动清空表格< %s >，分钱人数已改为%s人。原表格数据已保存至历史表格1。"], BG.GetFBinfo(FB, "shortName"), num) .. link)
                        else
                            local num = BG.ClearBiaoGe("biaoge", FB)
                            BG.SendSystemMessage(format(L["已自动清空表格< %s >，分钱人数已改为%s人。"], BG.GetFBinfo(FB, "shortName"), num))
                        end
                        if clearType == 1 then
                            BG.SendSystemMessage(L['自动清空表格的原因：1.当前副本你是新CD；2.%s']:format(
                                L['当前副本所在的表格BOSS编号（%s-%s）格子中存在旧记录。']:format(startB, endB)))
                        elseif clearType == 2 then
                            BG.SendSystemMessage(L['自动清空表格的原因：1.当前副本你是新CD；2.%s']:format(
                                teamText))
                        end
                        BG.PlaySound("qingkong")
                    end
                end
            end)
        end
        BG.RegisterEvent("RAID_INSTANCE_WELCOME", function(self, event, ...)
            if BGLite_equip.options["autoQingKong"] ~= 1 then return end
            needCheck = true
            RequestRaidInfo()
        end)
        BG.RegisterEvent("UPDATE_INSTANCE_INFO", function()
            if needCheck then
                needCheck = nil
                CheckCD()
            end
        end)

        local clicked = {}
        hooksecurefunc("SetItemRef", function(link)
            local _, biaoge, cehui, FB, time = strsplit(":", link)
            if not (biaoge == "BiaoGe" and cehui == L["撤回清空"] and FB) then return end
            if not clicked[time] then
                clicked[time] = true
                BG.SetBiaoGeFormHistory(FB, 1)
                BG.DeleteHistory(FB, 1)
                BG.SendSystemMessage(L["已撤回清空，还原了表格数据，并删除了历史表格1。"])
                BG.PlaySound("cehuiqingkong")
                BG.PlaySound(1)
            else
                BG.SendSystemMessage(BG.STC_r1(L["只能撤回一次。"]))
            end
        end)
    end

    -- 黑上按每次进本询问，不使用团队副本 CD 判断。
    local FB = "UBRSforever"
    local popupName = "BIAOGE_UBRS_CLEAR"
    local function InBlackrockSpire()
        return IsInInstance() and select(8, GetInstanceInfo()) == 229
    end
    local generation = 0
    local popupGeneration

    local function CanPrompt()
        return InBlackrockSpire() and IsInRaid(1)
            and BGLite_equip.options.autoQingKong == 1
            and BG.BiaoGeHavedItem(FB)
    end
    local function CancelPrompt()
        generation = generation + 1
        popupGeneration = nil
        StaticPopup_Hide(popupName)
    end

    StaticPopupDialogs[popupName] = {
        text = L["黑上表格中已有账目，是否清空表格？"],
        button1 = L["清空表格"],
        button2 = L["不清空表格"],
        OnAccept = function()
            if popupGeneration ~= generation or not CanPrompt() then return end
            popupGeneration = nil
            BG.SaveBiaoGe(FB)
            local num = BG.ClearBiaoGe("biaoge", FB)
            BG.SendSystemMessage(BG.STC_b1(format(
                L["已清空黑上表格，分钱人数已改为%s人。"], num)))
            BG.PlaySound("qingkong")
        end,
        OnHide = function()
            popupGeneration = nil
        end,
        timeout = 5,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
    }

    local function CheckEntry(entryGeneration)
        if entryGeneration ~= generation then return end
        if not CanPrompt() then return end
        popupGeneration = entryGeneration
        if not StaticPopup_Show(popupName) then
            popupGeneration = nil
        end
    end

    BG.RegisterEvent("PLAYER_ENTERING_WORLD", function(self, event, isInitialLogin, isReloadingUi)
        CancelPrompt()
        if isInitialLogin or isReloadingUi then return end
        local entryGeneration = generation
        BG.After(3, function()
            -- 只检查本次进入的场景，避免快速出本重进时沿用旧的副本状态。
            CheckEntry(entryGeneration)
        end)
    end)
    BG.RegisterEvent("PLAYER_LEAVING_WORLD", CancelPrompt)

    -- 清空时记录身上金币
    do
        local poit

        local function OnEnter(self)
            local FB = BG.FB1
            local p = SetClassCFF(BGLite_equip.clearBiaoGeMoney[FB].name)
            local f = BG.GetFBinfo(BGLite_equip.clearBiaoGeMoney[FB].FB, "shortName")
            local t = date("%m-%d %H:%M", BGLite_equip.clearBiaoGeMoney[FB].time)
            local m = GetMoneyString(BGLite_equip.clearBiaoGeMoney[FB].money .. "0000", true)
            GameTooltip:SetOwner(poit, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["清空表格时携带的金币"], 1, 1, 1, true)
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine(L["角色："], p, 1, 0.82, 0, 1, 0.82, 0)
            GameTooltip:AddDoubleLine(L["表格："], f, 1, 0.82, 0, 1, 0.82, 0)
            GameTooltip:AddDoubleLine(L["时间："], t, 1, 0.82, 0, 1, 0.82, 0)
            GameTooltip:AddDoubleLine(L["金币："], m, 1, 0.82, 0, 1, 0.82, 0)
            GameTooltip:Show()
        end

        function BG.UpdateButtonClearBiaoGeMoney()
            local FB = BG.FB1
            local f = BG.ButtonClearBiaoGeMoney
            if not (BGLite_equip.clearBiaoGeMoney and BGLite_equip.clearBiaoGeMoney[FB]) then
                f:Hide()
            else
                local jine = BG.Frame[FB]["boss" .. Maxb[FB] + 2].jine5
                f:Show()
                f:ClearAllPoints()
                f:SetPoint("TOPRIGHT", jine, "BOTTOMRIGHT", 1, -1)
                f.Text:SetText(BGLite_equip.clearBiaoGeMoney[FB].money)
                if BGLite_equip.clearBiaoGeMoney[FB].realmID == realmID and BGLite_equip.clearBiaoGeMoney[FB].name == BG.myName then
                    f.Text:SetTextColor(1, .82, 0)
                    f.title.Text:SetTextColor(1, .82, 0)
                else
                    f.Text:SetTextColor(.5, .5, .5)
                    f.title.Text:SetTextColor(.5, .5, .5)
                end
            end
        end

        local jine = BG.Frame[BG.FB1]["boss" .. Maxb[BG.FB1] + 2].jine5
        local f = CreateFrame("Frame", nil, BG.FBMainFrame, "BackdropTemplate")
        f:SetSize(jine:GetWidth(), 20)
        BG.ButtonClearBiaoGeMoney = f
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        t:SetAllPoints()
        t:SetJustifyH("LEFT")
        t:SetTextColor(1, .82, 0)
        f.Text = t
        f:SetScript("OnEnter", OnEnter)
        f:SetScript("OnLeave", GameTooltip_Hide)

        local f = CreateFrame("Frame", nil, BG.ButtonClearBiaoGeMoney, "BackdropTemplate")
        f:SetSize(0, 20)
        f:SetPoint("RIGHT", BG.ButtonClearBiaoGeMoney, "LEFT", 0, 0)
        poit = f
        BG.ButtonClearBiaoGeMoney.title = f
        local t = f:CreateFontString()
        t:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
        t:SetPoint("RIGHT")
        t:SetTextColor(1, .82, 0)
        t:SetJustifyH("RIGHT")
        t:SetText(L["清空表格时的金币："])
        t:SetWordWrap(false)
        f:SetWidth(min(t:GetStringWidth() + 20, 160))
        f.Text = t
        f:SetScript("OnEnter", OnEnter)
        f:SetScript("OnLeave", GameTooltip_Hide)

        BG.UpdateButtonClearBiaoGeMoney()
    end

    -- 自定义清空
    function BG.CreateFreeClearBiaoGeFrame()
        if BG.freeClearBiaoGeFrame and BG.freeClearBiaoGeFrame:IsVisible() then
            BG.freeClearBiaoGeFrame:Hide()
            return
        end
        if BG.exportFrame then
            BG.exportFrame:Hide()
        end
        local FB = BG.FB1
        local parent = BG["Frame" .. FB]
        local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        f:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        f:SetBackdropColor(0, 0, 0, 0.9)
        f:SetBackdropBorderColor(1, 1, 1, BG.borderAlpha)
        f:SetPoint("BOTTOMLEFT", BG.ButtonQingKong, "TOPLEFT", 0, 5)
        f:SetSize(350, 450)
        f:EnableMouse(true)
        f:SetMovable(true)
        f:SetFrameStrata("HIGH")
        f.buttons = {}
        f:SetScript("OnHide", function(self)
            self:Hide()
        end)
        f:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        f:SetScript("OnMouseDown", function(self)
            self:StartMoving()
        end)
        BG.freeClearBiaoGeFrame = f

        BG.CreateCloseButton(f)

        local l = f:CreateLine()
        l:SetColorTexture(1, 1, 1, BG.borderAlpha)
        l:SetStartPoint("TOPLEFT", 1, -21)
        l:SetEndPoint("TOPRIGHT", -1, -21)
        l:SetThickness(1)

        f.titleText = f:CreateFontString()
        f.titleText:SetPoint("CENTER", f, "TOP", 0, -11)
        f.titleText:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        f.titleText:SetFormattedText(L["清空表格（%s）"], BG.GetFBinfo(FB, "shortName"))

        local function CreateCheckButton(b, text)
            local bt = CreateFrame("CheckButton", nil, f, "ChatConfigCheckButtonTemplate")
            bt:SetSize(30, 30)
            if next(f.buttons) then
                bt:SetPoint("TOPLEFT", f.buttons[#f.buttons], "BOTTOMLEFT", 0, 0)
            else
                bt:SetPoint("TOPLEFT", 10, -30)
            end
            bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            bt.Text:SetText(text)
            bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
            bt.id = b
            tinsert(f.buttons, bt)
            bt:HookScript("OnClick", function()
                f.sureButton:Update()
            end)
        end

        for b = 1, Maxb[FB] + 1 do
            local bossName = BG.Boss[FB]["boss" .. b].name2
            local color = BG.Boss[FB]["boss" .. b].color
            local text = "|cff" .. color .. bossName
            CreateCheckButton(b, text)
        end
        CreateCheckButton("auctionLog", L["自动拍卖记录"])
        f:SetHeight(#f.buttons * 30 + 40)

        local function OnClick(self)
            BG.PlaySound(1)
            for i, bt in ipairs(f.buttons) do
                bt:SetChecked(self.choose)
            end
            f.sureButton:Update()
        end

        local bt = BG.CreateButton(f)
        bt:SetSize(110, 25)
        bt:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -30)
        bt:SetText(L["全选"])
        bt.choose = true
        f.chooseAllButton = bt
        bt:SetScript("OnClick", OnClick)

        local bt = BG.CreateButton(f)
        bt:SetSize(110, 25)
        bt:SetPoint("TOP", f.chooseAllButton, "BOTTOM", 0, -5)
        bt:SetText(L["取消全选"])
        f.cancelAllButton = bt
        bt:SetScript("OnClick", OnClick)

        local bt = BG.CreateButton(f)
        bt:SetSize(110, 25)
        bt:SetPoint("BOTTOMRIGHT", -10, 10)
        bt:SetText(L["确定清空表格"])
        f.sureButton = bt
        bt:SetScript("OnClick", function(self)
            for i, bt in ipairs(f.buttons) do
                if bt:GetChecked() then
                    local b = bt.id
                    if b == "auctionLog" then
                        BGLite_equip[FB].auctionLog = nil
                        BG.UpdateAuctionLogFrame()
                        BG.auctionLogFrame.changeFrame:Hide()
                    elseif type(b) == "number" then
                        BG.ClearBiaoGeByIndex(FB, bt.id)
                    end
                end
            end
            BG.PlaySound(2)
            f:Hide()
        end)
        function f.sureButton:Update()
            self:Disable()
            for i, bt in ipairs(f.buttons) do
                if bt:GetChecked() then
                    self:Enable()
                end
            end
        end

        f.sureButton:Update()
    end

    -- 清空心愿
    do
        local bt = BG.CreateButton(BG.HopeMainFrame)
        bt:SetSize(120, 25)
        bt:SetPoint("BOTTOMLEFT", BG.MainFrame, "BOTTOMLEFT", 30, 38)
        bt:SetText(L["清空心愿"])
        BG.ButtonHopeQingKong = bt
        -- 按钮触发
        bt:SetScript("OnClick", function()
            StaticPopup_Show("QINGKONGXINYUAN")
            BG.PlaySound(1)
        end)
        bt:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
            GameTooltip:ClearLines()
            GameTooltip:AddLine(L["清空心愿"], 1, 1, 1, true)
            GameTooltip:AddLine(L["一键清空全部心愿装备"], 1, 0.82, 0, true)
            GameTooltip:Show()
        end)
        BG.GameTooltip_Hide(bt)

        StaticPopupDialogs["QINGKONGXINYUAN"] = {
            text = L["确定清空心愿？"],
            button1 = L["是"],
            button2 = L["否"],
            OnAccept = function()
                BG.ClearBiaoGe("hope", BG.FB1)
                SendSystemMessage(BG.STC_g1(format(L["已清空心愿< %s >"], BG.GetFBinfo(BG.FB1, "shortName"))))
                BG.PlaySound(2)
            end,
            OnCancel = function()
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            showAlert = true,
        }
    end
end
