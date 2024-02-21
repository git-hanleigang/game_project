---
--island
--2018年4月12日
--JackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面

local JackPotWinView = class("JackPotWinView",util_require("base.BaseView"))

function JackPotWinView:initUI(data)
    local resourceFilename="Socre_Pharaoh_JackpotWon.csb"
    self:createCsbNode(resourceFilename)
    self.m_csbNode:setPosition(display.cx,display.cy)
    -- TODO 输入自己初始化逻辑
end

function JackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    self.m_csbOwner["m_lb_coins"]:setString(coins)

    local node=self:findChild("m_lb_coins")
    self:updateLabelSize({label=node,sx=0.8,sy=0.8},680)
    
    self.m_callFun=callBackFun

    self:runCsbAction("jackpot_"..(index-1),false,function()
        performWithDelay(self,function()
            if self.m_callFun ~= nil then
                self.m_callFun()
            end
            self.m_callFun=nil
            self:removeFromParent()
        end,1)
    end)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end
function JackPotWinView:clickFunc(sender)
    sender:setTouchEnabled(false)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_callFun ~= nil then
        self.m_callFun()
    end
    self.m_callFun=nil
    self:removeFromParent()
end

return JackPotWinView
