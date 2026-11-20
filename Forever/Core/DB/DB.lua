local AddonName, ns    = ...

local L                = ns.L
local RGB              = ns.RGB
local GetClassColor    = ns.GetClassColor

local pt               = print

local LibBG            = ns.Menu -- 独立菜单库
ns.LibBG               = LibBG

local realmID          = GetRealmID()
local realmName        = BG.realmName
local GetAddOnMetadata = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local IsAddOnLoaded    = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local LoadAddOn        = LoadAddOn or C_AddOns.LoadAddOn

ns.Interface           = "Interface\\AddOns\\" .. AddonName .. "\\Forever\\"

C_ChatInfo.RegisterAddonMessagePrefix("BiaoGe")
C_ChatInfo.RegisterAddonMessagePrefix("BiaoGe2")

BiaoGeTooltip = CreateFrame("GameTooltip", "BiaoGeTooltip", UIParent, "GameTooltipTemplate")   -- 用于装备过滤功能
BiaoGeTooltip2 = CreateFrame("GameTooltip", "BiaoGeTooltip2", UIParent, "GameTooltipTemplate") -- 用于装备库
BiaoGeTooltip2:SetClampedToScreen(false)
BiaoGeTooltip3 = CreateFrame("GameTooltip", "BiaoGeTooltip3", UIParent, "GameTooltipTemplate") -- 用于装备过期提醒
BiaoGeTooltip4 = CreateFrame("GameTooltip", "BiaoGeTooltip4", UIParent, "GameTooltipTemplate") -- 用于装等获取
BiaoGeTooltip5 = CreateFrame("GameTooltip", "BiaoGeTooltip5", UIParent, "GameTooltipTemplate") -- 用于显示已装备的同部位装备
BiaoGeTooltip5:SetClampedToScreen(false)

-- 用于提示套装属性
for i = 11, 15 do
    local frameName = "BiaoGeTooltip" .. i
    CreateFrame("GameTooltip", frameName, UIParent, "GameTooltipTemplate")
    _G[frameName]:SetClampedToScreen(false)
end

-- 游戏按键设置
BINDING_HEADER_BIAOGE     = AddonName
BINDING_NAME_BIAOGE       = L["打开/关闭表格"]
BINDING_NAME_RoleOverview = L["打开/关闭角色总览"]

-- 主界面开关快捷键：无限服没有 BGLite 主插件（根 Bindings.xml 只注册 RoleOverview），
-- 改用 CLICK 绑定（SecureActionButton，同 MRT 做法，按键面板可正常绑定）
_G["BINDING_NAME_CLICK BGLiteEquipToggle:LeftButton"] = L["打开/关闭表格"]
do
    local btn = CreateFrame("Button", "BGLiteEquipToggle", nil, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "macro")
    btn:SetAttribute("macrotext", "/bgef")
    btn:RegisterForClicks("AnyUp", "AnyDown")
end

-- 全局变量
do
    BG.FBtable = {}
    BG.FBtable2 = {}
    BG.FBIDtable = {}
    BG.lootQuality = {}
    BG.difficultyTable = {}
    BG.diffIDTbl = {}
    BG.phaseFBtable = {}
    BG.bossPositionStartEnd = {}
    BG.FBfromBossPosition = {}
    BG.Movetable = {}
    BG.options = {}
    BG.dropDown = LibBG:Create_UIDropDownMenu(nil, UIParent)
    BG.onEnterAlpha = 0.1
    BG.highLightAlpha = 0.2
    BG.otherEditAlpha = 0.3
    BG.scrollStep = 80
    BG.borderAlpha = .5
    BG.ver = "v" .. GetAddOnMetadata(AddonName, "Version")
    BG.BG = "|cff00BFFF<BGLite_equip>|r "
    BG.rareIcon = "|A:nameplates-icon-elite-silver:0:0|a"
    BG.iconTexCoord = { .07, .93, .07, .93 }
    BG.zaxiang = {} -- 杂项如果太多，则需要换列
    BG.zhuangbeiWidth = 140
    BG.zhuangbeiWidth2 = 235
    BG.maijiaWidth = 90
    BG.jineWidth = 90
    BG.spFB = {}
    BG.fakuanIsFirst = {}
    BG.editTemplate = "BiaoGe_InputBoxTemplate" or "InputBoxTemplate"
    BG.editSearchTemplate = "BiaoGe_SearchBoxTemplate" or "SearchBoxTemplate"
    BG.scrollTemplate = "BiaoGe_ModernScrollFrameTemplate" or "UIPanelScrollFrameTemplate"
    BG.notLootBossIDs = {}
    BG.itemOnEnterDelay = 0.02
    BG.addonChannelCount = 10
    BG.LastBagItemFrame = {}
    BG.saveDays = {
        { day = 3, text = "3" .. L["天"] },
        { day = 7, text = "7" .. L["天"] },
        { day = 15, text = "15" .. L["天"] },
        { day = 30, text = "30" .. L["天"] },
        { day = 60, text = "60" .. L["天"] },
        { day = 90, text = "90" .. L["天"] },
        { day = 0, text = L["永久"] },
    }
    BG.CloseButtonOffset = 0

    if C_GameRules and C_GameRules.IsHardcoreActive and C_GameRules.IsHardcoreActive() then
        BG.IsBlackListPlayer = true
        local frameName = 'BiaoGeYingHeError'
        if not StaticPopupDialogs[frameName] then
            StaticPopupDialogs[frameName] = {
                text = L["插件提醒：由于暴雪对插件UI数量的限制，本插件无法在硬核服务器使用，请你自行禁用。"],
                button1 = L["好的"],
                OnAccept = function()
                end,
                whileDead = true,
                showAlert = true,
            }
        end
        StaticPopup_Show(frameName)
    end
