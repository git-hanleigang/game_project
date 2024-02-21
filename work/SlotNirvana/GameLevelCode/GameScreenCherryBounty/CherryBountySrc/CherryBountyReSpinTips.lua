--[[
    reSpin提示
]]
local CherryBountyReSpinTips = class("CherryBountyReSpinTips", util_require("base.BaseView"))

function CherryBountyReSpinTips:initUI(_machine)
    self.m_machine = _machine
    self.m_bonus2Coins = 0 
    self.m_bonus3Coins = 0 

    self:createCsbNode("CherryBounty_respin_bar.csb")
    self.m_labBonus2Coins = self:findChild("m_lb_coins1")
    self.m_labBonus3Coins = self:findChild("m_lb_coins2")
end

--金额文本-初始化玩法金额
function CherryBountyReSpinTips:initLabelCoins(_bonus2Coins, _bonus3Coins)
    self.m_bonus2Coins = _bonus2Coins 
    self.m_bonus3Coins = _bonus3Coins 
    self:upDateLabelCoins(_bonus2Coins, _bonus3Coins)
end
--金额文本-刷新金额
function CherryBountyReSpinTips:upDateLabelCoins(_bonus2Coins, _bonus3Coins)
    self.m_labBonus2Coins:setString( util_formatCoinsLN(_bonus2Coins, 3) )
    self.m_labBonus3Coins:setString( util_formatCoinsLN(_bonus3Coins, 3) )
    self:updateLabelSize({label=self.m_labBonus2Coins, sx=0.78, sy=0.78}, 92)
    self:updateLabelSize({label=self.m_labBonus3Coins, sx=0.78, sy=0.78}, 92)
end

--时间线-刷新金额
function CherryBountyReSpinTips:playReSpinTipIdle()
    self:runCsbAction("idle", false)
end
--时间线-刷新金额
function CherryBountyReSpinTips:playUpDateBonus3CoinsAnim(_bonus3Coins)
    self:stopAllActions()
    self:runCsbAction("switch", false, function()
        self:playReSpinTipIdle()
    end)
    self.m_bonus3Coins = _bonus3Coins 
    performWithDelay(self,function()
        self:upDateLabelCoins(self.m_bonus2Coins, self.m_bonus3Coins)
    end, 9/60)
end
--跳过-刷新金额
function CherryBountyReSpinTips:playSkipUpDateBonus3Coins(_bonus3Coins)
    self:playUpDateBonus3CoinsAnim(_bonus3Coins)
end


return CherryBountyReSpinTips