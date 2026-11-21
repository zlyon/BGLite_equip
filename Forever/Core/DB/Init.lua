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

----------服务器 ID / 名字（无限服冷启动）----------
-- 这个客户端在插件文件加载阶段还没下发服务器信息：GetRealmID() 返回 0、GetRealmName() 返回空串，
-- 进世界之后（/reload）才有真值。原版是在文件加载时就把这两个值缓存进各模块的，
-- 于是同一个角色一次记在 0、另一次记在真实 ID，角色配置里就会看到两个一样的角色，服务器名也常是空的。
-- 存档在插件加载前已经就绪：这里让这两个查询在客户端给不出真值时，返回存档里实际在用的那个 ID / 名字；
-- 客户端一旦给出真值就照原样返回。对模块来说和原版完全一致，模块代码不用动。
local TryRealmName, SaveRealmName
do
    local rawGetRealmID, rawGetRealmName = GetRealmID, GetRealmName
    local pinnedID, cachedName

    -- 存档里的角色数据挂在哪个服 ID 下面（只看按服分层的表；同时存在多个服时不猜，交回客户端值）
    local function SavedRealmID()
        local db = type(BGLite_equip) == "table" and BGLite_equip
        if not db then return end
        local found, multi = nil, false
        for _, layer in ipairs({ db, db.ZL }) do
            if type(layer) == "table" then
                for _, key in ipairs({ "playerInfo", "MONEY", "RaidCD", "equip" }) do
                    local t = layer[key]
                    if type(t) == "table" then
                        for id, v in pairs(t) do
                            if type(id) == "number" and type(v) == "table" and next(v) then
                                if found and found ~= id then
                                    multi = true
                                end
                                found = found or id
                            end
                        end
                    end
                end
            end
        end
        if found and not multi then return found end
    end

    -- 这个客户端（无限服）的原生 GetRealmID() 恒 0，但 GUID 第 2 段就是「规则集编号」：
    --   实测四个规则集分别是 Player-6745-… / 6959-… / 6961-… / 6752-…
    -- 同一规则集内它稳定不变、不同规则集不同，正好可以当分服键。
    -- 把它顶上去之后，各模块在插件加载期就能锁到「本规则集」的键，不同规则集各存一份，
    -- 同名角色也不会再互相覆盖。官方服的 GetRealmID() 本来就有真值，永远走不到这里。
    local function GuidRealmID()
        local ok, g = pcall(function() return UnitGUID and UnitGUID("player") end)
        if not ok or type(g) ~= "string" then return nil end
        local ok2, seg = pcall(function() return select(2, strsplit("-", g)) end)
        local n = ok2 and tonumber(seg) or nil
        if type(n) == "number" and n > 0 then return n end
        return nil
    end
    BG.GuidRealmID = GuidRealmID

    function GetRealmID()
        -- ⚠ 0 绝不能当成「已经钉好」：插件加载那一刻 GUID 可能还没就绪，一旦把 0 钉死，
        -- 整个会话所有模块都会往 0 号键里写，而界面按真实规则集键去读 ⇒ 同一个角色被拆成两条。
        -- 所以只有拿到非 0 值才算钉住，仍是 0 时每次调用都再试一次（UnitGUID 很便宜）。
        if pinnedID and pinnedID ~= 0 then return pinnedID end
        local v = rawGetRealmID and rawGetRealmID()
        if type(v) == "number" and v ~= 0 then
            pinnedID = v
            return pinnedID
        end
        -- 原生值是 0（客户端不给 realmID）时才用 GUID 段；再不行才退回存档里在用的键
        local g = GuidRealmID()
        if g then
            pinnedID = g
            return pinnedID
        end
        pinnedID = pinnedID or SavedRealmID() or 0
        return pinnedID
    end

    function GetRealmName()
        local v = rawGetRealmName and rawGetRealmName()
        if type(v) == "string" and v ~= "" then return v end
        if cachedName then return cachedName end
        local db = type(BGLite_equip) == "table" and BGLite_equip
        local rid = GetRealmID()
        for _, t in ipairs({ db and db.realmName, db and db.ZL and db.ZL.realmName }) do
            local name = type(t) == "table" and t[rid]
            if type(name) == "string" and name ~= "" then
                cachedName = name
                return name
            end
        end
        return ""
    end

    -- 这个客户端不发服务器名，GetRealmName() 会拿「角色名」冒充（实测返回 "圣教军伽罗"）。
    -- 这类值一旦写进 BG.realmName，会污染 BG.GFN 拼出来的角色全名，必须拦掉。
    local function IsSelfName(s)
        if type(s) ~= "string" then return false end
        local ok, bare = pcall(function() return (s:gsub(" ", "")) end)
        if not ok or bare == "" then return false end
        local function eq(v)
            if type(v) ~= "string" then return false end
            local ok2, b = pcall(function() return (v:gsub(" ", "")) end)
            return ok2 and b ~= "" and b == bare
        end
        return eq(BG.myName)
            or eq(UnitName and UnitName("player"))
            or eq(GetUnitName and GetUnitName("player", true))
    end
    BG.IsSelfRealmName = IsSelfName
    -- 诊断用：暴露客户端原生的 GetRealmID / GetRealmName，供 /zlrealm 对比
    BG.GetRawRealmID = rawGetRealmID
    BG.GetRawRealmName = rawGetRealmName

    -- 冷启动时客户端还没下发服务器信息（GetRealmName 返回空串），要等进世界之后才有值。
    -- 原版在文件加载时就把值缓存了，于是这一整个会话的服名都是空 → 角色总览不显示服务器名。
    -- 这里在登录后补写一次；只填空位，存档里已有的服名绝不覆盖。
    SaveRealmName = function(name)
        if IsSelfName(name) then return end   -- 角色名冒充的假服名，一概不记
        BG.realmName = name
        cachedName = name
        if type(ZL) == "table" then
            ZL.realmName = name
        end
        local db = type(BGLite_equip) == "table" and BGLite_equip
        if not db then return end
        for _, t in ipairs({ db.realmName, db.ZL and db.ZL.realmName }) do
            if type(t) == "table" and (t[BG.realmID] == nil or t[BG.realmID] == "") then
                t[BG.realmID] = name
            end
        end
    end

    TryRealmName = function()
        local v = rawGetRealmName and rawGetRealmName()
        if type(v) == "string" and v ~= "" then
            local name = v:gsub(" ", ""):gsub("%-", "")
            if IsSelfName(name) then return false end  -- 客户端拿角色名冒充服名：当作「还没下发」，继续等
            if name ~= BG.realmName then
                SaveRealmName(name)
            end
            return true
        end
        return false
    end

    ----------规则集分服：登录时把「当前角色」的记录搬到它所属规则集的键下----------
    -- 老存档把四个规则集全记在 realmID=0 下（客户端以前只给 0）。现在键改成了 GUID 段，
    -- 老数据就落在没人读的 0 里。这里在该角色登录时把它的记录整条搬过来：
    --   * 只搬「按角色名分层」的四张表，不碰邮件/交易那些历史表（各规则集重新累积即可）
    --   * 搬完旧键里就没有这条了 ⇒ 总览里不会出现「同一个角色两条」
    -- 这些表在 ZL 下都是「[规则集键][角色名]」两层，搬的时候要一层层搬。
    -- 少搬一张的后果是那张表的数据永远留在旧键里 —— 表现为总览有等级没装等、或缺金币/CD。
    local CHAR_TABLES = {
        "playerInfo", "PlayerItemsLevel", "equip", "MONEY", "bag",
        "RaidCD", "QuestCD", "worldBossCD", "bestPrice", "tradeHistory",
        "roleOverviewNote", "RoleOverviewSort",
    }

    local function MigrateChar(name, keepID)
        local db = type(BGLite_equip) == "table" and BGLite_equip
        local zl = db and db.ZL
        if type(name) ~= "string" or type(zl) ~= "table" or type(keepID) ~= "number" then return 0 end
        local moved = 0
        -- 两套数据根都要搬：ZL（角色总览）与顶层（金团表格）。
        -- 只搬 ZL 会让「角色配置」里同一个角色在 0 和真键各出现一次，也违背同步唯一名的前提。
        for _, root in ipairs({ zl, db }) do
            for _, key in ipairs(CHAR_TABLES) do
                local t = root[key]
                if type(t) == "table" then
                    local rec
                    for id, sub in pairs(t) do
                        -- ⚠ 只从 0 号键（「不知道属于哪台服务器」的老数据）搬。
                        -- 以前写成「任意键 ≠ 本键」会把同名角色在另一台服务器的记录一起吞掉——
                        -- 那正是分键要解决的「同名跨服互相覆盖」，必须只搬 0。
                        if id == 0 and id ~= keepID and type(sub) == "table" then
                            local v = sub[name]
                            if v ~= nil then
                                rec = rec or v
                                sub[name] = nil
                                moved = moved + 1
                            end
                        end
                    end
                    if rec ~= nil then
                        t[keepID] = type(t[keepID]) == "table" and t[keepID] or {}
                        if t[keepID][name] == nil then t[keepID][name] = rec end
                    end
                end
            end
        end
        return moved
    end
    BG.MigrateCharRealm = MigrateChar

    -- 老存档里同一个角色常在 0 号键留一份、真键又有一份（历次迁移的结果）。
    -- 每套数据根内部各清一次：某个名字在非 0 键已经存在，就把 0 号键那份删掉，
    -- 免得界面同一个角色出现两行、也免得同步认不出唯一名。
    -- 只在「同一个根」里比较，不跨 ZL / 顶层，避免一套有、另一套没有时误删。
    function BG.CleanZeroDuplicates()
        local db = type(BGLite_equip) == "table" and BGLite_equip
        if not db then return 0 end
        local removed = 0
        for _, root in ipairs({ db.ZL, db }) do
            if type(root) == "table" then
                for _, key in ipairs(CHAR_TABLES) do
                    local t = root[key]
                    if type(t) == "table" and type(t[0]) == "table" then
                        local known = {}
                        for id, sub in pairs(t) do
                            if type(id) == "number" and id ~= 0 and type(sub) == "table" then
                                for nm in pairs(sub) do known[nm] = true end
                            end
                        end
                        for nm in pairs(t[0]) do
                            if known[nm] then
                                t[0][nm] = nil
                                removed = removed + 1
                            end
                        end
                    end
                end
            end
        end
        return removed
    end

    -- 进世界后重算一次：加载期 GUID 没就绪（个别冷启动）时 pinnedID 会是 0，
    -- 这里拿到 GUID 段后改钉到正确规则集，并把当前角色的老记录搬过来。
    function BG.RefreshRealmID()
        local before = pinnedID
        local v = rawGetRealmID and rawGetRealmID()
        if type(v) == "number" and v ~= 0 then
            pinnedID = v
        else
            -- ⚠ before 可能是 0（加载期没能取到 GUID）。0 在 Lua 里是真值，
            -- 直接 `or before` 会把 0 顶上去，RefreshRealmID 就白跑了。
            pinnedID = GuidRealmID() or (before ~= 0 and before) or SavedRealmID() or 0
        end
        BG.realmID = pinnedID
        if type(BG.myName) == "string" and BG.myName ~= "" then
            MigrateChar(BG.myName, pinnedID)
        end
        return pinnedID, before
    end
