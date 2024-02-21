---
--xcyy
--2018年5月23日
--AladdinJackPotWinView.lua

local AladdinJackPotWinView = class("AladdinJackPotWinView", util_require("base.BaseView"))

local JACKPOT_ID = {
    Grand = 1,
    Major = 2,
    Minor = 3,
    Mini = 4
}

function AladdinJackPotWinView:initUI(data)
    self.m_machine = data
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "Aladdin/JackpotWin.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
    
end

function AladdinJackPotWinView:initViewData(jackpot,coins,callBackFun)
    local index = 1
    local choose = JACKPOT_ID[jackpot]
    while true do
        local node = self:findChild("jackpot"..index)
        if node == nil then
            break
        else
            if index ~= choose then
                node:setVisible(false)
            end
        end
        index = index + 1
    end

    self.m_jackpotIndex = choose
    self:createGrandShare(self.m_machine)

    self:runCsbAction("start",false,function(  )
        -- if self.m_JumpOver == nil then
        --     self.m_JumpOver = gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_jackpot_coin_end.mp3")
        -- end
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=0.84,sy=0.84}, 740)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_jackpot_coin_jump.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, choose)
end

function AladdinJackPotWinView:jumpCoins(coins )
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
            self:updateLabelSize({label=node,sx=1,sy=1},624)

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                self:jumpCoinsFinish()
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_jackpot_coin_end.mp3")
            end
            
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)
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
                    gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_jackpot_coin_end.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},624)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function AladdinJackPotWinView:onEnter()
    
end

function AladdinJackPotWinView:onExit()
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

function AladdinJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self:checkShareState() then
            return
        end

        
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then 
                self.m_JumpOver = gLobalSoundManager:playSound("AladdinSounds/sound_Aladdin_jackpot_coin_end.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},624)
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle",true)
            self:jumpCoinsFinish()
        else
            self:jackpotViewOver(function()
                self.m_click = true
                self:closeUI()
            end)
        end
            
        
        
    end
end

function AladdinJackPotWinView:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end

--[[
    自动分享 | 手动分享
]]
function AladdinJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function AladdinJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function AladdinJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function AladdinJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return AladdinJackPotWinView