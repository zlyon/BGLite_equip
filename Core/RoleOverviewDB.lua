local AddonName, ns = ...

local pt = print

-- 存档表 BGLite_equip 由本 toc 的 ## SavedVariables 声明加载，
-- 此处不做任何全局兜底赋值（文件执行期存档尚未就绪，赋值会在加载时被整体替换）

local realmID   = GetRealmID()
local player    = BG.playerName
local realmName = BG.realmName

BGE.Init(function() -- @shared-db-ok
    -- 存档文件异常（如手工遗留文件未给声明变量赋值）时兜底建表，保证可正常写入并在登出保存
    if type(BGLite_equip) ~= "table" then BGLite_equip = {} end
    if not BGLite_equip.options then
        BGLite_equip.options = {}
    end
    if not BGLite_equip.options.SearchHistory then
        BGLite_equip.options.SearchHistory = {}
    end
    if not BGLite_equip.point then
        BGLite_equip.point = {}
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
        BGLite_equip.playerInfo[realmID][player] = BGLite_equip.playerInfo[realmID][player] or {}
        BGLite_equip.playerInfo[realmID][player].class = select(2, UnitClass("player"))
        BGLite_equip.playerInfo[realmID][player].raceID = select(3, UnitRace("player"))
        BGLite_equip.playerInfo[realmID][player].faction = UnitFactionGroup("player")
        BGLite_equip.playerInfo[realmID][player].iLevel = select(2, GetAverageItemLevel()) or 0

        local function UpdateLevel(level)
            BGLite_equip.playerInfo[realmID][player].level = level
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
            local function GetTalent(_, event)
                local specIndex
                if BG.verOver4 then
                    specIndex = C_SpecializationInfo.GetSpecialization()
                    if specIndex == 0 or specIndex == 5 then
                        specIndex = nil
                    end
                else
                    local maxNum = 0
                    for i = 1, 3 do
                        local num = select(5, GetTalentTabInfo(i, nil, nil, GetActiveTalentGroup()))
                        if num and num >= maxNum then
                            maxNum = num
                            specIndex = i
                        end
                    end
                    if maxNum == 0 then specIndex = nil end
                end
                BGLite_equip.playerInfo[realmID][player].talent = specIndex
            end

            local f = CreateFrame("Frame")
            f:RegisterEvent("PLAYER_TALENT_UPDATE")
            f:RegisterEvent("PLAYER_ENTERING_WORLD")
            if BG.verOver4 then
                f:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
            end
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
        end
    end
end)

BGE.Init3(function()
    if type(BGLite_equip) ~= "table" then BGLite_equip = {} end
    BGLite_equip.options = BGLite_equip.options or {}
    BGLite_equip.options.SearchHistory = BGLite_equip.options.SearchHistory or {}
    BGLite_equip.point = BGLite_equip.point or {}
    BGLite_equip.realmName = BGLite_equip.realmName or {}
    BGLite_equip.realmName[realmID] = realmName
    BGLite_equip.playerInfo = BGLite_equip.playerInfo or {}
    BGLite_equip.playerInfo[realmID] = BGLite_equip.playerInfo[realmID] or {}
    BGLite_equip.playerInfo[realmID][player] = BGLite_equip.playerInfo[realmID][player] or {}
    local info = BGLite_equip.playerInfo[realmID][player]
    info.class = select(2, UnitClass("player"))
    info.raceID = select(3, UnitRace("player"))
    info.faction = UnitFactionGroup("player")
    info.iLevel = select(2, GetAverageItemLevel()) or 0
    info.level = UnitLevel("player")
    BG.isFullLevel = (info.level or 0) >= (BG.fullLevel or 0)
end)
