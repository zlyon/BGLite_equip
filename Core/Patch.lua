local AddonName, ns = ...

if type(BG) ~= "table" or type(BGE) ~= "table" then
    return
end

local function Section(tag, func)
    local ok, err = pcall(func)
    if not ok then
        print("|cffff5555[BGLite_equip]|r 补丁段【" .. tag .. "】执行失败：" .. tostring(err))
    end
    return ok
end

Section("版本信息", function()
    local ver
    local ok, v = pcall(function()
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            return C_AddOns.GetAddOnMetadata(AddonName, "Version")
        end
        if GetAddOnMetadata then
            return GetAddOnMetadata(AddonName, "Version")
        end
    end)
    if ok and type(v) == "string" and v ~= "" then
        ver = v
    end
    BGE.Ver = ver and ("v" .. ver) or nil
end)
BGE.Ver = BGE.Ver or "v?"
BGE.Author = "zlyon"

Section("资源前缀", function()
    ns.Interface = "Interface\\AddOns\\" .. AddonName .. "\\"
end)

Section("C_Item 兜底", function()
    if not C_Item then return end
    GetItemInfo = GetItemInfo or C_Item.GetItemInfo
    GetItemInfoInstant = GetItemInfoInstant or C_Item.GetItemInfoInstant
    GetItemQualityColor = GetItemQualityColor or C_Item.GetItemQualityColor
    GetItemCount = GetItemCount or C_Item.GetItemCount
    GetItemSetInfo = GetItemSetInfo or C_Item.GetItemSetInfo
end)

local function EquipLocName(raw)
    if not raw then return nil end
    local f = BG.GetEquipLocName
    if type(f) == "function" then
        local ok, name = pcall(f, raw)
        if ok and name then return name end
    end
    return raw
end

local function CheckItemEquipLoc(link)
    if not link then return nil end

    local itemID, _, _, itemEquipLoc = GetItemInfoInstant(link)

    local phase = BG.phaseFBtable and BG.FB1 and BG.phaseFBtable[BG.FB1]
    if itemID and phase then
        for _, FB in pairs(phase) do
            local loot = BG.Loot and BG.Loot[FB]
            local ex = loot and loot.ExchangeItems
            local firstItem = ex and ex[itemID] and ex[itemID][1]
            if firstItem then
                local loc = select(4, GetItemInfoInstant(firstItem))
                if loc then
                    return EquipLocName(loc)
                end
            end
        end
    end

    return EquipLocName(itemEquipLoc)
end

local function GoToItemLibImpl(button)
    if not button or not button.GetText then return end
    local link = button:GetText()
    if not link then return end

    local inv = CheckItemEquipLoc(link)
    if inv then
        for _, bt in ipairs(BG.itemLib_Inv_Buttons or {}) do
            if bt.inv == inv then
                if BG.ItemLibMainFrame and BG.ItemLibMainFrame.first then
                    BG.InvOnClick(bt)
                    BG.ClickTabButton(BG.ItemLibMainFrameTabNum)
                else
                    BG.ClickTabButton(BG.ItemLibMainFrameTabNum)
                    BG.InvOnClick(bt)
                end
                return
            end
        end
    else
        local L = ns.L
        if UIErrorsFrame and L and L["这个物品不是装备"] then
            UIErrorsFrame:AddMessage(L["这个物品不是装备"], RED_FONT_COLOR:GetRGB())
        end
    end
end

local function RestoreItemLibVisibility()
    local f = BG.ItemLibMainFrame
    if f and type(BG.ItemLibUI) == "function" then
        f.IsVisible = nil
        f.IsShown = nil
    end
end

