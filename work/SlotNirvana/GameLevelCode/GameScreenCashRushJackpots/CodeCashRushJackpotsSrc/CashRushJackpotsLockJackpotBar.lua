---
--xcyy
--2018年5月23日
--CashRushJackpotsLockJackpotBar.lua

local CashRushJackpotsLockJackpotBar = class("CashRushJackpotsLockJackpotBar",util_require("Levels.BaseLevelDialog"))

function CashRushJackpotsLockJackpotBar:initUI(_jackpotIndex)

    self:createCsbNode("CashRushJackpots_UnlockTips.csb")

    self.m_jackpotIndex = _jackpotIndex

    for i=2, 5 do
        if i == self.m_jackpotIndex then
            self:findChild("Tip"..i):setVisible(true)
        else
            self:findChild("Tip"..i):setVisible(false)
        end
    end

    self.m_scWaitNodeAction = cc.Node:create()
    self:addChild(self.m_scWaitNodeAction)
end

function CashRushJackpotsLockJackpotBar:showLockTips()
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        -- self:playLockTipsAction()
    end)
end

function CashRushJackpotsLockJackpotBar:hideLockTips()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

--延时关闭
function CashRushJackpotsLockJackpotBar:playLockTipsAction()
    self.m_scWaitNodeAction:stopAllActions()
    util_schedule(self.m_scWaitNodeAction, function()
       self:hideUnlockTips()
       self.m_scWaitNodeAction:stopAllActions()
    end, 3.0)
end

return CashRushJackpotsLockJackpotBar
