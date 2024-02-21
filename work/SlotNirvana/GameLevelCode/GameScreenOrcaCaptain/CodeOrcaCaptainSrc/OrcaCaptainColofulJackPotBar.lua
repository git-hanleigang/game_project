---
--xcyy
--2018年5月23日
--OrcaCaptainColofulJackPotBar.lua
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainColofulJackPotBar = class("OrcaCaptainColofulJackPotBar",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5
}

function OrcaCaptainColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("OrcaCaptain_jackpot_dfdc.csb")
    self:runIdleAni()

    self.m_collectItems = {}    --所有的收集点
    self.m_collectProcess = {}  --所有的收集进度
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_collectItems[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        for index = 1,3 do
            local item = util_createAnimation("OrcaCaptain_jackpot_dfdc_1.csb")
            --设置收集点的jackpot显示
            -- for tempType,tempIndex in pairs(JACKPOT_INDEX) do
            --     if item:findChild(tempType) then
            --         item:findChild(tempType):setVisible(tempType == jackpotType)
            --     end
            -- end
            self.m_collectItems[jackpotType][index] = item
            item:runCsbAction("idle")
            item.m_runActName = "idle"
            local parentNode = self:findChild("Node_"..jackpotType.."_"..index)
            if parentNode then
                parentNode:addChild(item)
            end
        end
    end
end

function OrcaCaptainColofulJackPotBar:onEnter()

    OrcaCaptainColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function OrcaCaptainColofulJackPotBar:onExit()
    OrcaCaptainColofulJackPotBar.super.onExit(self)
end

function OrcaCaptainColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置界面显示
]]
function OrcaCaptainColofulJackPotBar:resetView()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_collectProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            item:runCsbAction("idle")
            item.m_runActName = "idle"
            -- item:setVisible(false)
        end
    end
    self:runIdleAni()
end

--[[
    收集反馈动效
]]
function OrcaCaptainColofulJackPotBar:collectFeedBackAni(jackpotType,pointItem)
    if pointItem then
        -- pointItem:setVisible(true)
        pointItem.m_runActName = "start"
        pointItem:runCsbAction("start",false,function ()
            pointItem.m_runActName = "idle2"
            pointItem:runCsbAction("idle2",true)
        end)
    end
    self:nextTriggerAni(jackpotType)        --待触发动效
end

--待触发动效
function OrcaCaptainColofulJackPotBar:nextTriggerAni(jackpotType)
    local process = self.m_collectProcess[jackpotType]
    if process == 2 then
        local item = self:getFeedBackPoint(jackpotType,process + 1)
        if not tolua.isnull(item) then
            item.m_runActName = "idle3"
            item:runCsbAction("idle3",true)
        end
    end
end

function OrcaCaptainColofulJackPotBar:resetNextTriggerItemAct()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_collectProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            if not tolua.isnull(item) and item.m_runActName == "idle3" then
                item:runCsbAction("idle")
                item.m_runActName = "idle"
            end
        end
    end
end

--[[
    获取收集反馈点
]]
function OrcaCaptainColofulJackPotBar:getFeedBackPoint(jackpotType,index)
    local itemList = self.m_collectItems[jackpotType]
    return itemList[index]
end

--[[
    获取收集进度
]]
function OrcaCaptainColofulJackPotBar:getProcessByType(jackpotType)
    self.m_collectProcess[jackpotType] = self.m_collectProcess[jackpotType] + 1
    --检测进度是否集满
    if self.m_collectProcess[jackpotType] >= 3 then
        self.m_collectProcess[jackpotType] = 3
    end
    return self.m_collectProcess[jackpotType]
end

--[[
    显示中奖光效
]]
function OrcaCaptainColofulJackPotBar:showHitLight(jackpotType)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OrcaCaptain_color_collect_jp)
    self:resetNextTriggerItemAct()
    local jackpotIndex = JACKPOT_INDEX[jackpotType]
    -- self:runCsbAction("actionframe"..jackpotIndex,true)
    self:runCsbAction("zhongjiang",true)
    for tempType,tempIndex in pairs(JACKPOT_INDEX) do
        if self:findChild("light_"..tempIndex) then
            self:findChild("light_"..tempIndex):setVisible(tempType == jackpotType)
        end
    end
    
end

--[[
    idle
]]
function OrcaCaptainColofulJackPotBar:runIdleAni()
    self:runCsbAction("idle",true)
end

-- 更新jackpot 数值信息
--
function OrcaCaptainColofulJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self:findChild(MegaName), 2, true)
    self:changeNode(self:findChild(MajorName), 3, true)
    self:changeNode(self:findChild(MinorName), 4)
    self:changeNode(self:findChild(MiniName), 5)

    self:updateSize()
end

function OrcaCaptainColofulJackPotBar:updateSize()

    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 1.01, sy = 1}
    local info2 = {label = label2, sx = 0.84, sy = 0.82}
    local info3 = {label = label3, sx = 0.84, sy = 0.82}
    local info4 = {label = label4, sx = 0.78, sy = 0.78}
    local info5 = {label = label5, sx = 0.78, sy = 0.78}

    self:updateLabelSize(info1, 365)
    self:updateLabelSize(info2, 356)
    self:updateLabelSize(info3, 356)
    self:updateLabelSize(info4, 331)
    self:updateLabelSize(info5, 331)
end

function OrcaCaptainColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end




return OrcaCaptainColofulJackPotBar