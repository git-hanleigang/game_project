---
--island
--2018年4月12日
--CloverHatJackPotWinView.lua
local CloverHatJackPotWinView = class("CloverHatJackPotWinView", util_require("base.BaseView"))


CloverHatJackPotWinView.m_isOverAct = false
CloverHatJackPotWinView.m_isJumpOver = false

function CloverHatJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "CloverHat/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

end

function CloverHatJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index
    self.m_coins = coins

    self.m_bgSoundId =  gLobalSoundManager:playSound("CloverHatSounds/CloverHat_JackPotWinShow.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    self.m_soundId = gLobalSoundManager:playSound("CloverHatSounds/CloverHat_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("CloverHatSounds/CloverHat_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"CloverHat_grand","CloverHat_major","CloverHat_minor","CloverHat_mini"}
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

function CloverHatJackPotWinView:onEnter()
end

function CloverHatJackPotWinView:onExit()

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

function CloverHatJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_4" then

        if self.m_click == true then
            return 
        end

        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:runCsbAction("over")
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end,1)
                end)
            end
        end 

        


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)
            self:jumpCoinsFinish()

            waitTimes = 2
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("CloverHatSounds/CloverHat_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end

        
        

    end
end

function CloverHatJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then

                gLobalSoundManager:playSound("CloverHatSounds/CloverHat_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function CloverHatJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function CloverHatJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function CloverHatJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function CloverHatJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CloverHatJackPotWinView

