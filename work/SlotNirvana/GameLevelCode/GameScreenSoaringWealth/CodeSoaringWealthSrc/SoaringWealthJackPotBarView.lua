---
--xcyy
--2018年5月23日
--SoaringWealthJackPotBarView.lua

local SoaringWealthJackPotBarView = class("SoaringWealthJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_GrandCoins"
local MegaName = "m_lb_MegaCoins"
local MajorName = "m_lb_MegaCoins_0"
local MinorName = "m_lb_MinorCoins"
local MiniName = "m_lb_MiniCoins" 

function SoaringWealthJackPotBarView:initUI()

    self:createCsbNode("SoaringWealth_JackpotView.csb")
    self:initData()

    self.m_Minor = util_createAnimation("SoaringWealth_Jackpot_Minor.csb")
    self:findChild("Node_Minor"):addChild(self.m_Minor)

    self.m_Mini = util_createAnimation("SoaringWealth_Jackpot_Mini.csb")
    self:findChild("Node_Mini"):addChild(self.m_Mini)
    
    self.tblPanel[1] = self:findChild("Panel_Left")
    self.tblPanel[2] = self:findChild("Panel_Right")

    self.tblLeftNode[1] = self:findChild("Node_Minor")
    self.tblLeftNode[2] = self:findChild("Node_Mega")

    self.tblRightNode[1] = self:findChild("Node_Mini")
    self.tblRightNode[2] = self:findChild("Node_Major")

    -- self:runCsbAction("idleframe",true)

end

function SoaringWealthJackPotBarView:initData()
    self.barState = false
    self.tblLeftNode = {}
    self.tblRightNode= {}
    self.tblPanel = {}
    self.tblLeftPos = {cc.p(120, -15), cc.p(120, 57), cc.p(120, 136)}
    self.tblRightPos = {cc.p(119, -15), cc.p(119, 57), cc.p(119, 136)}
end

function SoaringWealthJackPotBarView:onEnter()

    SoaringWealthJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function SoaringWealthJackPotBarView:onExit()
    SoaringWealthJackPotBarView.super.onExit(self)
end

function SoaringWealthJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function SoaringWealthJackPotBarView:setMinorAndMiniAni(_antionName, _idleName, _callFunc)
    local antionName = _antionName
    local idleName = _idleName
    local callFunc = _callFunc
    self.m_Minor:runCsbAction(antionName, false, function()
        self.m_Minor:runCsbAction(idleName, true)
    end)
    self.m_Mini:runCsbAction(antionName, false, function()
        self.m_Mini:runCsbAction(idleName, true)
        if callFunc then
            callFunc()
            callFunc = nil
        end
    end)
end

function SoaringWealthJackPotBarView:runBarAction()
    if self.barState then
        local callFunc = function()
            for i=1, 2 do
                self.tblPanel[i]:setClippingEnabled(true)
            end
            self:playLeftAni_1()
            self:playLeftAni_2()
            self:playRightAni_1()
            self:playRightAni_2()
        end
        self:setMinorAndMiniAni("xiaoshi", "idle1", callFunc)
    end
end

function SoaringWealthJackPotBarView:playLeftAni_1()
    self.leftActionList_1 = {}

    local setStartPos = function()
        self.tblLeftNode[2]:setPosition(self.tblLeftPos[1])
    end
    local endFuncPos = function()
        if not self.barState then
            self.tblLeftNode[2]:stopAllActions()
            self.tblPanel[1]:setClippingEnabled(false)
            self:setMinorAndMiniAni("chuxian", "idle1")
        end
    end

    self.leftActionList_1[#self.leftActionList_1+1] = cc.MoveTo:create(1.0, self.tblLeftPos[3])
    self.leftActionList_1[#self.leftActionList_1+1] = cc.DelayTime:create(2.0)
    self.leftActionList_1[#self.leftActionList_1+1] = cc.CallFunc:create(function()
        setStartPos()
    end)
    self.leftActionList_1[#self.leftActionList_1+1] = cc.MoveTo:create(1.0, self.tblLeftPos[2])
    self.leftActionList_1[#self.leftActionList_1+1] = cc.CallFunc:create(function()
        endFuncPos()
    end)
    self.leftActionList_1[#self.leftActionList_1+1] = cc.DelayTime:create(2.0)
    local seq = cc.RepeatForever:create(cc.Sequence:create(self.leftActionList_1))
    self.tblLeftNode[2]:runAction(seq)
end

function SoaringWealthJackPotBarView:playLeftAni_2()
    self.leftActionList_2 = {}

    local setStartPos = function()
        self.tblLeftNode[1]:setPosition(self.tblLeftPos[1])
    end
    
    self.leftActionList_2[#self.leftActionList_2+1] = cc.MoveTo:create(1.0, self.tblLeftPos[2])
    self.leftActionList_2[#self.leftActionList_2+1] = cc.DelayTime:create(2.0)
    self.leftActionList_2[#self.leftActionList_2+1] = cc.MoveTo:create(1.0, self.tblLeftPos[3])
    self.leftActionList_2[#self.leftActionList_2+1] = cc.CallFunc:create(function()
        setStartPos()
        if not self.barState then
            self.tblLeftNode[1]:stopAllActions()
            self:setMinorAndMiniAni("chuxian", "idle1")
        end
    end)
    self.leftActionList_2[#self.leftActionList_2+1] = cc.DelayTime:create(2.0)
    local seq = cc.RepeatForever:create(cc.Sequence:create(self.leftActionList_2))
    self.tblLeftNode[1]:runAction(seq)
end

function SoaringWealthJackPotBarView:playRightAni_1()
    self.rightActionList_1 = {}

    local setStartPos = function()
        self.tblRightNode[2]:setPosition(self.tblRightPos[1])
    end
    local endFuncPos = function()
        if not self.barState then
            self.tblRightNode[2]:stopAllActions()
            self.tblPanel[2]:setClippingEnabled(false)
            self:setMinorAndMiniAni("chuxian", "idle1")
        end
    end

    self.rightActionList_1[#self.rightActionList_1+1] = cc.MoveTo:create(1.0, self.tblRightPos[3])
    self.rightActionList_1[#self.rightActionList_1+1] = cc.DelayTime:create(2.0)
    self.rightActionList_1[#self.rightActionList_1+1] = cc.CallFunc:create(function()
        setStartPos()
    end)
    self.rightActionList_1[#self.rightActionList_1+1] = cc.MoveTo:create(1.0, self.tblRightPos[2])
    self.rightActionList_1[#self.rightActionList_1+1] = cc.CallFunc:create(function()
        endFuncPos()
    end)
    self.rightActionList_1[#self.rightActionList_1+1] = cc.DelayTime:create(2.0)
    local seq = cc.RepeatForever:create(cc.Sequence:create(self.rightActionList_1))
    self.tblRightNode[2]:runAction(seq)
end

function SoaringWealthJackPotBarView:playRightAni_2()
    self.rightActionList_2 = {}

    local setStartPos = function()
        self.tblRightNode[1]:setPosition(self.tblRightPos[1])
    end

    self.rightActionList_2[#self.rightActionList_2+1] = cc.MoveTo:create(1.0, self.tblRightPos[2])
    self.rightActionList_2[#self.rightActionList_2+1] = cc.DelayTime:create(2.0)
    self.rightActionList_2[#self.rightActionList_2+1] = cc.MoveTo:create(1.0, self.tblRightPos[3])
    self.rightActionList_2[#self.rightActionList_2+1] = cc.CallFunc:create(function()
        setStartPos()
        if not self.barState then
            self.tblRightNode[1]:stopAllActions()
            self:setMinorAndMiniAni("chuxian", "idle1")
        end
    end)
    self.rightActionList_2[#self.rightActionList_2+1] = cc.DelayTime:create(2.0)
    local seq = cc.RepeatForever:create(cc.Sequence:create(self.rightActionList_2))
    self.tblRightNode[1]:runAction(seq)
end

function SoaringWealthJackPotBarView:cutShowBar()
    self.m_Minor:runCsbAction("dile1", true)
    self.m_Mini:runCsbAction("dile1", true)
    for i=1, 2 do
        self.tblLeftNode[i]:stopAllActions()
        self.tblRightNode[i]:stopAllActions()
        self.tblPanel[i]:setClippingEnabled(false)
        self.tblLeftNode[i]:setPosition(self.tblLeftPos[i])
        self.tblRightNode[i]:setPosition(self.tblRightPos[i])
    end
end

function SoaringWealthJackPotBarView:setBarActionState(_state)
    self.barState = _state
end

function SoaringWealthJackPotBarView:getBarActionState()
    return self.barState
end

-- 更新jackpot 数值信息
--
function SoaringWealthJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3,true)
    self:changeNode(self.m_Minor:findChild(MinorName),4,true)
    self:changeNode(self.m_Mini:findChild(MiniName),5,true)

    self:updateSize()
end

function SoaringWealthJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MegaName]
    local label3=self.m_csbOwner[MajorName]
    local label4=self.m_Minor:findChild(MinorName)
    local label5=self.m_Mini:findChild(MiniName)
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=0.85,sy=0.85}
    local info3={label=label3,sx=0.85,sy=0.85}
    local info4={label=label4,sx=0.85,sy=0.85}
    local info5={label=label5,sx=0.85,sy=0.85}
    self:updateLabelSize(info1,252)
    self:updateLabelSize(info2,214)
    self:updateLabelSize(info3,214)
    self:updateLabelSize(info4,214)
    self:updateLabelSize(info5,214)
end

function SoaringWealthJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

return SoaringWealthJackPotBarView
