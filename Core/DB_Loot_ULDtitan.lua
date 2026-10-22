if not BG.IsTitan then return end

local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local pt = print

-- 副本掉落
do
    local FB = "ULDtitan"

    BG.Loot[FB].N.Quest[""] = { 46017, 287189 }
end

do
    local FB = "ULDtitan"
    local bossLoot = BG.Loot[FB] and BG.Loot[FB].N

    local function AddLoot(boss, ...)
        local t = bossLoot and bossLoot["boss" .. boss]
        if type(t) ~= "table" then return end
        for _, id in ipairs({ ... }) do
            local haved
            for _, v in ipairs(t) do
                if v == id then
                    haved = true
                    break
                end
            end
            if not haved then tinsert(t, id) end
        end
    end

    AddLoot(1, 45283)
    AddLoot(2, 45298)
    AddLoot(3, 45316)
    AddLoot(4, 45675, 45679, 45680)
    AddLoot(5, 45324, 45333, 45607)
    AddLoot(7, 45864)
    AddLoot(8, 45458, 45612, 45873)
    AddLoot(9, 45570, 45893, 45894)
    AddLoot(10, 45613, 45935, 45940)
    AddLoot(11, 45620, 45972, 45976)
    AddLoot(12, 45996, 46008)
    AddLoot(14, 46053)
    AddLoot(15, 34057)
end

-- 兑换产物补全
do
    local FB = "ULDtitan"
    local loot = BG.Loot[FB]
    local bossLoot = loot and loot.N

    local function AddOther(boss, ...)
        local t = bossLoot and bossLoot["boss" .. boss .. "other"]
        if type(t) ~= "table" then return end
        for _, id in ipairs({ ... }) do
            local haved
            for _, v in ipairs(t) do
                if v == id then
                    haved = true
                    break
                end
            end
            if not haved then tinsert(t, id) end
        end
    end

    AddOther(8, 46111, 46118)
    AddOther(9, 46115, 46120)
    AddOther(10, 46116, 46121)
    AddOther(11, 46113, 46119)
    AddOther(13, 46117, 46122)
    AddOther(14, 45588, 45618, 45608, 45614)

    -- 回复代码阿尔法（奥尔加隆奖励四选一）的兑换映射，补官方缺失，
    -- 使装备库心愿能像套装一样换算到兑换物
    if type(loot.ExchangeItems) == "table" and type(loot.ExchangeItems[46053]) ~= "table" then
        loot.ExchangeItems[46053] = { 45588, 45618, 45608, 45614 }
    end

    if type(loot.ExchangeItems) == "table" and type(loot.ExchangeItems[270187]) == "table" then
        local haved
        for _, v in ipairs(loot.ExchangeItems[270187]) do
            if v == 287189 then
                haved = true
                break
            end
        end
        if not haved then tinsert(loot.ExchangeItems[270187], 287189) end
        AddOther(15, 287189)
    end
end

do
    local blacklist = BG.Loot.blacklist
    local stackItems = BG.Loot.stackItems
    local noStackItems = BG.Loot.noStackItems
    if type(blacklist) == "table" then
        blacklist[45038] = true
        blacklist[45039] = true
    end
    if type(stackItems) == "table" then
        stackItems[45087] = true
        stackItems[270187] = true
    end
    if type(noStackItems) == "table" then
        noStackItems[45087] = nil
    end
end

