if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

-- 一次性迁移：把旧共享表 MyUnderpants 的角色数据与界面设置接管进本插件自己的存档表 BGLite_equip。
-- 此后 BGLite_equip 表由本插件独占写入；旧表仍归 MyUnderpants 插件所有，这里只读不写。
-- 迁移后每个角色登录时由各模块用新数据覆盖自己的条目，全部覆盖完即完成过渡。
--
-- ⭐ 时序说明（泰坦客户端实测）：MyUnderpants 的存档可能晚于 PLAYER_LOGIN 才就绪，
-- 因此除了 Init3 之外，还监听 ADDON_LOADED(MyUnderpants) 触发；
-- 旧表未就绪时直接返回、不烧标记，等待下一次触发重试（补缺逻辑幂等，重复执行无害）。

local SETTINGS_KEYS = { "FBCDchoice", "MONEYchoice", "point", "realmName", "SKILLchoice" }

local function RunMigration()
    local db = BGLite_equip
    if type(db) ~= "table" then return end
    if db.legacyMigratedDone then return true end

    local old = MyUnderpants
    if type(old) ~= "table" then return end

    -- 界面设置：旧值优先接管。迁移完成前新表里只可能是本会话刚写入的默认值，
    -- 直接覆盖才能保证老用户更新后设置无感（玩家拍板：更新后绝不重置）
    if type(old.options) == "table" then
        db.options = db.options or {}
        for k, v in pairs(old.options) do
            -- 一次性动作标记（BGE.Once 用）单独补缺合并，保证历史 once 不重跑
            if k == "SearchHistory" and type(v) == "table" then
                db.options.SearchHistory = db.options.SearchHistory or {}
                for kk, vv in pairs(v) do
                    if db.options.SearchHistory[kk] == nil then
                        db.options.SearchHistory[kk] = vv
                    end
                end
            else
                db.options[k] = (type(v) == "table" and BG.Copy(v) or v)
            end
        end
    end
    for _, key in ipairs(SETTINGS_KEYS) do
        local src = old[key]
        if type(src) == "table" then
            db[key] = db[key] or {}
            for k, v in pairs(src) do
                db[key][k] = (type(v) == "table" and BG.Copy(v) or v)
            end
        end
    end

    -- 角色数据快照：逐角色补缺，当前角色本会话已写入的新数据优先（不覆盖）
    if BGE.DeletePlayerDataKeys then
        for _, key in ipairs(BGE.DeletePlayerDataKeys) do
            local src = old[key]
            if type(src) == "table" then
                db[key] = db[key] or {}
                for realmID, v in pairs(src) do
                    if type(realmID) == "number" and type(v) == "table" then
                        db[key][realmID] = db[key][realmID] or {}
                        for player, vv in pairs(v) do
                            if db[key][realmID][player] == nil then
                                db[key][realmID][player] = BG.Copy(vv)
                            end
                        end
                    end
                end
            end
        end
    end

    -- 排序列表（结构为 realmID -> 数组，旧值整体优先）
    if type(old.MyUnderpantsSort) == "table" then
        db.MyUnderpantsSort = db.MyUnderpantsSort or {}
        for realmID, v in pairs(old.MyUnderpantsSort) do
            if db.MyUnderpantsSort[realmID] == nil then
                db.MyUnderpantsSort[realmID] = BG.Copy(v)
            end
        end
    end

    db.legacyMigratedDone = true
    return true
end

-- 触发一：正常时序（所有插件与其存档加载完成后）
BGE.Init3(function()
    RunMigration()
end)

-- 触发二：旧表插件晚于 PLAYER_LOGIN 才就绪的客户端。
-- ADDON_LOADED 到达时其存档已加载完毕，此刻读取全局表是安全的
do
    local f = CreateFrame("Frame")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent", function(_, _, name)
        if name == "MyUnderpants" and RunMigration() then
            f:UnregisterEvent("ADDON_LOADED")
        end
    end)
end
