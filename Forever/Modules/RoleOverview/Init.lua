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

-- 存档挂在主插件的 BGLite_equip 表下的 ZL 子表。
-- ⚠ WoW 是先执行插件文件、后才注入 SavedVariables：注入会把全局 BGLite_equip
-- 换成存档表。所以这里绝不在文件顶层缓存指针（不写 ZLDb = ... 这类别名），
-- 全库一律现取 BGLite_equip.ZL —— 与 MultiAccountDB / 原作者全程用全局名
-- ZongLan.xxx 的写法完全一致，注入后天然指向真正的存档表，永不脱钩。
BGLite_equip = type(BGLite_equip) == "table" and BGLite_equip or {}
BGLite_equip.ZL = type(BGLite_equip.ZL) == "table" and BGLite_equip.ZL or {}

do
    -- 只保证子表存在，不保存任何指针（存档注入后 BGLite_equip 可能没有 ZL 子表）
    local function EnsureZL()
        if type(BGLite_equip) ~= "table" then BGLite_equip = {} end
        if type(BGLite_equip.ZL) ~= "table" then BGLite_equip.ZL = {} end
    end
    ns.EnsureZL = EnsureZL

    local bf = CreateFrame("Frame")
    bf:RegisterEvent("ADDON_LOADED")
    bf:SetScript("OnEvent", function(_, event, addonName)
        EnsureZL()
        if addonName == AddonName then
            -- 自己的存档已就位，后面的 ADDON_LOADED 不再需要
            bf:UnregisterEvent("ADDON_LOADED")
        end
    end)
end

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
    local loginFired = false
    local f = CreateFrame("Frame")
    f:RegisterEvent("PLAYER_LOGIN")
    f:SetScript("OnEvent", function(self, event)
        self:UnregisterEvent("PLAYER_LOGIN")
        loginFired = true
        -- 保险：确保存档子表在（只保证存在，不缓存指针）
        if ns.EnsureZL then ns.EnsureZL() end
        for i, func in ipairs(loginFuncs) do
            -- securecall 会把错误吞掉（连 BugGrabber 都收不到），这里改成 pcall 直接抓错误
            local ok, err = pcall(func)
            if not ok then
                print("|cffff0000[角色总览] 初始化出错：|r" .. tostring(err))
            end
        end
    end)
    function ZL.Init(func)
        -- 与主插件 Core/DB/Init.lua 的 BG.Init 同一套写法：
        -- 插件如果在 PLAYER_LOGIN 之后才载入，事件不会再触发，这里立即补执行。
        if loginFired then
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