-- 牌子装备
do
    local function AddCurrency(FB, currencyID, itemID, count)
        BG.Loot[FB].Currency[itemID] = { count = count, currencyID = currencyID }
    end

    local FB = "ULDtitan"

    AddCurrency(FB, 3403, 45270, 19)
    AddCurrency(FB, 3403, 46138, 19)
    AddCurrency(FB, 3403, 45114, 19)
    AddCurrency(FB, 3403, 45255, 19)
    AddCurrency(FB, 3403, 45169, 19)
    AddCurrency(FB, 3403, 45510, 19)
    AddCurrency(FB, 3403, 45436, 19)
    AddCurrency(FB, 3403, 45145, 19)
    AddCurrency(FB, 3403, 45144, 19)
    AddCurrency(FB, 3403, 45254, 19)
    AddCurrency(FB, 3403, 45509, 19)
    AddCurrency(FB, 3403, 45819, 19)
    AddCurrency(FB, 3403, 45820, 19)
    AddCurrency(FB, 3403, 45821, 19)
    AddCurrency(FB, 3403, 45822, 19)
    AddCurrency(FB, 3403, 45823, 19)
    AddCurrency(FB, 3403, 45824, 28)
    AddCurrency(FB, 3403, 45825, 28)
    AddCurrency(FB, 3403, 45826, 28)
    AddCurrency(FB, 3403, 45827, 28)
    AddCurrency(FB, 3403, 45828, 28)
    AddCurrency(FB, 3403, 45829, 28)
    AddCurrency(FB, 3403, 45830, 28)
    AddCurrency(FB, 3403, 45831, 28)
    AddCurrency(FB, 3403, 45833, 28)
    AddCurrency(FB, 3403, 45834, 28)
    AddCurrency(FB, 3403, 45835, 28)
    AddCurrency(FB, 3403, 45836, 28)
    AddCurrency(FB, 3403, 45837, 28)
    AddCurrency(FB, 3403, 45838, 28)
    AddCurrency(FB, 3403, 45839, 28)
    AddCurrency(FB, 3403, 45840, 28)
    AddCurrency(FB, 3403, 45841, 39)
    AddCurrency(FB, 3403, 45842, 39)
    AddCurrency(FB, 3403, 45843, 39)
    AddCurrency(FB, 3403, 45844, 39)
    AddCurrency(FB, 3403, 45845, 39)
    AddCurrency(FB, 3403, 45846, 39)
    AddCurrency(FB, 3403, 45847, 39)
    AddCurrency(FB, 3403, 45848, 39)
    AddCurrency(FB, 3403, 45294, 15)
    AddCurrency(FB, 3403, 45296, 15)
    AddCurrency(FB, 3403, 45448, 25)
    AddCurrency(FB, 3403, 45449, 25)
    AddCurrency(FB, 3403, 45868, 38)
    AddCurrency(FB, 3403, 45870, 38)
    AddCurrency(FB, 3403, 45876, 25)
    AddCurrency(FB, 3403, 45877, 25)
    AddCurrency(FB, 3403, 45886, 38)
    AddCurrency(FB, 3403, 45887, 25)
    AddCurrency(FB, 3403, 45930, 25)
    AddCurrency(FB, 3403, 45947, 25)
    AddCurrency(FB, 3403, 45990, 38)
    AddCurrency(FB, 3403, 46033, 38)
    AddCurrency(FB, 3403, 46035, 38)
    AddCurrency(FB, 3403, 46036, 25)
    AddCurrency(FB, 3403, 46067, 38)
    AddCurrency(FB, 3403, 46097, 25)
    AddCurrency(FB, 3403, 45293, 19)
    AddCurrency(FB, 3403, 45295, 25)
    AddCurrency(FB, 3403, 45297, 15)
    AddCurrency(FB, 3403, 45300, 19)
    AddCurrency(FB, 3403, 45447, 15)
    AddCurrency(FB, 3403, 45455, 19)
    AddCurrency(FB, 3403, 45456, 15)
    AddCurrency(FB, 3403, 45867, 25)
    AddCurrency(FB, 3403, 45869, 15)
    AddCurrency(FB, 3403, 45871, 15)
    AddCurrency(FB, 3403, 45888, 15)
    AddCurrency(FB, 3403, 45928, 19)
    AddCurrency(FB, 3403, 45929, 19)
    AddCurrency(FB, 3403, 45931, 19)
    AddCurrency(FB, 3403, 45933, 15)
    AddCurrency(FB, 3403, 45943, 19)
    AddCurrency(FB, 3403, 45945, 15)
    AddCurrency(FB, 3403, 45946, 15)
    AddCurrency(FB, 3403, 45982, 25)
    AddCurrency(FB, 3403, 45988, 19)
    AddCurrency(FB, 3403, 45989, 19)
    AddCurrency(FB, 3403, 45993, 25)
    AddCurrency(FB, 3403, 46032, 15)
    AddCurrency(FB, 3403, 46034, 25)
    AddCurrency(FB, 3403, 46037, 24)
    AddCurrency(FB, 3403, 46038, 24)
    AddCurrency(FB, 3403, 46039, 32)
    AddCurrency(FB, 3403, 46040, 19)
    AddCurrency(FB, 3403, 46041, 24)
    AddCurrency(FB, 3403, 46042, 19)
    AddCurrency(FB, 3403, 46043, 24)
    AddCurrency(FB, 3403, 46044, 24)
    AddCurrency(FB, 3403, 46045, 24)
    AddCurrency(FB, 3403, 46046, 19)
    AddCurrency(FB, 3403, 46047, 19)
    AddCurrency(FB, 3403, 46048, 19)
    AddCurrency(FB, 3403, 46049, 32)
    AddCurrency(FB, 3403, 46050, 24)
    AddCurrency(FB, 3403, 46051, 24)
    AddCurrency(FB, 3403, 46068, 19)
    AddCurrency(FB, 3403, 46095, 19)
    AddCurrency(FB, 3403, 46096, 15)
    AddCurrency(FB, 3403, 45133, 60)
    AddCurrency(FB, 3403, 45242, 60)
    AddCurrency(FB, 3403, 45243, 60)
    AddCurrency(FB, 3403, 45443, 60)
    AddCurrency(FB, 3403, 45459, 60)
    AddCurrency(FB, 3403, 45461, 60)
    AddCurrency(FB, 3403, 45471, 60)
    AddCurrency(FB, 3403, 45485, 60)
    AddCurrency(FB, 3403, 45486, 60)
    AddCurrency(FB, 3403, 45495, 60)
    AddCurrency(FB, 3403, 45496, 60)
    AddCurrency(FB, 3403, 45517, 60)
    AddCurrency(FB, 3403, 45518, 60)
    AddCurrency(FB, 3403, 45534, 60)
    AddCurrency(FB, 3403, 45535, 60)
    AddCurrency(FB, 3403, 45609, 60)
end

-- 专业制造
do
    local FB = "ULDtitan"
    BG.Loot[FB].Profession = {
        ["锻造"] = { 45561, 45560, 45552, 45551, 45550, 45559, },
        ["制皮"] = { 45563, 45564, 45555, 45565, 45562, 45554, 45553, 45556, },
        ["裁缝"] = { 45566, 45567, 45557, 45558, },
    }
end
