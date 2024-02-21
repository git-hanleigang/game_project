---
--xcyy
--2018年5月23日
--PowerUpTowerWInView.lua

local PowerUpTowerWInView = class("PowerUpTowerWInView", util_require("base.BaseView"))
PowerUpTowerWInView.m_coinsNum = -1
function PowerUpTowerWInView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("PowerUp_win.csb")
    self:runCsbAction("idle", true)
    self.m_goodluck = self:findChild("goodluck_1")
    self.m_goodluckBonus = self:findChild("goodluck_bonus")

end

function PowerUpTowerWInView:showGoodLucky(level)
    self.m_goodluck:setVisible(true)
    self.m_goodluckBonus:setVisible(false)
    self.m_goodluck:setVisible(true)
end
function PowerUpTowerWInView:resetView()
    self.m_goodluck:setVisible(false)
    -- self.m_goodluckBonus:setVisible(true)

    -- self.m_coinsNum = 0
    -- self.m_lbs_coins:setString(0)
end

function PowerUpTowerWInView:onEnter()
end

function PowerUpTowerWInView:onExit()

end

--默认按钮监听回调
function PowerUpTowerWInView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

return PowerUpTowerWInView
