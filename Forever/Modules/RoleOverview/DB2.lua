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

ZL.Init(function()
    BGLite_equip.ZL[FBCD] = BGLite_equip.ZL[FBCD] or {}
    BGLite_equip.ZL[FBCD][realmID] = BGLite_equip.ZL[FBCD][realmID] or {}

    BGLite_equip.ZL[MONEY] = BGLite_equip.ZL[MONEY] or {}
    BGLite_equip.ZL[MONEY][realmID] = BGLite_equip.ZL[MONEY][realmID] or {}
    BGLite_equip.ZL[MONEY][realmID][ZL.myName] = BGLite_equip.ZL[MONEY][realmID][ZL.myName] or {}

    BGLite_equip.ZL.roleOverviewNote = BGLite_equip.ZL.roleOverviewNote or {}
    BGLite_equip.ZL.roleOverviewNote[realmID] = BGLite_equip.ZL.roleOverviewNote[realmID] or {}

    -- 选择初始化
    if not BGLite_equip.ZL.FBCDchoice then
        BGLite_equip.ZL.FBCDchoice = {}
        ZL.Once("FBCDchoice", 260918, function()
            BGLite_equip.ZL.FBCDchoice.OLforever = 1
            BGLite_equip.ZL.FBCDchoice.HSforever = 1
            BGLite_equip.ZL.FBCDchoice.BDforever = 1
            for i, id in ipairs({ 2586, 2587, 2740, }) do
                BGLite_equip.ZL.FBCDchoice["faction" .. id] = 1
            end
        end)
    end
    if not BGLite_equip.ZL.MONEYchoice then
        BGLite_equip.ZL.MONEYchoice = {}
        BGLite_equip.ZL.MONEYchoice["money"] = 1
    end
    if not BGLite_equip.ZL.SKILLchoice then
        BGLite_equip.ZL.SKILLchoice = {}
        BGLite_equip.ZL.SKILLchoice[0] = true
    end

    -- 更新
    do
        ZL.Once("MONEYchoice", 260918, function()
            for i, id in ipairs({ 3469, 3402, 1792, }) do
                BGLite_equip.ZL.MONEYchoice[id] = 1
            end
        end)

        -- 默认勾选饰品和武器
        ZL.Once("MONEYchoice", 260731, function()
            BGLite_equip.ZL.MONEYchoice.trinkets = 1
        end)
        ZL.Once("MONEYchoice", 260818, function()
            BGLite_equip.ZL.MONEYchoice.weapons = 1
        end)
    end

    -- 时光服橙武
    local ids, ids_updateItem

    -- 基础数据初始化
    do
        ZL.factionTbl = {}
        ZL.FBCDall_table = {
            { name = 'OLforever', name2 = L['奥妮克希亚'], color = "00BFFF", fbId = 249, type = "fb" },
            { name = 'HSforever', name2 = L['海加尔峰'], color = "00BFFF", fbId = -100, type = "fb" },
            { name = 'BDforever', name2 = L['深穴'], color = "00BFFF", fbId = -100, type = "fb" },
        }
        ZL.FBCount = #ZL.FBCDall_table

        ZL.MONEYall_table = {
            { name = L["双倍经验"], color = "99ff99", type = "xp", id = "xp", tex = 1080931, width = 70 }, -- 双倍经验
            { color = "ffffff", id = 3469, width = 70 }, -- 褪色的安德麦雷亚尔
            { color = "ffffff", id = 3402, width = 70 }, -- 商人青睐
            { color = "ffffff", id = 1792, width = 70 }, -- 荣誉点数
            { color = "ffffff", id = 3468, width = 70 }, -- 等级点数
            { color = "ffffff", id = 515, width = 70 }, -- 暗月奖券
            { name = L["金币"], color = "FFD700", type = "money", id = "money", tex = 237618, width = 80 }, -- 金币
        }

        -- 声望
        ZL.factionTbl = {
            -- 1077, -- 破碎残阳
        }
        tinsert(ZL.factionTbl, 1, ZL.IsAlliance and 2586 or 2587) -- 贸易局
        if ZL.IsAlliance then
            tinsert(ZL.factionTbl, 2740)                          -- 肯瑞托
        end
        for _, id in ipairs(ZL.factionTbl) do
            local name3
            tinsert(ZL.FBCDall_table, {
                name = "faction" .. id,
                name2 = C_Reputation.GetFactionDataByID(id).name,
                name3 = name3,
                id = id,
                color = "FFFF00",
                type = "faction"
            })
        end

        local trinkets = {
            name = L["饰品"],
            color = "C084FC",
            type = "equip",
            id = "trinkets",
            tex = 136115,
            -- tex = 237274,
            width = 55,
        }
        local weapons = {
            name = L["武器"],
            color = "C084FC",
            type = "equip",
            id = "weapons",
            tex = 132402,
            width = 55,
        }
        tinsert(ZL.MONEYall_table, 2, trinkets)
        tinsert(ZL.MONEYall_table, 2, weapons)

        for i, v in ipairs(ZL.MONEYall_table) do
            if not v.type and type(v.id) == "number" then
                local info = C_CurrencyInfo.GetCurrencyInfo(v.id)
                if info then
                    ZL.MONEYall_table[i].name = info.name
                    ZL.MONEYall_table[i].tex = info.iconFileID
                    ZL.MONEYall_table[i].type = "currency"
                end
            end
        end

        local fuc = C_TradeSkillUI.GetTradeSkillDisplayName
        local color = "ADFF2F"
        -- local color = "FF99FF"
        -- local color = "F48CBA"

        ZL.SKILLall_table = {
            { name = "main", id = 0, name2 = L["主专业"], color = color, type = "skill", tex = "", width = 110 }, -- 主专业
            { name = "fish", id = 356, name2 = fuc(356), color = color, type = "skill", tex = 136245, width = 60 }, -- 钓鱼
            { name = "cook", id = 185, name2 = fuc(185), color = color, type = "skill", tex = 133971, width = 60 }, -- 烹饪
            { name = "heal", id = 129, name2 = fuc(129), color = color, type = "skill", tex = 135966, width = 60 }, -- 急救
        }
    end

    -- 爆发药水与合剂
    do
        local presetPotionIDs, presetFlaskIDs
        presetFlaskIDs = {
            13510, -- 泰坦合剂
            13511, -- 精炼智慧合剂
            13512, -- 超级能量合剂
            13513, -- 多重抗性合剂
        }
        ns.presetPotionIDs = presetPotionIDs
        ns.presetFlaskIDs = presetFlaskIDs
    end
end)
