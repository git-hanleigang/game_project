
local WheelOfRhinoJackPotWinView = class("WheelOfRhinoJackPotWinView",  util_require("Levels.BaseLevelDialog"))

function WheelOfRhinoJackPotWinView:initUI()
    self.m_click = false

    local resourceFilename = "WheelOfRhino/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showJcakpot.mp3")
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end)
end

function WheelOfRhinoJackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    if index > 9 then
        index = 9
    end
    self.m_index = index
    
    if self.m_index == 9 then
        self.m_jackpotIndex = 1
    end

    self:createGrandShare(mainMachine)

    self:findChild("jtb_"..self.m_index):setVisible(true)

    local coinString = self:findChild("m_lb_coins")

    self.m_callFun = callBackFun
    self.m_winCoins = coins
    -- coinString:setString(util_formatCoins(coins, 50))
    -- self:updateLabelSize({label = coinString,sx = 1,sy = 1},607)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_jackpot_jump.mp3",true)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index - 4)
end

function WheelOfRhinoJackPotWinView:jumpCoins(coins)
    local node = self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum = coins / (5 * 60) -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum), "0", math.random(1, 5))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum)

    local curCoins = 0

    self.m_updateCoinHandlerID =
        scheduler.scheduleUpdateGlobal(
        function()
            curCoins = curCoins + coinRiseNum

            if curCoins >= coins then
                curCoins = coins

                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},607)

                self:jumpCoinsFinish()

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_jackpot_over.mp3")
                end
            else
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},607)
            end
        end
    )
    performWithDelay(
        self,
        function()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_jackpot_over.mp3")
                end
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},607)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function WheelOfRhinoJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return 
        end
        local bShare = self:checkShareState()
        if not bShare then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                if self.m_JumpOver == nil then
                    self.m_JumpOver = gLobalSoundManager:playSound("WheelOfRhinoSounds/sound_WheelOfRhino_jackpot_over.mp3")
                end
                local node = self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},607)
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                end
                self:jumpCoinsFinish()
            else
                self:jackpotViewOver(function()
                    self.m_click = true
                    gLobalSoundManager:playSound("WheelOfRhinoSounds/music_WheelOfRhino_showJcakpotOver.mp3")
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
    end
end

--[[
    自动分享 | 手动分享
]]
function WheelOfRhinoJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WheelOfRhinoJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function WheelOfRhinoJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WheelOfRhinoJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WheelOfRhinoJackPotWinView
