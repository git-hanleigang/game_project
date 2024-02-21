---
--island
--2018年4月12日
--WheelOfRomanceJackPotWinView.lua
local WheelOfRomanceJackPotWinView = class("WheelOfRomanceJackPotWinView", util_require("base.BaseView"))


WheelOfRomanceJackPotWinView.m_isOverAct = false
WheelOfRomanceJackPotWinView.m_isJumpOver = false

function WheelOfRomanceJackPotWinView:initUI(_machine)
    self.m_click = true

    local resourceFilename = "WheelOfRomance/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

    self:createGrandShare(_machine)
end

function WheelOfRomanceJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    self.m_jackpotIndex = index

    self.m_bgSoundId = gLobalSoundManager:playSound("WheelOfRomanceSounds/WheelOfRomance_JackPotWinShow.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    self.m_soundId = gLobalSoundManager:playSound("WheelOfRomanceSounds/WheelOfRomance_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},741)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("WheelOfRomanceSounds/WheelOfRomance_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end,60)

    local imgName = {"grand","major","minor","mini"}
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

function WheelOfRomanceJackPotWinView:onEnter()
end

function WheelOfRomanceJackPotWinView:onExit()

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    if self.m_soundId then
       -- gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end

    if self.m_bgSoundId then
       gLobalSoundManager:stopAudio(self.m_bgSoundId)
        self.m_bgSoundId = nil
    end
    
end

function WheelOfRomanceJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then

        if self.m_click == true then
            return 
        end
        if self:checkShareState() then
            return
        end

        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

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
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},741)
            self:jumpCoinsFinish()
            
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
                gLobalSoundManager:playSound("WheelOfRomanceSounds/WheelOfRomance_JPCoinsJump_Over.mp3")
            end
        end 
    end
end

function WheelOfRomanceJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},741)
            self:jumpCoinsFinish()
            self.m_isJumpOver = true

            if self.m_soundId then

                gLobalSoundManager:playSound("WheelOfRomanceSounds/WheelOfRomance_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=1,sy=1},741)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function WheelOfRomanceJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function WheelOfRomanceJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function WheelOfRomanceJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function WheelOfRomanceJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WheelOfRomanceJackPotWinView