end

-- 初始化
do
    BG.Maxi                                    = 40
    BG.FBWidth                                 = {}
    BG.FBHeight                                = {}
    BG.BossNumtbl                              = {}
    local mainFrameWidth                       = 1275
    local mainFrameWidth2                      = 1685
    local Maxt, Maxb, Maxi, HopeMaxb, HopeMaxn = {}, {}, {}, {}, {}
    -- 表格大小、排列方式、BOSS格子数
    do
        local function AddDB(FB, width, height, maxt, maxb,
                             bossNumTbl, diffTbl, diffIDTbl, maxiTbl, zaxiangI,
                             payMaxi)
            BG.FBWidth[FB] = width
            BG.FBHeight[FB] = height
            Maxt[FB] = maxt
            Maxb[FB] = maxb
            BG.BossNumtbl[FB] = bossNumTbl
            HopeMaxb[FB] = maxb - 1
            BG.difficultyTable[FB] = diffTbl or { "N" }
            HopeMaxn[FB] = #BG.difficultyTable[FB]
            BG.diffIDTbl[FB] = diffIDTbl or {
                [3] = "N",
                [175] = "N",
                [4] = "N",
                [176] = "N",
                [5] = "H",
                [193] = "H",
                [6] = "H",
                [194] = "H",
                [14] = "N",
                [15] = "H",
                [16] = "M",
            }
            Maxi[FB] = maxiTbl
            -- 设置支出格子为x个
            tinsert(Maxi[FB], payMaxi or 8)
            -- 设置总览工资格子为x个
            tinsert(Maxi[FB], 5)
            if zaxiangI then
                BG.zaxiang[FB] = { i = zaxiangI }
            elseif maxb - bossNumTbl[#bossNumTbl] == 1 then
                BG.fakuanIsFirst[FB] = true
            end
        end

        AddDB("UBRSforever", mainFrameWidth, 810, 3, 7, { 0, 5, 6 }, nil, nil,
            { 6, 6, 6, 6, 6, 33, 10, })
        AddDB("BDforever", mainFrameWidth, 810, 3, 10, { 0, 5, 9 }, nil, nil,
            { 6, 6, 6, 6, 6, 6, 6, 6, 12, 10, })
        AddDB("HSforever", mainFrameWidth, 870, 3, 15, { 0, 7, 13 }, nil, nil,
            { 4, 4, 4, 4, 5, 5, 5, 5, 5, 5, 5, 5, 6, 14, 5, }, nil)
        AddDB("OLforever", mainFrameWidth, 810, 2, 3, { 0, 3, }, nil, nil,
            { 10, 10, 10, }, nil)
    end

    -- 表格基础信息
    do
        local function AddDB(FB, instanceID, phase, maxplayers, lootQuality,
                             phaseTable, bossPositionTbl, shortName)
            local localName = GetRealZoneText(instanceID)
            if localName == "" then
                localName = shortName or UNKNOWN
            end
            if instanceID == 548 then
                localName = L["毒蛇神殿"]
            end
            tinsert(BG.FBtable, FB)
            tinsert(BG.FBtable2,
                {
                    FB = FB,
                    ID = instanceID,
                    localName = localName,
                    phase = phase,
                    maxplayers = maxplayers,
                    shortName = shortName,
                })
            BG.FBIDtable[instanceID] = FB
            BG.lootQuality[FB] = lootQuality or 4
            BG.phaseFBtable[FB] = phaseTable or { FB }
            BG.bossPositionStartEnd[instanceID] = bossPositionTbl or { 1, Maxb[FB] - 2 }
            BG.FBfromBossPosition[FB] = {}
            for i = 1, Maxb[FB] do
                BG.FBfromBossPosition[FB][i] = { name = FB, localName = localName }
            end
        end
        local function AddOneBoss(FB, instanceID, bossNum, name)
            BG.FBIDtable[instanceID] = FB
            BG.bossPositionStartEnd[instanceID] = { bossNum, bossNum }
            BG.FBfromBossPosition[FB][bossNum] = { name = name, localName = GetRealZoneText(instanceID) }
        end

        BG.FB1 = "BDforever"
        BG.fullLevel = 60
        AddDB("UBRSforever", 229, "P1", 10, 3, nil, nil, L["黑石塔上层"])
        BG.FBtable2[#BG.FBtable2].localName = L["黑石塔上层"]
        for _, info in ipairs(BG.FBfromBossPosition.UBRSforever) do
            info.localName = L["黑石塔上层"]
        end
        AddDB("BDforever", -100, "P1", 10, nil, nil, nil, L['深穴'])
        AddDB("HSforever", -100, "P1", 20, nil, nil, nil, L['海加尔峰'])
        AddDB("OLforever", 249, "P1", 40, nil, nil, nil)
    end

    -- 装备库获取来源过滤
    do
        BG.itemLibGetFiter = {
            { name = L["团本"], name2 = "raid", },
            { name = L["牌子/货币"], name2 = "currency", },
            { name = L["5人本"], name2 = "fb5", },
            { name = L["声望"], name2 = "faction", },
            { name = L["专业"], name2 = "profession", },
            { name = L["世界掉落"], name2 = "world", },
            { name = L["PVP"], name2 = "pvp", },
        }
    end

    local HopeMaxi
    HopeMaxi = 7
    do
        ns.Maxt     = Maxt
        ns.Maxb     = Maxb
        ns.Maxi     = Maxi
        ns.HopeMaxi = HopeMaxi
        ns.HopeMaxb = HopeMaxb
        ns.HopeMaxn = HopeMaxn
        BG.Maxb     = Maxb

        function BG.GetMaxi(FB, b, isScrollFrame)
            if not b then return BG.Maxi end
            FB = FB or BG.FB1
            if not isScrollFrame then
                if b == Maxb[FB] then
                    return BG.Maxi
                elseif b == Maxb[FB] + 1 then
                    return 20
                elseif b == Maxb[FB] + 2 then
                    return 5
                end
            end
            return Maxi[FB][b] or 0
        end
    end

    local UnitRealm = BG.IsForever and
        function()
            return BG.realmName
        end
        or
        function(unit)
            local realm = select(2, UnitName(unit))
            if not realm or realm == "" then
                realm = realmName
            end
            return realm
        end

    local function UnitColor(unit)
        local _, class = UnitClass(unit)
        if not class then
            class = select(2, UnitClass(unit))
        end
        local r, g, b = 1, 1, 1
        if class then
            r, g, b = GetClassColor(class)
        end
        return { r, g, b }
    end
    BG.playerClass = {
        class = { func = UnitClass, select = 2 }, -- 职业
        realm = { func = UnitRealm, select = 1 }, -- 服务器
        color = { func = UnitColor, select = 1 }, -- 颜色
    }

    -- 表格
    do
        -- 表格UI
        BG.Frame = {}
        for index, value in ipairs(BG.FBtable) do
            BG.Frame[value] = {}
            for b = 1, 22 do
                BG.Frame[value]["boss" .. b] = {}
            end
        end

        -- 底色
        BG.FrameDs = {}
        for index, value in ipairs(BG.FBtable) do
            for i = 1, 3, 1 do
                BG.FrameDs[value .. i] = {}
                for b = 1, 22 do
                    BG.FrameDs[value .. i]["boss" .. b] = {}
                end
            end
        end

        -- 心愿UI
        BG.HopeFrame = {}
        for _, FB in ipairs(BG.FBtable) do
            BG.HopeFrame[FB] = {}
            for n = 1, HopeMaxn[FB] do
                BG.HopeFrame[FB]["nandu" .. n] = {}
                for b = 1, 22 do
                    BG.HopeFrame[FB]["nandu" .. n]["boss" .. b] = {}
                end
            end
        end

        -- 心愿底色
        BG.HopeFrameDs = {}
        for index, value in ipairs(BG.FBtable) do
            for t = 1, 3, 1 do
                BG.HopeFrameDs[value .. t] = {}
                for n = 1, 4 do
                    BG.HopeFrameDs[value .. t]["nandu" .. n] = {}
                    for b = 1, 22 do
                        BG.HopeFrameDs[value .. t]["nandu" .. n]["boss" .. b] = {}
                    end
                end
            end
        end

        -- 历史UI
        BG.HistoryFrame = {}
        for index, value in ipairs(BG.FBtable) do
            BG.HistoryFrame[value] = {}
            for b = 1, 22 do
                BG.HistoryFrame[value]["boss" .. b] = {}
            end
        end

        -- 历史底色
        BG.HistoryFrameDs = {}
        for index, value in ipairs(BG.FBtable) do
            for i = 1, 3, 1 do
                BG.HistoryFrameDs[value .. i] = {}
                for b = 1, 22 do
                    BG.HistoryFrameDs[value .. i]["boss" .. b] = {}
                end
            end
        end

        -- 接收UI
        BG.ReceiveFrame = {}
        for index, value in ipairs(BG.FBtable) do
            BG.ReceiveFrame[value] = {}
            for b = 1, 22 do
                BG.ReceiveFrame[value]["boss" .. b] = {}
            end
        end

        -- 接收底色
        BG.ReceiveFrameDs = {}
        for index, value in ipairs(BG.FBtable) do
            for i = 1, 3, 1 do
                BG.ReceiveFrameDs[value .. i] = {}
                for b = 1, 22 do
                    BG.ReceiveFrameDs[value .. i]["boss" .. b] = {}
                end
            end
        end

        -- 对账UI
        BG.DuiZhangFrame = {}
        for index, value in ipairs(BG.FBtable) do
            BG.DuiZhangFrame[value] = {}
            for b = 1, 22 do
                BG.DuiZhangFrame[value]["boss" .. b] = {}
            end
        end

        -- 对账底色
        BG.DuiZhangFrameDs = {}
        for index, value in ipairs(BG.FBtable) do
            for i = 1, 3, 1 do
                BG.DuiZhangFrameDs[value .. i] = {}
                for b = 1, 22 do
                    BG.DuiZhangFrameDs[value .. i]["boss" .. b] = {}
                end
            end
        end
    end

    -- 掉落
    do
        BG.Loot = {}
        for _, FB in pairs(BG.FBtable) do
            BG.Loot[FB] = {
                N = { Quest = {}, },
                H = { Quest = {}, },
                M = { Quest = {}, },

                N10 = { Quest = {}, },
                N25 = { Quest = {}, },
                H10 = { Quest = {}, },
                H25 = { Quest = {}, },

                DEATHKNIGHT = {},
                PALADIN = {},
                WARRIOR = {},
                SHAMAN = {},
                HUNTER = {},
                DRUID = {},
                ROGUE = {},
                MAGE = {},
                WARLOCK = {},
                PRIEST = {},
                EVOKER = {},
                DEMONHUNTER = {},
                MONK = {},

                Team = {},         -- 5人本
                World = {},        -- 世界掉落
                WorldBoss = {},    -- 世界boss
                Currency = {},     -- 货币贷款（WLK）
                Faction = {},      -- 声望
                PVP = {},          -- PVP
                PVP_currency = {}, -- PVP货币
                Profession = {},   -- 专业制造
                Quest = {},        -- 任务
                Shop = {},         -- 商店直接售卖

                Holiday = {},      -- 节日

                Sod_PVP = {},      -- 赛季服PVP活动
                Sod_Currency = {},

                ExchangeItems = {},
            }
        end
    end

    -- 颜色
    do
        BG.b1 = "00BFFF"
        function BG.STC_b1(text)
            if text then
                local t
                t = "|cff" .. "00BFFF" .. text .. "|r"
                return t
            end
        end

        BG.r1 = "FF0000"
        function BG.STC_r1(text)
            if text then
                local t
                t = "|cff" .. "FF0000" .. text .. "|r"
                return t
            end
        end

        BG.r2 = "FF1493"
        function BG.STC_r2(text)
            if text then
                local t
                t = "|cff" .. "FF1493" .. text .. "|r"
                return t
            end
        end

        BG.r3 = "FF69B4"
        function BG.STC_r3(text)
            if text then
                local t
                t = "|cff" .. "FF69B4" .. text .. "|r"
                return t
            end
        end

        BG.g1 = "00FF00"
        function BG.STC_g1(text)
            if text then
                local t
                t = "|cff" .. "00FF00" .. text .. "|r"
                return t
            end
        end

        BG.g2 = "40c040"
        function BG.STC_g2(text)
            if text then
                local t
                t = "|cff" .. "40c040" .. text .. "|r"
                return t
            end
        end

        BG.y1 = "FFFF00"
        function BG.STC_y1(text) -- yellow
            if text then
                local t
                t = "|cff" .. "FFFF00" .. text .. "|r"
                return t
            end
        end

        BG.y2 = "FFD100"
        function BG.STC_y2(text) -- gold
            if text then
                local t
                t = "|cff" .. "FFD100" .. text .. "|r"
                return t
            end
        end

        BG.w1 = "FFFFFF"
        function BG.STC_w1(text) -- 白色
            if text then
                local t
                t = "|cff" .. "FFFFFF" .. text .. "|r"
                return t
            end
        end

        BG.dis = "808080"
        function BG.STC_dis(text) -- 灰色
            if text then
                local t
                t = "|cff" .. "808080" .. text .. "|r"
                return t
            end
        end
    end

    -- 声音
    do
        BG.sound1 = SOUNDKIT.GS_TITLE_OPTION_OK -- 按键音效
        BG.sound2 = 569593                      -- 升级音效
        BG.sound3 = SOUNDKIT.IG_MAINMENU_CLOSE  -- 菜单打开音效

        local Interface = ns.Interface .. "Media\\sound\\"
        BG.soundAuthor = {
            { ID = "AI", addonName = AddonName, isBiaoGe = true },
        }
        BG.soundTbl = BG.soundAuthor
        BG.soundTbl2 = {
            { ID = "paimai", name = "拍卖啦" },
            { ID = "hope", name = "心愿达成" },
            { ID = "qingkong", name = "已清空表格" },
            { ID = "cehuiqingkong", name = "已撤回清空" },
            { ID = "alchemyReady", name = "炼金转化已就绪" },
            { ID = "tailorReady", name = "裁缝洗布已就绪" },
            { ID = "leatherworkingReady", name = "制皮筛盐已就绪" },
            { ID = "equipfull", name = "表格满了" },
            { ID = "guoqi", name = "装备快过期了" },
            { ID = "uploading", name = "账单正在上传" },
            { ID = "uploaded", name = "账单上传成功" },
            { ID = "countDownStop", name = "倒数暂停" },
            { ID = "HusbandComeOn", name = "老公加油" },
            { ID = "qiankuan", name = "你有未收欠款" },
            { ID = "autoAuctionAutoEndTips", name = "自动出价结束" },
            { ID = "autoStartAuctionEnd", name = "自动拍卖结束" },
            { ID = "tradeSuccess", name = "交易成功" },
            { ID = "tradeFalse", name = "交易失败" },
            { ID = "tradeSaveBGFalse", name = "交易记账失败" },
            { ID = "fakuanFull", name = "罚款格子满了" },
            { ID = "auctionError", name = "拍卖出错了" },
            { ID = "currencyfull", name = "牌子满了" },
            { ID = "auctionTopPrice", name = "小心偷家" },
            { ID = "tooLate", name = "请不要卡秒出价" },
        }
        --[[
/run BG.PlaySound("paimai")
/run BG.PlaySound("hope")
]]
        local function DefaultSound()
            for i = 1, C_AddOns.GetNumAddOns() do
                local addonName = C_AddOns.GetAddOnInfo(i)
                local enabled = C_AddOns.GetAddOnEnableState(i, BG.myName)
                if C_AddOns.GetAddOnMetadata(i, "X-BiaoGe-Voice") and enabled ~= 0 then
                    local author = C_AddOns.GetAddOnMetadata(i, "Author")
                    tinsert(BG.soundAuthor, { ID = author, addonName = addonName })
                end
            end
            for _, value in ipairs(BG.soundAuthor) do
                local author = value.ID
                local addonName = value.addonName
                local isBiaoGe = value.isBiaoGe
                for _, v in ipairs(BG.soundTbl2) do
                    local soundID = v.ID
                    local soundName = v.name
                    if isBiaoGe then
                        BG["sound_" .. soundID .. author] = Interface .. author .. "\\" .. soundID
                    else
                        BG["sound_" .. soundID .. author] = format("Interface\\AddOns\\%s\\sound\\%s", addonName, soundName)
                    end
                end
            end

            local yes
            for i, v in ipairs(BG.soundAuthor) do
                if BGLite_equip.options.Sound == v.ID then
                    yes = true
                end
            end
            if not yes then
                BGLite_equip.options.Sound = "AI"
            end
        end

        BG.Init2(function()
            DefaultSound()
        end)
    end

    BG.classColorNames = {}
    for i = 1, GetNumClasses() do
        local className, classFilename = GetClassInfo(i)
        if className then
            local color = select(4, GetClassColor(classFilename))
            BG.classColorNames[className] = format("|c%s%s|r", color, className)
        end
    end
end

-- 本地配置数据库
BG.Init(function()
    if type(BGLite_equip) ~= "table" then
        BGLite_equip = {}
    end

    BGLite_equip.battleNetRoles = nil
    BGLite_equip.blacklist = nil
    BGLite_equip.migrations = nil
    BGLite_equip.historySummary = nil

    BGLite_equip.disabledModules = BGLite_equip.disabledModules or {}

    -- 副本选择初始化
    -- FB1 是UI当前选择的副本
    -- FB2 是玩家当前所处的副本
    if BGLite_equip.FB then
        local yes
        for k, FB in pairs(BG.FBtable) do
            if BGLite_equip.FB == FB then
                BG.FB1 = BGLite_equip.FB
                yes = true
                break
            end
        end
        if not yes then
            BGLite_equip.FB = BG.FB1
        end
    else
        BGLite_equip.FB = BG.FB1
    end

    if not BGLite_equip.point then
        BGLite_equip.point = {}
    end
    if not BGLite_equip.duizhang then
        BGLite_equip.duizhang = {}
    end

    for _, FB in ipairs(BG.FBtable) do
        if not BGLite_equip[FB] then
            BGLite_equip[FB] = {}
        end
        BGLite_equip[FB].tradeTbl = BGLite_equip[FB].tradeTbl or {}
        for b = 1, 22 do
            if not BGLite_equip[FB]["boss" .. b] then
                BGLite_equip[FB]["boss" .. b] = {}
            end
        end
    end

    if not BGLite_equip.HistoryList then
        BGLite_equip.HistoryList = {}
    end
    for _, FB in ipairs(BG.FBtable) do
        if not BGLite_equip.HistoryList[FB] then
            BGLite_equip.HistoryList[FB] = {}
        end
    end

    if not BGLite_equip.History then
        BGLite_equip.History = {}
    end
    for _, FB in ipairs(BG.FBtable) do
        if not BGLite_equip.History[FB] then
            BGLite_equip.History[FB] = {}
        end
    end


    if not BGLite_equip.options then
        BGLite_equip.options = {}
    end
    if not BGLite_equip.options.SearchHistory then
        BGLite_equip.options.SearchHistory = {}
    end
    local name = "moLing"
    BG.options[name .. "reset"] = 1
    BGLite_equip.options[name] = BGLite_equip.options[name] or BG.options[name .. "reset"]

    -- 高亮天赋装备
    if not BGLite_equip.filterClassNum then
        BGLite_equip.filterClassNum = {}
    end
    if not BGLite_equip.filterClassNum[realmID] then
        BGLite_equip.filterClassNum[realmID] = {}
    end
    if not BGLite_equip.filterClassNum[realmID][BG.myName] then
        BGLite_equip.filterClassNum[realmID][BG.myName] = 0
    end
    if BiaoGeA and BiaoGeA.filterClassNum then
        BGLite_equip.filterClassNum[realmID][BG.myName] = BiaoGeA.filterClassNum
        BiaoGeA.filterClassNum = nil
    end

    -- 心愿清单
    if not BGLite_equip.Hope then
        BGLite_equip.Hope = {}
    end
    if not BGLite_equip.Hope[realmID] then
        BGLite_equip.Hope[realmID] = {}
    end
    if not BGLite_equip.Hope[realmID][BG.myName] then
        BGLite_equip.Hope[realmID][BG.myName] = {}
    end
    for index, FB in ipairs(BG.FBtable) do
        if not BGLite_equip.Hope[realmID][BG.myName][FB] then
            BGLite_equip.Hope[realmID][BG.myName][FB] = {}
        end
        for n = 1, 4 do
            if not BGLite_equip.Hope[realmID][BG.myName][FB]["nandu" .. n] then
                BGLite_equip.Hope[realmID][BG.myName][FB]["nandu" .. n] = {}
                for b = 1, 22 do
                    if not BGLite_equip.Hope[realmID][BG.myName][FB]["nandu" .. n]["boss" .. b] then
                        BGLite_equip.Hope[realmID][BG.myName][FB]["nandu" .. n]["boss" .. b] = {}
                    end
                end
            end
        end
    end

    -- 记录服务器名称
    do
        BGLite_equip.realmName = BGLite_equip.realmName or {}
        BGLite_equip.realmName[realmID] = realmName
    end
    -- 记录每个角色的职业、等级、天赋
    do
        BGLite_equip.playerInfo = BGLite_equip.playerInfo or {}
        BGLite_equip.playerInfo[realmID] = BGLite_equip.playerInfo[realmID] or {}
        BGLite_equip.playerInfo[realmID][BG.myName] = BGLite_equip.playerInfo[realmID][BG.myName] or {}
        BGLite_equip.playerInfo[realmID][BG.myName].class = select(2, UnitClass("player"))
        BGLite_equip.playerInfo[realmID][BG.myName].raceID = select(3, UnitRace("player"))
        BGLite_equip.playerInfo[realmID][BG.myName].faction = UnitFactionGroup("player")

        local function UpdateLevel(level)
            BGLite_equip.playerInfo[realmID][BG.myName].level = level
            BG.isFullLevel = level >= BG.fullLevel
        end
        UpdateLevel(UnitLevel("player"))
        BG.RegisterEvent("PLAYER_LEVEL_UP", function(self, event, level)
            UpdateLevel(level)
            if BG.UpdateMeetingHornLevelButton then
                BG.UpdateMeetingHornLevelButton()
            end
        end)

        -- 天赋
        do
            BG.talentIcon = {
                DEATHKNIGHT = {
                    "Interface\\Icons\\Spell_Deathknight_BloodPresence", -- T
                    "Interface\\Icons\\Spell_Deathknight_FrostPresence",
                    "Interface\\Icons\\Spell_Deathknight_UnholyPresence",
                },
                PALADIN = {
                    "Interface\\Icons\\Spell_Holy_HolyBolt",     -- N
                    "Interface\\Icons\\Spell_Holy_DevotionAura", -- T
                    "Interface\\Icons\\Spell_Holy_AuraOfLight",
                },
                WARRIOR = {
                    "Interface\\Icons\\ability_warrior_savageblow",
                    "Interface\\Icons\\ability_warrior_innerrage",
                    "Interface\\Icons\\ability_warrior_defensivestance", -- T
                },
                EVOKER = {                                               -- 唤魔师
                    "Interface\\Icons\\ability_evoker_powerswell",
                    "Interface\\Icons\\ability_evoker_emeraldblossom",
                    "Interface\\Icons\\ability_evoker_reversion_green",
                },
                SHAMAN = {
                    "Interface\\Icons\\spell_nature_lightning",
                    "Interface\\Icons\\spell_nature_lightningshield",
                    "Interface\\Icons\\Spell_Nature_HealingWaveGreater", -- N
                },
                HUNTER = {
                    "Interface\\Icons\\Ability_Hunter_BeastTaming",
                    "Interface\\Icons\\Ability_Marksmanship",
                    "Interface\\Icons\\Ability_Hunter_SwiftStrike",
                },
                DEMONHUNTER = {
                    "Interface\\Icons\\ability_demonhunter_specdps",
                    "Interface\\Icons\\Ability_DemonHunter_SpecTank",
                    "Interface\\Icons\\classicon_demonhunter_void",
                },
                MONK = {
                    "Interface/Icons/spell_monk_brewmaster_spec", -- 酒仙
                    "Interface/Icons/spell_monk_mistweaver_spec", -- 织雾
                    "Interface/Icons/spell_monk_windwalker_spec", -- 踏风
                },
                ROGUE = {
                    "Interface\\Icons\\ability_rogue_eviscerate",
                    "Interface\\Icons\\ability_backstab",
                    "Interface\\Icons\\ability_stealth",
                },
                MAGE = {
                    "Interface\\Icons\\inv_misc_rune_03",
                    "Interface\\Icons\\spell_fire_firebolt02",
                    "Interface\\Icons\\spell_frost_frostbolt02",
                },
                WARLOCK = {
                    "Interface\\Icons\\spell_shadow_deathcoil",
                    "Interface\\Icons\\spell_shadow_metamorphosis",
                    "Interface\\Icons\\spell_shadow_rainoffire",
                },
                PRIEST = {
                    "Interface\\Icons\\spell_holy_wordfortitude",  -- N
                    "Interface\\Icons\\spell_holy_guardianspirit", -- N
                    "Interface\\Icons\\spell_shadow_shadowwordpain",
                },
            }
            BG.talentIcon.DRUID = {
                "Interface\\Icons\\spell_nature_starfall",
                "Interface\\Icons\\ability_racial_bearform",
                "Interface\\Icons\\Spell_Nature_HealingTouch", -- N
            }
        end
    end

    -- 修正数据
    local function Fix(FB, insertAt)
        local last = ns.Maxb[FB] + 2 -- 最后一格：总览

        local function Shift(record, lastBoss)
            for b = lastBoss or last, insertAt + 1, -1 do
                record["boss" .. b] = BG.Copy(record["boss" .. (b - 1)] or {})
            end
            record["boss" .. insertAt] = {}
        end

        Shift(BGLite_equip[FB])
        for _, history in pairs(BGLite_equip.History[FB]) do
            Shift(history)
        end
        -- 心愿清单只移动到杂项，不包含罚款、支出和总览。
        for _, realm in pairs(BGLite_equip.Hope) do
            for _, player in pairs(realm) do
                if player[FB] then
                    for n = 1, ns.HopeMaxn[FB] do
                        local wishes = player[FB]["nandu" .. n]
                        if wishes then
                            Shift(wishes, ns.Maxb[FB] - 1)
                        end
                    end
                end
            end
        end
    end

    -- 删除旧表格数据
    do
    end

    -- 默认字体
    do
        local l = GetLocale()
        local default, list
        if (l == "koKR") then
            default = "2002.TTF"
        elseif (l == "zhCN") then
            default = "ARKai_T.ttf"
            list = {
                "ARKai_T.ttf",
                "ARKai_C.ttf",
                "ARHei.ttf",
                -- "ARIALN.ttf",
                -- "FRIZQT__.ttf",
            }
        elseif (l == "zhTW") then
            default = "blei00d.TTF"
            list = {
                "bLEI00D.ttf",
                "bHEI00M.ttf",
                "bHEI01B.ttf",
                "bKAI00M.ttf",
            }
        elseif (l == "ruRU") then
            default = "FRIZQT___CYR.TTF"
        else
            default = "FRIZQT__.TTF"
            list = {
                "FRIZQT__.TTF",
                "2002.TTF",
                "2002B.TTF",
                "ARHei.TTF",
                "ARKai_C.TTF",
                "ARKai_T.TTF",
                "ARIALN.TTF",
                "K_Pagetext.TTF",
                "MORPHEUS_CYR.TTF",
                "NIM_____.ttf",
                "SKURRI_CYR.TTF",
            }
        end
        BGLite_equip.font = BGLite_equip.font or default

        local t = UIParent:CreateFontString()
        t:SetFont(format("Fonts\\%s", BGLite_equip.font), 15, "OUTLINE")
        t:Hide()
        if not t:GetFont() then
            BGLite_equip.font = default
        end
        BIAOGE_TEXT_FONT = format("Fonts\\%s", BGLite_equip.font)

        if list then
            for i = #list, 1, -1 do
                local t = UIParent:CreateFontString()
                t:SetFont(format("Fonts\\%s", list[i]), 15, "OUTLINE")
                t:Hide()
                if not t:GetFont() then
                    tremove(list, i)
                end
            end
        end
        BG.fontList = list

        local name = "editFontSize"
        BGLite_equip.options[name] = BGLite_equip.options[name] or 14
        function BiaoGe_InputBoxTemplate_OnLoad(self)
            self:SetFont(BIAOGE_TEXT_FONT, BGLite_equip.options[name], "OUTLINE")
        end
    end

    -- 自定义字体
    do
        local function CreateMyFont(color, size, H)
            local cff
            if color == "Blue" then
                cff = "00BFFF"
            elseif color == "Green" then
                cff = "00FF00"
            elseif color == "Green2" then
                cff = "40c040"
            elseif color == "Red" then
                cff = "FF0000"
            elseif color == "Fen" then
                cff = "FF69B4"
            elseif color == "Gold" then
                cff = "FFD100"
            elseif color == "Yellow" then
                cff = "FFFF00"
            elseif color == "White" then
                cff = "FFFFFF"
            elseif color == "Dis" then
                cff = "808080"
            end
            BG["Font" .. color .. size] = CreateFont("BG.Font" .. color .. size)
            BG["Font" .. color .. size]:SetTextColor(RGB(cff))
            BG["Font" .. color .. size]:SetFont(BIAOGE_TEXT_FONT, size, "OUTLINE")
        end

        CreateMyFont("Blue", 13)
        CreateMyFont("Blue", 15)

        CreateMyFont("Green", 13)
        CreateMyFont("Green", 15)
        CreateMyFont("Green", 25)

        CreateMyFont("Green2", 15)

        CreateMyFont("Gold", 13)
        CreateMyFont("Gold", 15)

        CreateMyFont("Yellow", 13)
        CreateMyFont("Yellow", 15)

        CreateMyFont("Red", 13)
        CreateMyFont("Red", 15)

        CreateMyFont("Fen", 15)

        CreateMyFont("White", 13)
        CreateMyFont("White", 14)
        CreateMyFont("White", 15)
        CreateMyFont("White", 18)
        CreateMyFont("White", 25)

        CreateMyFont("Dis", 13)
        CreateMyFont("Dis", 15)
    end
end)

BG.Init2(function()
    if BG.hasHolidayLoot then
        BG.After(1, function()
            ToggleCalendar()
            Calendar_Hide()
        end)
    end

end)
