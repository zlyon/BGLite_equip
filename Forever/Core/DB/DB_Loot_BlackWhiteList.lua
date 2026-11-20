local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local pt = print

BG.Loot.blacklist = {}
BG.Loot.whitelist = {}
BG.Loot.zaXiangItems = {}
BG.Loot.stackItems = {}
BG.Loot.noStackItems = {}
BG.Loot.itemToBoss = {}
BG.Loot.itemPack = {}

BG.Loot.whitelist = {
    13519, -- 配方：泰坦合剂
    13522, -- 配方：多重抗性合剂
    18657, -- 结构图：高辐射烈焰反射器
    16247, -- 公式：附魔双手武器 - 超强冲击
}

local function FormatTable(tbl)
    local new = {}
    for _, itemID in ipairs(tbl) do
        new[itemID] = true
    end
    return new
end

for _, itemID in pairs(BG.Loot.noStackItems) do
    tinsert(BG.Loot.zaXiangItems, itemID)
end

BG.Loot.blacklist = FormatTable(BG.Loot.blacklist)
BG.Loot.whitelist = FormatTable(BG.Loot.whitelist)
BG.Loot.zaXiangItems = FormatTable(BG.Loot.zaXiangItems)
BG.Loot.stackItems = FormatTable(BG.Loot.stackItems)
BG.Loot.noStackItems = FormatTable(BG.Loot.noStackItems)
