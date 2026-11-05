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
        -- BGLite 构建主界面时已经调用过 BG.CreateBossModel，这里只在完全缺失时补建。
        -- 无条件再建一次会生成第二套全新的模型：新建的 PlayerModel 默认是显示的，
        -- 而选项页里的隐藏只对当时已存在的那套生效，于是重载后“显示BOSS模型”明明没勾，
        -- 模型照样出现（那是后建的重复模型）。同时两套模型重叠，渲染开销也翻倍。
        if BG.CreateBossModel and (not BG.bossModels or #BG.bossModels == 0) then
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

    -- 副本标签切换：BGLite 精简版的 BG.ClickFBbutton 只切了「表格」和「对账」两页，
    -- 心愿清单那一支被砍掉了（BiaoGeX 原版 Core/BiaoGe.lua 里是
    -- `elseif BG.HopeMainFrame:IsVisible() then ... HopeFrame:Show()`）。
    -- 后果：在心愿清单页点副本标签，BG.FB1 变了、心愿数据也刷新了，但显示的还是
    -- 上一个副本的格子，必须关窗重开（OnShow 里才用新的 BG.FB1 去 Show）才切换。
    -- BGLite 是纯净版不能改，这里用 hooksecurefunc 把缺的一支补上。
    if BG.HopeMainFrame and BG.ClickFBbutton and not BG.equipHopeSwitchHooked then
        BG.equipHopeSwitchHooked = true
        hooksecurefunc(BG, "ClickFBbutton", function(FB)
            if type(FB) ~= "string" then return end
            if not (BG.HopeMainFrame and BG.HopeMainFrame:IsVisible()) then return end
            local target = BG["HopeFrame" .. FB]
            if not target then return end
            for _, _FB in ipairs(BG.FBtable) do
                local f = BG["HopeFrame" .. _FB]
                if f and f ~= target then
                    f:Hide()
                end
            end
            -- 目标页已经是显示状态就别再 Show，免得白白重跑一次 OnShow 里的整理
            if not target:IsShown() then
                target:Show()
            end
        end)
    end

    -- 兜底：按存档里的“显示BOSS模型”再同步一次。BGLite 的隐藏只发生在选项页构建那一刻，
    -- 之后任何新建的模型都不会自动遵守这个开关，这里统一收口，避免再出现“没勾却显示”。
    if BG.bossModels then
        local show = BiaoGe and BiaoGe.options and BiaoGe.options.model == 1
        for _, model in ipairs(BG.bossModels) do
            if show then
                model:Show()
            else
                model:Hide()
            end
        end
    end
end)
