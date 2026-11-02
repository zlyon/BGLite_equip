local AddonName, ns = ...

if type(BG) ~= "table" or type(BGE) ~= "table" then
    return
end

local LibBG = ns.LibBG
local L = ns.L
local RGB = ns.RGB
local AddTexture = ns.AddTexture
local Maxb = BG.Maxb

------------------支出模版------------------
local SetExpenditureTemplateBossName
do
    local templateFrame
    local MAX_SLOT = 20
    local DB_KEY = "expenditureTemplate"

    local function DeepCopy(tbl)
        local copy = {}
        for key, value in pairs(tbl) do
            copy[key] = type(value) == "table" and DeepCopy(value) or value
        end
        return copy
    end

    local function GetDB()
        if type(BGLite_equip) ~= "table" then
            BGLite_equip = {}
        end
        local db = BGLite_equip[DB_KEY]
        if type(db) ~= "table" then
            db = {}
            BGLite_equip[DB_KEY] = db
        end
        -- 首次接管：本插件还没有模板时，继承 BiaoGe 存档里的同名数据
        if not db.migrated then
            db.migrated = true
            local old = type(BiaoGe) == "table" and BiaoGe[DB_KEY]
            if type(old) == "table" and type(old.template) == "table" and #old.template > 0
                and type(db.template) ~= "table" then
                local ok, copy = pcall(DeepCopy, old.template)
                if ok and type(copy) == "table" then
                    db.template = copy
                    db.lastChoose = old.lastChoose
                end
            end
        end

        if type(db.template) ~= "table" then
            db.template = {}
        end
        if #db.template == 0 then
            db.template[1] = {
                name = L["模版1"],
                detail = {},
            }
        end
        for i, template in ipairs(db.template) do
            if type(template) ~= "table" then
                db.template[i] = {
                    name = L["模版"] .. i,
                    detail = {},
                }
            else
                template.name = type(template.name) == "string" and template.name ~= "" and template.name or L["模版"] .. i
                template.detail = type(template.detail) == "table" and template.detail or {}
            end
        end
        db.lastChoose = tonumber(db.lastChoose) or 1
        db.lastChoose = max(1, min(floor(db.lastChoose), #db.template))
        return db
    end

    local function UseExpenditureTemplate(FB, choose)
        local db = GetDB()
        local template = db.template[choose]
        if not template then
            return
        end
        local frames = FB and BG.Frame and BG.Frame[FB] and BG.Frame[FB]["boss" .. (Maxb[FB] + 1)]
        if not frames then
            return
        end

        for i = 1, MAX_SLOT do
            local name = frames["zhuangbei" .. i]
            if name then
                name:SetText(template.detail["name" .. i] or "")
                local money = frames["jine" .. i]
                money:SetText(template.detail["money" .. i] or "")
                money:SetCursorPosition(0)
            end
        end
        BG.PlaySound(2)
    end

    -- 保存表格里当前的支出到当前模版
    local function SaveExpenditureTemplate(FB, choose)
        local db = GetDB()
        local template = db.template[choose]
        local frames = FB and BG.Frame and BG.Frame[FB] and BG.Frame[FB]["boss" .. (Maxb[FB] + 1)]
        if not template or not frames then
            return
        end

        template.detail = {}
        for i = 1, MAX_SLOT do
            local name = frames["zhuangbei" .. i]
            if name then
                local nameText = name:GetText()
                local moneyText = frames["jine" .. i]:GetText()
                if nameText ~= "" then
                    template.detail["name" .. i] = nameText
                end
                if moneyText ~= "" then
                    template.detail["money" .. i] = moneyText
                end
            end
        end
        BG.PlaySound(2)
    end

    local function ParseExpenditureTemplates(text)
        if type(text) ~= "string" or not ns.IsBase64(text) then
            return
        end
        local ok, decoded = pcall(ns.Decode, text)
        if not ok or type(decoded) ~= "string" then
            return
        end

        local templates = {}
        decoded = decoded .. "^^"
        for templateName, detailStr in decoded:gmatch("([^@]+)@@([^%^]*)%^%^") do
            if templateName ~= "" then
                local template = {
                    name = templateName,
                    detail = {},
                }
                for i, name, money in detailStr:gmatch("(.-)¦(.-)¦(.-)&&") do
                    i = tonumber(i)
                    if i and i >= 1 and i <= MAX_SLOT and (name ~= "" or money ~= "") then
                        template.detail["name" .. i] = name ~= "" and name or nil
                        template.detail["money" .. i] = money ~= "" and money or nil
                    end
                end
                tinsert(templates, template)
            end
        end
        if #templates > 0 then
            return templates
        end
    end

    local function CreateExpenditureTemplateFrame(anchor)
        local db = GetDB()
        local parent = BG.FBMainFrame or BG.MainFrame or UIParent
        local mainFrame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        mainFrame:SetBackdrop({
            bgFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 1,
        })
        mainFrame:SetBackdropColor(0, 0, 0, 0.9)
        mainFrame:SetBackdropBorderColor(1, 1, 1, .8)
        mainFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, 0)
        mainFrame:SetFrameStrata("HIGH")
        mainFrame:SetClampedToScreen(true)
        mainFrame:SetFrameLevel(200)
        mainFrame:SetSize(560, 250)
        mainFrame:EnableMouse(true)
        mainFrame:SetMovable(true)
        mainFrame:Hide()
        mainFrame:SetScript("OnMouseUp", function(self)
            self:StopMovingOrSizing()
        end)
        mainFrame:SetScript("OnMouseDown", function(self)
            self:StartMoving()
        end)
        mainFrame.CloseButton = CreateFrame("Button", nil, mainFrame, "UIPanelCloseButton")
        mainFrame.CloseButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 2, 2)
        templateFrame = mainFrame
        BG.expenditureTemplateFrame = mainFrame

        local dropDown = LibBG:Create_UIDropDownMenu(nil, mainFrame)
        dropDown:SetPoint("TOPLEFT", 5, -5)
        LibBG:UIDropDownMenu_SetWidth(dropDown, 80)
        LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "TOP", dropDown, "BOTTOM")
        dropDown:SetScale(.95)
        mainFrame.dropDown = dropDown

        local function UpdateDropDownText()
            local pay = GetDB()
            LibBG:UIDropDownMenu_SetText(dropDown, pay.template[pay.lastChoose].name)
        end

        local function UpdatePayText()
            local pay = GetDB()
            local detail = pay.template[pay.lastChoose].detail
            for i = 1, MAX_SLOT do
                mainFrame.Buttons["name" .. i]:SetText(detail["name" .. i] or "")
                mainFrame.Buttons["money" .. i]:SetText(detail["money" .. i] or "")
            end
        end
        mainFrame.UpdatePayText = UpdatePayText

        LibBG:UIDropDownMenu_Initialize(dropDown, function()
            local pay = GetDB()
            for i, template in ipairs(pay.template) do
                local index = i
                local info = LibBG:UIDropDownMenu_CreateInfo()
                info.text = template.name
                info.checked = pay.lastChoose == index
                info.func = function()
                    pay.lastChoose = index
                    UpdateDropDownText()
                    UpdatePayText()
                end
                LibBG:UIDropDownMenu_AddButton(info)
            end
        end)

        local scroll = CreateFrame("ScrollFrame", nil, mainFrame, BG.scrollTemplate)
        scroll:SetWidth(mainFrame:GetWidth() - 35)
        scroll:SetHeight(mainFrame:GetHeight() - 60)
        scroll:SetPoint("TOPLEFT", 10, -55)
        BG.CreateSrollBarBackdrop(scroll.ScrollBar)
        BG.HookScrollBarShowOrHide(scroll)
        local child = CreateFrame("Frame", nil, scroll)
        child:SetSize(1, 1)
        scroll:SetScrollChild(child)

        mainFrame.Buttons = {}
        local function OnTextChanged(self)
            local pay = GetDB()
            local text = self:GetText()
            local newText = text:gsub("¦", ""):gsub("%^", "")
            if self.kind == "money" then
                newText = newText:gsub("&&", "")
            end
            if newText ~= text then
                self:SetText(newText)
                return
            end
            pay.template[pay.lastChoose].detail[self.key] = text ~= "" and text or nil
        end
        local function OnTabPressed(self)
            local nextKey
            if self.kind == "name" then
                nextKey = "money" .. self.index
            elseif mainFrame.Buttons["name" .. (self.index + 1)] then
                nextKey = "name" .. (self.index + 1)
            end
            if nextKey then
                mainFrame.Buttons[nextKey]:SetFocus()
            end
        end
        local function OnKeyDown(self, key)
            local target
            if key == "UP" then
                target = mainFrame.Buttons[self.kind .. (self.index - 1)]
            elseif key == "DOWN" then
                target = mainFrame.Buttons[self.kind .. (self.index + 1)]
            elseif key == "LEFT" or key == "RIGHT" then
                local kind = self.kind == "name" and "money" or "name"
                target = mainFrame.Buttons[kind .. self.index]
            end
            if target then
                target:SetFocus()
            end
        end
        local function OnMouseDown(self, button)
            if button == "RightButton" then
                self:SetEnabled(false)
                self:SetText("")
            end
        end
        local function OnMouseUp(self)
            self:SetEnabled(true)
        end

        for i = 1, MAX_SLOT do
            local name = CreateFrame("EditBox", nil, child, BG.editTemplate)
            name:SetSize(390, 20)
            name:SetAutoFocus(false)
            name:SetTextColor(0, 1, 0)
            name.kind = "name"
            name.index = i
            name.key = "name" .. i
            if i == 1 then
                name:SetPoint("TOPLEFT", 5, 0)
            else
                name:SetPoint("TOPLEFT", mainFrame.Buttons["name" .. (i - 1)], "BOTTOMLEFT")
            end
            mainFrame.Buttons[name.key] = name

            local money = CreateFrame("EditBox", nil, child, BG.editTemplate)
            money:SetSize(90, 20)
            money:SetAutoFocus(false)
            money:SetTextColor(0, 1, 0)
            money.kind = "money"
            money.index = i
            money.key = "money" .. i
            money:SetPoint("LEFT", name, "RIGHT", 5, 0)
            mainFrame.Buttons[money.key] = money

            for _, edit in ipairs({ name, money }) do
                edit:SetScript("OnTextChanged", OnTextChanged)
                edit:SetScript("OnEnterPressed", function(self)
                    self:ClearFocus()
                end)
                edit:SetScript("OnTabPressed", OnTabPressed)
                edit:SetScript("OnKeyDown", OnKeyDown)
                edit:SetScript("OnMouseDown", OnMouseDown)
                edit:SetScript("OnMouseUp", OnMouseUp)
            end
        end

        local title = scroll:CreateFontString()
        title:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        title:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 5, 2)
        title:SetTextColor(1, .82, 0)
        title:SetText(L["支出项"])
        local moneyTitle = scroll:CreateFontString()
        moneyTitle:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
        moneyTitle:SetPoint("BOTTOMLEFT", scroll, "TOPLEFT", 395, 2)
        moneyTitle:SetTextColor(1, .82, 0)
        moneyTitle:SetText(L["金额"])

        local function CreateTopButton(text, relative)
            local button = BG.CreateButton(mainFrame)
            button:SetSize(40, 25)
            button:SetPoint("LEFT", relative, "RIGHT", relative == dropDown and 3 or 1, 0)
            button:SetText(text)
            return button
        end

        mainFrame.newButton = CreateTopButton(L["新增"], dropDown)
        mainFrame.newButton:SetScript("OnClick", function()
            BG.PlaySound(1)
            local pay = GetDB()
            local count = #pay.template + 1
            tinsert(pay.template, {
                name = L["模版"] .. count,
                detail = {},
            })
            pay.lastChoose = count
            UpdateDropDownText()
            UpdatePayText()
            mainFrame.deleteButton:UpdateState()
        end)

        mainFrame.copyButton = CreateTopButton(L["复制"], mainFrame.newButton)
        mainFrame.copyButton:SetScript("OnClick", function()
            BG.PlaySound(2)
            local pay = GetDB()
            local source = pay.template[pay.lastChoose]
            local copy = {
                name = source.name .. L["复制"],
                detail = {},
            }
            for key, value in pairs(source.detail) do
                copy.detail[key] = value
            end
            tinsert(pay.template, copy)
            pay.lastChoose = #pay.template
            UpdateDropDownText()
            UpdatePayText()
            mainFrame.deleteButton:UpdateState()
        end)

        mainFrame.deleteButton = CreateTopButton(L["删除"], mainFrame.copyButton)
        mainFrame.deleteButton:SetScript("OnClick", function(self)
            local pay = GetDB()
            local choose = pay.lastChoose
            StaticPopupDialogs["BGLite_equip_ExpenditureTemplateDelete"] = {
                text = L["确认删除\"%s\"？"],
                button1 = L["是"],
                button2 = L["否"],
                OnAccept = function()
                    tremove(pay.template, choose)
                    pay.lastChoose = min(choose, #pay.template)
                    UpdateDropDownText()
                    UpdatePayText()
                    self:UpdateState()
                    LibBG:CloseDropDownMenus()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            StaticPopup_Show("BGLite_equip_ExpenditureTemplateDelete", pay.template[choose].name)
        end)
        function mainFrame.deleteButton:UpdateState()
            self:SetEnabled(#GetDB().template > 1)
        end

        mainFrame.changeButton = CreateTopButton(L["改名"], mainFrame.deleteButton)
        mainFrame.changeButton:SetScript("OnClick", function()
            local pay = GetDB()
            StaticPopupDialogs["BGLite_equip_ExpenditureTemplateRename"] = {
                text = L["正在更改\"%s\"的名字"],
                button1 = L["是"],
                button2 = L["否"],
                hasEditBox = true,
                editBoxWidth = 230,
                OnAccept = function(self)
                    local edit = self.EditBox or self.editBox
                    local text = edit:GetText():gsub("@", "")
                    if text ~= "" then
                        pay.template[pay.lastChoose].name = text
                        UpdateDropDownText()
                    end
                end,
                OnShow = function(self, name)
                    local edit = self.EditBox or self.editBox
                    edit:SetFocus()
                    edit:SetText(name)
                    edit:HighlightText()
                end,
                EditBoxOnEnterPressed = function(self)
                    self:GetParent():GetButton1():Click()
                end,
                EditBoxOnEscapePressed = function(self)
                    self:GetParent():Hide()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
            }
            local name = pay.template[pay.lastChoose].name
            StaticPopup_Show("BGLite_equip_ExpenditureTemplateRename", name, nil, name)
        end)

        mainFrame.useButton = CreateTopButton(L["使用"], mainFrame.changeButton)
        mainFrame.useButton:SetScript("OnClick", function()
            local FB = BG.FB1 or mainFrame.FB
            if FB then
                UseExpenditureTemplate(FB, GetDB().lastChoose)
            end
        end)

        mainFrame.saveButton = CreateTopButton(L["保存"], mainFrame.useButton)
        mainFrame.saveButton:SetScript("OnClick", function()
            local FB = BG.FB1 or mainFrame.FB
            if FB then
                SaveExpenditureTemplate(FB, GetDB().lastChoose)
                UpdatePayText()
            end
        end)

        local function ShowExportImportPopup(titleText, descText, initialText, isImport)
            if mainFrame.exportImportPopup then
                mainFrame.exportImportPopup:Hide()
            end
            local popup = CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
            mainFrame.exportImportPopup = popup
            popup:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            popup:SetBackdropColor(0, 0, 0, .9)
            popup:SetBackdropBorderColor(1, 1, 1, .8)
            popup:SetSize(310, mainFrame:GetHeight())
            popup:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", 1, 0)
            popup:EnableMouse(true)
            popup:SetFrameStrata("HIGH")
            popup:SetFrameLevel(mainFrame:GetFrameLevel() + 10)

            local titleTextFS = popup:CreateFontString()
            titleTextFS:SetPoint("TOP", 0, -10)
            titleTextFS:SetFont(BIAOGE_TEXT_FONT, 15, "OUTLINE")
            titleTextFS:SetTextColor(1, .82, 0)
            titleTextFS:SetText(titleText)
            local descTextFS = popup:CreateFontString()
            descTextFS:SetPoint("TOPLEFT", 10, -35)
            descTextFS:SetPoint("TOPRIGHT", -10, -35)
            descTextFS:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            descTextFS:SetJustifyH("LEFT")
            descTextFS:SetText(descText)

            local editBG = CreateFrame("Frame", nil, popup, "BackdropTemplate")
            editBG:SetBackdrop({
                bgFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeFile = "Interface/ChatFrame/ChatFrameBackground",
                edgeSize = 1,
            })
            editBG:SetBackdropColor(0, 0, 0, .5)
            editBG:SetBackdropBorderColor(1, 1, 1, .5)
            editBG:SetPoint("TOPLEFT", 10, -55)
            editBG:SetPoint("BOTTOMRIGHT", -10, 45)
            local editScroll = CreateFrame("ScrollFrame", nil, editBG, BG.scrollTemplate)
            editScroll:SetPoint("TOPLEFT", 3, -2)
            editScroll:SetPoint("BOTTOMRIGHT", -24, 2)
            BG.CreateSrollBarBackdrop(editScroll.ScrollBar)
            BG.HookScrollBarShowOrHide(editScroll)
            local edit = CreateFrame("EditBox", nil, editScroll)
            edit:SetMultiLine(true)
            edit:SetFont(BIAOGE_TEXT_FONT, 13, "OUTLINE")
            edit:SetWidth(editScroll:GetWidth())
            edit:SetText(initialText)
            edit:SetAutoFocus(false)
            BG.SetEditBaseClass(edit)
            editScroll:SetScrollChild(edit)
            popup:SetScript("OnMouseDown", function()
                edit:SetFocus()
            end)
            if not isImport then
                edit:SetScript("OnEditFocusGained", function(self)
                    self:HighlightText()
                end)
            end
            edit:SetFocus()

            if isImport then
                local clearCheck = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
                clearCheck:SetPoint("BOTTOMLEFT", 12, 40)
                clearCheck.text:SetText(L["导入时清空现有模板"])
                clearCheck.text:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
                clearCheck:SetChecked(GetDB().importClearExisting)
                clearCheck:SetFrameLevel(popup:GetFrameLevel() + 5)
                clearCheck:SetScript("OnClick", function(self)
                    GetDB().importClearExisting = self:GetChecked()
                end)

                local confirm = BG.CreateButton(popup)
                confirm:SetSize(80, 22)
                confirm:SetPoint("BOTTOM", -45, 12)
                confirm:SetText(L["确认导入"])
                confirm:SetScript("OnClick", function()
                    local templates = ParseExpenditureTemplates(edit:GetText())
                    if not templates then
                        BG.SendSystemMessage(L["未发现有效的模版数据或格式不正确。"])
                        return
                    end
                    local pay = GetDB()
                    if clearCheck:GetChecked() then
                        pay.template = templates
                    else
                        for _, template in ipairs(templates) do
                            tinsert(pay.template, template)
                        end
                    end
                    pay.lastChoose = #pay.template
                    UpdateDropDownText()
                    UpdatePayText()
                    mainFrame.deleteButton:UpdateState()
                    BG.SendSystemMessage(format(L["成功导入%d个模版。"], #templates))
                    BG.PlaySound(2)
                    popup:Hide()
                end)

                local cancel = BG.CreateButton(popup)
                cancel:SetSize(80, 22)
                cancel:SetPoint("LEFT", confirm, "RIGHT", 10, 0)
                cancel:SetText(CANCEL)
                cancel:SetScript("OnClick", function()
                    popup:Hide()
                end)
            else
                local close = BG.CreateButton(popup)
                close:SetSize(80, 22)
                close:SetPoint("BOTTOM", 0, 12)
                close:SetText(CLOSE)
                close:SetScript("OnClick", function()
                    popup:Hide()
                end)
            end
        end

        mainFrame.exportButton = CreateTopButton(L["导出"], mainFrame.saveButton)
        mainFrame.exportButton:SetScript("OnClick", function()
            BG.PlaySound(1)
            local data = {}
            for _, template in ipairs(GetDB().template) do
                local details = {}
                for i = 1, MAX_SLOT do
                    local name = template.detail["name" .. i]
                    local money = template.detail["money" .. i]
                    if name or money then
                        tinsert(details, format("%s¦%s¦%s&&", i, name or "", money or ""))
                    end
                end
                tinsert(data, format("%s@@%s", template.name, table.concat(details)))
            end
            if #data == 0 then
                BG.SendSystemMessage(L["模版为空，无数据可导出。"])
                return
            end
            ShowExportImportPopup(L["导出模版"], L["复制下方文本并保存"], ns.Encode(table.concat(data, "^^")), false)
        end)

        mainFrame.importButton = CreateTopButton(L["导入"], mainFrame.exportButton)
        mainFrame.importButton:SetScript("OnClick", function()
            BG.PlaySound(1)
            ShowExportImportPopup(L["导入模版"], L["粘贴之前导出的文本"], "", true)
        end)

        UpdateDropDownText()
        UpdatePayText()
        mainFrame.deleteButton:UpdateState()
        return mainFrame
    end

    local function OpenExpenditureTemplateFrame(anchor, FB)
        local mainFrame = templateFrame or CreateExpenditureTemplateFrame(anchor)
        mainFrame:ClearAllPoints()
        mainFrame:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -5, 0)
        mainFrame.FB = FB
        mainFrame.UpdatePayText()
        mainFrame:Show()
    end

    SetExpenditureTemplateBossName = function(FB, f)
        f:SetScript("OnMouseUp", function(self, button)
            if button == "RightButton" then
                local menu = {
                    {
                        text = L["支出模版"],
                        isTitle = true,
                        notCheckable = true,
                    },
                    {
                        text = L["管理模版"],
                        notCheckable = true,
                        func = function()
                            OpenExpenditureTemplateFrame(f, FB)
                        end,
                    },
                    {
                        text = L["保存当前支出到模版"],
                        notCheckable = true,
                        tooltipTitle = L["保存当前支出到模版"],
                        tooltipText = L["把表格里当前的支出项和金额，覆盖保存到上次选中的模版。"],
                        tooltipOnButton = true,
                        func = function()
                            SaveExpenditureTemplate(FB, GetDB().lastChoose)
                            BG.SendSystemMessage(L["已保存到模版："] .. GetDB().template[GetDB().lastChoose].name)
                        end,
                    },
                    {
                        text = "   ",
                        isTitle = true,
                        notCheckable = true,
                    },
                }
                local pay = GetDB()
                for i, template in ipairs(pay.template) do
                    local index = i
                    tinsert(menu, {
                        text = L["使用："] .. template.name,
                        notCheckable = true,
                        func = function()
                            UseExpenditureTemplate(FB, index)
                        end,
                    })
                end
                tinsert(menu, {
                    text = "   ",
                    isTitle = true,
                    notCheckable = true,
                })
                tinsert(menu, {
                    text = CANCEL,
                    notCheckable = true,
                    func = LibBG.CloseDropDownMenus,
                })
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
            GameTooltip:AddLine(L["支出"], 0, 1, 0)
            GameTooltip:AddLine(AddTexture("RIGHT") .. L["打开支出模版菜单"], 1, .82, 0)
            GameTooltip:Show()
            f.text:SetTextColor(1, 1, 1)
        end)
        f:SetScript("OnLeave", function()
            GameTooltip:Hide()
            f.text:SetTextColor(RGB(BG.Boss[FB]["boss" .. (Maxb[FB] + 1)].color))
        end)
    end
end

local function AttachExpenditureMenu(FB)
    local maxb = Maxb[FB]
    if not maxb then
        return
    end
    local tbl = BG.Frame[FB] and BG.Frame[FB]["boss" .. (maxb + 1)]
    local f = tbl and tbl.bossName
    if f and not f.BGEZhiChuMenu then
        f.BGEZhiChuMenu = true
        SetExpenditureTemplateBossName(FB, f)
        if ns.CreateRightClickHint then
            ns.CreateRightClickHint(f)
        end
    end
end

BGE.Init(function()
    if BG.FBMainFrame and BG.FBMainFrame.HookScript then
        -- 主窗重新打开时不连带弹出管理窗
        BG.FBMainFrame:HookScript("OnShow", function()
            if BG.expenditureTemplateFrame then
                BG.expenditureTemplateFrame:Hide()
            end
        end)
    end
    if type(BG.BossNameUI) == "function" then
        hooksecurefunc(BG, "BossNameUI", function(FB, t, b, bb, i, ii, frameName)
            if frameName == "Frame" then
                AttachExpenditureMenu(FB)
            end
        end)
    end
    if type(BG.FBtable) == "table" then
        for _, FB in pairs(BG.FBtable) do
            local ok, err = pcall(AttachExpenditureMenu, FB)
            if not ok then
                print("|cffff5555[BGLite_equip]|r 支出模版挂载失败（" .. tostring(FB) .. "）：" .. tostring(err))
            end
        end
    end
end)
