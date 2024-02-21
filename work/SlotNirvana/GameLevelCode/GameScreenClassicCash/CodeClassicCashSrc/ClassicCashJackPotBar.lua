---
--xcyy
--2018年5月23日
--ClassicCashJackPotBar.lua

local ClassicCashJackPotBar = class("ClassicCashJackPotBar",util_require("base.BaseView"))


function ClassicCashJackPotBar:initUI()

    self:createCsbNode("ClassicCash_Bonus_kuang.csb")

    self:runCsbAction("idle",true) -- 播放时间线

    self.m_LockGrand = util_createView("CodeClassicCashSrc.ClassicCashLockGrand")
    self:findChild("Jackpot_unlock"):addChild(self.m_LockGrand)
    self.m_LockGrand:runCsbAction("idle",true)
    self.m_LockGrand:setVisible(false)

    self.m_nodeMinor = self:findChild("Node_minor")
    self.m_nodeMini = self:findChild("Node_mini")

    self.m_jackpotPos = {cc.p(-506, 61), cc.p(-123, 61), cc.p(260, 61)}

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_nodeMini:setOpacity(0)
    performWithDelay(self.m_scWaitNode, function()
        self:setJackpotRotation()
    end, 2.0)
end

function ClassicCashJackPotBar:onExit()
 
end

function ClassicCashJackPotBar:setJackpotRotation()
    --major
    local delayTimeFade = 1.0
    local delayTime = 3.0
    local tblMajorActionList = {}
    
    tblMajorActionList[#tblMajorActionList+1] = cc.FadeOut:create(delayTimeFade)
    tblMajorActionList[#tblMajorActionList+1] = cc.DelayTime:create(delayTime)
    tblMajorActionList[#tblMajorActionList+1] = cc.FadeIn:create(delayTimeFade)
    tblMajorActionList[#tblMajorActionList+1] = cc.DelayTime:create(delayTime)
    local majorSeq = cc.Sequence:create(tblMajorActionList)
    self.m_nodeMinor:runAction(cc.RepeatForever:create(majorSeq))

    --mini
    local tblMiniActionList = {}
    tblMiniActionList[#tblMiniActionList+1] = cc.FadeIn:create(delayTimeFade)
    tblMiniActionList[#tblMiniActionList+1] = cc.DelayTime:create(delayTime)
    tblMiniActionList[#tblMiniActionList+1] = cc.FadeOut:create(delayTimeFade)
    tblMiniActionList[#tblMiniActionList+1] = cc.DelayTime:create(delayTime)
    local majorSeq = cc.Sequence:create(tblMiniActionList)
    self.m_nodeMini:runAction(cc.RepeatForever:create(majorSeq))
end

function ClassicCashJackPotBar:initMachine(machine)
    self.m_machine = machine
end

function ClassicCashJackPotBar:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

-- 更新jackpot 数值信息
--
function ClassicCashJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild("m_lb_grand"),1,true,20)
    self:changeNode(self:findChild("m_lb_major"),2,true,20)
    self:changeNode(self:findChild("m_lb_minor"),3,nil,20)
    self:changeNode(self:findChild("m_lb_mini"),4,nil,20)

    self:updateSize()
end

function ClassicCashJackPotBar:updateSize()

    local label1=self.m_csbOwner["m_lb_grand"]
    local label2=self.m_csbOwner["m_lb_major"]
    local info1={label=label1,sx=1.0,sy=1.0}
    local info2={label=label2,sx=0.64,sy=0.64}

    local label3=self.m_csbOwner["m_lb_minor"]
    local label4=self.m_csbOwner["m_lb_mini"]
    local info3={label=label3,sx=0.64,sy=0.64}
    local info4={label=label4,sx=0.64,sy=0.64}

    self:updateLabelSize(info1,525)
    self:updateLabelSize(info2,556)
    self:updateLabelSize(info3,556)
    self:updateLabelSize(info4,556)
end

function ClassicCashJackPotBar:changeNode(label,index,isJump,cut)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,cut))
end

function ClassicCashJackPotBar:toAction(actionName)

    self:runCsbAction(actionName)
end


return ClassicCashJackPotBar