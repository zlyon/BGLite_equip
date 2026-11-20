local AddonName, ns = ...

local L = ns.L
ns.GetClassColor = GetClassColor
local GetClassColor = ns.GetClassColor

local pt = print

local RR = "|r"
ns.RR = RR
local NN = "\n"
ns.NN = NN
local RN = "|r\n"
ns.RN = RN

BG = {}

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
    return "|c" .. color .. className .. "|r" .. BG.STC_y1(QUESTS_LABEL)
end
ns.ClassQuest = ClassQuest

-- 注册事件
do
    local loginFuncs = {}
    local playerReady = false
    BG.initErrors = {}
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self, event)
        self:UnregisterEvent("PLAYER_LOGIN")
        playerReady = true
        local index = 1
        while loginFuncs[index] do
            local ok, err = xpcall(loginFuncs[index], function(e) return tostring(e) end)
            if not ok and #BG.initErrors < 10 then
                tinsert(BG.initErrors, err)
            end
            index = index + 1
        end
        if BGLite_equip then
            BGLite_equip.initErrors = BG.initErrors
            if BGLite_equip.options then
                BGLite_equip.options.__initErrors = BG.initErrors
            end
        end
    end)
    function BG.Init(func)
        if playerReady then
            securecall(func)
        else
            tinsert(loginFuncs, func)
        end
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
    function BG.Init2(func)
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
    function BG.RegisterEvent(event, func)
        if type(event) == "table" then
            for _, e in ipairs(event) do
                RegisterOneEvent(e, func)
            end
        else
            RegisterOneEvent(event, func)
        end
    end
end

-- 无限服环境（1.60.x）：只保留无限服需要的标记，其余版本分支已移除
do
    if GetCurrentRegion() ~= 5 then
        BG.IsTW = true
    end
    BG.onlyOneHard = true
    BG.IsForever = true
    BG.IsNewUI = true
end

-- 无限服没有 WLK/TBC 阶段内容
function BG.IsWLKFB()
    return false
end

function BG.IsTBCFB()
    return false
end

function BG.GN(unit)
    unit = unit or "player"
    if unit == "t" then
        unit = "target"
    end
    return GetUnitName(unit, true)
end

BG.Init(function ()
    BG.myName = BG.GN()
end)
BG.realmName = GetRealmName():gsub(" ", ""):gsub("%-", "")
BG.realmID = GetRealmID()

local faction = UnitFactionGroup("player")
BG.IsAlliance = faction == "Alliance" or nil
BG.IsHorde = faction == "Horde" or nil

function BG.GFN(name)
    if not name then return end
    local name, realm = strsplit("-", name)
    realm = realm or BG.realmName
    return name .. "-" .. realm
end

function BG.GSN(name)
    if not name then return end
    local name, realm = strsplit("-", name)
    if not realm or realm == "" or realm == BG.realmName then
        return name
    else
        return name .. "-" .. realm
    end
end

function BG.SPN(name)
    if not name then return end
    if BG.IsSecret(name) then return end
    return strsplit("-", name, 2)
end

-- 增加节日掉落
function BG.AddHolidayLoot(lootInfo)
    BG.hasHolidayLoot = true
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
                BG.hasHoliday = true
                tinsert(all, lootInfo[event.eventID])
            end
        end

        for _, FB in pairs(BG.FBtable) do
            BG.Loot[FB].Holiday = all
        end
    end)
end

-- 特殊兑换物
function BG.InsertExLoot(FB, tbl)
    for exItem, loot in pairs(tbl) do
        BG.Loot[FB].ExchangeItems[exItem] = BG.Loot[FB].ExchangeItems[exItem] or {}
        for _, itemID in pairs(loot.items) do
            tinsert(BG.Loot[FB].ExchangeItems[exItem], itemID)
            for _, bossInfo in pairs(loot.boss) do
                local boss, hard = strsplit("-", bossInfo)
                BG.Loot[FB][hard]["boss" .. boss .. "other"] =
                    BG.Loot[FB][hard]["boss" .. boss .. "other"] or {}
                tinsert(BG.Loot[FB][hard]["boss" .. boss .. "other"], itemID)
            end
        end
    end
end

-- 套装相关
function BG.InsertSetLoot(FB, tbl)
    for boss, loot in pairs(tbl) do
        for hard, _loot in pairs(loot) do
            BG.Loot[FB][hard]["boss" .. boss .. "other"] =
                BG.Loot[FB][hard]["boss" .. boss .. "other"] or {}
            for exItemID, items in pairs(_loot) do
                BG.Loot[FB].ExchangeItems[exItemID] = items
                for _, itemID in pairs(items) do
                    tinsert(BG.Loot[FB][hard]["boss" .. boss .. "other"], itemID)
                end
            end
        end
    end
end
