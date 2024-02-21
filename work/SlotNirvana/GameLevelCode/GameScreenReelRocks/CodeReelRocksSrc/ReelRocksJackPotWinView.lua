---
--island
--2018年4月12日
--ReelRocksJackPotWinView.lua
local ReelRocksJackPotWinView = class("ReelRocksJackPotWinView", util_require("base.BaseView"))


ReelRocksJackPotWinView.m_isOverAct = false
ReelRocksJackPotWinView.m_isJumpOver = false

function ReelRocksJackPotWinView:initUI(index)
    self.m_click = true
    local jackpotIndex =  self:getJackpotPath(index)
    local resourceFilename = "ReelRocks/JackpotWinView_"..jackpotIndex..".csb"
    self:createCsbNode(resourceFilename)

    

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            self:clickFunc(self:findChild("Button"))
        end,5)
    end
    

end

function ReelRocksJackPotWinView:getJackpotPath(index)
    if index == 101 then
        return 4
    elseif index == 102 then
        return 3
    elseif index == 103 then
        return 2
    elseif index == 104 then
        return 1
    end
end

function ReelRocksJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = self:getJackpotPath(index)
    self.m_coins = coins

    
    -- self.m_bgSoundId =  gLobalSoundManager:playSound("AtlantisSounds/Atlantis_JackPotWinShow.mp3",false,function(  )
    --     self.m_bgSoundId = nil
    -- end)

    -- self.m_soundId = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )
    

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},650)
        end

        if self.m_soundId then

            -- gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    --根据index获取spine小块
    self:getPeopleSpine(index)
    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)
    self.m_callFun = callBackFun

end

function ReelRocksJackPotWinView:getPeopleSpine(index)
    local peopleSpinePath = nil
    if index == 101 then
        peopleSpinePath = "Socre_ReelRocks_5"
    elseif index == 102 then
        peopleSpinePath = "Socre_ReelRocks_6"
    elseif index == 103 then
        peopleSpinePath = "Socre_ReelRocks_7"
    elseif index == 104 then
        peopleSpinePath = "Socre_ReelRocks_8"
    end
    self.kuangGong = util_spineCreate(peopleSpinePath,true,true)
    self:findChild("Node_spine"):addChild(self.kuangGong)
    util_spinePlay(self.kuangGong,"idleframe11",false)
    util_spineEndCallFunc(self.kuangGong,"idleframe11",function (  )
        util_spinePlay(self.kuangGong,"idleframe12",true)
    end)
end

function ReelRocksJackPotWinView:onEnter()
end

function ReelRocksJackPotWinView:onExit()

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

function ReelRocksJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

        if self.m_click == true then
            return 
        end

        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

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
            self:updateLabelSize({label=node,sx=1,sy=1},650)

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end
end

function ReelRocksJackPotWinView:jumpCoins(coins )

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    
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
            self:updateLabelSize({label=node,sx=1,sy=1},650)

            self.m_isJumpOver = true

            if self.m_soundId then

                -- gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=1,sy=1},650)
        end
    end)
end


return ReelRocksJackPotWinView

