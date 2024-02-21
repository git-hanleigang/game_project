---
--xcyy
--2018年5月23日
--SaharaTreasureJackpotView.lua

local SaharaTreasureJackpotView = class("SaharaTreasureJackpotView",util_require("base.BaseView"))

local JACKPOT_ID_ARRAY = 
{
    [5] = 5,
    [6] = 4,
    [7] = 3,
    [8] = 2,
    [9] = 1
}

function SaharaTreasureJackpotView:initUI()

    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "SaharaTreasure/JackpotOver.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 

end


function SaharaTreasureJackpotView:initViewData(jackpot, coins, callBackFun)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idleframe",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun

    self:findChild("m_lb_num_0"):setString(jackpot)
    if jackpot > 9 then
        jackpot = 9
    end

    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},550)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_jackpot_up.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, JACKPOT_ID_ARRAY[jackpot])
end

function SaharaTreasureJackpotView:jumpCoins(coins )
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
            self:updateLabelSize({label=node,sx=1,sy=1},550)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_jackpot_end.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},550)
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
                    gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_jackpot_end.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},550)
            end
        end,
        5
    )
end

function SaharaTreasureJackpotView:onEnter()
    
end

function SaharaTreasureJackpotView:onExit()
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

function SaharaTreasureJackpotView:clickFunc(sender)
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
                self.m_JumpOver = gLobalSoundManager:playSound("SaharaTreasureSounds/sound_SaharaTreasure_jackpot_end.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},550)
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

function SaharaTreasureJackpotView:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end


return SaharaTreasureJackpotView