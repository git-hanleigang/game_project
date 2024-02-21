---
--island
--2018年4月12日
--GoldExpressJackPotLock.lua
---- respin 玩法结算时中 mini mijor等提示界面
local GoldExpressJackPotLock = class("GoldExpressJackPotLock", util_require("base.BaseView"))
GoldExpressJackPotLock.m_iJackpotNum = nil

function GoldExpressJackPotLock:initUI(data)
    self.m_click = false

    local resourceFilename = "GoldExpress_JackPot_Lock0"..data.index..".csb"
    self:createCsbNode(resourceFilename)
    self.m_labCion = self:findChild("GoldExpress_unlock_num")
    self.m_labCion:setString(util_formatCoins(data.value, 20))

    self:addClick(self:findChild("click_btn"))
    self.m_unlockTotalBet = data.value
    self:runCsbAction("idleframe")
end

function GoldExpressJackPotLock:playAnimation(animation)
    self:runCsbAction(animation)
end

function GoldExpressJackPotLock:onEnter()
    
end

function GoldExpressJackPotLock:onExit()
    
end

function GoldExpressJackPotLock:clickFunc(sender)
    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_click.mp3")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET, self.m_unlockTotalBet)
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return GoldExpressJackPotLock