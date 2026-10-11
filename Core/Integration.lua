local AddonName, ns = ...

local IsAddOnLoaded = IsAddOnLoaded or C_AddOns.IsAddOnLoaded

local function IsLoadBiaoGe()
    return IsAddOnLoaded("BiaoGe") or IsAddOnLoaded("BiaoGeX") or IsAddOnLoaded(AddonName)
end

local function HookTuanJian()
    if type(TJ) == "table" and type(TJ.IsLoadBiaoGe) == "function" then
        TJ.IsLoadBiaoGe = IsLoadBiaoGe
    end
    local t = _G.TuanJian
    if type(t) == "table" and t.LibBG ~= nil and t.BiaoGeName ~= nil then
        t.BiaoGeName = ns.equipTitle or "BGLite_equip补充包"
    end
end

do
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(self, _, name)
        if name == "TuanJian" then
            HookTuanJian()
        end
    end)
end

BGE.Init3(HookTuanJian)

BGE.Init(function()
    if not BG.MainFrame then return end

    do
        if BG.HopeUI then
            for k, FB in pairs(BG.FBtable) do
                local ok, err = pcall(BG.HopeUI, FB)
                if not ok then
                    print("|cffff5555[BGLite_equip] HopeUI(" .. tostring(FB) .. ") 错误:|r " .. tostring(err))
                end
            end
        end
        if BG.CreateBossModel then
            pcall(BG.CreateBossModel)
        end
        if not BG.IsRetail and BG.HopeDaoChuUI then
            pcall(BG.HopeDaoChuUI)
        end
        if BG.HistoryUI then
            pcall(BG.HistoryUI)
        end
        if BG.FilterClassItemUI then
            pcall(BG.FilterClassItemUI)
        end
        if BG.ItemLibUI then
            pcall(BG.ItemLibUI)
        end
    end
end)
