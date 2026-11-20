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

local L = ns.L
ns.GetClassColor = GetClassColor
local GetClassColor = ns.GetClassColor
if not GetItemInfo then
    GetItemInfo = C_Item.GetItemInfo
end
if not GetItemInfoInstant then
    GetItemInfoInstant = C_Item.GetItemInfoInstant
end
if not GetItemQualityColor then
    GetItemQualityColor = C_Item.GetItemQualityColor
end
if not GetItemCount then
    GetItemCount = C_Item.GetItemCount
end
if not GetItemSetInfo then
    GetItemSetInfo = C_Item.GetItemSetInfo
end

local pt = print

local RR = "|r"
ns.RR = RR
local NN = "\n"
ns.NN = NN
local RN = "|r\n"
ns.RN = RN

ZL = {}

-- 存档挂在主插件的 BGLite_equip 表下的 ZL 子表
BGLite_equip = type(BGLite_equip) == "table" and BGLite_equip or {}
BGLite_equip.ZL = type(BGLite_equip.ZL) == "table" and BGLite_equip.ZL or {}
ZLDb = BGLite_equip.ZL

----------tbl元素个数----------
local function Size(t)
    local s = 0
    for k, v in pairs(t) do
        if v ~= nil then s = s + 1 end
    end
    return s
end
ns.Size = Size

----------把16进制颜色转换成0-1RGB----------
local function RGB(hex, Alpha)
    local red = hex:sub(1, 2)
    local green = hex:sub(3, 4)
    local blue = hex:sub(5, 6)

    red = tonumber(red, 16) / 255
    green = tonumber(green, 16) / 255
    blue = tonumber(blue, 16) / 255

    if Alpha then
        return red, green, blue, Alpha
    else
        return red, green, blue
    end
end
ns.RGB = RGB

----------DB_Loot插入职业任务文本----------
local function ClassQuest(classID)
    local className, classFile, classID = GetClassInfo(classID)
    local color = select(4, GetClassColor(classFile))
    return "|c" .. color .. className .. "|r" .. ZL.STC_y1(QUESTS_LABEL)
end
ns.ClassQuest = ClassQuest


-- 注册事件
do
    local loginFuncs = {}
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self, event)
        self:UnregisterEvent("PLAYER_LOGIN")
        for _, func in ipairs(loginFuncs) do
            securecall(func)
        end
    end)
    function ZL.Init(func)
        tinsert(loginFuncs, func)
    end

    local enterWorldFuncs = {}
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(self, event, ...)
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        for _, func in ipairs(enterWorldFuncs) do
            securecall(func)
        end
    end)
    function ZL.Init2(func)
        tinsert(enterWorldFuncs, func)
    end

    local events = {}
    local f = CreateFrame("Frame")
    f:SetScript("OnEvent", function(_, event, ...)
        for _, func in ipairs(events[event]) do
            if event == "COMBAT_LOG_EVENT_UNFILTERED" then
                securecall(func, f, event, CombatLogGetCurrentEventInfo())
            else
                securecall(func, f, event, ...)
            end
        end
    end)
    local function RegisterOneEvent(event, func)
        if not events[event] then
            events[event] = {}
            f:RegisterEvent(event)
        end
        tinsert(events[event], func)
    end
    function ZL.RegisterEvent(event, func)
        if type(event) == "table" then
            for _, e in ipairs(event) do
                RegisterOneEvent(e, func)
            end
        else
            RegisterOneEvent(event, func)
        end
    end
end

-- 无限服环境（1.60.x）：其余版本分支已移除
do
    if GetCurrentRegion() ~= 5 then
        ZL.IsTW = true
    end
    ZL.onlyOneHard = true
    ZL.IsForever = true
    ZL.IsNewUI = true
end

function ZL.IsWLKFB()
    return false
end

function ZL.IsTBCFB()
    return false
end

-- 阵营
if UnitFactionGroup("player") == "Alliance" then
    ZL.IsAlliance = true
end

if UnitFactionGroup("player") == "Horde" then
    ZL.IsHorde = true
end

function ZL.GN(unit)
    unit = unit or "player"
    if unit == "t" then
        unit = "target"
    end
    return GetUnitName(unit, true)
end

ZL.Init(function ()
    ZL.myName = ZL.GN()
end)
ZL.realmName = GetRealmName():gsub(" ", ""):gsub("%-", "")
ZL.realmID = GetRealmID()

function ZL.GFN(name)
    if not name then return end
    local name, realm = strsplit("-", name)
    realm = realm or ZL.realmName
    return name .. "-" .. realm
end

function ZL.GSN(name)
    if not name then return end
    local name, realm = strsplit("-", name)
    if not realm or realm == "" or realm == ZL.realmName then
        return name
    else
        return name .. "-" .. realm
    end
end

function ZL.SPN(name)
    if not name then return end
    if ZL.IsSecret(name) then return end
    return strsplit("-", name, 2)
end

-- 增加节日掉落
function ZL.AddHolidayLoot(lootInfo)
    ZL.hasHolidayLoot = true
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")
    f:SetScript("OnEvent", function(self, event, isLogin, isReload)
        if event == "PLAYER_ENTERING_WORLD" then
            if isLogin then
                return
            else
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            end
        end

        local all = {}

        local currentCalendarTime = C_DateAndTime.GetCurrentCalendarTime()
        local day = currentCalendarTime.monthDay
        local numEvents = C_Calendar.GetNumDayEvents(0, day)
        if numEvents <= 0 then
            return
        end

        for i = 1, numEvents do
            local event = C_Calendar.GetDayEvent(0, day, i)
            if event and lootInfo[event.eventID] then
                ZL.hasHoliday = true
                tinsert(all, lootInfo[event.eventID])
            end
        end

        for _, FB in pairs(ZL.FBtable) do
            ZL.Loot[FB].Holiday = all
        end

        if ZL.hasHoliday and ZL.InitHoliday then
            ZL.InitHoliday()
        end
    end)
end

-- 特殊兑换物
function ZL.InsertExLoot(FB, tbl)
    for exItem, loot in pairs(tbl) do
        ZL.Loot[FB].ExchangeItems[exItem] = ZL.Loot[FB].ExchangeItems[exItem] or {}
        for _, itemID in pairs(loot.items) do
            tinsert(ZL.Loot[FB].ExchangeItems[exItem], itemID)
            for _, bossInfo in pairs(loot.boss) do
                local boss, hard = strsplit("-", bossInfo)
                ZL.Loot[FB][hard]["boss" .. boss .. "other"] =
                    ZL.Loot[FB][hard]["boss" .. boss .. "other"] or {}
                tinsert(ZL.Loot[FB][hard]["boss" .. boss .. "other"], itemID)
            end
        end
    end
end

-- 套装相关
function ZL.InsertSetLoot(FB, tbl)
    for boss, loot in pairs(tbl) do
        for hard, _loot in pairs(loot) do
            ZL.Loot[FB][hard]["boss" .. boss .. "other"] =
                ZL.Loot[FB][hard]["boss" .. boss .. "other"] or {}
            for exItemID, items in pairs(_loot) do
                ZL.Loot[FB].ExchangeItems[exItemID] = items
                for _, itemID in pairs(items) do
                    tinsert(ZL.Loot[FB][hard]["boss" .. boss .. "other"], itemID)
                end
            end
        end
    end
end
