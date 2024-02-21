---
--island
--2018年4月12日
--CoinCircusBonusOverView.lua
local CoinCircusBonusOverView = class("CoinCircusBonusOverView", util_require("Levels.BaseLevelDialog"))


CoinCircusBonusOverView.m_isOverAct = false
CoinCircusBonusOverView.m_isJumpOver = false

function CoinCircusBonusOverView:initUI(data)
    self.m_click = true

    local resourceFilename = "CoinCircus/FreeSpinOver.csb"
    self:createCsbNode(resourceFilename)

end

function CoinCircusBonusOverView:initViewData(coins,callBackFun)

    self.m_coins = coins

    self.m_bgSoundId =  gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_PusherOverView.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        self.m_soundId = gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JackPotWinCoins.mp3",true)
        waitNode:removeFromParent()
    end,18/60)
    

    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
        end

        if self.m_soundId then

            -- gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

  
    self.m_callFun = callBackFun

end

function CoinCircusBonusOverView:onExit()

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    if self.m_soundId then
       gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_bgSoundId then
       gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
    
    CoinCircusBonusOverView.super.onExit(self)
end

function CoinCircusBonusOverView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_Click.mp3")  

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            if self.m_callFun then
                self.m_callFun()
            end

        end 

        


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)

            waitTimes = 2
        end

        if self.m_soundId then

            -- gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end

        
        

    end
end

function CoinCircusBonusOverView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)

            self.m_isJumpOver = true

            if self.m_soundId then

                -- gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JPCoinsJump_Over.mp3")

                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end


            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
        end
        

    end)



end


return CoinCircusBonusOverView