end

BG.Init(function ()
    BG.myName = BG.GN()
    -- 进世界后重算规则集键：冷启动时插件加载那一刻 GUID 万一还没就绪，pinnedID 会是 0，
    -- 这里改钉到本规则集的键，并把当前角色的老记录搬过来（老存档全在 0 下）。
    if BG.RefreshRealmID then BG.RefreshRealmID() end
    -- 老存档遗留：0 号键里与真键重复的角色记录清掉（同一个角色只留真键那一份）
    if BG.CleanZeroDuplicates then BG.CleanZeroDuplicates() end
    -- 服务器显示名的位次表：当前服务器排第一（无限服 → 无限服二 → …），界面各处共用这一份
    if BG.SyncRealmOrder then BG.SyncRealmOrder(BG.realmID) end
    -- 登录/进世界后客户端才有服务器信息：拿不到就静默重试，直到拿到为止（最多约 1 分钟）
    if TryRealmName() then return end
    local tries = 0
    local function Retry()
        if TryRealmName() or tries >= 30 then return end
        tries = tries + 1
        if C_Timer and C_Timer.After then
            C_Timer.After(2, Retry)
        end
    end
    Retry()
end)
BG.realmName = (GetRealmName() or ""):gsub(" ", ""):gsub("%-", "")
-- 客户端会把角色名冒充服名（加载期角色还没加载、上面过滤不掉），这里再兜一次
if BG.realmName ~= "" and BG.IsSelfRealmName and BG.IsSelfRealmName(BG.realmName) then
    BG.realmName = ""
end
BG.realmID = GetRealmID()
-- 诊断用：插件文件加载的那一瞬间 GUID 是否已经就绪。
-- 如果能拿到，说明「把存档键直接换成规则集编号」可行（各模块加载期就能锁到正确的键）；
-- 拿不到就只能把规则集编号记在角色记录里（当前做法）。/zlrealm 会把它的值打出来。
BG.loadGUID = (function()
    local ok, g = pcall(function() return UnitGUID and UnitGUID("player") end)
    return (ok and type(g) == "string") and g or nil
end)()

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
