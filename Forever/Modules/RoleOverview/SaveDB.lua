if ZL.IsBlackListPlayer then return end
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

local LibBG = ns.LibBG
local L = ns.L
local GetClassColor = ns.GetClassColor

local RR = ns.RR
local NN = ns.NN
local RN = ns.RN
local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local Round = ns.Round

local pt = print

local realmID = GetRealmID()

local FBCD = "RaidCD"
local MONEY = "MONEY"
local dbNames = { AddonName, "MultiAccountDB" }

ZL.RoleOverviewOtherEquipSlots = {
    { id = "head", name = INVTYPE_HEAD, slots = { { id = "1", name = "HeadSlot" } } },
    { id = "neck", name = INVTYPE_NECK, slots = { { id = "2", name = "NeckSlot" } } },
    { id = "shoulder", name = INVTYPE_SHOULDER, slots = { { id = "3", name = "ShoulderSlot" } } },
    { id = "back", name = INVTYPE_CLOAK, slots = { { id = "15", name = "BackSlot" } } },
    { id = "chest", name = INVTYPE_CHEST, slots = { { id = "5", name = "ChestSlot" } } },
    { id = "wrist", name = INVTYPE_WRIST, slots = { { id = "9", name = "WristSlot" } } },
    { id = "hands", name = INVTYPE_HAND, slots = { { id = "10", name = "HandsSlot" } } },
    { id = "waist", name = INVTYPE_WAIST, slots = { { id = "6", name = "WaistSlot" } } },
    { id = "legs", name = INVTYPE_LEGS, slots = { { id = "7", name = "LegsSlot" } } },
    { id = "feet", name = INVTYPE_FEET, slots = { { id = "8", name = "FeetSlot" } } },
    {
        id = "finger",
        name = INVTYPE_FINGER,
        slots = {
            { id = "11", name = "Finger0Slot" },
            { id = "12", name = "Finger1Slot" },
        },
    },
}

ZL.RoleOverviewOtherEquipInfo = {
    name = L["装备"],
    color = "C084FC",
    type = "equip",
    id = "otherEquips",
    tex = select(2, GetInventorySlotInfo("ChestSlot")),
    width = 55,
}

ZL.RoleOverviewCustomItemsInfo = {
    name = L["物品"],
    color = "FFFF00",
    type = "items",
    id = "customItems",
    tex = 134842,
    minWidth = 55,
    width = 55,
}