local function EnsureVerText()
    if BGE.VerText and BGE.VerText:GetParent() == BG.MainFrame then
        return true
    end
    if not (BG.MainFrame and BG.VerText) then
        return false
    end

    local ok = Section("顶部版本号", function()
        local t = BG.MainFrame:CreateFontString()
        t:SetPoint("BOTTOMLEFT", BG.VerText, "BOTTOMRIGHT", 8, 0)
        if BIAOGE_TEXT_FONT then
            t:SetFont(BIAOGE_TEXT_FONT, 12, "OUTLINE")
        else
            t:SetFontObject(GameFontNormal)
        end
        if ns.RGB then
            t:SetTextColor(ns.RGB("FFD700"))
        else
            t:SetTextColor(1, 0.82, 0)
        end
        t:SetText("|cffFFD700" .. (ns.equipTitle or "BGLite_equip补充包") .. "|r " .. tostring(BGE.Ver))

        BG.VerText:HookScript("OnShow", function() t:Show() end)
        BG.VerText:HookScript("OnHide", function() t:Hide() end)
        if not BG.VerText:IsShown() then
            t:Hide()
        end

        BGE.VerText = t
    end)

    return ok and BGE.VerText ~= nil
end

local function AppendEquipInstructions()
    local texts = ns.equipInstructionsText
    if type(texts) ~= "table" then return end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffFFD700< " .. (ns.equipTitle or "BGLite_equip补充包")
        .. " " .. tostring(BGE.Ver) .. " >|r", 1, 1, 1, true)
    for _, text in ipairs(texts) do
        GameTooltip:AddLine(text, 1, 1, 1, true)
    end
    GameTooltip:Show()
end

local function EnsureShuoMingShuHook()
    local f = BG.ShuoMingShu
    if not f or type(ns.equipInstructionsText) ~= "table" then
        return false
    end

    local old = f.GetScript and f:GetScript("OnEnter")
    if old == BGE.__ShuoMingShuOnEnter then
        return true
    end

    local wrapper = function(self, ...)
        if old then
            pcall(old, self, ...)
        end
        local ok, err = pcall(AppendEquipInstructions)
        if not ok then
            print("|cffff5555[BGLite_equip]|r 说明书追加失败：" .. tostring(err))
        end
    end

    local ok = Section("说明书钩子", function()
        f:SetScript("OnEnter", wrapper)
    end)
    if ok then
        BGE.__ShuoMingShuOnEnter = wrapper
    end
    return ok
end

local function FindOptionsTitle()
    local title

    local function scan(f)
        if not (f and f.GetNumRegions) then return false end
        for i = 1, f:GetNumRegions() do
            local r = select(i, f:GetRegions())
            if r and r.GetText and BG.optionsName then
                local text = r:GetText()
                if type(text) == "string" and text:find(BG.optionsName, 1, true) then
                    title = r
                    return true
                end
            end
        end
        return false
    end

    local frame = BG.optionsBackground and BG.optionsBackground.GetParent and BG.optionsBackground:GetParent()
    if scan(frame) then
        return frame, title
    end

    local bt = BG.ButtonOptions_bgliteEquip
    frame = bt and bt.GetParent and bt:GetParent()
    if scan(frame) then
        return frame, title
    end

    return nil, nil
end

local function EnsureOptionsVerText()
    if BGE.OptionsVerText and BGE.OptionsVerText.GetParent and BGE.OptionsVerText:GetParent() then
        return true
    end

    local main, title = FindOptionsTitle()
    if not (main and title) then
        return false
    end

    local ok = Section("设置页版本号", function()
        local t = main:CreateFontString()
        t:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
        if BIAOGE_TEXT_FONT then
            t:SetFont(BIAOGE_TEXT_FONT, 11, "OUTLINE")
        else
            t:SetFontObject(GameFontNormalSmall)
        end
        if ns.RGB then
            t:SetTextColor(ns.RGB("FFD700"))
        else
            t:SetTextColor(1, 0.82, 0)
        end
        t:SetText("|cffFFD700" .. (ns.equipTitle or "BGLite_equip补充包") .. "|r " .. tostring(BGE.Ver)
            .. "  |cff808080" .. (ns.equipAuthor or ("作者：" .. tostring(BGE.Author))) .. "|r")

        BGE.OptionsVerText = t
    end)

    return ok and BGE.OptionsVerText ~= nil
