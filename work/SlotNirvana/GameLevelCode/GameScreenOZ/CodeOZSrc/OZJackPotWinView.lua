---
--island
--2018年4月12日
--OZJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local OZJackPotWinView = class("OZJackPotWinView", util_require("base.BaseView"))

function OZJackPotWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "OZ/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)

end

function OZJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index

    local node1=self:findChild("m_lb_coins1")
    local node2=self:findChild("m_lb_coins2")
    local node3=self:findChild("m_lb_coins3")
    local node4=self:findChild("m_lb_coins4")
    self:runCsbAction("show_"..(index-1))

    self.m_callFun = callBackFun
    node1:setString(coins)
    node2:setString(coins)
    node3:setString(coins)
    node4:setString(coins)
    self:updateLabelSize({label=node1},807)
    self:updateLabelSize({label=node2},807)
    self:updateLabelSize({label=node3},807)
    self:updateLabelSize({label=node4},807)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function OZJackPotWinView:onEnter()
end

function OZJackPotWinView:onExit()
    
end

function OZJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over_"..(self.m_index - 1))
        performWithDelay(self,function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end,1)

    end
end

--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return OZJackPotWinView