---
--island
--2018年4月12日
--MrCashJackPotWinView.lua
local MrCashJackPotWinView = class("MrCashJackPotWinView", util_require("base.BaseView"))


MrCashJackPotWinView.m_isOverAct = false
MrCashJackPotWinView.m_isJumpOver = false

function MrCashJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "MrCash/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

end

function MrCashJackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    self:createGrandShare(mainMachine)
    self.m_index = index
    self.m_coins = coins
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("MrCashSounds/music_MrCash_JackPotGame_WinView.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    -- self.m_soundId = gLobalSoundManager:playSound("MrCashSounds/MrCash_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},506)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            -- gLobalSoundManager:playSound("MrCashSounds/MrCash_JPCoinsJump_Over.mp3")

            -- gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"MrCash_grand_3","MrCash_major_5","MrCash_minor_6","MrCash_mini_8"}
    local imgBgName = {"MrCash_granddi_2","MrCash_majordi_4","MrCash_minordi_7","MrCash_minidi_9"}
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
    
    for k,v in pairs(imgBgName) do
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

function MrCashJackPotWinView:onEnter()
end

function MrCashJackPotWinView:onExit()

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

function MrCashJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        local bShare = self:checkShareState()
        if not bShare then
        
            gLobalSoundManager:playSound("MrCashSounds/music_MrCash_BrnClick.mp3")
            gLobalSoundManager:playSound("MrCashSounds/MrCash_JackPotGame_View_ShouHui.mp3")
        
            if self.m_updateCoinHandlerID == nil then
                self:jackpotViewOver(function()
                    sender:setTouchEnabled(false)
                    self.m_click = true

                    self:runCsbAction("over")
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end,1)
                end)
            else
                local waitTimes = 0
                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                    local node=self:findChild("m_lb_coins")
                    node:setString(util_formatCoins(self.m_coins,50))
                    self:updateLabelSize({label=node,sx=1,sy=1},506)
        
                    waitTimes = 2
                    self:jumpCoinsFinish()
                end
        
                if self.m_soundId then
        
                    -- gLobalSoundManager:playSound("MrCashSounds/MrCash_JPCoinsJump_Over.mp3")
        
                    -- gLobalSoundManager:stopAudio(self.m_soundId)
                    self.m_soundId = nil
                end
            end
        end
    end
end

function MrCashJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1,sy=1},506)

            self.m_isJumpOver = true

            if self.m_soundId then

                -- gLobalSoundManager:playSound("MrCashSounds/MrCash_JPCoinsJump_Over.mp3")

                -- gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            self:jumpCoinsFinish()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},506)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function MrCashJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MrCashJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_index)
    end
end

function MrCashJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MrCashJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return MrCashJackPotWinView

