---
--island
--2018年4月12日
--DragonsJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local DragonsJackPotWinView = class("DragonsJackPotWinView", util_require("base.BaseView"))

function DragonsJackPotWinView:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "Dragons/JackpotWinView.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
end


function DragonsJackPotWinView:initViewData(_type,coins,callBackFun)
    self.m_index = _type
    self.m_StrType = "Mini"
    if self.m_index == "Mini" then
        self.m_StrType = "Mini"
        self.m_index = 1
    elseif self.m_index == "Minor" then
        self.m_StrType = "Minor"
        self.m_index = 2
    elseif self.m_index == "Major" then
        self.m_StrType = "Major"
        self.m_index = 3
    elseif self.m_index == "Super" then
        self.m_StrType = "Super"
        self.m_index = 4
    elseif self.m_index == "Grand" then
        self.m_StrType = "Grand"
        self.m_index = 5
    end
    self:findChild("grandjackpot"):setVisible(false)
    self:findChild("superjackpot"):setVisible(false)
    self:findChild("majorjackpot"):setVisible(false)
    self:findChild("minorjackpot"):setVisible(false)
    self:findChild("minijackpot"):setVisible(false)
    
    if self.m_index == 5 then
        self:findChild("grandjackpot"):setVisible(true)
    elseif self.m_index == 4 then
        self:findChild("superjackpot"):setVisible(false)
    elseif self.m_index == 3 then
        self:findChild("majorjackpot"):setVisible(true)
    elseif self.m_index == 2 then
        self:findChild("minorjackpot"):setVisible(true)
    elseif self.m_index == 1 then
        self:findChild("minijackpot"):setVisible(true)
    end

    self:runCsbAction("start",false,function(  )
        if self.m_JumpOver == nil then
            -- self.m_JumpOver = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
        end
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},628)
    self:jumpCoins(coins )
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function DragonsJackPotWinView:jumpCoins(coins )
    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum),"0", math.random(1,5) )
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        -- print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},628)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                -- gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},628)
        end
    end)
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},634)
            end
        end,
        5
    )
end

function DragonsJackPotWinView:onEnter()

end

function DragonsJackPotWinView:onExit()
    if self.m_JumpOver then
        gLobalSoundManager:stopAudio(self.m_JumpOver)
        self.m_JumpOver = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
end

function DragonsJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_2" then
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then 
                self.m_JumpOver = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},634)
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle",true)
        else
            self.m_click = true
            self:closeUI()
        end
    end
end

function DragonsJackPotWinView:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return DragonsJackPotWinView