--------------------------------------------------------------------
-- 服务器名
-- ⚠ 客户端冷启动时原生 GetRealmName() 返回空串，进世界之后才下发；
-- 在文件加载期拍快照会把空串定死一整个会话 → 总览/存档里永远没有服务器名。
-- 这里做多源探测 + 进世界后重试，并且只填空位，绝不覆盖存档里已记好的真服名。
--------------------------------------------------------------------
do
    -- 这个客户端（12.x 基础）带「保密值」机制：issecretvalue 为真的字符串一旦被比较/拼接/当表键就报错。
    -- 所以每个来源都单独 pcall，一个源爆掉不影响其它源，也不会中断插件加载。
    local function SafeCall(f)
        if type(f) ~= "function" then return nil end
        -- ⚠ 必须多接一个：GetPlayerInfoByGUID 返回 7 个值，第 7 个才是 realm。
        -- 只接 6 个会把 realm 丢掉，于是「服名」永远读成角色名。
        local ok, a, b, c, d, e, g, h = pcall(f)
        if not ok then return nil end
        return a, b, c, d, e, g, h
    end
    ns.SafeCall = SafeCall

    local function IsSecret(v)
        if not issecretvalue then return false end
        local ok, r = pcall(issecretvalue, v)
        return (ok and r) and true or false
    end
    ns.IsSecret = IsSecret

    local function Show(v)
        if v == nil then return "nil" end
        local ok, s = pcall(tostring, v)
        if not ok then return "<不可读>" end
        return s
    end
    ns.ShowValue = Show

    -- 客户端不发服务器名时会拿「角色名」冒充：
    --   GetRealmName()            → "圣教军伽罗"
    --   GetPlayerInfoByGUID(...,6) → "圣教军 伽罗"
    -- 这类值一旦当服名用，会把角色名写进存档、还会污染 BG.realmName 进而污染 BG.GFN 生成的角色全名。
    local function BareName(s)
        if type(s) ~= "string" then return nil end
        local ok, v = pcall(function() return (s:gsub(" ", "")) end)
        if not ok or v == "" then return nil end
        return v
    end

    local function IsSelfName(s)
        local bare = BareName(s)
        if not bare then return false end
        local function eq(v)
            return BareName(v) == bare
        end
        if eq(type(ZL) == "table" and ZL.myName) then return true end
        if eq(SafeCall(function() return UnitName and UnitName("player") end)) then return true end
        if eq(SafeCall(function() return GetUnitName and GetUnitName("player", true) end)) then return true end
        local full = SafeCall(function() return UnitFullName and UnitFullName("player") end)
        if eq(full) then return true end
        -- 玩家自己的 GUID 第 6 值是角色名（第 7 才是服名）
        local gpi = GetPlayerInfoByGUID or (C_PlayerInfo and C_PlayerInfo.GetPlayerInfoByGUID)
        local guid = SafeCall(function() return UnitGUID and UnitGUID("player") end)
        if gpi and guid then
            local _, _, _, _, _, myNameFromGuid = SafeCall(function() return gpi(guid) end)
            if eq(myNameFromGuid) then return true end
        end
        return false
    end
    ns.IsSelfName = IsSelfName

    local function CleanRealm(s)
        if type(s) ~= "string" then return nil end
        if IsSecret(s) then return nil end        -- 保密值读不了，放弃这一源
        local ok, cleaned = pcall(function()
            return (s:gsub(" ", ""):gsub("%-", ""))
        end)
        if not ok or type(cleaned) ~= "string" or cleaned == "" then return nil end
        if IsSelfName(cleaned) then return nil end -- 角色名冒充的假服名，丢掉
        return cleaned
    end
    ns.CleanRealm = CleanRealm

    -- 规则集编号：这个客户端不给 realmID（恒 0），但 GUID 第 2 段就是规则集编号。
    --   实测四个规则集分别是 Player-6745-… / 6959-… / 6961-… / 6752-…
    -- 存档的「键」不能改成它（24 个模块在插件加载时就把 realmID 锁死了，那时 GUID 还没就绪，
    -- 改键只会让一边写旧键、一边读新键），所以把编号记在每条角色记录里，供总览标注与排序。
    local guidKey, guidKeyFor
    function ns.GuidRealmKey()
        local g = SafeCall(function() return UnitGUID and UnitGUID("player") end)
        if type(g) ~= "string" then return nil end
        if g == guidKeyFor then return guidKey end
        local ok, seg = pcall(function() return select(2, strsplit("-", g)) end)
        local n = ok and tonumber(seg) or nil
        guidKeyFor = g
        guidKey = (type(n) == "number" and n > 0) and n or nil
        return guidKey
    end

    -- 当前规则集键：唯一权威。GUID 第 2 段现取（这个客户端恒定可用），拿不到才退回已钉的 realmID。
    -- ⚠ 各写入点必须走它，不能再用「加载期算出来的 realmID」：加载时 GUID 可能还没就绪，
    -- 那个 0 一旦被用来写存档，记录就落在没人读的 0 号键里（界面按真键读 ⇒ 看不见）。
    -- 顺带把 ZL.realmID 同步成同一个值，避免两处各说各话。
    function ns.CurRealmID()
        local rk = ns.GuidRealmKey()
        local db = type(BGLite_equip) == "table" and BGLite_equip
        local z = db and db.ZL
        if rk then
            if type(z) == "table" and z.realmID ~= rk then z.realmID = rk end
            return rk
        end
        return tonumber(type(z) == "table" and z.realmID) or 0
    end

    -- 服务器显示名统一由 BG 算（无限服 / 无限服二 / 无限服三；能解析规则集的用「PVP · 3区」），
    -- 位次表也共用 BG 那一份（存档 BGLite_equip.ZL.realmOrder），避免两处各算一套、名字对不上。
    function ns.RealmSeq(rid)
        return BG and BG.RealmSeq and BG.RealmSeq(rid)
    end

    function ns.SyncRealmOrder(cur)
        if BG and BG.SyncRealmOrder then BG.SyncRealmOrder(cur or ns.CurRealmID()) end
    end

    function ns.RealmKeyName(key)
        if BG and BG.GetRealmDisplay then
            local ok, name = pcall(BG.GetRealmDisplay, key)
            if ok and name then return name end
        end
        -- BG 还没加载时的兜底：只认存档里记过的名字
        local db = type(BGLite_equip) == "table" and BGLite_equip or nil
        local v = key and ((db and db.realmName and db.realmName[key])
            or (db and db.ZL and db.ZL.realmName and db.ZL.realmName[key]))
        if type(v) == "string" and v ~= "" then return v end
        return L["未知服务器"] or "未知服务器"
    end

    -- 所有可能的服名来源（顺序即优先级）
    local function Sources()
        local unitSuffix
        local n = SafeCall(function() return GetUnitName and GetUnitName("player", true) end)
        if type(n) == "string" and not IsSecret(n) then
            local ok, suffix = pcall(function() return select(2, strsplit("-", n)) end)
            if ok then unitSuffix = suffix end
        end
        local realmInfo
        local info = SafeCall(function() return GetRealmInfo and GetRealmInfo() end)
        if type(info) == "table" then realmInfo = info.name end
        -- UnitFullName 的第 2 个值：BG 的表格同步消息就是拿它当「服务器」字段
        local _, unitFullRealm = SafeCall(function() return UnitFullName and UnitFullName("player") end)
        -- GetPlayerInfoByGUID 的返回顺序是：
        --   localizedClass, englishClass, localizedRace, englishRace, sex, name, realm
        -- ⚠ 第 6 个是「角色名」，第 7 个才是「服务器名」。之前一直只读到第 6，所以拿到的是角色名。
        local guidName, guidRealm
        do
            local gpi = GetPlayerInfoByGUID or (C_PlayerInfo and C_PlayerInfo.GetPlayerInfoByGUID)
            local guid = SafeCall(function() return UnitGUID and UnitGUID("player") end)
            if gpi and guid then
                local _, _, _, _, _, nm, rlm = SafeCall(function() return gpi(guid) end)
                guidName, guidRealm = nm, rlm
            end
        end
        return {
            { "GetRealmName",           SafeCall(function() return GetRealmName and GetRealmName() end) },
            { "原生GetRealmName",        SafeCall(function() return BG and BG.GetRawRealmName and BG.GetRawRealmName() end) },
            { "PlayerInfoByGUID[7]服名", guidRealm },
            { "GetNormalizedRealmName", SafeCall(function() return GetNormalizedRealmName and GetNormalizedRealmName() end) },
            { "GetCVar.realmName",      SafeCall(function() return GetCVar and GetCVar("realmName") end) },
            { "UnitName后缀",            unitSuffix },
            { "UnitRealmName",          SafeCall(function() return UnitRealmName and UnitRealmName("player") end) },
            { "UnitFullName[2]",        unitFullRealm },
            { "PlayerInfoByGUID[6]角色名", guidName },
            { "C_CVar.realmName",       SafeCall(function() return C_CVar and C_CVar.GetCVar and C_CVar.GetCVar("realmName") end) },
            { "GetRealmInfo.name",      realmInfo },
        }
    end

    -- 探测一次：返回服名（可能为 nil），并把各源原值记到 ns.lastRealmProbe
    function ns.ProbeRealmName(verbose)
        local lines, result = {}, nil
        for _, item in ipairs(Sources()) do
            local label, v = item[1], item[2]
            local tag = ""
            if IsSecret(v) then
                tag = "(保密)"
            elseif IsSelfName(v) then
                tag = "(=角色名,已忽略)"
            end
            lines[#lines + 1] = format("%s=%s%s", label, Show(v), tag)
            if not result then result = CleanRealm(v) end
        end
        ns.lastRealmProbe = table.concat(lines, " | ")
        if verbose then
            print("|cff69ccf0[角色总览] 服名探测：|r" .. ns.lastRealmProbe)
        end
        return result
    end

    -- /zlrealm            → 打印各来源真实返回（含保密标记）+ 规则集分组统计
    -- /zlrealm <名字>     → 给「当前所在规则集」命名（各规则集只在各自的分组里生效）
    SLASH_ZLREALM1 = "/zlrealm"
    SlashCmdList["ZLREALM"] = function(msg)
        msg = tostring(msg or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if msg ~= "" then
            local rk = ns.GuidRealmKey()
            if ns.SaveRealmName(msg, true) then
                if rk then
                    print("|cff69ccf0[角色总览]|r 当前规则集（#" .. tostring(rk) .. "）显示名已设为：" .. msg .. "（重开总览可见）")
                else
                    print("|cff69ccf0[角色总览]|r 服务器名已设为：" .. msg .. "（重开总览可见）")
                end
            else
                print("|cff69ccf0[角色总览]|r 设置失败：名字为空或含不可用字符")
            end
            return
        end
        ns.ProbeRealmName(true)
        print(format("|cff69ccf0[角色总览]|r ZL.realmID=%s  ZL.realmName=%s  BG.realmName=%s",
            Show(ZL.realmID), Show(ZL.realmName), Show(type(BG) == "table" and BG.realmName or nil)))
        -- 分服依据 = GUID 第 2 段（规则集编号）。按角色记录里的 realmKey 统计，看总共有几个规则集、各几人
        local groups = {}
        local pi = BGLite_equip and BGLite_equip.ZL and BGLite_equip.ZL.playerInfo
        if type(pi) == "table" then
            for _, chars in pairs(pi) do
                if type(chars) == "table" then
                    for player, rec in pairs(chars) do
                        local rk = type(rec) == "table" and rec.realmKey or nil
                        local label
                        if rk and rk ~= 0 then
                            label = ns.RealmKeyName(rk) or ("#" .. tostring(rk))
                        else
                            label = "未标记"
                        end
                        groups[label] = groups[label] or {}
                        tinsert(groups[label], player)
                    end
                end
            end
        end
        local parts = {}
        for label, players in pairs(groups) do
            parts[#parts + 1] = format("%s(%d人)", label, #players)
        end
        table.sort(parts)
        print(format("|cff69ccf0[角色总览]|r 原生realmID=%s | 已钉realmID=%s | 当前规则集=%s | 加载期GUID=%s",
            Show(ns.SafeCall(function() return BG and BG.GetRawRealmID and BG.GetRawRealmID() end)),
            Show(ZL.realmID), Show(ns.GuidRealmKey()),
            Show(type(BG) == "table" and BG.loadGUID or nil)))
        print("|cff69ccf0[角色总览]|r 规则集分组：" .. (#parts > 0 and table.concat(parts, ", ") or "无"))
    end

    -- 把服名写进所有相关位置（默认只填空位；force=true 时强制覆盖）
    -- force 且已经知道规则集编号时 = 「给当前规则集命名」：只写规则集那一格，
    -- 绝不改全局 BG.realmName（否则 BG.GFN 拼出来的角色全名会变成「角色-规则集名」）。
    function ns.SaveRealmName(name, force)
        name = CleanRealm(name)
        if not name then return false end
        local db = type(BGLite_equip) == "table" and BGLite_equip
        local rk = ns.GuidRealmKey()
        local rid = ns.CurRealmID()
        -- force = 「给当前规则集命名」：只写规则集那一格，绝不动全局 BG.realmName，
        -- 否则 BG.GFN 拼出来的角色全名会变成「角色-规则集名」。
        if force then
            local key = rk or rid
            ns.RealmSeq(key)
            if db then
                for _, t in ipairs({ db.realmName, db.ZL and db.ZL.realmName }) do
                    if type(t) == "table" then t[key] = name end
                end
            end
            return true
        end
        ZL.realmName = name
        if type(BG) == "table" then
            local cur = BG.realmName
            if force or type(cur) ~= "string" or IsSecret(cur) or cur == "" then
                BG.realmName = name
            end
        end
        if not db then return true end
        -- 同时记到「存档键」和「规则集编号」下：后者才是每个规则集各自的服名
        local keys = { rid }
        if rk and rk ~= rid then keys[2] = rk end
        for _, t in ipairs({ db.realmName, db.ZL and db.ZL.realmName }) do
            if type(t) == "table" then
                for _, k in ipairs(keys) do
                    local cur = t[k]
                    if force or type(cur) ~= "string" or IsSecret(cur) or cur == "" then
                        t[k] = name
                    end
                end
            end
        end
        return true
    end

    -- 显示用：按 本服存档 → ZL 存档 → 多账号库 → 当前服名 → 「未知服务器」的顺序取
    -- （这个客户端一个服名接口都不给，宁可显示“未知服务器”也不要把 0 糊在表里）
    function ns.RealmDisplayName(rid, db)
        -- 0 号键 = 老存档里没记录属于哪台服务器的数据，别拿它冒充某台真服务器
        if tonumber(rid) == 0 then return L["未知服务器"] or "未知服务器" end
        local function ok(v)
            if type(v) == "string" and not IsSecret(v) and v ~= "" and not IsSelfName(v) then return v end
        end
        return ok(db and db.realmName and db.realmName[rid])
            or ok(BGLite_equip.ZL.realmName and BGLite_equip.ZL.realmName[rid])
            or ok(MultiAccountDB and MultiAccountDB.realmName and MultiAccountDB.realmName[rid])
            or ok(BG and BG.realmName)
            or ok(ZL.realmName)
            or L["未知服务器"]
    end

    -- 从存档里取已经记好的服名（手动设置过 / 老存档留下的）
    function ns.SavedRealmName()
        local db = type(BGLite_equip) == "table" and BGLite_equip
        local rid = ZL.realmID or 0
        local function pick(t)
            if type(t) == "table" then
                local v = t[rid]
                if type(v) == "string" and v ~= "" and not IsSecret(v) and not IsSelfName(v) then return v end
            end
        end
        return pick(db and db.realmName)
            or pick(db and db.ZL and db.ZL.realmName)
            or pick(MultiAccountDB and MultiAccountDB.realmName)
    end

    -- 清掉存档/BG 里已被写入的「角色名冒充服名」脏值（之前版本会把它当服名存进去）
    function ns.PurgeFakeRealmName()
        local removed = 0
        local db = type(BGLite_equip) == "table" and BGLite_equip
        if db then
            for _, t in ipairs({ db.realmName, db.ZL and db.ZL.realmName }) do
                if type(t) == "table" then
                    for rid, v in pairs(t) do
                        if type(v) == "string" and IsSelfName(v) then
                            t[rid] = nil
                            removed = removed + 1
                        end
                    end
                end
            end
        end
        if type(ZL.realmName) == "string" and IsSelfName(ZL.realmName) then
            ZL.realmName = ""
            removed = removed + 1
        end
        if type(BG) == "table" and type(BG.realmName) == "string" and IsSelfName(BG.realmName) then
            BG.realmName = ""
            removed = removed + 1
        end
        return removed
    end

    ZL.realmID   = GetRealmID()
    -- 加载期一律不采信：这个客户端会把角色名冒充服名，且此时角色还没加载、过滤不掉。
    -- 进世界后先清脏值、再从存档恢复（手动设置过的名字），最后才尝试探测。
    ZL.realmName = ""

    -- 进世界后：先清「角色名冒充服名」的脏值 → 恢复手动设置过的名字 → 再尝试探测
    -- 每 1 秒一次，最多 40 次（≈ 客户端下发服务器信息前后的窗口）
    local tries = 0
    local cleaned = false
    local function Try()
        ZL.realmID = GetRealmID()
        ns.SyncRealmOrder()
        if not cleaned then
            cleaned = true
            ns.PurgeFakeRealmName()
            local saved = ns.SavedRealmName()
            if saved then ZL.realmName = saved end
        end
        local name = ns.ProbeRealmName()
        if name then
            ns.SaveRealmName(name)
            return true
        end
        -- 探测不到（客户端不发服名）：有手动设置值就算完成，没有就继续等一会儿
        return ZL.realmName ~= ""
    end
    local hook = CreateFrame("Frame")
    hook:RegisterEvent("PLAYER_ENTERING_WORLD")
    hook:SetScript("OnEvent", function(self)
        local function Step()
            if Try() then
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                return
            end
            if tries >= 40 then
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                ns.ProbeRealmName(true)  -- 全源都空：打一行原始值，方便定位
                return
            end
            tries = tries + 1
            C_Timer.After(1, Step)
        end
        Step()
    end)
end

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
