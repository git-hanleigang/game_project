---
--island
--2018年4月12日
--BingoPriatesJackPotWinView.lua
local BingoPriatesJackPotWinView = class("BingoPriatesJackPotWinView", util_require("base.BaseView"))


BingoPriatesJackPotWinView.m_isOverAct = false
BingoPriatesJackPotWinView.m_isJumpOver = false

function BingoPriatesJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "BingoPriates/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

end

function BingoPriatesJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    
    -- self.m_bgSoundId =  gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_JackPotWinShow.mp3",false,function(  )
    --     self.m_bgSoundId = nil
    -- end)

    -- self.m_soundId = gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},685)
        end

        if self.m_soundId then

            -- gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"tb_grand","tb_major","tb_mini"}
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

end

function BingoPriatesJackPotWinView:onEnter()
end

function BingoPriatesJackPotWinView:onExit()

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

function BingoPriatesJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then

        if self.m_click == true then
            return 
        end

        
        
        gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_Click.mp3")
        
       
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
            self:updateLabelSize({label=node,sx=1,sy=1},685)

            waitTimes = 2
        end

        if self.m_soundId then

            -- gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end

        
        

    end
end

function BingoPriatesJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1,sy=1},685)

            self.m_isJumpOver = true

            if self.m_soundId then

                -- gLobalSoundManager:playSound("BingoPriatesSounds/BingoPriates_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=1,sy=1},685)
        end
        

    end)



end


return BingoPriatesJackPotWinView

