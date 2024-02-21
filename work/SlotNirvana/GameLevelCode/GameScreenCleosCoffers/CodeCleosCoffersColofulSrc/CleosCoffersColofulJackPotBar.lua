---
--xcyy
--2018年5月23日
--CleosCoffersColofulJackPotBar.lua
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersColofulJackPotBar = class("CleosCoffersColofulJackPotBar",util_require("base.BaseView"))

local GrandName = "m_lb_grand"
local MegaName = "m_lb_mega"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini"

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5,
}

function CleosCoffersColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("CleosCoffers_dfdc_jackpot.csb")
    self:runIdleAni()

    -- 待触发的特效
    self.m_toBeTriggeredEffectTbl = {}
    self.m_collectItems = {}    --所有的收集点
    self.m_collectProcess = {}  --所有的收集进度
    for jackpotType,jackpotIndex in pairs(JACKPOT_INDEX) do
        self.m_toBeTriggeredEffectTbl[jackpotType] = {}
        self.m_collectItems[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        for index = 1,3 do
            local item = util_createAnimation("CleosCoffers_dfdc_jackpot_collect.csb")
            --设置收集点的jackpot显示
            for tempType,tempIndex in pairs(JACKPOT_INDEX) do
                if item:findChild(tempType) then
                    item:findChild(tempType):setVisible(tempType == jackpotType)
                end
            end
            self.m_collectItems[jackpotType][index] = item
            local parentNode = self:findChild("Node_"..jackpotType.."_"..index)
            if parentNode then
                parentNode:addChild(item)
            end
        end
    end

    self.m_totalCount = 5

    local jackpotTriggerNodeTbl = {"Node_tx1", "Node_tx2", "Node_tx3", "Node_tx4", "Node_tx5"}
    self.m_jackpotLightSpineTbl = {}
    for i=1, self.m_totalCount do
        self.m_jackpotLightSpineTbl[i] = util_spineCreate("CleosCoffers_dfdc_jackpot_tx",true,true)
        self:findChild(jackpotTriggerNodeTbl[i]):addChild(self.m_jackpotLightSpineTbl[i])
        self.m_jackpotLightSpineTbl[i]:setVisible(false)
    end

    -- 基础倍数
    self:setOldMul(1)
    self:setNewMul(1)
    self:setIntervaMul(0)
    self.m_scScheduleNode = cc.Node:create()
    self:addChild(self.m_scScheduleNode)
end

function CleosCoffersColofulJackPotBar:onEnter()

    CleosCoffersColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function CleosCoffersColofulJackPotBar:onExit()
    if self.m_scScheduleNode ~= nil then
        self.m_scScheduleNode:unscheduleUpdate()
    end
    CleosCoffersColofulJackPotBar.super.onExit(self)
end

function CleosCoffersColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置界面显示
]]
function CleosCoffersColofulJackPotBar:resetView()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_toBeTriggeredEffectTbl[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            item:setVisible(false)
        end
    end

    for index, lightSpine in pairs(self.m_jackpotLightSpineTbl) do
        lightSpine:setVisible(false)
    end
    self:runIdleAni()
end

--[[
    重置除中奖外的界面显示
]]
function CleosCoffersColofulJackPotBar:resetTriggerView(_triggerType)
    local triggerType = _triggerType
    for jackpotType,itemList in pairs(self.m_toBeTriggeredEffectTbl) do
        if jackpotType ~= triggerType then
            for index,item in ipairs(itemList) do
                item:setVisible(false)
            end
        end
    end
end

--[[
    收集反馈动效
]]
function CleosCoffersColofulJackPotBar:collectFeedBackAni(_jackpotType, _pointItem)
    local jackpotType = _jackpotType
    local pointItem = _pointItem
    local curCollectCount = self.m_collectProcess[jackpotType]
    local finalItem = self.m_collectItems[jackpotType][3]
    if pointItem then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_Collect_FeedBack)
        pointItem:setVisible(true)
        pointItem:runCsbAction("shouji", false, function()
            if curCollectCount == 2 and finalItem then
                finalItem:setVisible(true)
                finalItem:runCsbAction("idle2", true)
                self.m_toBeTriggeredEffectTbl[jackpotType][#self.m_toBeTriggeredEffectTbl[jackpotType]+1] = finalItem
            end
            pointItem:runCsbAction("idle3", true)
        end)
    end
end

--[[
    获取收集反馈点
]]
function CleosCoffersColofulJackPotBar:getFeedBackPoint(jackpotType,index)
    local itemList = self.m_collectItems[jackpotType]
    return itemList[index]
end

--[[
    获取收集进度
]]
function CleosCoffersColofulJackPotBar:getProcessByType(jackpotType)
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
function CleosCoffersColofulJackPotBar:showHitLight(_jackpotType)
    local jackpotType = string.lower(_jackpotType)
    local jackpotActNameTbl = {"dfdc_grand", "dfdc_mega", "dfdc_major", "dfdc_minor", "dfdc_mini"}
    local jackpotIndex = JACKPOT_INDEX[jackpotType]
    if self.m_jackpotLightSpineTbl[jackpotIndex] then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_jackpot_TriggerLight)
        self.m_jackpotLightSpineTbl[jackpotIndex]:setVisible(true)
        util_spinePlay(self.m_jackpotLightSpineTbl[jackpotIndex], jackpotActNameTbl[jackpotIndex], true)
    end
