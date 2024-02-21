---
--island
--2018年4月12日
--RoyaleBattleJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local RoyaleBattleJackPotWinView = class("RoyaleBattleJackPotWinView", util_require("base.BaseView"))


RoyaleBattleJackPotWinView.m_isOverAct = false
RoyaleBattleJackPotWinView.m_isJumpOver = false

function RoyaleBattleJackPotWinView:initUI(data)
    self.m_click = true

    -- local resourceFilename = "RoyaleBattle/Jackpot.csb"
    self:createCsbNode(resourceFilename)

end

function RoyaleBattleJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("RoyaleBattleSounds/RoyaleBattle_JackPotWinShow.mp3",false)

    self.m_soundId = gLobalSoundManager:playSound("RoyaleBattleSounds/RoyaleBattle_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)





    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"RoyaleBattle_jackpot_tanban__grand ","RoyaleBattle_jackpot_tanban__major","RoyaleBattle_jackpot_tanban__minor","RoyaleBattle_jackpot_tanban__mini"}
    for k,v in pairs(imgName) do
        local img =  self:findChild(v)
        if img then
            if k == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end
    
    
    

    self.m_callFun = callBackFun


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function RoyaleBattleJackPotWinView:onEnter()
end

function RoyaleBattleJackPotWinView:onExit()

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
    
end

function RoyaleBattleJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_collect" then

        if self.m_click == true then
            return 
        end

        
        
        gLobalSoundManager:playSound("RoyaleBattleSounds/music_RoyaleBattles_Click_Collect.mp3")

        
        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            self:runCsbAction("over")
            performWithDelay(self,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end,1)
        end 

        


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end

        
        

    end
end

function RoyaleBattleJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)

            self.m_isJumpOver = true

            if self.m_soundId then
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
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
        end
        

    end)



end


return RoyaleBattleJackPotWinView

