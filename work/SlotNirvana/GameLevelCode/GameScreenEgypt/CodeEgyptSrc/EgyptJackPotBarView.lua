---
--xcyy
--2018年5月23日
--EgyptJackPotBarView.lua

local EgyptJackPotBarView = class("EgyptJackPotBarView",util_require("base.BaseView"))

local JACKPOT_LAB_NAME = 
{
    "rapid_5",
    "rapid_6",
    "rapid_7",
    "rapid_8",
    "rapid_9"
}

local JACKPOT_LAB_SCALE = 
{
    0.66,
    0.72,
    0.76,
    0.82,
    0.9
}

local JACKPOT_INDEX = {5, 6, 7, 8, 9}


function EgyptJackPotBarView:initUI()

    self:createCsbNode("Egypt_Jackpot.csb")

    self:runCsbAction("idle",true)
    self.m_lockNode = {}
    self.m_lockParent = {}
    for i = 2, #JACKPOT_INDEX, 1 do
        local lock = util_createView("CodeEgyptSrc.EgyptViewJackpotLock", i - 1)
        local parent = self:findChild("lock"..JACKPOT_INDEX[i])
        parent:addChild(lock)
        self.m_lockNode[JACKPOT_INDEX[i]] = lock
        self.m_lockParent[JACKPOT_INDEX[i]] = parent
    end

    local effect = util_createView("CodeEgyptSrc.EgyptJackpotEffect")
    self:findChild("Node_zhongjiang"):addChild(effect)
end

function EgyptJackPotBarView:initUnlockCoin(vecBet)
    for i = 1, #vecBet, 1 do 
        self.m_lockNode[JACKPOT_INDEX[i + 1]]:initLabBet(vecBet[i].p_totalBetValue)
    end
end

function EgyptJackPotBarView:onExit()
 
end

function EgyptJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function EgyptJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function EgyptJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    local iJackpotNum = #JACKPOT_LAB_NAME
    for i = 1, iJackpotNum, 1 do
        self:changeNode(self:findChild(JACKPOT_LAB_NAME[i]), iJackpotNum - i + 1, true)
        self:changeNode(self:findChild(JACKPOT_LAB_NAME[i].."_lock") , iJackpotNum - i + 1, true)
    end

    self:updateSize()
end

function EgyptJackPotBarView:updateSize()

    for i = 1, #JACKPOT_LAB_SCALE, 1 do
        local label1 = self.m_csbOwner[JACKPOT_LAB_NAME[i]]
        local info1={label = label1,sx = JACKPOT_LAB_SCALE[i], sy = JACKPOT_LAB_SCALE[i]}

        local label2 = self.m_csbOwner[JACKPOT_LAB_NAME[i].."_lock"]
        local info2={label = label2,sx = JACKPOT_LAB_SCALE[i], sy = JACKPOT_LAB_SCALE[i]}

        self:updateLabelSize(info1,387)
        self:updateLabelSize(info2,387)
    end

end

function EgyptJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,30,nil,nil,true))
end

function EgyptJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

function EgyptJackPotBarView:updateUI(betID)
    for i = 1, betID, 1 do
        self:findChild(JACKPOT_LAB_NAME[i]):setVisible(true)
        self:findChild(JACKPOT_LAB_NAME[i].."_lock"):setVisible(false)
        if i > 1 then
            self.m_lockParent[JACKPOT_INDEX[i]]:setVisible(false)
            self.m_lockNode[JACKPOT_INDEX[i]]:showUnlock()
        end
    end
    for i = betID + 1, 5, 1 do
        self:findChild(JACKPOT_LAB_NAME[i]):setVisible(false)
        self:findChild(JACKPOT_LAB_NAME[i].."_lock"):setVisible(true)
        self.m_lockParent[JACKPOT_INDEX[i]]:setVisible(true)
        self.m_lockNode[JACKPOT_INDEX[i]]:showLock()
    end
end

function EgyptJackPotBarView:showJackpot(num, isFire)
    self:runCsbAction("win"..num, true)

    local effectNode, effectAct = util_csbCreate("Egypt_Jackpot_Effect.csb")
    util_csbPlayForKey(effectAct, "idleframe", true)
    if isFire then
        local fire = self:findChild("Fire_"..num)
        fire:getParent():addChild(effectNode)
        effectNode:setPosition(fire:getPositionX(), fire:getPositionY())
    else
        local jackpot = self:findChild("Jackpot_"..num)
        jackpot:getParent():addChild(effectNode)
        effectNode:setPosition(jackpot:getPositionX(), jackpot:getPositionY())
    end
    self.m_effectNode = effectNode
end

function EgyptJackPotBarView:showIdle()
    self:runCsbAction("idle",true)
    if self.m_effectNode ~= nil then
        self.m_effectNode:removeFromParent()
        self.m_effectNode = nil
    end
end

return EgyptJackPotBarView