---
--xcyy
--2018年5月23日
--TurkeyDayColofulJackPotBar.lua
local PublicConfig = require "TurkeyDayPublicConfig"
local TurkeyDayColofulJackPotBar = class("TurkeyDayColofulJackPotBar",util_require("base.BaseView"))

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

local JACKPOT_INDEX = {
    grand = 1,
    mega = 2,
    major = 3,
    minor = 4,
    mini = 5,
}

function TurkeyDayColofulJackPotBar:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("TurkeyDay_pick_jackpot.csb")
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
            local item = util_createAnimation("TurkeyDay_pick_jiedian.csb")
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
    self.m_jackpotIdleSpineTbl = {}

    local jackpotNodeTbl = {"Node_idle_GRAND", "Node_idle_mega", "Node_idle_major", "Node_idle_minor", "Node_idle_mini"}
    for i=1, self.m_totalCount do
        self.m_jackpotIdleSpineTbl[i] = util_spineCreate("TurkeyDay_pick_jackpot",true,true)
        self:findChild(jackpotNodeTbl[i]):addChild(self.m_jackpotIdleSpineTbl[i])
    end

    local jackpotTriggerNodeTbl = {"Node_grand", "Node_mega", "Node_major", "Node_minor", "Node_mini"}
    self.m_jackpotLightAniTbl = {}
    for i=1, self.m_totalCount do
        self.m_jackpotLightAniTbl[i] = util_createAnimation("TurkeyDay_pick_jackpot_zj.csb")
        self:findChild(jackpotTriggerNodeTbl[i]):addChild(self.m_jackpotLightAniTbl[i])
    end

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:setJackpotIdle(1)
end

-- 播放jackpot-idle
function TurkeyDayColofulJackPotBar:setJackpotIdle(_curIndex)
    local curIndex = _curIndex
    if curIndex == 1 then
        for k, v in pairs(self.m_jackpotIdleSpineTbl) do
            v:setVisible(false)
        end
    end

    local jackpotIdleNameTbl = {"idle_GRAND", "idle_mega", "idle_major", "idle_minor", "idle_mini"}
    -- 间隔播放jackpot-idle
    if curIndex <= self.m_totalCount then
         local tblActionList = {}
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_jackpotIdleSpineTbl[curIndex]:setVisible(true)
            util_spinePlay(self.m_jackpotIdleSpineTbl[curIndex], jackpotIdleNameTbl[curIndex], true)
        end)
        -- 播到第40帧再开始播下一个
        -- tblActionList[#tblActionList+1] = cc.DelayTime:create(40/60)
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self:setJackpotIdle(curIndex+1)
        end)
        local seq = cc.Sequence:create(tblActionList)
        self.m_scWaitNode:runAction(seq)
    end
end

function TurkeyDayColofulJackPotBar:onEnter()

    TurkeyDayColofulJackPotBar.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end, 0.08)
end

function TurkeyDayColofulJackPotBar:onExit()
    TurkeyDayColofulJackPotBar.super.onExit(self)
end

function TurkeyDayColofulJackPotBar:initMachine(machine)
    self.m_machine = machine
end

--[[
    重置界面显示
]]
function TurkeyDayColofulJackPotBar:resetView()
    for jackpotType,itemList in pairs(self.m_collectItems) do
        self.m_toBeTriggeredEffectTbl[jackpotType] = {}
        self.m_collectProcess[jackpotType] = 0
        for index,item in ipairs(itemList) do
            item:setVisible(false)
        end
    end

    for index,lightAni in pairs(self.m_jackpotLightAniTbl) do
        lightAni:setVisible(false)
    end
    self:runIdleAni()
end

--[[
    重置除中奖外的界面显示
]]
function TurkeyDayColofulJackPotBar:resetTriggerView(_triggerType)
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
function TurkeyDayColofulJackPotBar:collectFeedBackAni(_jackpotType, _pointItem)
    local jackpotType = _jackpotType
    local pointItem = _pointItem
    local curCollectCount = self.m_collectProcess[jackpotType]
    local finalItem = self.m_collectItems[jackpotType][3]
    if pointItem then
        pointItem:setVisible(true)
        pointItem:runCsbAction("actionframe", false, function()
            if curCollectCount == 2 and finalItem then
                finalItem:setVisible(true)
                finalItem:runCsbAction("idle", true)
                self.m_toBeTriggeredEffectTbl[jackpotType][#self.m_toBeTriggeredEffectTbl[jackpotType]+1] = finalItem
            end
            pointItem:runCsbAction("idleframe", true)
        end)
    end
end

--[[
    获取收集反馈点
]]
function TurkeyDayColofulJackPotBar:getFeedBackPoint(jackpotType,index)
    local itemList = self.m_collectItems[jackpotType]
    return itemList[index]
end

--[[
    获取收集进度
]]
function TurkeyDayColofulJackPotBar:getProcessByType(jackpotType)
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
function TurkeyDayColofulJackPotBar:showHitLight(jackpotType)
    local jackpotIndex = JACKPOT_INDEX[jackpotType]
    self.m_jackpotLightAniTbl[jackpotIndex]:setVisible(true)
    self.m_jackpotLightAniTbl[jackpotIndex]:runCsbAction("actionframe",true)
end

--[[
    idle
]]
function TurkeyDayColofulJackPotBar:runIdleAni()
    -- self:runCsbAction("idleframe",true)
end

-- 更新jackpot 数值信息
--
function TurkeyDayColofulJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function TurkeyDayColofulJackPotBar:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MegaName]
    local label3=self.m_csbOwner[MajorName]
    local label4=self.m_csbOwner[MinorName]
    local label5=self.m_csbOwner[MiniName]

    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local info3={label=label3,sx=1,sy=1}
    local info4={label=label4,sx=1,sy=1}
    local info5={label=label5,sx=1,sy=1}
    self:updateLabelSize(info1,245)
    self:updateLabelSize(info2,245)
    self:updateLabelSize(info3,245)
    self:updateLabelSize(info4,245)
    self:updateLabelSize(info5,245)
end

function TurkeyDayColofulJackPotBar:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value,20,nil,nil,true))
end

return TurkeyDayColofulJackPotBar
