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

local L                                     = ns.L
local RGB                                   = ns.RGB
local GetClassColor                         = ns.GetClassColor

local pt                                    = print

local LibBG                                 = ns.Menu -- 调用库菜单UI
ns.LibBG                                    = LibBG

local realmID                               = GetRealmID()
local realmName                             = ZL.realmName
local GetAddOnMetadata                      = GetAddOnMetadata or C_AddOns.GetAddOnMetadata
local IsAddOnLoaded                         = IsAddOnLoaded or C_AddOns.IsAddOnLoaded
local LoadAddOn                             = LoadAddOn or C_AddOns.LoadAddOn

ZLTooltip                              = CreateFrame("GameTooltip", "ZLTooltip", UIParent, "GameTooltipTemplate") -- 用于装等获取

-- 游戏按键设置归类到主插件的按键分类下，见 Bindings.xml（名称复用 Core/DB/DB.lua 的 BINDING_NAME_RoleOverview）

ns.Interface = "Interface\\AddOns\\" .. AddonName .. "\\Forever\\Modules\\RoleOverview\\"

-- 全局变量
do
    ZL.Movetable = {}
    ZL.options = {}
    ZL.itemCaches = {}
    ZL.dropDown = LibBG:Create_UIDropDownMenu(nil, UIParent)
    ZL.onEnterAlpha = 0.1
    ZL.highLightAlpha = 0.2
    ZL.otherEditAlpha = 0.3
    ZL.scrollStep = 80
    ZL.borderAlpha = .5
    ZL.ver = "v" .. GetAddOnMetadata(AddonName, "Version")
    ZL.rareIcon = "|A:nameplates-icon-elite-silver:0:0|a"
    ZL.iconTexCoord = { .07, .93, .07, .93 }
    ZL.fakuanIsFirst = {}
    ZL.editTemplate = "ZL_InputBoxTemplate" or "InputBoxTemplate"
    ZL.editSearchTemplate = "ZL_SearchBoxTemplate" or "SearchBoxTemplate"
    ZL.scrollTemplate = "ZL_ModernScrollFrameTemplate" or "UIPanelScrollFrameTemplate"
    ZL.notLootBossIDs = {}
    ZL.itemOnEnterDelay = 0.02
    ZL.addonChannelCount = 10
    ZL.LastBagItemFrame = {}
    ZL.CloseButtonOffset = ZL.IsNewUI and -2 or 2
end

-- 初始化
do
    -- 基础信息
    do
        ZL.fullLevel = 60
        ZL.fullLevel_RoleOverview = 10
    end

    -- 颜色
    do
        ZL.b1 = "00BFFF"
        function ZL.STC_b1(text)
            if text then
                local t
                t = "|cff" .. "00BFFF" .. text .. "|r"
                return t
            end
        end

        ZL.r1 = "FF0000"
        function ZL.STC_r1(text)
            if text then
                local t
                t = "|cff" .. "FF0000" .. text .. "|r"
                return t
            end
        end

        ZL.r2 = "FF1493"
        function ZL.STC_r2(text)
            if text then
                local t
                t = "|cff" .. "FF1493" .. text .. "|r"
                return t
            end
        end

        ZL.r3 = "FF69B4"
        function ZL.STC_r3(text)
            if text then
                local t
                t = "|cff" .. "FF69B4" .. text .. "|r"
                return t
            end
        end

        ZL.g1 = "00FF00"
        function ZL.STC_g1(text)
            if text then
                local t
                t = "|cff" .. "00FF00" .. text .. "|r"
                return t
            end
        end

        ZL.g2 = "40c040"
        function ZL.STC_g2(text)
            if text then
                local t
                t = "|cff" .. "40c040" .. text .. "|r"
                return t
            end
        end

        ZL.y1 = "FFFF00"
        function ZL.STC_y1(text) -- yellow
            if text then
                local t
                t = "|cff" .. "FFFF00" .. text .. "|r"
                return t
            end
        end

        ZL.y2 = "FFD100"
        function ZL.STC_y2(text) -- gold
            if text then
                local t
                t = "|cff" .. "FFD100" .. text .. "|r"
                return t
            end
        end

        ZL.w1 = "FFFFFF"
        function ZL.STC_w1(text) -- 白色
            if text then
                local t
                t = "|cff" .. "FFFFFF" .. text .. "|r"
                return t
            end
        end

        ZL.dis = "808080"
        function ZL.STC_dis(text) -- 灰色
            if text then
                local t
                t = "|cff" .. "808080" .. text .. "|r"
                return t
            end
        end
    end

    -- 声音
    do
        ZL.sound1 = SOUNDKIT.GS_TITLE_OPTION_OK -- 按键音效
        ZL.sound2 = 569593                      -- 升级音效
        ZL.sound3 = SOUNDKIT.IG_MAINMENU_CLOSE  -- 菜单打开音效
    end

    ZL.classColorNames = {}
    for i = 1, GetNumClasses() do
        local className, classFilename = GetClassInfo(i)
        if className then
            local color = select(4, GetClassColor(classFilename))
            ZL.classColorNames[className] = format("|c%s%s|r", color, className)
        end
    end

