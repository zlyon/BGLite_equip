local AddonName, ns = ...

if not BG then
    return
end

------------------------------------------------------------------------
-- 与团长助手 BGLite_leader 的版本互通
--
-- 团长助手要显示「团员的 BGLite_equip 版本」，但 BGLite 广播的版本是它自己的，
-- 和本补充包无关。所以由本插件在专用频道 BGLLeaderEquip 里报自己的版本：
--   团长助手 -> 发 "VersionCheck"
--   本插件   -> 回 "MyVer-v1.0.47"
-- 进组/进本时也主动广播一次，免得团长不查询时列表里全是「未知」。
------------------------------------------------------------------------
local EQUIP_PREFIX = "BGLLeaderEquip"
C_ChatInfo.RegisterAddonMessagePrefix(EQUIP_PREFIX)

local GetAddOnMeta = GetAddOnMetadata or (C_AddOns and C_AddOns.GetAddOnMetadata)
local myVer = "v" .. (GetAddOnMeta and GetAddOnMeta(AddonName, "Version") or "0")

local lastReply = 0
local function SendMyVer(force)
    if not IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return
    end
    -- 团长可能反复查询，同一时间只回一次，避免 40 人同时刷频道
    local now = GetTime()
    if not force and now - lastReply < 3 then
        return
    end
    lastReply = now
    C_ChatInfo.SendAddonMessage(EQUIP_PREFIX, "MyVer-" .. myVer, "RAID")
end

BG.RegisterEvent("CHAT_MSG_ADDON", function(_, _, prefix, message, distribution)
    if prefix ~= EQUIP_PREFIX or distribution ~= "RAID" then
        return
    end
    if message == "VersionCheck" then
        SendMyVer()
    end
end)

BGE.Init3(function()
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:SetScript("OnEvent", function()
        BG.After(1, function() SendMyVer(true) end)
    end)
    SendMyVer(true)
end)
