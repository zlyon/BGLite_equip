if not BG.IsForever then return end

local _, ns = ...

local GetItemInfo = GetItemInfo or C_Item.GetItemInfo

local LibBG = ns.LibBG
local L = ns.L

local Size = ns.Size
local ClassQuest = ns.ClassQuest
local RR = ns.RR
local NN = ns.NN
local RN = ns.RN

local pt = print

local _, classFilename, classID = UnitClass("player")
--[[
1	Warrior	WARRIOR	
2	Paladin	PALADIN	
3	Hunter	HUNTER	
4	Rogue	ROGUE	
5	Priest	PRIEST	
6	Death Knight	DEATHKNIGHT
7	Shaman	SHAMAN	
8	Mage	MAGE	
9	Warlock	WARLOCK	
10	Monk	MONK
11	Druid	DRUID	
]]

-- 副本掉落
do
    -- P1
    do
        local FB = "UBRSforever"
        do
            BG.Loot[FB].N.boss1 = { 16672, 12929, 12927, 12905, 12926, 23320 }
            BG.Loot[FB].N.boss2 = { 12590, 16733, 12587, 12936, 18104, 12935, 18102, 22247, 18103, 12940, 12939, 12583, 12871, 16669, 22225, 12960, 12953, 12952, 13522, }
            BG.Loot[FB].N.boss3 = { 16729, 12967, 12968, 12966, 12965, 12963, 12964, 22311, 12709, 12969, 24101, 19227 }
            BG.Loot[FB].N.boss4 = { 12592, 22267, 13141, 22269, 13142, 13098, 22268, 22253, 12602, 15730, 13519, 16690, 16688, 16700, 16721, 16706, 16674, 16666, 16726, 16730 }
            BG.Loot[FB].N.boss5 = { 22302, 22340, 22337, 22343, 22342, 22339, 22336, 22335, }
            BG.Loot[FB].N.boss6 = {
                -- 小怪
                24102, 13260, 16696, 16683, 16703, 16713, 16681, 16680, 16673, 16735, 16247,
                -- 索拉卡・火冠
                16695, 12609, 12603, 12589, 12606, 18657,
                -- 杰德
                12604, 12930, 12605,
                -- 古拉鲁克
                13502, 13498, 18047, 18048, 12834, 12837, 18779, 12806, 12696,
            }
            for b = 1, 5 do
                BG.Loot[FB].N["boss" .. b .. "other"] = {}
            end
        end

        local FB = "BDforever"
        do
            BG.Loot[FB].N.boss1 = {}
            BG.Loot[FB].N.boss2 = {}
            BG.Loot[FB].N.boss3 = {}
            BG.Loot[FB].N.boss4 = {}
            BG.Loot[FB].N.boss5 = {}
            BG.Loot[FB].N.boss6 = {}
            BG.Loot[FB].N.boss7 = {}
            BG.Loot[FB].N.boss8 = {}
            BG.Loot[FB].N.boss1other = {}
            BG.Loot[FB].N.boss2other = {}
            BG.Loot[FB].N.boss3other = {}
            BG.Loot[FB].N.boss4other = {}
            BG.Loot[FB].N.boss5other = {}
            BG.Loot[FB].N.boss6other = {}
            BG.Loot[FB].N.boss7other = {}
            BG.Loot[FB].N.boss8other = {}
        end

        local FB = "HSforever"
        do
            BG.Loot[FB].N.boss1 = {}
            BG.Loot[FB].N.boss2 = {}
            BG.Loot[FB].N.boss3 = {}
            BG.Loot[FB].N.boss4 = {}
            BG.Loot[FB].N.boss5 = {}
            BG.Loot[FB].N.boss6 = {}
            BG.Loot[FB].N.boss7 = {}
            BG.Loot[FB].N.boss8 = {}
            BG.Loot[FB].N.boss9 = {}
            BG.Loot[FB].N.boss10 = {}
            BG.Loot[FB].N.boss11 = {}
            BG.Loot[FB].N.boss12 = {}
            BG.Loot[FB].N.boss13 = {}
            BG.Loot[FB].N.boss1other = {}
            BG.Loot[FB].N.boss2other = {}
            BG.Loot[FB].N.boss3other = {}
            BG.Loot[FB].N.boss4other = {}
            BG.Loot[FB].N.boss5other = {}
            BG.Loot[FB].N.boss6other = {}
            BG.Loot[FB].N.boss7other = {}
            BG.Loot[FB].N.boss8other = {}
            BG.Loot[FB].N.boss9other = {}
            BG.Loot[FB].N.boss10other = {}
            BG.Loot[FB].N.boss11other = {}
            BG.Loot[FB].N.boss12other = {}
            BG.Loot[FB].N.boss13other = {}
        end

        local FB = "OLforever"
        do
            BG.Loot[FB].N.boss1 = {}
            BG.Loot[FB].N.boss1other = {}
        end
    end
end

-- 声望装备
do
    -- P1
    do
        local FB = "BDforever"
    end
end

-- PVP
do
    -- P1
    do
        local FB = "BDforever"
    end
end

-- 专业制造
do
    -- P1
    local FB = "BDforever"
    BG.Loot[FB].Profession = {
        ["锻造"] = {},
        ["制皮"] = {},
        ["裁缝"] = {},
    }
end

-- 世界掉落
do
    -- P1
    local FB = "BDforever"
    BG.Loot[FB].World = {}
end

-- 货币
do
    -- 赛季服货币/牌子
    local function AddDB(FB, get, itemID, count, coin, color, type)
        if type then
            GetItemInfo(count)
        end

        get = get or ""
        count = count or ""
        coin = coin or ""
        type = type or ""

        tinsert(BG.Loot[FB].Sod_Currency, {
            [itemID] = get .. "-" .. count .. "-" .. coin .. "-" .. color .. "-" .. type
        })
    end
end

-- 模板
--[[
    local FB = "BWLsod"
    do
        BG.Loot[FB].N.boss1 = { }
        BG.Loot[FB].N.boss2 = { }
        BG.Loot[FB].N.boss3 = { }
        BG.Loot[FB].N.boss4 = { }
        BG.Loot[FB].N.boss5 = { }
        BG.Loot[FB].N.boss6 = { }
        BG.Loot[FB].N.boss7 = { }
        BG.Loot[FB].N.boss8 = { }
        BG.Loot[FB].N.boss9 = { }
        BG.Loot[FB].N.boss10 = { }
        BG.Loot[FB].N.boss1other = { }
        BG.Loot[FB].N.boss2other = { }
        BG.Loot[FB].N.boss3other = { }
        BG.Loot[FB].N.boss4other = { }
        BG.Loot[FB].N.boss5other = { }
        BG.Loot[FB].N.boss6other = { }
        BG.Loot[FB].N.boss7other = { }
        BG.Loot[FB].N.boss8other = { }
        BG.Loot[FB].N.boss9other = { }
        BG.Loot[FB].N.boss10other = { }
        -- 兑换物
        BG.Loot[FB].ExchangeItems = {
            -- [ ] = {  },
            -- [ ] = {  },
            -- [ ] = {  },
        }

    end
]]
