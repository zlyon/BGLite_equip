local AddonName, ns = ...

local L = ns.L
local pt = print

BGE.Init3(function()
    if not BGLite_equip or not BGLite_equip.options then return end

    local defaults = {
        roleOverviewScale                 = 1,
        roleOverviewAlpha                 = 0.9,
        roleOverviewSort1                 = "iLevel-class-player",
        roleOverviewDefaultShow           = "one",
        roleOverviewLayout                = BG.IsRetail and "new" or "up_down",
        roleOverviewNotShowLevel          = 0,
        roleOverviewNotShowiLevel         = 0,
        showRaidCDKillNum                 = BG.IsRetail and 1 or 0,
        roleOverviewShowNote_width        = 100,
        roleOverviewShowNote_useClassColor = 1,
    }
    for name, value in pairs(defaults) do
        if BGLite_equip.options[name] == nil then
            BGLite_equip.options[name] = value
        end
    end
end)

BGE.Init(function()
    if not BG.RoleOverviewUI then return end
    local ok, err = pcall(BG.RoleOverviewUI)
    if not ok then
        print("|cffff5555[BGLite_equip] 角色总览初始化失败:|r " .. tostring(err))
    end
end)

BGE.Init(function()
    SlashCmdList["BiaoGeRoleOverview"] = function()
        if BGE.SetFBCD then
            BGE.SetFBCD(nil, nil, true)
        end
    end
    _G["SLASH_" .. "BiaoGeRoleOverview" .. "1"] = "/bgr"
end)

BGE.Init3(function()
    local ok, ldb = pcall(LibStub.GetLibrary, LibStub, "LibDataBroker-1.1", true)
    if not ok or not ldb or not ldb.GetDataObjectByName then return end

    local ok2, plugin = pcall(ldb.GetDataObjectByName, ldb, "BGLite")
    if not ok2 or not plugin then return end
    if plugin.__bgeRoleOverviewHooked then return end
    plugin.__bgeRoleOverviewHooked = true

    local origOnClick = plugin.OnClick
    local origOnEnter = plugin.OnEnter
    local origOnLeave = plugin.OnLeave

    function plugin:OnClick(button)
        if BGE.SetFBCD and (button == "MiddleButton" or (button == "LeftButton" and IsControlKeyDown())) then
            BGE.SetFBCD(nil, nil, true)
            if BG.PlaySound then BG.PlaySound(1) end
            return
        end
        if origOnClick then
            return origOnClick(self, button)
        end
    end

    function plugin:OnEnter(button)
        if origOnEnter then
            pcall(origOnEnter, self, button)
        end
        if BGE.SetFBCD then
            local ok3, err = pcall(BGE.SetFBCD, self, "minimap")
            if not ok3 then
                print("|cffff5555[BGLite_equip] 角色总览预览失败:|r " .. tostring(err))
            end
        end
    end

    function plugin:OnLeave(button)
        if origOnLeave then
            pcall(origOnLeave, self, button)
        end
        pcall(function()
            if BG.FBCDFrame and not BG.FBCDFrame.click then
                BG.FBCDFrame:Hide()
            end
            GameTooltip:Hide()
        end)
    end
end)

BGE.Init(function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
    f:SetScript("OnEvent", function()
        if not BG.hasHoliday or not BG.InitHoliday then return end
        local ok, err = pcall(BG.InitHoliday)
        if not ok then
            print("|cffff5555[BGLite_equip] 节日总览初始化失败:|r " .. tostring(err))
        end
    end)
end)
