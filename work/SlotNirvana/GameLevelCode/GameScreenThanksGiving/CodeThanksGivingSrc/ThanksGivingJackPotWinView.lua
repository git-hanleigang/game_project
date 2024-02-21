
local ThanksGivingJackPotWinView = class("ThanksGivingJackPotWinView", util_require("base.BaseView"))

function ThanksGivingJackPotWinView:initUI(data)
    self.m_click = false

    local resourceFilename = "ThanksGiving/JackPotover.csb"
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

function ThanksGivingJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    
    -- self:findChild("jtb_"..self.m_index):setVisible(true)

    local coinString = self:findChild("m_lb_coins")

    self.m_callFun = callBackFun
    self.m_winCoins = coins
    -- coinString:setString(util_formatCoins(coins))
    -- self:updateLabelSize({label = coinString,sx = 0.93,sy = 0.93},497)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("ThanksGivingSounds/sound_ThanksGiving_jackpot_jump.mp3",true)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function ThanksGivingJackPotWinView:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (5 * 60) -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = 0

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 0.93,sy = 0.93},497)

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("ThanksGivingSounds/sound_ThanksGiving_jackpot_over.mp3")
                end
            else
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 0.93,sy = 0.93},497)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("ThanksGivingSounds/sound_ThanksGiving_jackpot_over.mp3")
                end
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 0.93,sy = 0.93},497)
            end
        end,
        5
    )
end



function ThanksGivingJackPotWinView:onEnter()
end

function ThanksGivingJackPotWinView:onExit()
    
end

function ThanksGivingJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return 
        end
        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                self.m_JumpOver = gLobalSoundManager:playSound("ThanksGivingSounds/sound_ThanksGiving_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node,sx = 0.93,sy = 0.93},497)
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        else
            self.m_click = true
            self:runCsbAction("over")
            performWithDelay(self,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end,1)
        end
    end
end

return ThanksGivingJackPotWinView