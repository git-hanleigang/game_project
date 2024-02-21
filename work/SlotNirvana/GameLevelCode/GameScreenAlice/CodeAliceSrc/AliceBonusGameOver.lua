---
--xcyy
--2018年5月23日
--AliceView.lua

local AliceBonusGameOver = class("AliceBonusGameOver", util_require("base.BaseView"))

function AliceBonusGameOver:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "Alice/BonusGameOver.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_pop_window2.mp3")
end

function AliceBonusGameOver:initViewData(startPrice, multip, coins, callBackFun)
    
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx = 1,sy = 1}, 712)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_over.mp3",true)
    --通知jackpot
    -- globalData.jackpotRunData:notifySelfJackpot(coins, choose)

    local labMultip = self:findChild("m_lb_multip")
    labMultip:setString( util_formatCoins(startPrice, 50).." x "..multip.." = "..util_formatCoins(coins, 50))
   
end

function AliceBonusGameOver:jumpCoins(coins )
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
            self:updateLabelSize({label=node,sx=1,sy=1},624)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_jackpot_coin_end.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)
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
                    gLobalSoundManager:playSound("AliceSounds/sound_Alice_jackpot_coin_end.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},624)
            end
        end,
        5
    )
end

function AliceBonusGameOver:onEnter()
    
end

function AliceBonusGameOver:onExit()
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

function AliceBonusGameOver:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then 
                self.m_JumpOver = gLobalSoundManager:playSound("AliceSounds/sound_Alice_jackpot_coin_end.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)
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

function AliceBonusGameOver:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_winCoins, true, false})
        self:removeFromParent()
    end)
end


return AliceBonusGameOver