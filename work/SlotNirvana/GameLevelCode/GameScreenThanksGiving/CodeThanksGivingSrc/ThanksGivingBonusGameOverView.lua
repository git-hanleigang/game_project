
local ThanksGivingBonusGameOverView = class("ThanksGivingBonusGameOverView", util_require("base.BaseView"))

function ThanksGivingBonusGameOverView:initUI(data)
    self.m_click = false

    local resourceFilename = "ThanksGiving/BonusGameOver.csb"
    self:createCsbNode(resourceFilename)
   
    self.m_chicken = util_spineCreate("ThanksGiving_Jackpot_Juese",true,true)
    self:findChild("ThanksGiving_ji"):addChild(self.m_chicken)
    util_spinePlay(self.m_chicken,"idleframe7",true)

    self:findChild("ThanksGiving_jizhua"):setVisible(false)
    self:findChild("ThanksGiving_jizhua_0"):setVisible(false)

    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end)
end

function ThanksGivingBonusGameOverView:initViewData(avgBet,multiple,coins,callBackFun)

    local coinString = self:findChild("m_lb_coins")
    -- local coinString2 = self:findChild("m_lb_coins_2")

    self.m_callFun = callBackFun

    self.m_winCoins = coins
    coinString:setString(util_formatCoins(coins,50))
    self:updateLabelSize({label = coinString,sx = 0.93,sy = 0.93},497)

    -- coinString2:setString(util_formatCoins(avgBet,50).." X "..multiple.." = "..util_formatCoins(coins,50))
end

function ThanksGivingBonusGameOverView:onEnter()
end

function ThanksGivingBonusGameOverView:onExit()
    
end

function ThanksGivingBonusGameOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return 
        end

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        self.m_click = true
        self:runCsbAction("over",false,function ()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)

    end
end

return ThanksGivingBonusGameOverView