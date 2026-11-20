local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Maxb = ns.Maxb

local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local BossNum = ns.BossNum

local pt = print

function BG.NotifyChannelUI(lastbt)
    BGLite_equip.NotifyChannel = BGLite_equip.NotifyChannel or "RAID"
    if not _G[BGLite_equip.NotifyChannel] then
        BGLite_equip.NotifyChannel = "RAID"
    end

    local function AddButton(dropDown, channel)
        local info = LibBG:UIDropDownMenu_CreateInfo()
        info.text = _G[channel]
        info.func = function()
            BGLite_equip.NotifyChannel = channel
            LibBG:UIDropDownMenu_SetText(dropDown, _G[BGLite_equip.NotifyChannel])
        end
        if BGLite_equip.NotifyChannel == channel then
            info.checked = true
        end
        LibBG:UIDropDownMenu_AddButton(info)
    end

    local dropDown = LibBG:Create_UIDropDownMenu(nil, BG.ButtonZhangDan)
    dropDown:SetPoint("LEFT", lastbt, "RIGHT", 5, 0)
    LibBG:UIDropDownMenu_SetWidth(dropDown, 50)
    LibBG:UIDropDownMenu_SetAnchor(dropDown, 0, 0, "BOTTOM", dropDown, "TOP")
    LibBG:UIDropDownMenu_SetText(dropDown, _G[BGLite_equip.NotifyChannel])
    LibBG:UIDropDownMenu_Initialize(dropDown, function(self, level, menuList)
        local info = LibBG:UIDropDownMenu_CreateInfo()
        info.text = L["通报频道"]
        info.isTitle = true
        info.notCheckable = true
        LibBG:UIDropDownMenu_AddButton(info)
        AddButton(dropDown, "RAID")
        AddButton(dropDown, "GUILD")
        AddButton(dropDown, "SAY")
        AddButton(dropDown, "YELL")
    end)
end