ZL.Init(function()
    -- 获取副本CD
    do
        local colorplayer = SetClassCFF(ZL.myName, "player")

        function ZL.UpdateFBCD()
            local time = GetServerTime()
            local cd = {}

            for i = 1, GetNumSavedInstances() do
                local name, lockoutId, resettime, difficultyId, locked,
                extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName,
                numEncounters, encounterProgress, extendDisabled, instanceId =
                    GetSavedInstanceInfo(i)
                if locked then
                    local killInfo = {}
                    local killNum = 0
                    for encounterIndex = 1, numEncounters do
                        local bossName, fileDataID, isKilled = GetSavedInstanceEncounterInfo(i, encounterIndex)
                        tinsert(killInfo, { name = bossName, isKilled = isKilled })
                        if isKilled then
                            killNum = killNum + 1
                        end
                    end
                    local a = {
                        player = ZL.myName,
                        colorplayer = colorplayer,
                        fbId = instanceId,
                        num = maxPlayers,
                        resettime = resettime,
                        endtime = resettime + time,
                        diff = difficultyId,
                        bossSum = numEncounters,
                        killNum = killNum,
                        killInfo = killInfo,
                    }
                    tinsert(cd, a)
                end
            end
            if next(cd) then
                BGLite_equip.ZL[FBCD][realmID][ZL.myName] = cd
            else
                BGLite_equip.ZL[FBCD][realmID][ZL.myName] = {
                    {
                        player = ZL.myName,
                        colorplayer = colorplayer,
                    }
                }
            end

            -- 检查其他角色cd是否到期
            for _, db in pairs(dbNames) do
                if _G[db] and _G[db][FBCD] then
                    for realmID in pairs(_G[db][FBCD]) do
                        if type(realmID) == "number" and type(_G[db][FBCD][realmID]) == "table" then
                            local playerList = {}
                            for _player in pairs(_G[db][FBCD][realmID]) do
                                tinsert(playerList, _player)
                            end
                            for _, _player in ipairs(playerList) do
                                if _player ~= ZL.myName then
                                    local yes
                                    local player0, colorplayer0
                                    for i = #_G[db][FBCD][realmID][_player], 1, -1 do
                                        local cd = _G[db][FBCD][realmID][_player][i]
                                        if cd and not player0 and not colorplayer0 then
                                            player0 = cd.player
                                            colorplayer0 = cd.colorplayer
                                        end
                                        if cd and cd.endtime then
                                            if time >= cd.endtime then
                                                tremove(_G[db][FBCD][realmID][_player], i)
                                            elseif time < cd.endtime then
                                                cd.resettime = cd.endtime - time
                                                yes = true
                                            end
                                        end
                                    end
                                    if not yes then
                                        _G[db][FBCD][realmID][_player] = {
                                            {
                                                player = player0,
                                                colorplayer = colorplayer0,
                                            }
                                        }
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        local cd
        local function RequestRaidInfoWithCD()
            if not cd then
                cd = true
                ZL.After(0.5, function()
                    cd = nil
                    RequestRaidInfo()
                end)
            end
        end
        ZL.Init2(RequestRaidInfoWithCD)
        ZL.RegisterEvent("ENCOUNTER_END", function(self, event, _, _, _, _, success)
            if success == 1 then
                RequestRaidInfoWithCD()
            end
        end)
        ZL.RegisterEvent("CHAT_MSG_SYSTEM", function(self, event, msg)
            if not ZL.IsSecret(msg) and msg == INSTANCE_SAVED then
                RequestRaidInfoWithCD()
            end
        end)

        ZL.Init2(function()
            ZL.After(1, ZL.UpdateFBCD)
        end)
        ZL.RegisterEvent("ENCOUNTER_END", function(self, event, _, _, _, _, success)
            if success == 1 then
                ZL.After(1, ZL.UpdateFBCD)
            end
        end)
        ZL.RegisterEvent("UPDATE_INSTANCE_INFO", function()
            ZL.After(1, ZL.UpdateFBCD)
        end)

        for realmID, players in pairs(BGLite_equip.ZL[MONEY]) do
            for player, v in pairs(players) do
                if not BGLite_equip.ZL[FBCD][realmID][player] then
                    BGLite_equip.ZL[FBCD][realmID][player] = {
                        {
                            player = player,
                            colorplayer = v.colorplayer,
                        }
                    }
                end
            end
        end
    end

    -- 世界BOSS（MOP）
    BGLite_equip.ZL.worldBossCD = BGLite_equip.ZL.worldBossCD or {}
    BGLite_equip.ZL.worldBossCD[realmID] = BGLite_equip.ZL.worldBossCD[realmID] or {}
    BGLite_equip.ZL.worldBossCD[realmID][ZL.myName] = BGLite_equip.ZL.worldBossCD[realmID][ZL.myName] or {}

    -- 日常任务
    local holidayDungeonIDs = { 286, 285, 287, 288 }                                   -- 火焰节、万圣节、美酒节、情人节
    local holidayEventIDs = { [324] = true, [341] = true, [372] = true, [423] = true } -- 火焰节、万圣节、美酒节、情人节
    do
        BGLite_equip.ZL.QuestCD = BGLite_equip.ZL.QuestCD or {}
        BGLite_equip.ZL.QuestCD[realmID] = BGLite_equip.ZL.QuestCD[realmID] or {}
        BGLite_equip.ZL.QuestCD[realmID][ZL.myName] = BGLite_equip.ZL.QuestCD[realmID][ZL.myName] or {}

        local function IsLearnSkill(skillID)
            return BGLite_equip.ZL[MONEY][realmID][ZL.myName].skill[skillID]
        end

        local function GetQuestSkillID(questName)
            return ZL.dayQuests and ZL.dayQuests[questName] and ZL.dayQuests[questName].skillID
        end

        -- 日常
        local function SaveDayQuest(questName, questID, count)
            local currentTimestamp = GetServerTime()
            local secondsUntilNext7am = ZL.GetNextDayTime()
            local timestamp = currentTimestamp + secondsUntilNext7am

            local colorplayer = SetClassCFF(ZL.myName, "player")
            BGLite_equip.ZL.QuestCD[realmID][ZL.myName][questName] = {
                name = questName,
                player = ZL.myName,
                colorplayer = colorplayer,
                questID = questID,
                resettime = secondsUntilNext7am,
                endtime = timestamp,
                count = count,
            }
        end
        local function UpdateDayQuest(questID)
            if not ZL.dayQuests then return end
            for questName in pairs(ZL.dayQuests) do
                for _, _questID in pairs(ZL.dayQuests[questName].questIDs) do
                    if _questID == questID then
                        SaveDayQuest(questName, questID)
                        return
                    end
                end
            end
        end
        -- 日常数量
        local function UpdateDayQuestCount()
            if not GetDailyQuestsCompleted then return end
            local count = GetDailyQuestsCompleted()
            if count > 0 then
                SaveDayQuest('dayQuestCount', nil, count)
            else
                BGLite_equip.ZL.QuestCD[realmID][ZL.myName].dayQuestCount = nil
            end
        end

        -- 周常
        local function SaveWeekQuest(questName, questID)
            local currentTimestamp = GetServerTime()
            local secondsToNextThursday = ZL.GetNextWeekTime()         -- 距离下周四还有多少秒
            local timestamp = currentTimestamp + secondsToNextThursday -- 到下周四的实际时间戳

            local colorplayer = SetClassCFF(ZL.myName, "player")
            BGLite_equip.ZL.QuestCD[realmID][ZL.myName][questName] = {
                name = questName,
                player = ZL.myName,
                colorplayer = colorplayer,
                questID = questID,
                resettime = secondsToNextThursday,
                endtime = timestamp
            }
        end
        local function UpdateWeekQuest(questID)
            if not ZL.weekQuests then return end
            for questName in pairs(ZL.weekQuests) do
                for _, _questID in pairs(ZL.weekQuests[questName].questIDs) do
                    if _questID == questID then
                        SaveWeekQuest(questName, questID)
                        return
                    end
                end
            end
        end

        -- MOP收菜

        -- 节日本

        -- 永久任务：登录时追溯，交任务后更新，不参与每日/每周重置
        local permanentQuests = {}
        local function SavePermanentQuest(questID)
            local questName = permanentQuests[questID]
            if not questName then return end
            BGLite_equip.ZL.QuestCD[realmID][ZL.myName][questName] = {
                name = questName,
                questID = questID,
                permanent = true,
            }
        end

        -- 交任务时触发
        ZL.RegisterEvent("QUEST_TURNED_IN", function(self, event, questID)
            UpdateDayQuest(questID)
            UpdateWeekQuest(questID)
            SavePermanentQuest(questID)
            ZL.After(1, function()
                UpdateDayQuestCount()
            end)
        end)

        -- 检查全部角色的任务重置cd是否到期（日常是第二天凌晨7点）
        local function UpdateQuestEndTime()
            local time = GetServerTime()
            for _, db in pairs(dbNames) do
                if _G[db] and _G[db].QuestCD then
                    for realmID in pairs(_G[db].QuestCD) do
                        if type(realmID) == "number" and type(_G[db].QuestCD[realmID]) == "table" then
                            for player in pairs(_G[db].QuestCD[realmID]) do
                                local questList = {}
                                for questName in pairs(_G[db].QuestCD[realmID][player]) do
                                    tinsert(questList, questName)
                                end
                                for _, questName in ipairs(questList) do
                                    local v = _G[db].QuestCD[realmID][player][questName]
                                    if v.permanent then
                                        -- 永久任务保留完成状态
                                    elseif v.endtime and time < v.endtime then
                                        v.resettime = v.endtime - time
                                    else
                                        local skillID = GetQuestSkillID(questName)
                                        if skillID then
                                            -- 专业任务，加上notFinish标记，用于显示X
                                            _G[db].QuestCD[realmID][player][questName].endtime = nil
                                            _G[db].QuestCD[realmID][player][questName].resettime = nil
                                            _G[db].QuestCD[realmID][player][questName].notFinish = true
                                            -- 但如果自己没学这个专业了，则清空
                                            if ZL.IsMe(realmID, player) and not IsLearnSkill(skillID) then
                                                _G[db].QuestCD[realmID][player][questName] = nil
                                            end
                                        else
                                            _G[db].QuestCD[realmID][player][questName] = nil
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- 追溯已完成的任务
        local function CheckQuestsCompleted()
            if ZL.dayQuests then
                for questName, v in pairs(ZL.dayQuests) do
                    if not BGLite_equip.ZL.QuestCD[realmID][ZL.myName][questName] then
                        local skillID = v.skillID
                        if skillID and IsLearnSkill(skillID) then
                            BGLite_equip.ZL.QuestCD[realmID][ZL.myName][questName] = {
                                notFinish = true,
                            }
                        end
                    end
                    for _, _questID in pairs(ZL.dayQuests[questName].questIDs) do
                        if C_QuestLog.IsQuestFlaggedCompleted(_questID) then
                            SaveDayQuest(questName, _questID)
                            break
                        end
                    end
                end
            end
            if ZL.weekQuests then
                for questName in pairs(ZL.weekQuests) do
                    for _, _questID in pairs(ZL.weekQuests[questName].questIDs) do
                        if C_QuestLog.IsQuestFlaggedCompleted(_questID) then
                            SaveWeekQuest(questName, _questID)
                            break
                        end
                    end
                end
            end
            for questID in pairs(permanentQuests) do
                if C_QuestLog.IsQuestFlaggedCompleted(questID) then
                    SavePermanentQuest(questID)
                end
            end
            UpdateDayQuestCount()
        end

        ZL.Init2(function()
            ZL.After(3, function()
                CheckQuestsCompleted()
                UpdateQuestEndTime()
            end)
        end)
        C_Timer.NewTicker(60, function()
            UpdateQuestEndTime()
        end)
    end

    -- 橙披

    BGLite_equip.ZL.buffCD = nil

    -- 专业技能CD
    do
        BGLite_equip.ZL.tradeSkillCooldown = BGLite_equip.ZL.tradeSkillCooldown or {}
        BGLite_equip.ZL.tradeSkillCooldown[realmID] = BGLite_equip.ZL.tradeSkillCooldown[realmID] or {}
        BGLite_equip.ZL.tradeSkillCooldown[realmID][ZL.myName] = BGLite_equip.ZL.tradeSkillCooldown[realmID][ZL.myName] or {}

        -- 无限服三件套：炼金转化 / 制皮筛盐（看筛盐器物品CD） / 裁缝洗布
        local tbl = {
            alchemy = {
                name = L["炼金转化"],
                name2 = L["炼金术"],
                skillLineID = 171,
                spell = 17187, -- 转化奥金
                icon = "Interface/Icons/trade_alchemy",
            },
            leatherworking = {
                name = L["制皮筛盐"],
                name2 = L["制皮"],
                skillLineID = 165,
                spell = 19566, -- 筛盐
                item = 15846,  -- 筛盐器
                icon = "Interface/Icons/trade_leatherworking",
            },
            tailor = {
                name = L["裁缝洗布"],
                name2 = L["裁缝"],
                skillLineID = 197,
                spell = 18560, -- 月布
                icon = "Interface/Icons/trade_tailoring",
            },
        }
        local FBCDchoice = BGLite_equip.ZL.FBCDchoice or {}
        for name in pairs(tbl) do
            if FBCDchoice["ignore_" .. name] == 1 then
                tbl[name] = nil
            end
        end
        for _, v in pairs(tbl) do
            if not v.icon then
                v.icon = C_Spell.GetSpellTexture(v.spell)
            end
        end
        ZL.professionCDInfo = tbl

        local myCD = BGLite_equip.ZL.tradeSkillCooldown[realmID][ZL.myName]
        local function GetCooldown()
            local time = GetServerTime()
            local getTime = GetTime()
            for profession, v in pairs(tbl) do
                local startTime, duration, cooldown
                if v.item and C_Item.GetItemCooldown then
                    startTime, duration = C_Item.GetItemCooldown(v.item)
                elseif ZL.IsNewUI then
                    local info = C_Spell.GetSpellCooldown(v.spell)
                    startTime = info and info.startTime
                    duration = info and info.duration
                else
                    startTime, duration = GetSpellCooldown(v.spell)
                end
                if not ZL.IsSecret(startTime) and not ZL.IsSecret(duration)
                    and startTime and duration and duration > 2 then
                    -- 服务器时间可能带 2^32 偏移，先换算成本地 GetTime 口径
                    startTime = startTime > getTime and (startTime - 2 ^ 32 / 1000) or startTime
                    cooldown = startTime + duration - getTime
                end
                if cooldown and cooldown > 0 then
                    myCD[profession] = {
                        class = select(2, UnitClass("player")),
                        resettime = cooldown,
                        endtime = cooldown + time,
                        ready = nil,
                    }
                end
            end
        end

        local pending
        local function Go()
            pending = nil
            GetCooldown()
        end
        local function QueueCooldownUpdate()
            if pending then return end
            pending = true
            ZL.After(1, Go)
        end
        ZL.RegisterEvent("BAG_UPDATE_COOLDOWN", QueueCooldownUpdate)
        ZL.RegisterEvent("PLAYER_REGEN_ENABLED", QueueCooldownUpdate)
        ZL.RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
            if InCombatLockdown() then return end
            QueueCooldownUpdate()
        end)

        -- 检查其他角色的CD是否到期
        local doneSound = "Interface\\AddOns\\" .. AddonName .. "\\Forever\\Media\\sound\\other\\done.mp3"
        local function UpdateProfessionCD()
            local time = GetServerTime()
            local delay = 3
            for _, dbName in pairs(dbNames) do
                local data = dbName == AddonName and BGLite_equip.ZL or _G[dbName]
                if data and data.tradeSkillCooldown then
                    for rid in pairs(data.tradeSkillCooldown) do
                        if type(rid) == "number" and type(data.tradeSkillCooldown[rid]) == "table" then
                            for player in pairs(data.tradeSkillCooldown[rid]) do
                                for profession, v in pairs(data.tradeSkillCooldown[rid][player]) do
                                    if v.endtime then
                                        if time >= v.endtime then
                                            v.resettime = nil
                                            v.endtime = nil
                                            v.ready = true
                                            -- 只提醒本账号：其他子账号的 endtime 删不掉，否则会重复提醒
                                            if dbName == AddonName and tbl[profession]
                                                and (BGLite_equip.ZL.FBCDchoice or {}).professionCD == 1 then
                                                local color
                                                if v.class then
                                                    color = select(4, GetClassColor(v.class))
                                                end
                                                local name = ZL.IsMe(rid, player) and L["我"] or player
                                                local colorName = color and "|c" .. color .. name .. "|r" or name
                                                local msg = ZL.STC_g1(format(L["%s：%s已就绪！"], colorName, tbl[profession].name))
                                                ZL.After(delay, function()
                                                    ZL.SendSystemMessage(msg)
                                                    local pack = BGLite_equip.options.Sound
                                                    if pack and BG and BG["sound_" .. profession .. "Ready" .. pack] then
                                                        BG.PlaySound(profession .. "Ready")
                                                    else
                                                        PlaySoundFile(doneSound, "Master")
                                                    end
                                                end)
                                                delay = delay + 3
                                            end
                                        elseif time < v.endtime then
                                            v.resettime = v.endtime - time
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 专业遗忘了就删掉对应CD记录
        local function CheckSkillIsForget()
            local first, second = GetProfessions()
            if not first and not second then return end
            local learned = {}
            for _, index in pairs({ first, second }) do
                local skillLineID = select(7, GetProfessionInfo(index))
                if not skillLineID or skillLineID <= 0 then return end
                learned[skillLineID] = true
            end
            for profession, v in pairs(tbl) do
                if not learned[v.skillLineID] then
                    myCD[profession] = nil
                end
            end
        end
        ZL.RegisterEvent("SKILL_LINES_CHANGED", function()
            ZL.After(2, CheckSkillIsForget)
        end)

        ZL.Init2(function()
            ZL.After(2, function()
                GetCooldown()
                UpdateProfessionCD()
            end)
        end)
        C_Timer.NewTicker(19, UpdateProfessionCD)
    end

    -- 专业技能点数
    local skillInfo = {
        [L["锻造"]] = { id = 164, icon = 136241, isMain = true },
        [L["工程学"]] = { id = 202, icon = 136243, isMain = true },
        [L["炼金术"]] = { id = 171, icon = 136240, isMain = true },
        [L["制皮"]] = { id = 165, icon = 133611, isMain = true },
        [L["裁缝"]] = { id = 197, icon = 136249, isMain = true },
        [L["附魔"]] = { id = 333, icon = 136244, isMain = true },
        [L["采矿"]] = { id = 186, icon = 136248, isMain = true },
        [L["草药学"]] = { id = 182, icon = 136065, isMain = true },
        [L["剥皮"]] = { id = 393, icon = 134366, isMain = true },
        [L["铭文"]] = { id = 773, icon = 237171, isMain = true },
        [L["珠宝加工"]] = { id = 755, icon = 134071, isMain = true },
        [L["考古学"]] = { id = 794, icon = 441139, isMain = nil },
        [L["钓鱼"]] = { id = 356, icon = 136245, isMain = nil },
        [L["烹饪"]] = { id = 185, icon = 133971, isMain = nil },
        [L["急救"]] = { id = 129, icon = 135966, isMain = nil },
    }
    local function UpdatetradeSkill()
        local profession1, profession2, archaeology, fishing, cooking = GetProfessions()
        local professionIndexes = { profession1, profession2, archaeology, fishing, cooking }
        local tbl = {}
        for _, professionIndex in pairs(professionIndexes) do
            local _, icon, rank, _, _, _, skillLine = GetProfessionInfo(professionIndex)
            if skillLine then
                tbl[skillLine] = {
                    level = rank,
                    icon = icon,
                    isMain = professionIndex == profession1 or professionIndex == profession2 or nil,
                }
            end
        end
        BGLite_equip.ZL[MONEY][realmID][ZL.myName].skill = tbl
    end

    ZL.Init2(function()
        UpdatetradeSkill()
    end)
    ZL.RegisterEvent("SKILL_LINES_CHANGED", UpdatetradeSkill)
    C_Timer.NewTicker(5, function()
        UpdatetradeSkill()
    end)

    -- 获取货币信息
    do
        function ZL.MONEYupdate()
            local tbl = {}
            tbl.player = ZL.myName
            tbl.colorplayer = SetClassCFF(ZL.myName, "player")
            tbl.skill = BGLite_equip.ZL[MONEY][realmID][ZL.myName].skill
            for i, v in ipairs(ZL.MONEYall_table) do
                if v.type == "money" then
                    tbl.money = floor(GetMoney() / 1e4)
                elseif v.type == "items" then
                    local itemsTbl = {}
                    for _, v in ipairs(v.ids) do
                        if type(v) == "table" then
                            local items = v
                            for _, itemID in ipairs(items) do
                                local count = GetItemCount(itemID, true)
                                if count and count > 0 then
                                    tinsert(itemsTbl, {
                                        id = itemID,
                                        count = count,
                                    })
                                    break
                                end
                            end
                        else
                            local itemID = v
                            local count = GetItemCount(itemID, true)
                            if count and count > 0 then
                                tinsert(itemsTbl, {
                                    id = itemID,
                                    count = count,
                                })
                            end
                        end
                    end
                    tbl[v.id] = itemsTbl
                elseif v.type == "item" then
                    local id = v.id
                    local tex = v.tex
                    if v.quest2 and not C_QuestLog.IsQuestFlaggedCompleted(v.quest2) then
                        id = v.id2
                        tex = v.tex2
                    end
                    local count
                    if v.id_gold and v.id_copper then
                        count = GetItemCount(v.id_gold, true) * 100 + GetItemCount(v.id, true) + floor(GetItemCount(v.id_copper, true) / 100)
                    else
                        count = GetItemCount(id, true)
                    end
                    local questsCompleted
                    if v.quest and C_QuestLog.IsQuestFlaggedCompleted(v.quest) then
                        questsCompleted = true
                    end
                    tbl[v.id] = { count = count, tex = tex, isItem = true, quest = questsCompleted, }
                elseif v.type == "xp" then
                    tbl.xp = BGLite_equip.ZL[MONEY][realmID][ZL.myName].xp
                elseif v.type ~= "equip" and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                    local info = C_CurrencyInfo.GetCurrencyInfo(v.id)
                    if info then
                        local count = info.quantity
                        local tex = info.iconFileID
                        tbl[v.id] = {
                            count = count,
                            tex = tex,
                        }
                        local weekMax = info.maxWeeklyQuantity
                        if weekMax and weekMax > 0 then
                            local weekCount = info.quantityEarnedThisWeek
                            tbl[v.id].weekCount = weekCount
                            tbl[v.id].weekMax = weekMax
                            if weekCount >= weekMax then
                                tbl[v.id].weekTimestamp = select(2, ZL.GetNextWeekTime())
                            end
                        end
                        local totalMax = info.maxQuantity
                        if totalMax and totalMax > 0 then
                            if info.useTotalEarnedForMaxQty then
                                local totalCount = info.totalEarned
                                tbl[v.id].totalCount = totalCount
                                tbl[v.id].totalMax = totalMax
                                if totalCount >= totalMax then
                                    tbl[v.id].weekTimestamp = select(2, ZL.GetNextWeekTime())
                                end
                            else
                                if count >= totalMax then
                                    tbl[v.id].isFull = true
                                end
                            end
                        end
                    end
                end
            end
            BGLite_equip.ZL[MONEY][realmID][ZL.myName] = tbl
        end

        local function UpdateCD()
            local time = GetServerTime()
            for _, db in ipairs(dbNames) do
                if _G[db] and _G[db][MONEY] then
                    for realmID in pairs(_G[db][MONEY]) do
                        if type(realmID) == "number" and type(_G[db][MONEY][realmID]) == "table" then
                            for player in pairs(_G[db][MONEY][realmID]) do
                                for id, v in pairs(_G[db][MONEY][realmID][player]) do
                                    if type(v) == "table" and v.weekTimestamp and time >= v.weekTimestamp then
                                        _G[db][MONEY][realmID][player][id].weekTimestamp = nil
                                        if v.weekCount then
                                            _G[db][MONEY][realmID][player][id].weekCount = 0
                                        end
                                        if v.totalMax then
                                            _G[db][MONEY][realmID][player][id].totalMax = 0
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- 事件
        ZL.Init2(function()
            UpdateCD()
            C_Timer.After(0.5, ZL.MONEYupdate)
        end)
        ZL.RegisterEvent({ "CURRENCY_DISPLAY_UPDATE", "PLAYER_MONEY", "BAG_UPDATE_DELAYED" }, function()
            C_Timer.After(0.5, ZL.MONEYupdate)
        end)
    end

    -- 获取双倍经验
    do
        -- 创建插件框架
        local race = select(2, UnitRace("player"))
        local isPanda = race == "Pandaren"
        local function UpdateXP()
            local exhaustion = GetXPExhaustion() -- 获取剩余双倍经验值
            local per = 0
            if exhaustion then
                local maxXP = UnitXPMax("player")
                per = exhaustion / maxXP * 100
            end
            BGLite_equip.ZL[MONEY][realmID][ZL.myName].xp = {
                per = format("%.1f", per),
                perNow = format("%d", per),
                time = GetServerTime(),
                resting = IsResting(),
                isPanda = isPanda,
            }
        end
        ZL.Init2(UpdateXP)
        ZL.RegisterEvent({ "PLAYER_XP_UPDATE", "UPDATE_EXHAUSTION", "PLAYER_LEVEL_UP", "PLAYER_UPDATE_RESTING" }, UpdateXP)

        function ZL.UpdateXP()
            local time = GetServerTime()
            local function Update(db)
                if not (db and db[MONEY]) then return end
                for realmID, v in pairs(db[MONEY]) do
                    if (type(realmID) == "number" and type(db[MONEY][realmID]) == "table") then
                        for player, v in pairs(db[MONEY][realmID]) do
                            if type(v.xp) == "table" then
                                local num = 4
                                if v.xp.resting then
                                    num = 1
                                end
                                local panda = 1
                                if v.xp.isPanda then
                                    panda = 0.5
                                end
                                v.xp.perNow = min(150, format("%d", tonumber(v.xp.per) + (time - v.xp.time) / (60 * 60 * 8 * num * panda) * 5))
                            end
                        end
                    end
                end
            end
            Update(BGLite_equip.ZL)
            Update(MultiAccountDB)
        end
    end

    -- 角色装备和装等
    do
        BGLite_equip.ZL.equip = BGLite_equip.ZL.equip or {}
        BGLite_equip.ZL.equip[realmID] = BGLite_equip.ZL.equip[realmID] or {}
        BGLite_equip.ZL.equip[realmID][ZL.myName] = BGLite_equip.ZL.equip[realmID][ZL.myName] or {}

        local ItemLevelPattern = gsub(ITEM_LEVEL, "%%d", "(%%d+)")
        local function GetItemLevelByTooltip(slot, link)
            ZLTooltip:SetOwner(UIParent, "ANCHOR_NONE")
            ZLTooltip:SetInventoryItem("player", slot)
            local text, level
            for i = 2, 5 do
                if _G[ZLTooltip:GetName() .. "TextLeft" .. i] then
                    text = _G[ZLTooltip:GetName() .. "TextLeft" .. i]:GetText() or ""
                    level = string.match(text, ItemLevelPattern)
                    if level then
                        return tonumber(level)
                    end
                end
            end
            level = select(4, GetItemInfo(link)) or 0
            return level
        end

        function ZL.GetPlayerEquip()
            local tbl = BGLite_equip.ZL.equip[realmID][ZL.myName]
            wipe(tbl)
            for slot = 1, 19 do
                local link = GetInventoryItemLink("player", slot)
                if link then
                    local itemID = GetInventoryItemID("player", slot)
                    local quality = GetInventoryItemQuality("player", slot)
                    local level
                    level = select(4, GetItemInfo(link))
                    slot = tostring(slot)
                    tbl[slot] = {
                        link = link,
                        itemID = itemID,
                        quality = quality,
                        level = level,
                    }
                end
            end
        end

        local function GetPlayerAverageItemLevel()
            local _, avgLevel = GetAverageItemLevel()
            BGLite_equip.ZL.playerInfo[realmID][ZL.myName].iLevel = avgLevel or 0
        end

        local delay
        local again
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_ENTERING_WORLD" then
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
                delay = 3
                again = true
                ZL.After(delay, function()
                    self:RegisterEvent("UNIT_INVENTORY_CHANGED")
                end)
            else
                delay = 1
            end
            self.t = 0
            self:SetScript("OnUpdate", function(_, t)
                self.t = self.t + t
                if self.t > delay then
                    self:SetScript("OnUpdate", nil)
                    ZL.GetPlayerEquip()
                    GetPlayerAverageItemLevel()
                    if again then
                        again = nil
                        ZL.After(5, function()
                            ZL.GetPlayerEquip()
                            GetPlayerAverageItemLevel()
                        end)
                    end
                end
            end)
        end)
    end

    -- 背包
    do
        BGLite_equip.ZL.bag = BGLite_equip.ZL.bag or {}
        BGLite_equip.ZL.bag[realmID] = BGLite_equip.ZL.bag[realmID] or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName] = BGLite_equip.ZL.bag[realmID][ZL.myName] or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName].bag = BGLite_equip.ZL.bag[realmID][ZL.myName].bag or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName].bagKey = BGLite_equip.ZL.bag[realmID][ZL.myName].bagKey or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName].bank = BGLite_equip.ZL.bag[realmID][ZL.myName].bank or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName].bagLink = BGLite_equip.ZL.bag[realmID][ZL.myName].bagLink or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName].bagKeyLink = BGLite_equip.ZL.bag[realmID][ZL.myName].bagKeyLink or {}
        BGLite_equip.ZL.bag[realmID][ZL.myName].bankLink = BGLite_equip.ZL.bag[realmID][ZL.myName].bankLink or {}

        local function GetBagSlots(bagType)
            if bagType == "bag" then
                do
                    return BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS
                end
            elseif bagType == "bank" then
                do
                    return NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS
                end
            end
        end

        local function SaveFromBagNum(bag, bagType)
            for slot = 1, C_Container.GetContainerNumSlots(bag) do
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info then
                    BGLite_equip.ZL.bag[realmID][ZL.myName][bagType][info.itemID] =
                        (BGLite_equip.ZL.bag[realmID][ZL.myName][bagType][info.itemID] or 0) + info.stackCount
                    local link = info.hyperlink
                    if not link and C_Container.GetContainerItemLink then
                        link = C_Container.GetContainerItemLink(bag, slot)
                    end
                    if link then
                        local linkType = bagType .. "Link"
                        local oldInfo = BGLite_equip.ZL.bag[realmID][ZL.myName][linkType][link]
                        local oldCount = type(oldInfo) == "table" and oldInfo.count or tonumber(oldInfo) or 0
                        local maxStack = select(8, GetItemInfo(link))
                        BGLite_equip.ZL.bag[realmID][ZL.myName][linkType][link] = {
                            count = oldCount + info.stackCount,
                            stackable = (type(oldInfo) == "table" and oldInfo.stackable)
                                or info.stackCount > 1 or (maxStack and maxStack > 1) or nil,
                        }
                    end
                end
            end
        end

        function ZL.SaveBag()
            wipe(BGLite_equip.ZL.bag[realmID][ZL.myName].bag)
            wipe(BGLite_equip.ZL.bag[realmID][ZL.myName].bagKey)
            wipe(BGLite_equip.ZL.bag[realmID][ZL.myName].bagLink)
            wipe(BGLite_equip.ZL.bag[realmID][ZL.myName].bagKeyLink)
            local startBag, endBag = GetBagSlots("bag")
            for bag = startBag, endBag do
                SaveFromBagNum(bag, "bag")
            end
            SaveFromBagNum(-2, "bagKey")
        end

        function ZL.SaveBank()
            if ZL.IsNewUI then return end
            if not ZL.bankIsOpen then return end
            wipe(BGLite_equip.ZL.bag[realmID][ZL.myName].bank)
            wipe(BGLite_equip.ZL.bag[realmID][ZL.myName].bankLink)
            local startBag, endBag = GetBagSlots("bank")
            for bag = startBag, endBag do
                SaveFromBagNum(bag, "bank")
            end
            SaveFromBagNum(-1, "bank")
        end

        function ZL.GetItemBagCount(tbl, itemID)
            return (tbl.bag and tbl.bag[itemID] or 0)
                + (tbl.bagKey and tbl.bagKey[itemID] or 0)
                + (tbl.bank and tbl.bank[itemID] or 0)
        end

        ZL.RegisterEvent("BAG_UPDATE_DELAYED", function()
            ZL.SaveBag()
            ZL.SaveBank()
        end)
        ZL.RegisterEvent("BANKFRAME_OPENED", function()
            ZL.bankIsOpen = true
            ZL.SaveBank()
        end)
        ZL.RegisterEvent("BANKFRAME_CLOSED", function()
            ZL.bankIsOpen = false
        end)
    end

    -- 声望
    BGLite_equip.ZL.bag[realmID][ZL.myName].faction = BGLite_equip.ZL.bag[realmID][ZL.myName].faction or {}

    local function SaveReputation()
        for _, factionID in ipairs(ZL.factionTbl) do
            local name, standingID, barMin, barMax, barValue
            local factionData = C_Reputation.GetFactionDataByID(factionID)
            if factionData then
                name = factionData.name
                standingID = factionData.reaction
                barMin = factionData.currentReactionThreshold
                barMax = factionData.nextReactionThreshold
                barValue = factionData.currentStanding
            end
            if name then
                BGLite_equip.ZL.bag[realmID][ZL.myName].faction[factionID] = {
                    name = name,
                    standingID = standingID,
                    currentValue = barValue - barMin,
                    maxValue = barMax - barMin,
                    factionID = factionID,
                }
            end
        end
    end

    ZL.Init2(function()
        ZL.After(10, function()
            SaveReputation()
        end)
    end)

    ZL.RegisterEvent("UPDATE_FACTION", function()
        ZL.After(.5, function()
            SaveReputation()
        end)
    end)

    -- 删除重复角色装备数据
    for realmID, v in pairs(BGLite_equip.ZL.equip) do
        if type(realmID) == "number" and type(v) == "table" then
            if BGLite_equip.ZL.playerInfo[realmID] then
                for player in pairs(BGLite_equip.ZL.equip[realmID]) do
                    if not BGLite_equip.ZL.playerInfo[realmID][player] then
                        BGLite_equip.ZL.equip[realmID][player] = nil
                    end
                end
            else
                BGLite_equip.ZL.equip[realmID] = nil
            end
        end
    end
end)
