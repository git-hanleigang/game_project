---
--island
--2018年4月12日
--FairyDragonJackpotWin.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FairyDragonJackpotWin = class("FairyDragonJackpotWin", util_require("base.BaseView"))

function FairyDragonJackpotWin:initUI(data)
    self.m_click = false
    local resourceFilename = "FairyDragon/Jackpotwin.csb"
    self:createCsbNode(resourceFilename)
    self.m_JumpOver = nil 
end


function FairyDragonJackpotWin:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_StrType = "mini"
    self:findChild("Jackpot_mini"):setVisible(false)
    self:findChild("Jackpot_minor"):setVisible(false)
    self:findChild("Jackpot_major"):setVisible(false)


    if index == 4 then
        self.m_StrType = "grand"

        self.m_index = 1
    elseif index == 3 then
        self.m_StrType = "major"
        self:findChild("Jackpot_major"):setVisible(true)
        self.m_index = 2
    elseif index == 2 then
        self.m_StrType = "minor"
        self:findChild("Jackpot_minor"):setVisible(true)
        self.m_index = 3
    elseif index == 1 then
        self.m_StrType = "mini"
        self:findChild("Jackpot_mini"):setVisible(true)
        self.m_index = 4
    end

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},553)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_jump.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_index)
end

function FairyDragonJackpotWin:jumpCoins(coins )
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
            self:updateLabelSize({label=node,sx=1,sy=1},553)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_stop.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},553)
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
                    gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_stop.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},553)
            end
        end,
        5
    )
end

function FairyDragonJackpotWin:onEnter()

end

function FairyDragonJackpotWin:onExit()
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

function FairyDragonJackpotWin:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            
            gLobalSoundManager:playSound("FairyDragonSounds/sound_FairyDragon_jackpot_stop.mp3")
            
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},553)
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

function FairyDragonJackpotWin:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return FairyDragonJackpotWin