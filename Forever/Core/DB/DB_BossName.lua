local _, ns = ...

local L = ns.L

local Maxb = ns.Maxb

local pt = print

BG.Boss = {}

function BG.FormatBossName(name)
    local n, c
    if ns.enUS then
        n, c = name:gsub(" ", "\n")
    elseif name:find("\n") then
        return name
    else
        local newstr = ""
        for i = 1, string.utf8len(name) do
            newstr = newstr .. (i == 1 and "" or "\n") .. string.utf8sub(name, i, i)
        end
        n = newstr
    end
    return n, c
end

local function AddDB(FB, boss)
    if not BG.Boss[FB] then BG.Boss[FB] = {} end
    for b = 1, #boss do
        local name = boss[b].name
        BG.Boss[FB]["boss" .. b] = BG.Boss[FB]["boss" .. b] or {}
        BG.Boss[FB]["boss" .. b].name2 = name:gsub("\n", "")
        BG.Boss[FB]["boss" .. b].color = boss[b].color
        BG.Boss[FB]["boss" .. b].name, BG.Boss[FB]["boss" .. b].nCount = BG.FormatBossName(name)
    end
end
local function Addother(boss)
    tinsert(boss, { name = L["杂\n\n项"], color = "ffffff" })
    tinsert(boss, { name = L["罚\n\n款"], color = "ffffff" })
    tinsert(boss, { name = L["支\n\n出"], color = "00FF00" })
    tinsert(boss, { name = L["总\n览"], color = "EE82EE" })
end



-- Forever
do
    local boss = {
        { name = L["烈焰卫士"], color = "FF6600" },
        -- { name = L["索拉卡・火冠"], color = "90EE90" },
        { name = L["雷德・黑手"], color = "DA70D6" },
        { name = L["比斯巨兽"], color = "FFD100" },
        { name = L["达基萨斯将军"], color = "00BFFF" },
        { name = L["瓦塔拉克公爵"], color = "90EE90" },
    }
    Addother(boss)
    AddDB("UBRSforever", boss)

    local boss = {
        { name = L["深痕族母"], color = "8B4513" }, -- 深穴熊怪首领：土褐色
        { name = L["恐网者卡利斯"], color = "9932CC" }, -- 恐惧与蛛网：暗紫色
        { name = L["阿梅斯拉克斯"], color = "8A2BE2" }, -- 神秘蛛魔：紫罗兰色
        { name = L["拉弗斯与达莉莎"], color = "FF8C00" }, -- 双人战与爆炸物：橙色
        { name = L["长者纠爪"], color = "228B22" }, -- 德鲁伊熊形态：森林绿
        { name = L["悲伤之井"], color = "87CEFA" }, -- 被腐化的哀伤之水：浅天蓝
        { name = L["德利纳尔·歌木"], color = "2E8B57" }, -- 林地德鲁伊：海洋绿
        { name = L["索尼娅·暗影之谷"], color = "FF6347" }, -- 最终首领与黑暗意象：珊瑚红
    }
    Addother(boss)
    AddDB("BDforever", boss)

    local boss = {
        { name = L["班达拉尔"], color = "3CB371" }, -- 森林守护者：翠绿
        { name = L["迷时军团"], color = "ADD8E6" }, -- 迷失时空的军团：浅钢蓝
        { name = L["老暮暗潜伏者"], color = "BA55D3" }, -- 阴影潜伏者：亮紫
        { name = L["卡斯里斯"], color = "E6E6FA" }, -- 鬼魅亡灵：淡紫白
        { name = L["长者敏德雷尔"], color = "90EE90" }, -- 自然长老：浅绿
        { name = L["荆棘议会"], color = "32CD32" }, -- 荆棘与自然魔法：酸橙绿
        { name = L["荒野之王"], color = "FFD700" }, -- 荒野之王：金色
        { name = L["腐朽古树"], color = "CD853F" }, -- 腐朽树灵：沙褐色
        { name = L["希尔维斯翠丝"], color = "9370DB" }, -- 暮歌与月夜：中紫
        { name = L["加拉里斯"], color = "40E0D0" }, -- 深渊之力：青绿
        { name = L["阿娜拉·寒风"], color = "87CEEB" }, -- 寒风冰霜：天蓝
        { name = L["追踪者静风"], color = "F0E68C" }, -- 追踪者：卡其黄
        { name = L["缚梦者尼苏斯"], color = "FF69B4" }, -- 梦境束缚与恐惧：亮粉紫
    }
    Addother(boss)
    AddDB("HSforever", boss)

    local boss = {
        { name = L["奥妮克希亚"], color = "CC6600" },
    }
    local FB = "OLforever"
    Addother(boss)
    AddDB(FB, boss)
end






