local AddonName, nsAll = ...
local ns = nsAll.ZL
if not ns then
    ns = {}
    nsAll.ZL = ns
    setmetatable(ns, {
        __index = function(_, k)
            if k == "Menu" or k == "Maxb" or k == "HopeMaxi" or k == "HopeMaxb" or k == "HopeMaxn" then
                return nsAll[k]
            end
        end,
    })
end
if ZL.IsBlackListPlayer then return end

local L = ns.L

-- 小地图按钮统一由主插件提供（见 Core/Module/minimap.lua），
-- 这里只负责“悬浮框”（可拖动的常驻小图标，默认隐藏）。
local ICON_PATH = ns.Interface .. "Media\\icon\\icon.png"

local function ToggleRoleOverview()
    ZL.SetFBCD(nil, nil, true)
end

local function OpenOptions()
    ZL.OpenOption()
end

local function CreateMainIcon()
    local frameName = "ZLMainIcon"
    local frame = CreateFrame("Button", frameName, UIParent, "BackdropTemplate")
    frame:SetBackdrop({
        bgFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeFile = "Interface/ChatFrame/ChatFrameBackground",
        edgeSize = 1,
    })
    frame:SetBackdropColor(0, 0, 0, 0)
    frame:SetBackdropBorderColor(0, 0, 0, 0)
    frame:SetSize(100, 22)
    frame:SetFrameStrata(ZLDb.options.mainIconFrameLevel)
    frame:SetScale(ZLDb.options.mainIconScale)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    frame:RegisterForDrag("LeftButton")

    ZLDb.point = ZLDb.point or {}
    local point = ZLDb.point[frameName]
    if point then
        frame:SetPoint(point[1], UIParent, point[2], point[3], point[4])
    else
        frame:SetPoint("TOP", UIParent, "TOP", 0, 0)
    end
    frame:SetShown(ZLDb.options.mainIcon == 1)
    ZL.MainIcon = frame

    frame:SetScript("OnDragStart", function(self)
        self.moved = true
        self:StartMoving()
        if ZL.FBCDFrame and not ZL.FBCDFrame.click then
            ZL.FBCDFrame:Hide()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local anchor, _, relativeAnchor, x, y = self:GetPoint(1)
        ZLDb.point[frameName] = { anchor, relativeAnchor, x, y }
        C_Timer.After(0, function()
            self.moved = nil
        end)
    end)
    frame:SetScript("OnClick", function(self, button)
        if self.moved then return end
        if button == "LeftButton" then
            ToggleRoleOverview()
        elseif button == "RightButton" then
            OpenOptions()
        else
            return
        end
        ZL.PlaySound(1)
    end)
    frame:SetScript("OnEnter", function(self)
        if not self.moved then
            ZL.SetFBCD(self, "minimap")
        end
    end)
    frame:SetScript("OnLeave", function()
        if ZL.FBCDFrame and not ZL.FBCDFrame.click then
            ZL.FBCDFrame:Hide()
        end
    end)

    local texture = frame:CreateTexture()
    texture:SetSize(20, 20)
    texture:SetPoint("LEFT")
    texture:SetTexture(ICON_PATH)

    local text = frame:CreateFontString()
    text:SetFont(ns.Font, 15, "OUTLINE")
    text:SetPoint("LEFT", texture, "RIGHT", 0, -1)
    text:SetTextColor(1, 0.82, 0)
    text:SetText(L["角色总览"] or "角色总览")
    frame:SetWidth(texture:GetWidth() + text:GetStringWidth())
end

ZL.Init(function()
    ZLDb.options.mainIcon = ZLDb.options.mainIcon or 0
    ZLDb.options.mainIconScale = tonumber(ZLDb.options.mainIconScale) or 1
    ZLDb.options.mainIconFrameLevel = ZLDb.options.mainIconFrameLevel or "HIGH"
    CreateMainIcon()
end)