end
BGE.EnsureOptionsVerText = EnsureOptionsVerText

local function EnsurePatches()
    EnsureVerText()
    EnsureShuoMingShuHook()
    EnsureOptionsVerText()
end

function BGE.PatchStatus()
    local missing = {}
    if not BG then missing[#missing + 1] = "BG" end
    if not BG or not BG.MainFrame then missing[#missing + 1] = "BG.MainFrame" end
    if not BG or not BG.VerText then missing[#missing + 1] = "BG.VerText" end
    if not BG or not BG.ShuoMingShu then missing[#missing + 1] = "BG.ShuoMingShu" end
    if type(ns.equipInstructionsText) ~= "table" then missing[#missing + 1] = "ns.equipInstructionsText" end
    return table.concat({
        "MyVer=" .. tostring(BGE.Ver),
        "BGLiteVer=" .. tostring(BG and BG.ver),
        "MyVerText=" .. tostring(BGE.VerText ~= nil),
        "OptionsVerText=" .. tostring(BGE.OptionsVerText ~= nil),
        "ShuoMingShuHook=" .. tostring(BGE.__ShuoMingShuOnEnter ~= nil),
        "GoToItemLib=" .. tostring(BG and BG.GoToItemLib ~= nil),
        "ItemLibButtons=" .. tostring(BG and type(BG.itemLib_Inv_Buttons)),
        "缺少锚点=" .. (#missing > 0 and table.concat(missing, ",") or "无"),
    }, " | ")
end

Section("补丁下发", function()
    BGE.Init(function()
        Section("GoToItemLib 补丁", function()
            BG.GoToItemLib = GoToItemLibImpl
        end)
        Section("装备库可见性还原", RestoreItemLibVisibility)
        Section("海山黑庙槽位", function()
            local eid = BG.Loot and BG.Loot.encounterID
            if not (eid and eid.HS and eid.BT) then return end
            if BG.Maxb and BG.Maxb.HS then return end
            local merged = {}
            for _, v in ipairs(eid.HS) do
                tinsert(merged, v)
            end
            for _, v in ipairs(eid.BT) do
                tinsert(merged, v)
            end
            eid.BT = merged
            eid.HS = nil
        end)
        Section("正式服金币超上限阈值", function()
            if not BG.IsRetail then return end
            local top = BG.tradeGoldTop
            if not (top and top.topNum) then return end
            local oldNum = tostring(top.topNum)
            top.topNum = 9999999
            local bt = BG.options and BG.options["buttontradePreview"]
            local ontext = bt and bt.ontext
            if type(ontext) == "table" then
                for i = 1, #ontext do
                    if type(ontext[i]) == "string" then
                        ontext[i] = ontext[i]:gsub(oldNum, "9999999")
                    end
                end
            end
        end)
    end)

    BGE.Init2(function()
        Section("奥杜尔符文宝珠一键分配", function()
            if not BG.IsWLK then return end
            local al = BG.autoLoot and BG.autoLoot.info
            if not al then return end
            al[603] = { gem = { itemIDs = { 45087 }, isGem = true, title = ns.L["|cffffff00符文宝珠"] } }
        end)
    end)

    BGE.Init(EnsurePatches)
    BGE.Init2(EnsurePatches)
    BGE.Init3(function()
        EnsurePatches()

        if BG.MainFrame and not BGE.__OnShowHooked then
            BGE.__OnShowHooked = true
            pcall(function() BG.MainFrame:HookScript("OnShow", EnsurePatches) end)
        end

        if not BGE.PatchWarned then
            BGE.PatchWarned = true
            local ok1 = BGE.VerText ~= nil
            local ok2 = BGE.__ShuoMingShuOnEnter ~= nil
            if not (ok1 and ok2) then
                print("|cffff5555[BGLite_equip]|r 补丁层未完全挂载：" .. BGE.PatchStatus())
            end
        end
    end)
end)
