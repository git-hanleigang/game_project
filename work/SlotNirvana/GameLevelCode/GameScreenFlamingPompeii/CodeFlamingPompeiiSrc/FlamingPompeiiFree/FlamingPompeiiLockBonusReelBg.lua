--[[
    处理图标锁定玩法
]]
local FlamingPompeiiLockBonusReelBg = class("FlamingPompeiiLockBonusReelBg", util_require("base.BaseView"))

FlamingPompeiiLockBonusReelBg.State = {
    NotShow = 0,            --隐藏
    Start   = 1,            --播start
    Idle    = 2,            --播idle
    Over    = 3,            --播over
}

function FlamingPompeiiLockBonusReelBg:initData_(_machine)
    self.m_machine  = _machine

    self:initUI()
end
function FlamingPompeiiLockBonusReelBg:initUI()
    local parent = self.m_machine.m_clipParent
    self.m_lockBonusReelBgList = {}
    for iCol=1,self.m_machine.m_iReelColumnNum do
        local reelBgCsb = util_createAnimation("FlamingPompeii_ht.csb")
        parent:addChild(reelBgCsb, -1)
        util_setCascadeOpacityEnabledRescursion(reelBgCsb, true)
        reelBgCsb:setVisible(false)
        local reelName = string.format("sp_reel_%d", (iCol - 1))
        local reel = self.m_machine:findChild(reelName)
        reelBgCsb:setPosition(cc.p(reel:getPosition()))
        self.m_lockBonusReelBgList[iCol] = {csb = reelBgCsb, state = self.State.NotShow}
    end
end

function FlamingPompeiiLockBonusReelBg:onEnter()
    FlamingPompeiiLockBonusReelBg.super.onEnter(self)

    -- 更新卷轴的展示状态
    gLobalNoticManager:addObserver(self,function(self, params)
        local iCol = params.iCol
        self:showLockBonusReelBg(iCol)
    end,"FlamingPompeiiMachine_showLockBonusReelBg")
    gLobalNoticManager:addObserver(self,function(self, params)
        local iCol = params.iCol
        self:hideLockBonusReelBg(iCol)
    end,"FlamingPompeiiMachine_hideLockBonusReelBg")
end

function FlamingPompeiiLockBonusReelBg:getLockBonusReelBgShowState(_iCol)
    local reelBg      = self.m_lockBonusReelBgList[_iCol]
    local reelBgstate = reelBg.state
    return reelBgstate ~= self.State.NotShow
end
--
function FlamingPompeiiLockBonusReelBg:showLockBonusReelBg(_iCol)
    local reelBg      = self.m_lockBonusReelBgList[_iCol]
    local reelBgCsb   = reelBg.csb
    local reelBgstate = reelBg.state
    if reelBgstate ~= self.State.NotShow then
        return
    end
    reelBg.state = self.State.Start
    reelBgCsb:setVisible(true)
    reelBgCsb:runCsbAction("start", false, function()
        reelBg.state = self.State.Idle
        reelBgCsb:runCsbAction("idle", true)
    end)
end
function FlamingPompeiiLockBonusReelBg:hideLockBonusReelBg(_iCol)
    local reelBg      = self.m_lockBonusReelBgList[_iCol]
    local reelBgCsb   = reelBg.csb
    local reelBgstate = reelBg.state
    if reelBgstate == self.State.Over or reelBgstate == self.State.NotShow then
        return
    end
    reelBg.state = self.State.Over
    reelBgCsb:runCsbAction("over", false, function()
        reelBg.state = self.State.NotShow
        reelBgCsb:setVisible(false)
    end)
end

return FlamingPompeiiLockBonusReelBg