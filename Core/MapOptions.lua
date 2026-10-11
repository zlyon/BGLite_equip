local AddonName, ns = ...

local L = ns.L
local LibBG = ns.LibBG
local RGB = ns.RGB
local RR = ns.RR
local SetClassCFF = ns.SetClassCFF
local AddTexture = ns.AddTexture
local Maxb = ns.Maxb

local function SetParent(self, key)
    if BiaoGe.options[key] ~= 1 then
        self:Hide()
    end
    local parent = BG.options["button" .. key]
    parent.child = parent.child or {}
    tinsert(parent.child, self)
    if not parent.hookDisable then
        parent.hookDisable = true
        hooksecurefunc(parent, "Disable", function()
            if parent.Text then
                parent.Text:SetTextColor(.5, .5, .5)
            end
            for i, child in ipairs(parent.child) do
                child:Hide()
            end
        end)
    end
end

-- 打开BiaoGe设置并切换到战术（map）设置页。
function BG.OpenMapOptions()
    if BG.ButtonOptions_map then
        BG.ButtonOptions_map:Click()
    end
    BG.OpenOption()
end

BGE.Init(function()
    function BG.HideMove()
        if not BG.boardReceiverMoveOnly then
            for k, f in pairs(BG.Movetable) do
                f:SetBackdropColor(0, 0, 0, 0)
                f:SetBackdropBorderColor(0, 0, 0, 0)
                f:SetMovable(false)
                f:EnableMouse(false)
                f:SetScript("OnUpdate", nil)
                f.name:Hide()
                f:Clear()
            end
        end
        if BG.HideBoardReceiverMovePreview then
            BG.HideBoardReceiverMovePreview()
        end
        BG.boardReceiverMoveOnly = nil
        BG.ButtonMoveLock:Hide()
        BG.ButtonMove:SetText(L["通知移动"])
    end

    -- 进入仅显示减伤链进度条的通知移动模式。
    function BG.MoveBoardReceiver()
        if InCombatLockdown and InCombatLockdown() then return end
        if BG.boardReceiverMoveOnly then
            BG.HideMove()
        else
            BG.boardReceiverMoveOnly = true
            if BG.ShowBoardReceiverMovePreview then
                BG.ShowBoardReceiverMovePreview()
            end
            BG.ButtonMoveLock:Show()
            BG.MainFrame:Hide()
        end
        BG.PlaySound(1)
    end

    function BG.Move()
        if BG.boardReceiverMoveOnly or BG.FrameLootMsg:IsMovable() then
            BG.HideMove()
        else
            for k, f in pairs(BG.Movetable) do
                f:SetBackdrop({
                    bgFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                    edgeSize = 2,
                })
                f:SetBackdropColor(0, 0, 0, 0.5)
                f:SetBackdropBorderColor(0, 0, 0, 1)
                f:SetMovable(true)
                f:SetScript("OnMouseUp", function(self, enter)
                    self:StopMovingOrSizing()
                    if enter == "RightButton" then
                        f:ClearAllPoints()
                        f:SetPoint(unpack(f.homepoin))
                    end
                    BiaoGe.point[f:GetName()] = { f:GetPoint(1) }
                end)
                f:SetScript("OnMouseDown", function(self)
                    self:StartMoving()
                end)
                f.name:Show()

                local time1 = 0
                local time_update = 1.5
                if f == BG.FrameTradeMsg then
                    time_update = 4
                end
                local name, link, quality, level, _, _, _, _, _, Texture, _, typeID = GetItemInfo(itemID)
                local FB = BG.FB1
                local num = Maxb[FB] - 2
                f:SetScript("OnUpdate", function()
                    local time2 = GetTime()
                    if time2 - time1 >= time_update then
                        if link then
                            if f == BG.FrameLootMsg then
                                f:AddMessage("|cff00BFFF" ..
                                    format(L["已自动记入表格：%s%s(%s) => %s< %s >%s"], RR, (AddTexture(Texture) .. link), level, "|cffFF1493", BG.Boss[FB]["boss" .. num]["name2"], RR) .. BG.STC_r1(L[" （测试） "]))
                            else
                                f:AddMessage(format("|cff00BFFF" .. L["< 交易记账成功 >|r\n装备：%s\n买家：%s\n金额：%s%d|rg%s\nBOSS：%s%s|r"],
                                    (AddTexture(Texture) .. link), SetClassCFF(BG.playerName, "Player"), "|cffFFD700", 10000, L["|cffFF0000（欠款2000）|r"], "|cff" .. BG.Boss[FB]["boss" .. num]["color"], BG.Boss[FB]["boss" .. num]["name2"]) .. BG.STC_r1(L[" （测试） "]))
                            end
                        else
                            name, link, quality, level, _, _, _, _, _, Texture, _, typeID = GetItemInfo(itemID)
                        end
                        time1 = time2
                    end
                end)
            end
            if BG.ShowBoardReceiverMovePreview then
                BG.ShowBoardReceiverMovePreview()
            end
            BG.ButtonMoveLock:Show()
            BG.MainFrame:Hide()
            BG.ButtonMove:SetText(L["锁定"])
        end
        BG.PlaySound(1)
    end
    if BG.ButtonMove then
        BG.ButtonMove:SetScript("OnClick", BG.Move)
    end
end)

