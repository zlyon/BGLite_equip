local AddonName, ns = ...

local pt = print

MyUnderpants = MyUnderpants or {}

local realmID   = GetRealmID()
local player    = BG.playerName
local realmName = BG.realmName

BGE.Init(function() -- @shared-db-ok
    if not MyUnderpants.options then
        MyUnderpants.options = {}
    end
    if not MyUnderpants.options.SearchHistory then
        MyUnderpants.options.SearchHistory = {}
    end
    if not MyUnderpants.point then
        MyUnderpants.point = {}
    end
    -- 记录服务器名称
    do
        MyUnderpants.realmName = MyUnderpants.realmName or {}
        MyUnderpants.realmName[realmID] = realmName
    end
    -- 记录每个角色的职业、等级、天赋
    do
        MyUnderpants.playerInfo = MyUnderpants.playerInfo or {}
        MyUnderpants.playerInfo[realmID] = MyUnderpants.playerInfo[realmID] or {}
        MyUnderpants.playerInfo[realmID][player] = MyUnderpants.playerInfo[realmID][player] or {}
        MyUnderpants.playerInfo[realmID][player].class = select(2, UnitClass("player"))
        MyUnderpants.playerInfo[realmID][player].raceID = select(3, UnitRace("player"))
        MyUnderpants.playerInfo[realmID][player].faction = UnitFactionGroup("player")
        MyUnderpants.playerInfo[realmID][player].iLevel = select(2, GetAverageItemLevel()) or 0

        local function UpdateLevel(level)
            MyUnderpants.playerInfo[realmID][player].level = level
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
                MyUnderpants.playerInfo[realmID][player].talent = specIndex
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
    MyUnderpants = MyUnderpants or {}
    MyUnderpants.options = MyUnderpants.options or {}
    MyUnderpants.options.SearchHistory = MyUnderpants.options.SearchHistory or {}
    MyUnderpants.point = MyUnderpants.point or {}
    MyUnderpants.realmName = MyUnderpants.realmName or {}
    MyUnderpants.realmName[realmID] = realmName
    MyUnderpants.playerInfo = MyUnderpants.playerInfo or {}
    MyUnderpants.playerInfo[realmID] = MyUnderpants.playerInfo[realmID] or {}
    MyUnderpants.playerInfo[realmID][player] = MyUnderpants.playerInfo[realmID][player] or {}
    local info = MyUnderpants.playerInfo[realmID][player]
    info.class = select(2, UnitClass("player"))
    info.raceID = select(3, UnitRace("player"))
    info.faction = UnitFactionGroup("player")
    info.iLevel = select(2, GetAverageItemLevel()) or 0
    info.level = UnitLevel("player")
    BG.isFullLevel = (info.level or 0) >= (BG.fullLevel or 0)
end)