end

-- 本地配置数据库
ZL.Init(function()
    if type(ZLDb) ~= "table" then
        ZLDb = {}
    end
    if not ZLDb.point then
        ZLDb.point = {}
    end
    if not ZLDb.options then
        ZLDb.options = {}
    end

    if ZLDb.options.bagViewerShowBag == nil then
        ZLDb.options.bagViewerShowBag = true
    end
    if ZLDb.options.bagViewerShowBank == nil then
        ZLDb.options.bagViewerShowBank = true
    end

    if not ZLDb.options.SearchHistory then
        ZLDb.options.SearchHistory = {}
    end

    -- 记录服务器名称
    do
        ZLDb.realmName = ZLDb.realmName or {}
        ZLDb.realmName[realmID] = realmName
    end

    -- 记录每个角色的职业、等级、天赋
    do
        ZLDb.playerInfo = ZLDb.playerInfo or {}
        ZLDb.playerInfo[realmID] = ZLDb.playerInfo[realmID] or {}
        ZLDb.playerInfo[realmID][ZL.myName] = ZLDb.playerInfo[realmID][ZL.myName] or {}
        ZLDb.playerInfo[realmID][ZL.myName].class = select(2, UnitClass("player"))
        ZLDb.playerInfo[realmID][ZL.myName].raceID = select(3, UnitRace("player"))
        ZLDb.playerInfo[realmID][ZL.myName].faction = UnitFactionGroup("player")
        ZLDb.playerInfo[realmID][ZL.myName].iLevel = select(2, GetAverageItemLevel()) or 0

        -- 登录和登出时记录当前角色的最后更新时间
        local function UpdateLastUpdate()
            ZLDb.playerInfo[realmID][ZL.myName].lastUpdate = GetServerTime()
        end
        UpdateLastUpdate()
        ZL.RegisterEvent("PLAYER_LOGOUT", UpdateLastUpdate)

        local function UpdateLevel(level)
            ZLDb.playerInfo[realmID][ZL.myName].level = level
            ZL.isFullLevel = level >= ZL.fullLevel
        end
        UpdateLevel(UnitLevel("player"))
        ZL.RegisterEvent("PLAYER_LEVEL_UP", function(self, event, level)
            UpdateLevel(level)
            if ZL.UpdateMeetingHornLevelButton then
                ZL.UpdateMeetingHornLevelButton()
            end
        end)
    end
    
    -- 天赋
    do
        local GetTalent
        GetTalent = function(_, event)
            if not (C_Traits and C_Traits.GetConfigInfo and C_Traits.GetGroupDisplayInfoByTreeID and C_Traits.GetGroupCurrencyInfo) then
                ZLDb.playerInfo[realmID][ZL.myName].talent = nil
                return
            end

            local configID = C_ClassTalents and C_ClassTalents.GetActiveConfigID and C_ClassTalents.GetActiveConfigID()
            if not configID and C_SpecializationInfo.GetCombatConfigIDForSpecGroup then
                configID = C_SpecializationInfo.GetCombatConfigIDForSpecGroup(C_SpecializationInfo.GetActiveSpecGroup())
            end

            local configInfo = configID and C_Traits.GetConfigInfo(configID)
            if not configInfo or not configInfo.treeIDs then
                ZLDb.playerInfo[realmID][ZL.myName].talent = nil
                return
            end

            local groups, groupIDs, knownGroupIDs = {}, {}, {}
            for _, treeID in ipairs(configInfo.treeIDs) do
                local displayInfos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
                for _, displayInfo in ipairs(displayInfos or {}) do
                    if not knownGroupIDs[displayInfo.groupID] then
                        knownGroupIDs[displayInfo.groupID] = true
                        groups[#groups + 1] = displayInfo
                    end
                end
            end

            table.sort(groups, function(a, b)
                if a.orderIndex == b.orderIndex then
                    return a.groupID < b.groupID
                end
                return a.orderIndex < b.orderIndex
            end)
            for _, group in ipairs(groups) do
                groupIDs[#groupIDs + 1] = group.groupID
            end

            local spentByGroup = {}
            for _, groupInfo in ipairs(C_Traits.GetGroupCurrencyInfo(configID, groupIDs) or {}) do
                local currencyInfo = groupInfo.currencyInfos and groupInfo.currencyInfos[1]
                spentByGroup[groupInfo.traitNodeGroupID] = currencyInfo and currencyInfo.spent or 0
            end

            local specIndex, maxPoints
            for index, group in ipairs(groups) do
                local spent = spentByGroup[group.groupID] or 0
                if not maxPoints or spent >= maxPoints then
                    specIndex, maxPoints = index, spent
                end
            end
            if not maxPoints or maxPoints == 0 then
                specIndex = nil
            end
            ZLDb.playerInfo[realmID][ZL.myName].talent = specIndex
        end

        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_TALENT_UPDATE")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("TRAIT_CONFIG_UPDATED")
        f:RegisterEvent("ACTIVE_COMBAT_CONFIG_CHANGED")
        f:SetScript("OnEvent", function(self, event, ...)
            if event == "PLAYER_ENTERING_WORLD" then
                self:UnregisterEvent("PLAYER_ENTERING_WORLD")
            end
            self.t = 0
            self:SetScript("OnUpdate", function(_, t)
                self.t = self.t + t
                if self.t > 1 then
                    self:SetScript("OnUpdate", nil)
                    GetTalent()
                end
            end)
        end)

        function ZL.GetTalentIcon(class, talent, w)
            w = w or 0
            if talent then
                local a, b, c, d = unpack(ZL.iconTexCoord)
                local coord = format("100:100:%s:%s:%s:%s", a * 100, b * 100, c * 100, d * 100)
                local tex = ZL.talentIcon[class][talent]
                if tex then
                    return format("|T%s:%s:%s:0:0:%s|t", ZL.talentIcon[class][talent], w, w, coord)
                end
            end
            return format("|A:GarrMission_ClassIcon-%s:%s:%s|a", class, w, w)
        end

        ZL.talentIcon = {
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
        ZL.talentIcon.DRUID = {
            "Interface\\Icons\\spell_nature_starfall",
            "Interface\\Icons\\ability_racial_bearform",
            "Interface\\Icons\\Spell_Nature_HealingTouch", -- N
        }
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
        -- 字体统一使用主插件（金团表格）的设置，两处不再各存一份
        ZLDb.font = BGLite_equip.font or default
        ns.Font = BIAOGE_TEXT_FONT or format("Fonts\\%s", ZLDb.font)
        ZL.fontList = BG.fontList or list

        BGLite_equip.options.editFontSize = BGLite_equip.options.editFontSize or 14
        function ZL_InputBoxTemplate_OnLoad(self)
            self:SetFont(ns.Font, BGLite_equip.options.editFontSize, "OUTLINE")
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
            ZL["Font" .. color .. size] = CreateFont("ZL.Font" .. color .. size)
            ZL["Font" .. color .. size]:SetTextColor(RGB(cff))
            ZL["Font" .. color .. size]:SetFont(ns.Font, size, "OUTLINE")
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

-- 命令行
SlashCmdList["BGRoleOverview"] = function()
    ZL.SetFBCD(nil, nil, true)
end
SLASH_BGRoleOverview1 = "/zl"
SLASH_BGRoleOverview2 = "/bgr"
