local AddonName, ns = ...

local L = ns.L
local RGB = ns.RGB

BGE.Init3(function()
    if not BG.OptionsCreateTab then return end
    if BG.FrameOptions_bgliteEquip then return end

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
    local tab = BG.OptionsCreateTab("Options_bgliteEquip", L["补充功能"])
    local height = -30
    local h = 0

    do
        local name = "guoqiRemind"
        BG.options[name .. "reset"] = 1
        BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
        local ontext = {
            L["装备过期提醒"],
            L["当装备剩余可交易时间低于一定时（默认是低于30分钟），会有语音+文字提醒。每次提醒的最低间隔是5分钟，避免提醒过于频繁。"],
            " ",
            L["该功能只有你是团长或物品分配者时起作用。"],
        }
        local f = O.CreateCheckButton(name, BG.STC_g1(L["装备过期提醒"]), tab, 15, height - h, ontext)
        BG.options["button" .. name] = f
        f:HookScript("OnClick", function()
            local name1 = "guoqiRemindMinTime"
            if f:GetChecked() then
                BG.options["button" .. name1]:Show()
            else
                BG.options["button" .. name1]:Hide()
            end
        end)
    end
    h = h + 30
    -- 剩余多少分钟时提醒
    do
        local name = "guoqiRemindMinTime"
        BG.options[name .. "reset"] = 30
        BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
        local ontext = {
            L["剩余时间低于多少时提醒"] .. L["|cff808080（右键还原设置）|r"],
            L["当装备剩余可交易时间低于该时间时，会提醒，默认是30分钟。"],
        }
        local f = O.CreateSlider(name, "|cffFFFFFF" .. L["剩余时间低于多少时提醒(分)"] .. "|r", tab, 1, 120, 1, 220, height - h - 25, ontext)
        BG.options["button" .. name] = f
        if BiaoGe.options["guoqiRemind"] ~= 1 then
            f:Hide()
        end
    end
    h = h + 80

    O.CreateLine(tab, height - h)
    h = h + 15

    do
        local name = "mouseHistoryMoney"
        BG.options[name .. "reset"] = 1
        BiaoGe.options[name] = BiaoGe.options[name] or BG.options[name .. "reset"]
        local ontext = {
            L["鼠标提示装备的历史价格区间"],
            L["鼠标悬浮在一个装备时，显示其历史价格区间，数据来自你的历史表格。"],
        }
        local f = O.CreateCheckButton(name, L["鼠标提示装备的历史价格区间"], tab, 15, height - h, ontext)
        BG.options["button" .. name] = f
    end
    h = h + 30

    do
        local name = "searchList"
        BG.options[name .. "reset"] = 1
        if not BiaoGe.options[name] then
            BiaoGe.options[name] = BG.options[name .. "reset"]
        end
        local ontext = {
            L["查询记录"],
            L["在查询名单列表中增加查询记录。"],
            " ",
            L["在查询名单列表中增加导出名单功能（可用于在官网进行批量举报）。"],
        }
        local f = O.CreateCheckButton(name, L["查询记录"], tab, 15, height - h, ontext, true)
        BG.options["button" .. name] = f
    end
    h = h + 30

    if BG.canShowAtlasLoot then
        local tbl = {
            {
                name = "AtlasLoot_betterChoose",
                name2 = L["更好的选择"],
                reset = 0,
                ontext = {
                    L["更好的选择"],
                    L["当你点击一个菜单选项时，"],
                    L["该插件的原本设定：下一级菜单中总是默认显示第一项。"],
                    L["现在优化为：下一级菜单中会显示更合适的项目。"],
                    " ",
                    L["比如："],
                    L["点击地下城和团队副本时，会自动显示25人奥杜尔；"],
                    L["点击专业制造时，会自动显示附魔；"],
                    L["点击专业制造-铭文时，会自动显示你对应的铭文；"],
                },
            },
            {
                name = "AtlasLoot_fastChoose",
                name2 = L["快捷按钮"],
                reset = 0,
                ontext = {
                    L["快捷按钮"],
                    L["在AtlasLoot主界面的右边，增加多个快捷按钮，点击后直接显示相应页面。"],
                    " ",
                    L["比如珠宝按钮，点击后直接显示珠宝页面。"],
                },
            },
        }
        for _, v in ipairs(tbl) do
            BG.options[v.name .. "reset"] = v.reset
            BiaoGe.options[v.name] = BiaoGe.options[v.name] or BG.options[v.name .. "reset"]
            local f = O.CreateCheckButton(v.name, v.name2, tab, 15, height - h, v.ontext)
            BG.options["button" .. v.name] = f
            if v.name == "AtlasLoot_fastChoose" then
                f:HookScript("OnClick", function()
                    if BG.AtlasLootUpdateFastButton then
                        BG.AtlasLootUpdateFastButton()
                    end
                end)
            end
            h = h + 30
        end
    end
    h = h + 30

    if BGE.EnsureOptionsVerText then
        BGE.EnsureOptionsVerText()
    end
end)
