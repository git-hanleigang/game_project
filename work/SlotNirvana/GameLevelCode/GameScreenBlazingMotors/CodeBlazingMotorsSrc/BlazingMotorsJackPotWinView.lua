---
--island
--2018年4月12日
--BlazingMotorsJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local BlazingMotorsJackPotWinView = class("BlazingMotorsJackPotWinView", util_require("base.BaseView"))

BlazingMotorsJackPotWinView.jPnum = {9,8,7,6,5}

function BlazingMotorsJackPotWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "BlazingMotors/JackPotWon.csb"
    self:createCsbNode(resourceFilename)

end

function BlazingMotorsJackPotWinView:initViewData(coins,index,callBackFun)
    self.m_index = index

    local node1=self:findChild("m_lb_coins")
    local node2=self:findChild("m_lb_num")
    
    self:runCsbAction("start")

    self.m_callFun = callBackFun
    node1:setString(coins)
    node2:setString(self.jPnum[index])

    self:updateLabelSize({label=node1,sx = 1,sy = 1},517)


    --通知jackpot
    local jpIndex = 10 -  index
    globalData.jackpotRunData:notifySelfJackpot(coins,jpIndex)
end

function BlazingMotorsJackPotWinView:onEnter()
end

function BlazingMotorsJackPotWinView:onExit()
    
end

function BlazingMotorsJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "backBtn" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over")
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

return BlazingMotorsJackPotWinView