---
--island
--2018年4月12日
--RoaringKingJackPotWinView.lua
local RoaringKingJackPotWinView = class("RoaringKingJackPotWinView", util_require("Levels.BaseLevelDialog"))


RoaringKingJackPotWinView.m_isOverAct = false
RoaringKingJackPotWinView.m_isJumpOver = false

function RoaringKingJackPotWinView:initUI(index)
    self.m_click = true
    local resourceFilename = "RoaringKing/Jackpot.csb"
    self:createCsbNode(resourceFilename)
  

end


function RoaringKingJackPotWinView:initViewData(machine,index,coins,callBackFun,startFunc)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index
    self.m_coins = coins
    self.m_click = true

    local name = {"grand","major","minor"}
    self.m_bgSoundId =  gLobalSoundManager:playSound("RoaringKingSounds/RoaringKing_JackPotWinShow_" .. name[self.m_index] .. ".mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    self.m_soundId = gLobalSoundManager:playSound("RoaringKingSounds/sound_RoaringKing_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )
    

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.67,sy=0.67},818)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("RoaringKingSounds/sound_RoaringKing_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    local nameList = {"RoaringKing_GRAND","RoaringKing_MAJOR","RoaringKing_MINOR"}
    for i=1,#nameList do
        local img = self:findChild(nameList[i])
        if img then
            if self.m_index == i then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
        end
    end
    
    

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
        if startFunc then
            startFunc()
        end
    end)
    self.m_callFun = function(  )
        if callBackFun then
            callBackFun()
        end
        
        self:clearHandler( )
    end 

end

function RoaringKingJackPotWinView:clearHandler( )
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

function RoaringKingJackPotWinView:onEnter( )
    RoaringKingJackPotWinView.super.onEnter(self)
    
    gLobalNoticManager:addObserver(self,function(Target,params)

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.67,sy=0.67},818)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("RoaringKingSounds/sound_RoaringKing_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        local sender = self:findChild("Button_1")
        self:clickFunc(sender)

    end,"ROARINKING_NOTIFY_CLOSE_JP_VIEW")
end

function RoaringKingJackPotWinView:onExit()
    self:clearHandler( )
    RoaringKingJackPotWinView.super.onExit(self)
   
end

function RoaringKingJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        
        gLobalSoundManager:playSound( "RoaringKingSounds/music_RoaringKin_Click.mp3" )

        if self.m_updateCoinHandlerID == nil then

            self.m_click = true
            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:runCsbAction("over")
                    performWithDelay(self,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:setVisible(false)
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
            self:updateLabelSize({label=node,sx=0.67,sy=0.67},818)
            self:jumpCoinsFinish()
            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end
end

function RoaringKingJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=0.67,sy=0.67},818)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:playSound("RoaringKingSounds/sound_RoaringKing_JPCoinsJump_Over.mp3")
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
            self:updateLabelSize({label=node,sx=0.67,sy=0.67},818)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function RoaringKingJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function RoaringKingJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function RoaringKingJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function RoaringKingJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return RoaringKingJackPotWinView