BGE.Init3(function()
    if not BG.OptionsCreateTab then return end
    if BG.FrameOptions_map then return end

    local O = {}

    -- 模板
    do
        -- 滑块
        do
            local function updateSliderEditBox(self)
                local slider = self.__owner
                local minValue, maxValue = slider:GetMinMaxValues()
                local text = tonumber(self:GetText())
                if not text then return end
                text = min(maxValue, text)
                text = max(minValue, text)
                slider:SetValue(text)
                self:SetText(text)
                BiaoGe.options[slider.name] = text
                self:ClearFocus()
                BG.PlaySound(1)
            end
            local function OnValueChanged(self, value)
                self.edit:ClearFocus()
                value = tonumber(value)
                BiaoGe.options[self.name] = value
                self.edit:SetText(value)
            end
            local function OnClick(self, enter)
                local slider = self.__owner
                if enter == "RightButton" then
                    if BG.options[slider.name .. "reset"] then
                        local value = BG.options[slider.name .. "reset"]
                        BiaoGe.options[slider.name] = value
                        slider:SetValue(value)
                        slider.edit:SetText(value)
                        BG.PlaySound(1)
                    end
                end
            end
            local function OnEnter(self)
                local slider = self.__owner
                if slider.ontext then
                    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
                    GameTooltip:ClearLines()
                    if type(slider.ontext) == "table" then
                        for i, text in ipairs(slider.ontext) do
                            if i == 1 then
                                GameTooltip:AddLine(text, 1, 1, 1, true)
                            else
                                GameTooltip:AddLine(text, 1, 0.82, 0, true)
                            end
                            GameTooltip:Show()
                        end
                    else
                        GameTooltip:SetText(slider.ontext)
                    end
                end
            end
            local function OnLeave(self)
                GameTooltip:Hide()
            end
            function O.CreateSlider(name, text, parent, minValue, maxValue, step, x, y, ontext, width)
                local savedValue = tonumber(BiaoGe.options[name]) or minValue
                local value = min(maxValue, savedValue)
                value = max(minValue, value)
                BiaoGe.options[name] = value

                local template
                if BG.IsWLK_80 then
                    template = "TextToSpeechSliderTemplate"
                else
                    template = "OptionsSliderTemplate"
                end

                local slider = CreateFrame("Slider", nil, parent, template)
                slider:SetPoint("TOPLEFT", parent, x, y)
                slider:SetWidth(width or 180)
                slider:SetMinMaxValues(minValue, maxValue)
                slider:SetValueStep(step)
                slider:SetObeyStepOnDrag(true)
                slider:SetHitRectInsets(0, 0, 0, 0)
                slider:SetValue(BiaoGe.options[name])
                slider.name = name
                slider.ontext = ontext
                slider:SetScript("OnValueChanged", OnValueChanged)
                if BG.IsTBC then
                    slider.bar = CreateFrame("Frame", nil, slider, "BackdropTemplate")
                    slider.bar:SetBackdrop({
                        bgFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                        edgeSize = 1,
                    })
                    slider.bar:SetBackdropColor(1, 1, 1, .1)
                    -- slider.bar:SetBackdropColor(.5, .5, .5, .3)
                    slider.bar:SetBackdropBorderColor(0, 0, 0, 1)
                    slider.bar:SetSize(slider:GetWidth(), slider:GetHeight() - 8)
                    slider.bar:SetPoint("CENTER")
                    slider.bar:SetFrameLevel(slider:GetFrameLevel())
                end

                slider.Low:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                slider.Low:SetText(minValue)
                slider.Low:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 10, -2)
                slider.High:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                slider.High:SetText(maxValue)
                slider.High:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", -10, -2)
                slider.Text:SetFont(BIAOGE_TEXT_FONT, 14, "OUTLINE")
                slider.Text:ClearAllPoints()
                slider.Text:SetPoint("CENTER", 0, 25)
                slider.Text:SetText(text)
                slider.Text:SetTextColor(1, .8, 0)
                slider.Text:SetSize(slider:GetWidth(), 40)

                slider.edit = CreateFrame("EditBox", nil, slider, BG.editTemplate)
                slider.edit:SetSize(50, 20)
                slider.edit:SetPoint("TOP", slider, "BOTTOM")
                slider.edit:SetJustifyH("CENTER")
                slider.edit:SetAutoFocus(false)
                slider.edit:SetText(BiaoGe.options[name])
                slider.edit:SetCursorPosition(0)
                slider.edit.__owner = slider
                slider.edit:SetScript("OnEnterPressed", updateSliderEditBox)
                slider.edit:SetScript("OnEditFocusLost", updateSliderEditBox)

                slider.button = CreateFrame("Button", nil, slider)
                slider.button:SetAllPoints(slider.Text)
                slider.button:RegisterForClicks("RightButtonUp")
                slider.button.__owner = slider
                slider.button:SetScript("OnClick", OnClick)
                slider.button:SetScript("OnEnter", OnEnter)
                slider.button:SetScript("OnLeave", OnLeave)

                return slider
            end
        end
        -- 多选按钮
        do
            local function OnClick(self)
                if self:GetChecked() then
                    BiaoGe.options[self.name] = 1
                else
                    BiaoGe.options[self.name] = 0
                end
                if self.child then
                    for _, f in pairs(self.child) do
                        f:SetShown(self:GetChecked())
                    end
                end
                if self.callback then
                    local func, arg1, arg2, arg3, arg4, arg5 = unpack(self.callback)
                    func(arg1, arg2, arg3, arg4, arg5)
                end
                BG.PlaySound(1)
            end
            local function OnEnter(self)
                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
                GameTooltip:ClearLines()
                if type(self.ontext) == "table" then
                    for i, text in ipairs(self.ontext) do
                        if i == 1 then
                            GameTooltip:AddLine(text, 1, 1, 1, true)
                        else
                            GameTooltip:AddLine(text, 1, 0.82, 0, true)
                        end
                        GameTooltip:Show()
                    end
                else
                    GameTooltip:SetText(self.ontext)
                end
            end
            local function OnLeave(self)
                GameTooltip:Hide()
            end
            local function OnShow(self)
                self:SetChecked(BiaoGe.options[self.name] == 1)
            end
            function O.CreateCheckButton(name, text, parent, x, y, ontext, long, callback)
                local bt = CreateFrame("CheckButton", nil, parent, "ChatConfigCheckButtonTemplate")
                bt:SetSize(30, 30)
                bt:SetPoint("TOPLEFT", parent, x, y)
                bt.Text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                bt.Text:SetText(text)
                bt.Text:SetWordWrap(false)
                bt.Text:SetWidth(min(bt.Text:GetStringWidth() + 20, (type(long) == 'number' and long) or (long and 500 or 160)))
                bt:SetHitRectInsets(0, -bt.Text:GetWidth(), 0, 0)
                bt.name = name
                bt.ontext = ontext
                bt.callback = callback
                BG.options["button" .. name] = bt
                bt:SetChecked(BiaoGe.options[name] == 1)
                bt:SetScript("OnClick", OnClick)
                bt:SetScript("OnEnter", OnEnter)
                bt:SetScript("OnLeave", OnLeave)
                bt:SetScript("OnShow", OnShow)
                return bt
            end
        end
        -- 线
        do
            function O.CreateLine(parent, y, height)
                local l = parent:CreateLine()
                l:SetColorTexture(RGB("808080", 1))
                l:SetStartPoint("TOPLEFT", 5, y)
                l:SetEndPoint("TOPLEFT", SettingsPanel.Container:GetWidth() - 20, y)
                l:SetThickness(height or 1.5)
                return l
            end
        end
        -- 快捷键
        do
            function O.CreateBindKey(parent, x, y, wdith, bindKey, name)
                local bt = BG.CreateButton(parent)
                bt:SetSize(wdith or 150, 25)
                bt:SetPoint("TOPLEFT", x, y)
                bt.bindKey = bindKey
                bt:SetScript("OnClick", function(self)
                    local category
                    for i, v in pairs(SettingsPanel:GetAllCategories()) do
                        if v.name == SETTINGS_KEYBINDINGS_LABEL then
                            category = v
                            break
                        end
                    end
                    if category then
                        SettingsPanel:SelectCategory(category)
                        SettingsPanel.Container.SettingsList.ScrollBox:ScrollToEnd()
                        for _, f in pairs({ SettingsPanel.Container.SettingsList.ScrollBox.ScrollTarget:GetChildren() }) do
                            local optionsName = BG.optionsName or AddonName
                            if f.Button and f.Button.Text and f.Button.Text:GetText() == optionsName then
                                local initializer = f:GetElementData()
                                local data = initializer.data
                                data.expanded = nil;
                                f.Button:Click()
                            end
                        end
                        BG.After(0, function()
                            SettingsPanel.Container.SettingsList.ScrollBox:ScrollToEnd()
                        end)
                    end
                end)
                bt:SetScript("OnShow", function(self)
                    local key1, key2 = GetBindingKey(self.bindKey)
                    if key1 or key2 then
                        bt:SetText(key1 or key2)
                    else
                        bt:SetText(L["无"])
                    end
                end)
                local t = bt:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("BOTTOM", bt, "TOP", 0, 5)
                t:SetText(name)
            end
        end
    end

    local map
    if BG.MapFrame then
        map = BG.OptionsCreateTab("Options_map", L["战术"])
    end

    -- 战术
    if map then
        local width = 15
        local height = -10
        local height_jiange = 22
        local line_height = 4
        local h = 0

        -- 站位图
        do
            local text = map:CreateFontString()
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetPoint("TOPLEFT", width, height)
            text:SetText(BG.STC_g1(L["站位图"]))
            height = height - height_jiange

            O.CreateLine(map, height + line_height)

            h = h + 30
            -- UI缩放
            do
                local name = "mapScale"
                BG.options[name .. "reset"] = 0.75
                BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
                if not tonumber(BiaoGe.options[name]) then
                    BiaoGe.options[name] = BG.options[name .. "reset"]
                end
                local ontext = {
                    L["站位图UI缩放"] .. L["|cff808080（右键还原设置）|r"],
                    L["调整站位图UI的大小。"],
                }
                local f = O.CreateSlider(name, "|cffFFFFFF" .. L["站位图UI缩放"] .. "|r", map, 0.5, 1.5, 0.01, 15, height - h, ontext)
                BG.options["button" .. name] = f

                f:SetScript("OnValueChanged", function(self, value)
                    f.edit:ClearFocus()
                    value = tonumber(string.format("%.2f", value))
                    BiaoGe.options[name] = value
                    f.edit:SetText(value)
                    BG.MapFrame:SetScale(BiaoGe.options.mapScale)
                end)
                f.button:SetScript("OnClick", function(self, enter)
                    if enter == "RightButton" then
                        if BG.options[name .. "reset"] then
                            local value = BG.options[name .. "reset"]
                            BiaoGe.options[name] = value
                            f:SetValue(value)
                            f.edit:SetText(value)
                            BG.MapFrame:SetScale(BiaoGe.options.mapScale)
                            BG.PlaySound(1)
                        end
                    end
                end)
            end

            -- 图标缩放
            do
                local name = "mapIconScale"
                BG.options[name .. "reset"] = 1
                BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
                if not tonumber(BiaoGe.options[name]) then
                    BiaoGe.options[name] = BG.options[name .. "reset"]
                end

                local ontext = {
                    L["图标缩放"] .. L["|cff808080（右键还原设置）|r"],
                    L["调整图标的大小。"],
                }
                local f = O.CreateSlider(name, "|cffFFFFFF" .. L["图标缩放"] .. "|r", map, 0.3, 1.5, 0.05, 220, height - h, ontext)
                BG.options["button" .. name] = f

                f:SetScript("OnValueChanged", function(self, value)
                    f.edit:ClearFocus()
                    value = tonumber(string.format("%.2f", value))
                    BiaoGe.options[name] = value
                    f.edit:SetText(value)
                    BG.UpdateMapIconScale()
                end)
                f.button:SetScript("OnClick", function(self, enter)
                    if enter == "RightButton" then
                        if BG.options[name .. "reset"] then
                            local value = BG.options[name .. "reset"]
                            BiaoGe.options[name] = value
                            f:SetValue(value)
                            f.edit:SetText(value)
                            BG.UpdateMapIconScale()
                            BG.PlaySound(1)
                        end
                    end
                end)
            end

            -- UI层级
            do
                local name = "mapFrameLevel"
                BG.options[name .. "reset"] = "MEDIUM"
                BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]

                local dropDown = LibBG:Create_UIDropDownMenu(nil, map)
                dropDown:SetPoint("TOPLEFT", 430, height - h)
                LibBG:UIDropDownMenu_SetWidth(dropDown, 120)
                LibBG:UIDropDownMenu_SetText(dropDown, BiaoGe.options[name])
                LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
                BG.dropDownToggle(dropDown)
                BG.options["button" .. name] = dropDown

                local t = dropDown:CreateFontString()
                t:SetPoint("BOTTOM", dropDown, "TOP", 0, 8)
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetTextColor(1, 1, 1)
                t:SetText(L["UI层级"])

                LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    for _, text in ipairs({ "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP", }) do
                        info.text = text
                        info.func = function()
                            BiaoGe.options[name] = text
                            LibBG:UIDropDownMenu_SetText(dropDown, BiaoGe.options[name])
                            BG.MapFrame:SetFrameStrata(BiaoGe.options[name])
                        end
                        info.checked = BiaoGe.options[name] == text
                        LibBG:UIDropDownMenu_AddButton(info)
                    end
                end)
            end
        end

        -- 减伤链接收器
        do
            local frameWidth = map.scroll:GetWidth() - 20
            local frameHeight = 25
            h = h + 70
            local receiverMaskTop = height - h + 15
            local receiverEditBoxes = {}
            local receiverDependentControls = {}

            local text = map:CreateFontString()
            text:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            text:SetPoint("TOPLEFT", 15, height - h)
            text:SetText(BG.STC_g1(L["减伤链提醒"]))
            h = h + height_jiange

            O.CreateLine(map, height - h + line_height)
            h = h + 0

            -- 判断当前是否处于禁止修改减伤链选项的战斗状态。
            local function ReceiverOptionsLocked()
                return InCombatLockdown and InCombatLockdown()
            end

            -- 应用一项非战斗状态下的减伤链接收端设置。
            local function UpdateReceiver()
                if ReceiverOptionsLocked() then return false end
                if BG.UpdateBoardReceiverSettings then
                    BG.UpdateBoardReceiverSettings()
                end
                return true
            end

            -- 为减伤链复选框设置带战斗保护的点击逻辑。
            local function SetReceiverCheckButtonScript(button, name)
                button:SetScript("OnClick", function(self)
                    if ReceiverOptionsLocked() then
                        self:SetChecked(BiaoGe.options[name] == 1)
                        return
                    end
                    BiaoGe.options[name] = self:GetChecked() and 1 or 0
                    if self.child then
                        for _, child in ipairs(self.child) do
                            child:SetShown(self:GetChecked())
                        end
                    end
                    if name == "boardReceiverEnabled" and not self:GetChecked() and
                        BG.boardReceiverMoveOnly and BG.HideMove then
                        BG.HideMove()
                    end
                    UpdateReceiver()
                    BG.PlaySound(1)
                end)
            end

            -- 提交减伤链滑块输入框数值，并在战斗中恢复原值。
            local function UpdateReceiverSliderEditBox(self)
                if self.receiverUpdating then return end
                self.receiverUpdating = true
                local slider = self.__owner
                if ReceiverOptionsLocked() then
                    self:SetText(BiaoGe.options[slider.name])
                    self:ClearFocus()
                    self.receiverUpdating = nil
                    return
                end
                local minValue, maxValue = slider:GetMinMaxValues()
                local value = tonumber(self:GetText())
                if value then
                    value = min(maxValue, value)
                    value = max(minValue, value)
                    slider:SetValue(value)
                    self:SetText(value)
                    self:ClearFocus()
                    BG.PlaySound(1)
                end
                self.receiverUpdating = nil
            end

            -- 启用减伤链提醒
            do
                local name = "boardReceiverEnabled"
                local ontext = {
                    L["启用减伤链提醒"],
                    L["启用后接收TuanJian团长发送的减伤链；关闭后不显示进度条、不播放语音，也不发送团长密语提醒。"],
                }
                local enabled = O.CreateCheckButton(name, L["启用减伤链提醒"], map, 15, height - h, ontext, true)
                SetReceiverCheckButtonScript(enabled, name)
                BG.options["button" .. name] = enabled
            end
            -- 预览并移动减伤链进度条
            do
                local preview = BG.CreateButton(map)
                preview:SetSize(160, 25)
                preview:SetPoint("LEFT", BG.options["buttonboardReceiverEnabled"].Text, "RIGHT", 10, 0)
                preview:SetText(L["预览减伤链进度条"])
                receiverDependentControls[#receiverDependentControls + 1] = preview
                preview:SetScript("OnClick", function()
                    if ReceiverOptionsLocked() then return end
                    if BG.MoveBoardReceiver then
                        BG.MoveBoardReceiver()
                    end
                end)
            end
            h = h + 30
            -- 减伤链语音提醒
            do
                local name = "boardReceiverVoice"
                local ontext = {
                    L["减伤链语音提醒"],
                    L["当减伤链安排到你时，播放技能准备和交减伤技能语音。"],
                }
                local voice = O.CreateCheckButton(name, L["减伤链语音提醒"], map, 15, height - h, ontext, true)
                SetReceiverCheckButtonScript(voice, name)
                receiverDependentControls[#receiverDependentControls + 1] = voice
            end
            h = h + 30
            -- 团长密语提醒
            do
                local name = "boardReceiverWhisper"
                local ontext = {
                    L["团长密语提醒"],
                    L["当你是减伤链发送者时，在倒数5秒时给相应团员发送密语提醒。"],
                }
                local whisper = O.CreateCheckButton(name, L["团长密语提醒"], map, 15, height - h, ontext, true)
                SetReceiverCheckButtonScript(whisper, name)
                receiverDependentControls[#receiverDependentControls + 1] = whisper
            end
            h = h + 30
            -- 显示谁的减伤
            h = h + 40
            do
                local name = "boardReceiverWhoShow"
                local frame = CreateFrame("Frame", nil, map, "BackdropTemplate")
                frame:SetPoint("TOPLEFT", 15, -h)
                frame:SetSize(frameWidth, frameHeight)
                receiverDependentControls[#receiverDependentControls + 1] = frame
                local t = frame:CreateFontString()
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetPoint("LEFT")
                t:SetTextColor(1, 1, 1)
                t:SetText(L["显示谁的减伤："])
                BG.options["Text" .. name] = t

                local whoShow = {
                    [1] = L["当我是团长/助理时显示所有人的减伤，否则仅显示我的减伤"],
                    [2] = L["显示所有人的减伤"],
                    [3] = L["仅显示我的减伤"],
                }
                local dropDown = LibBG:Create_UIDropDownMenu(nil, map)
                dropDown:SetPoint("LEFT", BG.options["Text" .. name], "RIGHT", -10, -2)
                LibBG:UIDropDownMenu_SetWidth(dropDown, 350)
                LibBG:UIDropDownMenu_SetText(dropDown, whoShow[BiaoGe.options[name]] or whoShow[1])
                LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
                BG.dropDownToggle(dropDown)
                BG.options["button" .. name] = dropDown
                receiverDependentControls[#receiverDependentControls + 1] = dropDown
                LibBG:UIDropDownMenu_Initialize(dropDown, function()
                    for value = 1, 3 do
                        local optionValue = value
                        local info = LibBG:UIDropDownMenu_CreateInfo()
                        info.text = whoShow[optionValue]
                        info.func = function()
                            if ReceiverOptionsLocked() then return end
                            BiaoGe.options[name] = optionValue
                            LibBG:UIDropDownMenu_SetText(dropDown, whoShow[optionValue])
                            UpdateReceiver()
                        end
                        info.checked = BiaoGe.options[name] == optionValue
                        LibBG:UIDropDownMenu_AddButton(info)
                    end
                end)
            end
            h = h + 40
            -- UI缩放
            do
                local name = "boardReceiverScale"
                BG.options[name .. "reset"] = 1
                local ontext = {
                    L["减伤链进度条缩放"] .. L["|cff808080（右键还原设置）|r"],
                    L["调整减伤链进度条的大小。"],
                }
                local f = O.CreateSlider(name, "|cffFFFFFF" .. L["减伤链进度条缩放"] .. "|r", map, 0.5, 1.5, 0.01, 15, height - h, ontext)
                BG.options["button" .. name] = f
                receiverDependentControls[#receiverDependentControls + 1] = f

                f:SetScript("OnValueChanged", function(self, value)
                    if ReceiverOptionsLocked() then
                        local oldValue = tonumber(BiaoGe.options[name]) or BG.options[name .. "reset"]
                        if value ~= oldValue then
                            f:SetValue(oldValue)
                        end
                        f.edit:SetText(oldValue)
                        return
                    end
                    f.edit:ClearFocus()
                    value = tonumber(string.format("%.2f", value))
                    BiaoGe.options[name] = value
                    f.edit:SetText(value)
                    UpdateReceiver()
                end)
                f.edit:SetScript("OnEnterPressed", UpdateReceiverSliderEditBox)
                f.edit:SetScript("OnEditFocusLost", UpdateReceiverSliderEditBox)
                receiverEditBoxes[#receiverEditBoxes + 1] = f.edit
                f.button:SetScript("OnClick", function(self, enter)
                    if ReceiverOptionsLocked() then return end
                    if enter == "RightButton" then
                        if BG.options[name .. "reset"] then
                            local value = BG.options[name .. "reset"]
                            BiaoGe.options[name] = value
                            f:SetValue(value)
                            f.edit:SetText(value)
                            UpdateReceiver()
                            BG.PlaySound(1)
                        end
                    end
                end)
            end
            -- 减伤链提前显示时间
            do
                local name = "boardReceiverRemainingTime"
                BG.options[name .. "reset"] = 10
                local ontext = {
                    L["减伤链提前显示时间"] .. L["|cff808080（右键还原设置）|r"],
                    L["只在进入设定的最后若干秒时显示减伤链进度条。"],
                }
                local f = O.CreateSlider(name, "|cffFFFFFF" .. L["减伤链提前显示时间"] .. "|r", map, 6, 30, 1, 220, height - h, ontext)
                BG.options["button" .. name] = f
                receiverDependentControls[#receiverDependentControls + 1] = f

                f:SetScript("OnValueChanged", function(self, value)
                    if ReceiverOptionsLocked() then
                        local oldValue = tonumber(BiaoGe.options[name]) or BG.options[name .. "reset"]
                        if value ~= oldValue then
                            f:SetValue(oldValue)
                        end
                        f.edit:SetText(oldValue)
                        return
                    end
                    f.edit:ClearFocus()
                    value = tonumber(string.format("%.2f", value))
                    BiaoGe.options[name] = value
                    f.edit:SetText(value)
                    UpdateReceiver()
                end)
                f.edit:SetScript("OnEnterPressed", UpdateReceiverSliderEditBox)
                f.edit:SetScript("OnEditFocusLost", UpdateReceiverSliderEditBox)
                receiverEditBoxes[#receiverEditBoxes + 1] = f.edit
                f.button:SetScript("OnClick", function(self, enter)
                    if ReceiverOptionsLocked() then return end
                    if enter == "RightButton" then
                        if BG.options[name .. "reset"] then
                            local value = BG.options[name .. "reset"]
                            BiaoGe.options[name] = value
                            f:SetValue(value)
                            f.edit:SetText(value)
                            UpdateReceiver()
                            BG.PlaySound(1)
                        end
                    end
                end)
            end
            -- UI层级
            do
                local name = "boardReceiverFrameStrata"
                BG.options[name .. "reset"] = "MEDIUM"

                local dropDown = LibBG:Create_UIDropDownMenu(nil, map)
                dropDown:SetPoint("TOPLEFT", 430, height - h)
                LibBG:UIDropDownMenu_SetWidth(dropDown, 120)
                LibBG:UIDropDownMenu_SetText(dropDown, BiaoGe.options[name])
                LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
                BG.dropDownToggle(dropDown)
                BG.options["button" .. name] = dropDown
                receiverDependentControls[#receiverDependentControls + 1] = dropDown

                local t = dropDown:CreateFontString()
                t:SetPoint("BOTTOM", dropDown, "TOP", 0, 8)
                t:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
                t:SetTextColor(1, 1, 1)
                t:SetText(L["UI层级"])

                LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level)
                    local info = LibBG:UIDropDownMenu_CreateInfo()
                    for _, text in ipairs({ "BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP", }) do
                        info.text = text
                        info.func = function()
                            if ReceiverOptionsLocked() then return end
                            BiaoGe.options[name] = text
                            LibBG:UIDropDownMenu_SetText(dropDown, BiaoGe.options[name])
                            UpdateReceiver()
                        end
                        info.checked = BiaoGe.options[name] == text
                        LibBG:UIDropDownMenu_AddButton(info)
                    end
                end)
            end

            for _, control in ipairs(receiverDependentControls) do
                SetParent(control, "boardReceiverEnabled")
            end

            -- 创建战斗中覆盖减伤链选项区域的红色鼠标拦截遮罩。
            local receiverCombatMask = CreateFrame("Frame", nil, map, "BackdropTemplate")
            receiverCombatMask:SetPoint("TOPLEFT", map, "TOPLEFT", 5, receiverMaskTop)
            receiverCombatMask:SetPoint("BOTTOMRIGHT", map, "TOPLEFT", frameWidth + 20, height - h - 50)
            receiverCombatMask:SetFrameLevel(map:GetFrameLevel() + 100)
            receiverCombatMask:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            receiverCombatMask:SetBackdropColor(1, 0, 0, .18)
            receiverCombatMask:SetBackdropBorderColor(1, 0, 0, .8)
            receiverCombatMask:EnableMouse(true)
            receiverCombatMask:EnableMouseWheel(true)
            receiverCombatMask:SetScript("OnMouseWheel", function() end)

            local combatText = receiverCombatMask:CreateFontString(nil, "OVERLAY")
            combatText:SetPoint("CENTER")
            combatText:SetFont(BIAOGE_TEXT_FONT, 18, "OUTLINE")
            combatText:SetTextColor(1, .1, .1)
            combatText:SetText(L["战斗中无法修改减伤链选项"])

            -- 根据战斗状态显示遮罩，并在进入战斗时关闭残留交互。
            local function UpdateReceiverCombatMask()
                BG.After(.1, function()
                    local locked = ReceiverOptionsLocked()
                    receiverCombatMask:SetShown(locked)
                    if locked then
                        LibBG:CloseDropDownMenus()
                        local focus = GetCurrentKeyBoardFocus()
                        for _, editBox in ipairs(receiverEditBoxes) do
                            if focus == editBox then
                                editBox:ClearFocus()
                                break
                            end
                        end
                        if BG.boardReceiverMoveOnly and BG.HideMove then
                            BG.HideMove()
                        end
                    end
                end)
            end
            BG.RegisterEvent({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED" }, UpdateReceiverCombatMask)
            map:HookScript("OnShow", UpdateReceiverCombatMask)
            UpdateReceiverCombatMask()
        end
    end

end)