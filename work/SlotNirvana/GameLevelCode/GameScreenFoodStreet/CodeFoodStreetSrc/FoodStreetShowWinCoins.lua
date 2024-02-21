---
--xcyy
--2018年5月23日
--FoodStreetView.lua

local FoodStreetShowWinCoins = class("FoodStreetShowWinCoins",util_require("base.BaseView"))

function FoodStreetShowWinCoins:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "FoodStreet/zhuanpanover.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
    
end

function FoodStreetShowWinCoins:initViewData(coins,machine)
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    -- self.m_callFun = callBackFun
    self.m_machine = machine
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},600)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_jackpot_up.mp3",true)
    --通知jackpot
end

function FoodStreetShowWinCoins:jumpCoins(coins )
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
                gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_jackpot_end.mp3")
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
                    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_jackpot_end.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},624)
            end
        end,
        5
    )
end

function FoodStreetShowWinCoins:onEnter()
    
end

function FoodStreetShowWinCoins:onExit()
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

function FoodStreetShowWinCoins:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then 
                self.m_JumpOver = gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_jackpot_end.mp3")
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

function FoodStreetShowWinCoins:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        
        local isUpdateTop = true
        if self.m_machine then
            local winlines = self.m_machine.m_runSpinResultData.p_winLines or {}
            if #winlines > 0 then
                isUpdateTop = false
            end
        end 

        local lastWinCoin = globalData.slotRunData.lastWinCoin
        globalData.slotRunData.lastWinCoin = 0
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_winCoins,isUpdateTop,true})
        globalData.slotRunData.lastWinCoin = lastWinCoin

        self:removeFromParent()
    end)
end

function FoodStreetShowWinCoins:setCallFunc(callFun)
    self.m_callFun = callFun
end

return FoodStreetShowWinCoins