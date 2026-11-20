if BG.IsBlackListPlayer then return end
local AddonName, ns = ...
local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN

local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

local pt = print

local plugin = ldb:NewDataObject(AddonName, { text = AddonName, type = "data source", icon = ns.Interface .. "Media\\icon\\icon" })

function plugin:OnClick(button) --function plugin.OnClick(self, button)
    if button == "LeftButton" then
        -- 左键：打开拍卖表格
        BG.MainFrame:SetShown(not BG.MainFrame:IsVisible())
    elseif button == "RightButton" then
        -- 右键：打开设置
        if SettingsPanel:IsVisible() then
            HideUIPanel(SettingsPanel)
        else
            if ZL and ZL.OpenOption then
                ZL.OpenOption()
            else
                BG.OpenOption()
            end
            BG.MainFrame:Hide()
        end
    end
    BG.PlaySound(1)
end

function plugin:OnEnter(button)
    -- 悬停：直接显示角色总览
    if ZL and ZL.SetFBCD then
        ZL.SetFBCD(self, "minimap")
    else
        if BG.ButtonIsInRight(self) then
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
        else
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        end
        GameTooltip:ClearLines()
        GameTooltip:AddLine(L["%s"]:format(AddonName), 0, .75, 1, true)
        GameTooltip:AddLine(L["|cffFFFFFF左键：|r打开表格"], 1, 0.82, 0, true)
        GameTooltip:AddLine(L["|cffFFFFFF右键：|r打开设置"], 1, 0.82, 0, true)
        GameTooltip:Show()
    end
end

function plugin:OnLeave(button)
    if ZL and ZL.FBCDFrame and not ZL.FBCDFrame.click then
        ZL.FBCDFrame:Hide()
    end
    if BG.FBCDFrame and not BG.FBCDFrame.click then
        BG.FBCDFrame:Hide()
    end
    GameTooltip:Hide()
end

BG.Init(function()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon then return end

    BGLite_equip.minimapPos = BGLite_equip.minimapPos or 200
    icon:Register(AddonName, plugin, BGLite_equip)

    C_Timer.After(1, function()
        if BGLite_equip.options["miniMap"] == 0 then
            icon:Hide(AddonName)
        end
    end)
end)