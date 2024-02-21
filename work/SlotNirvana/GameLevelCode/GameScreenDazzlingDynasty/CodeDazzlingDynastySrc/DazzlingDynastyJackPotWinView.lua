---
--island
--2018年4月12日
--DazzlingDynastyJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local DazzlingDynastyJackPotWinView = class("DazzlingDynastyJackPotWinView", util_require("base.BaseView"))

function DazzlingDynastyJackPotWinView:initUI()
    local resourceFilename = "DazzlingDynasty/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)
    self.grand = self:findChild("Grand")
    self.major = self:findChild("Major")
    self.mini = self:findChild("Mini")
    self.minor = self:findChild("Minor")
    self.backBtn = self:findChild("backBtn")
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_lb_coins_0 = self:findChild("m_lb_coins_0")
end

function DazzlingDynastyJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_callFun = callBackFun
    self.grand:setVisible(index == 1)
    self.major:setVisible(index == 2)
    self.mini:setVisible(index == 3)
    self.minor:setVisible(index == 4)

    local m_lb_coins = self.m_lb_coins
    local m_lb_coins_0 = self.m_lb_coins_0
    m_lb_coins:setString(util_formatCoins(coins,18))
    m_lb_coins_0:setString(util_formatCoins(coins,18))
    self:updateLabelSize({label=m_lb_coins,sx = 0.6,sy = 0.6},1181)
    self:updateLabelSize({label=m_lb_coins_0,sx = 0.6,sy = 0.6},1181)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function DazzlingDynastyJackPotWinView:clickFunc(sender)
    if sender == self.backBtn then
        sender:setEnabled(false)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over",false,function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)
    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return DazzlingDynastyJackPotWinView