end

--[[
    jackpot增加光效
]]
function CleosCoffersColofulJackPotBar:showAddJackpotHitLight(_jackpotType)
    local jackpotActNameTbl = {"dfdc_grand2", "dfdc_mega2", "dfdc_major2", "dfdc_minor2", "dfdc_mini2"}
    for jackpotIndex=1, self.m_totalCount do
        if self.m_jackpotLightSpineTbl[jackpotIndex] then
            self.m_jackpotLightSpineTbl[jackpotIndex]:setVisible(true)
            util_spinePlay(self.m_jackpotLightSpineTbl[jackpotIndex], jackpotActNameTbl[jackpotIndex], false)
            util_spineEndCallFunc(self.m_jackpotLightSpineTbl[jackpotIndex], jackpotActNameTbl[jackpotIndex], function()
                self.m_jackpotLightSpineTbl[jackpotIndex]:setVisible(false)
            end)
        end
    end
end

--[[
    idle
]]
function CleosCoffersColofulJackPotBar:runIdleAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle",true)
end

function CleosCoffersColofulJackPotBar:runTriggerBuffAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:runIdleAni()
    end)
end

-- 更新jackpot 数值信息
--
function CleosCoffersColofulJackPotBar:updateJackpotInfo()
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

function CleosCoffersColofulJackPotBar:updateSize()
    local label1 = self.m_csbOwner[GrandName]
    local label2 = self.m_csbOwner[MegaName]
    local label3 = self.m_csbOwner[MajorName]
    local label4 = self.m_csbOwner[MinorName]
    local label5 = self.m_csbOwner[MiniName]

    local info1 = {label = label1, sx = 0.87, sy = 0.87}
    local info2 = {label = label2, sx = 0.71, sy = 0.71}
    local info3 = {label = label3, sx = 0.71, sy = 0.71}
    local info4 = {label = label4, sx = 0.67, sy = 0.67}
    local info5 = {label = label5, sx = 0.67, sy = 0.67}

    self:updateLabelSize(info1, 372)
    self:updateLabelSize(info2, 372)
    self:updateLabelSize(info3, 361)
    self:updateLabelSize(info4, 355)
    self:updateLabelSize(info5, 355)
end

-- 之前的倍数
function CleosCoffersColofulJackPotBar:setOldMul(_baseMul)
    self.m_baseMul = _baseMul
end

function CleosCoffersColofulJackPotBar:getOldMul()
    return self.m_baseMul
end

-- 最新的倍数
function CleosCoffersColofulJackPotBar:setNewMul(_nowMul, _isAdd)
    self.m_newMul = _nowMul
    if _isAdd then
        self:runTriggerBuffAni()
        self:setIntervaMul(self:getNewMul() - self:getOldMul())
        self:startAddJackpotCoins()
    end
end

function CleosCoffersColofulJackPotBar:getNewMul()
    return self.m_newMul
end

-- 现在和上次倍数的差值
function CleosCoffersColofulJackPotBar:setIntervaMul(_intervaMul)
    self.m_intervaMul = _intervaMul
end

function CleosCoffersColofulJackPotBar:getIntervaMul()
    return self.m_intervaMul
end

function CleosCoffersColofulJackPotBar:startAddJackpotCoins()
    if self.m_scScheduleNode ~= nil then
        self.m_scScheduleNode:onUpdate(function(delayTime)
            self:addCurJackpotMul(delayTime)
        end)
    end
end

function CleosCoffersColofulJackPotBar:addCurJackpotMul(_delayTime)
    local delayTime = _delayTime
    local totalTime = 1.5
    local curMul = self:getOldMul() + delayTime/totalTime*self:getIntervaMul()
    if curMul >= self:getNewMul() then
        self:setOldMul(self:getNewMul())
        if self.m_scScheduleNode ~= nil then
            self.m_scScheduleNode:unscheduleUpdate()
        end
    else
        self:setOldMul(curMul)
    end
end

function CleosCoffersColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    local addJackpotState = self.m_machine:getAddJackptState()
    if addJackpotState then
        value = value*self:getOldMul()
    end
    label:setString(util_formatCoins(value,12,nil,nil,true))
end

return CleosCoffersColofulJackPotBar
