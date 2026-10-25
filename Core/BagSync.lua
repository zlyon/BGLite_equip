if BG.IsBlackListPlayer then return end
local AddonName, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local Size = ns.Size
local RGB = ns.RGB
local RGB_16 = ns.RGB_16
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local GetText_T = ns.GetText_T
local AddTexture = ns.AddTexture
local GetItemID = ns.GetItemID
local GetClassName = ns.GetClassName
local CreateLine = ns.CreateLine
local SendSystemMessage = ns.SendSystemMessage
local ver = ns.ver
local After = C_Timer.After
local player = UnitName("player")
local realmID = GetRealmID()

local pt = print

local function GetPlayerBagDB()
    BGLite_equip = BGLite_equip or {}
    local db = BGLite_equip.bag
    if not db then db = {}; BGLite_equip.bag = db end
    local r = db[realmID]
    if not r then r = {}; db[realmID] = r end
    local p = r[player]
    if not p then p = {}; r[player] = p end
    if not p.bag then p.bag = {} end
    if not p.bagKey then p.bagKey = {} end
    if not p.bank then p.bank = {} end
    if not p.mail then p.mail = {} end
    if not p.faction then p.faction = {} end
    return p
end

BGE.Init3(GetPlayerBagDB)

BGE.Init(function() -- @shared-db-ok
    -- 背包
    GetPlayerBagDB()

    local function GetBagSlots(bagType)
        if bagType == "bag" then
            if BG.IsRetail then
                return BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS
            else
                return BACKPACK_CONTAINER, BACKPACK_CONTAINER + NUM_BAG_SLOTS
            end
        elseif bagType == "bank" then
            if BG.IsRetail then
                return NUM_TOTAL_EQUIPPED_BAG_SLOTS + 1, NUM_TOTAL_EQUIPPED_BAG_SLOTS + NUM_BANKBAGSLOTS
            else
                return NUM_BAG_SLOTS + 1, NUM_BAG_SLOTS + NUM_BANKBAGSLOTS
            end
        end
    end

    local function SaveFormBagNum(p, b, bagType)
        for i = 1, C_Container.GetContainerNumSlots(b) do
            local info = C_Container.GetContainerItemInfo(b, i)
            if info then
                p[bagType][info.itemID] = (p[bagType][info.itemID] or 0) + info.stackCount
            end
        end
    end
    function BG.SaveBag()
        local p = GetPlayerBagDB()
        wipe(p.bag)
        wipe(p.bagKey)
        local startB, endB = GetBagSlots("bag")
        for b = startB, endB do
            SaveFormBagNum(p, b, "bag")
        end
        SaveFormBagNum(p, -2, "bagKey")
    end

    function BG.SaveBank()
        if BG.IsRetail then return end -- todo
        if not BG.bankIsOpen then return end
        local p = GetPlayerBagDB()
        wipe(p.bank)
        local startB, endB = GetBagSlots("bank")
        for b = startB, endB do
            SaveFormBagNum(p, b, "bank")
        end
        SaveFormBagNum(p, -1, "bank")
    end

    function BG.SaveMail()
        local p = GetPlayerBagDB()
        wipe(p.mail)
        for mailIndex = 1, GetInboxNumItems() do
            local packageIcon, stationeryIcon, sender, subject, money, CODAmount, daysLeft,
            hasItem = GetInboxHeaderInfo(mailIndex)
            if CODAmount <= 0 then
                if hasItem then
                    for itemIndex = 1, ATTACHMENTS_MAX_RECEIVE do
                        local name, itemID, texture, count, quality = GetInboxItem(mailIndex, itemIndex)
                        if itemID then
                            p.mail[itemID] = (p.mail[itemID] or 0) + count
                        end
                    end
                end
            end
        end
    end

    function BG.GetItemBagCount(tbl, itemID)
        return (tbl.bag and tbl.bag[itemID] or 0)
            + (tbl.bagKey and tbl.bagKey[itemID] or 0)
            + (tbl.bank and tbl.bank[itemID] or 0)
            + (tbl.mail and tbl.mail[itemID] or 0)
    end

    BG.RegisterEvent("BAG_UPDATE_DELAYED", function(self, event)
        BG.SaveBag()
        BG.SaveBank()
    end)
    BG.RegisterEvent("BANKFRAME_OPENED", function(self, event)
        BG.bankIsOpen = true
        BG.SaveBank()
    end)
    BG.RegisterEvent("BANKFRAME_CLOSED", function(self, event)
        BG.bankIsOpen = false
    end)
    BG.RegisterEvent("MAIL_INBOX_UPDATE", function(self, event)
        BG.SaveMail()
    end)

    -- 声望
    if not BG.IsRetail then
        GetPlayerBagDB()

        local function SaveReputation()
            if not BG.factionTbl then return end
            local faction = GetPlayerBagDB().faction
            for _, ID in ipairs(BG.factionTbl) do
                local name, description, standingID, barMin, barMax, barValue = GetFactionInfoByID(ID)
                if name then
                    faction[ID] = {
                        name = name,
                        standingID = standingID,
                        currentValue = barValue - barMin,
                        maxValue = barMax - barMin,
                        factionID = ID,
                    }
                end
            end
        end

        BGE.Init2(function()
            After(10, function()
                SaveReputation()
            end)
        end)

        BG.RegisterEvent("UPDATE_FACTION", function(self, event)
            After(.5, function()
                SaveReputation()
            end)
        end)
    end
end)
