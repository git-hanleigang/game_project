---
--xcyy
--2018年5月23日
--MrCashGoJackPotBarView.lua

local MrCashGoJackPotBarView = class("MrCashGoJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local JackPotNodeName = {
    [1] = "GRAND",
    [2] = "MAJOR",
    [3] = "MINOR",
    [4] = "MINI",
}
function MrCashGoJackPotBarView:initDatas(_machine)
    self.m_machine  = _machine
end
function MrCashGoJackPotBarView:initUI()
    self:createCsbNode("JackPotBarMrCashGo.csb")

    self:initLightAnim()
end

function MrCashGoJackPotBarView:onEnter()

    MrCashGoJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MrCashGoJackPotBarView:onExit()
    MrCashGoJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function MrCashGoJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1)
    self:changeNode(self:findChild(MajorName),2)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function MrCashGoJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local info1={label=label1,sx=1,sy=1}
    local label2=self.m_csbOwner[MajorName]
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=0.9,sy=0.9}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=0.9,sy=0.9}

    self:updateLabelSize(info1, 305)
    self:updateLabelSize(info2, 305)
    self:updateLabelSize(info3, 305)
    self:updateLabelSize(info4, 305)
end

function MrCashGoJackPotBarView:changeNode(label,index)
    local value = self:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function MrCashGoJackPotBarView:BaseMania_updateJackpotScore(index,totalBet)
    if not totalBet then
        totalBet=globalData.slotRunData:getCurTotalBet()
    end
    local jackpotPools = globalData.jackpotRunData:getJackpotList(globalData.slotRunData.machineData.p_id)
    if not jackpotPools[index] then
        return 0
    end
    local totalScore,baseScore = globalData.jackpotRunData:refreshJackpotPool(jackpotPools[index],true,totalBet)
    return totalScore
end

--[[
    光效
]]
function MrCashGoJackPotBarView:initLightAnim()
    --{ [jpIndex] = node }
    self.m_lightList = {}

    for _jpIndex=1,4 do
        local lightSpine = util_spineCreate("JackPotBarMrCashGo_JP",true,true)
        local parent = self:findChild(JackPotNodeName[_jpIndex])
        parent:addChild(lightSpine)

        local idleName = self:getLightIdleName(_jpIndex)
        util_spinePlay(lightSpine, idleName, true)

        self.m_lightList[_jpIndex] = lightSpine
    end

    -- 层级较高的中奖动效
    self.m_topLightSpine = util_spineCreate("JackPotBarMrCashGo_JP",true,true)
    self:addChild(self.m_topLightSpine)
    self.m_topLightSpine:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_topLightSpine, true)
end

function MrCashGoJackPotBarView:playJackpotWinAnim(_jpIndex, _fun)
    local lightSpine = self.m_lightList[_jpIndex]

    self.m_topLightSpine:stopAllActions()
    local pos = util_convertToNodeSpace(lightSpine, self)
    self.m_topLightSpine:setPosition(pos)
    self.m_topLightSpine:setVisible(true)
    lightSpine:setVisible(false)
    -- 
    local animName = _jpIndex <= 2 and "actionframe2" or "actionframe1"
    util_spinePlay(self.m_topLightSpine, animName, false)
    util_spineEndCallFunc(self.m_topLightSpine, animName, function()
        util_spinePlay(self.m_topLightSpine, animName, true)

        
    end)
    -- 第15帧播放下一步流程
    self.m_machine:levelPerformWithDelay(15/30, function()
        _fun()
    end)
end
function MrCashGoJackPotBarView:hideJackpotWinAnim(_jpIndex)
    local lightSpine = self.m_lightList[_jpIndex]

    local actList = {}
    table.insert(actList, cc.FadeOut:create(0.5))
    table.insert(actList, cc.CallFunc:create(function()
        self.m_topLightSpine:setVisible(false)
        self.m_topLightSpine:setOpacity(255)

        lightSpine:setVisible(true)
        local idleName = self:getLightIdleName(_jpIndex)
        util_spinePlay(lightSpine, idleName, true)
    end))

    self.m_topLightSpine:runAction(cc.Sequence:create(actList))
end

function MrCashGoJackPotBarView:getLightIdleName(_jpIndex)
    local idleName = _jpIndex <= 2 and "idle2" or "idle1"
    return idleName
end

return MrCashGoJackPotBarView