local _, ns = ...

local LibBG = ns.LibBG
local L = ns.L

local Size = ns.Size
local RGB = ns.RGB
local GetClassRGB = ns.GetClassRGB
local SetClassCFF = ns.SetClassCFF
local TongBao = ns.TongBao
local XiaoFei = ns.XiaoFei
local Classpx = ns.Classpx
local WCLpm = ns.WCLpm
local WCLcolor = ns.WCLcolor
local Trade = ns.Trade
local Maxb = ns.Maxb
local BossNum = ns.BossNum

local pt = print

BG.bossModels = {}
local buttons = {}
local CreateAllTestButton
do
    local function OnClick(self)
        local func_get = self.func_get
        local func_set = self.func_set
        local deltaPitch

        if self._type3 then
            if self._type == "+" then
                deltaPitch = 0.5
            else
                deltaPitch = -0.5
            end

            local z, x, y = func_get(self.owner)
            if self._type3 == "z" then
                z = z + deltaPitch
            end
            if self._type3 == "x" then
                x = x + deltaPitch
            end
            if self._type3 == "y" then
                y = y + deltaPitch
            end
            func_set(self.owner, z, x, y)
            print(self._type2 .. ": " .. z .. " " .. x .. " " .. y)
        else
            if self._type == "+" then
                deltaPitch = 0.05
            else
                deltaPitch = -0.05
            end
            local currentPitch = func_get(self.owner)
            local newPitch = currentPitch + deltaPitch
            func_set(self.owner, newPitch)
            print(self._type2 .. ": " .. newPitch)
        end
    end
    local function OnMouseDown(self)
        local t = 0
        local t_do = 0.3
        self:SetScript("OnUpdate", function(self, elapsed)
            t = t + elapsed
            if t >= t_do then
                t = t_do - 0.1
                OnClick(self)
            end
        end)
    end
    local function OnMouseUp(self)
        self:SetScript("OnUpdate", nil)
    end
    local function OnEnter(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP", 0, 0)
        GameTooltip:ClearLines()
        GameTooltip:AddLine(self._type2, 1, 1, 1, true)
        GameTooltip:Show()
    end
    local function CreateButton(model, _type2, func_get, func_set, _type3)
        local tbl = { "+", "-" }
        for i = 1, 2 do
            local bt = CreateFrame("Button", nil, BG.MainFrame, "UIPanelButtonTemplate")
            bt:SetSize(40, 25)
            if not buttons[1] then
                bt:SetPoint("BOTTOMLEFT", BG.MainFrame, "TOPLEFT", 0, 2)
            else
                if i == 2 then
                    bt:SetPoint("LEFT", buttons[#buttons], "RIGHT", 0, 0)
                else
                    bt:SetPoint("LEFT", buttons[#buttons], "RIGHT", 5, 0)
                end
            end
            bt.owner = model
            bt._type = tbl[i]
            bt._type2 = _type2
            bt.func_get = func_get
            bt.func_set = func_set
            bt._type3 = _type3
            bt:SetText(tbl[i])
            bt:SetScript("OnClick", OnClick)
            bt:SetScript("OnEnter", OnEnter)
            bt:SetScript("OnLeave", GameTooltip_Hide)
            bt:SetScript("OnMouseDown", OnMouseDown)
            bt:SetScript("OnMouseUp", OnMouseUp)
            tinsert(buttons, bt)
        end
    end
    CreateAllTestButton = function(model)
        CreateButton(model, L["左右"], model.GetFacing, model.SetFacing)
        CreateButton(model, L["上下"], model.GetPitch, model.SetPitch)
        CreateButton(model, L["倾斜"], model.GetRoll, model.SetRoll)
        CreateButton(model, L["位置z"], model.GetPosition, model.SetPosition, "z")
        CreateButton(model, L["位置x"], model.GetPosition, model.SetPosition, "x")
        CreateButton(model, L["位置y"], model.GetPosition, model.SetPosition, "y")

        model:SetBackdrop({
            edgeFile = "Interface/ChatFrame/ChatFrameBackground",
            edgeSize = 2,
        })
        BG.lastModel = model
    end
end

local function UpdateModel(model, NPCID)
    model:SetScript("OnShow", function(self)
        model:SetCreature(NPCID)
    end)
end

-- BOSS模型
-- local function CreateBossModel(FB, bossnum, point_x, point_y, NPCID, scale, ModelScene)
--     local model = CreateFrame(ModelScene and "ModelScene" or "PlayerModel", nil, BG["Frame" .. FB], "BackdropTemplate")
--     model:SetSize(500, 500)
--     model:SetPoint("CENTER", BG.Frame[FB]["boss" .. bossnum].bossName, "CENTER", point_x, point_y)
--     model:SetFrameLevel(101)
--     model:SetAlpha(0.8)
--     model:SetScale(scale or 1)
--     if ModelScene then
--         model.actor = model:CreateActor()
--         model.actor:SetModelByCreatureDisplayID(NPCID)
--     end
--     model:SetScript("OnShow", function(self)
--         if ModelScene then
--             model.actor:SetModelByCreatureDisplayID(NPCID)
--         else
--             model:SetCreature(NPCID)
--         end
--     end)
--     tinsert(BG.bossModels, model)
--     return model
-- end
local function CreateBossModel(FB, bossnum, point_x, point_y, NPCID, scale)
    local model = CreateFrame("PlayerModel", nil, BG["Frame" .. FB], "BackdropTemplate")
    model:SetSize(500, 500)
    model:SetPoint("CENTER", BG.Frame[FB]["boss" .. bossnum].bossName, "CENTER", point_x, point_y)
    model:SetFrameLevel(101)
    model:SetAlpha(0.8)
    model:SetScale(scale or 1)
    model:SetCreature(NPCID)
    model:SetScript("OnShow", function(self)
        model:SetCreature(NPCID)
    end)
    tinsert(BG.bossModels, model)
    return model
end
function BG.CreateBossModel()
    local model = CreateBossModel("UBRSforever", 4, 20, 90, 10363, 0.6) -- 达基萨斯将军
    model:SetPosition(0, 0, 0)
    model:SetFacing(-0.2)
    model:SetPitch(0)
    model:SetRoll(0)
    -- CreateAllTestButton(model)

    local model = CreateBossModel("OLforever", 1, 15, -10, 10184, 0.75)
    model:SetPosition(-5, 0, 5)
    model:SetFacing(-0.2)
    model:SetPitch(1)
    model:SetRoll(-0.1)
    -- CreateAllTestButton(model)
end
