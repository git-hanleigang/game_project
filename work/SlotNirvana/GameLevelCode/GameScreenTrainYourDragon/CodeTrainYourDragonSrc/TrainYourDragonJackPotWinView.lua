
local TrainYourDragonJackPotWinView = class("TrainYourDragonJackPotWinView", util_require("base.BaseView"))
-- FIX IOS 139 1
function TrainYourDragonJackPotWinView:initUI(data)
    self.m_click = true
    self.m_showViewId = gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_showJackpotView.mp3")
    local resourceFilename = "TrainYourDragon/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

    self:runCsbAction("start",false,function ()
        self.m_click = false
        self:runCsbAction("idle",true)
    end)
end



function TrainYourDragonJackPotWinView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end
    TrainYourDragonJackPotWinView.super.onExit(self)
end

function TrainYourDragonJackPotWinView:initViewData(index, coins, mainMachine,callBackFun)
    self:createGrandShare(mainMachine)

    self.m_index = index
    self.m_jackpotIndex = 4 - index + 1
    self:findChild("jackpot"..index):setVisible(true)

    self.m_callFun = callBackFun
    self.m_winCoins = coins

    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_jump.mp3",true)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function TrainYourDragonJackPotWinView:jumpCoins(coins)
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
                self:updateLabelSize({label = node,sx = 1,sy = 1},625)
                self:jumpCoinsFinish()
                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_over.mp3")
                end
            else
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},625)
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
                    gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_over.mp3")
                end
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 1,sy = 1},625)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function TrainYourDragonJackPotWinView:clickFunc(sender)
    if self.m_click == true then
        return
    end

    local name = sender:getName()
    if name == "tb_btn" then
        local bShare = self:checkShareState()
        if not bShare then
            self:onCollectBtnClick()
        end
    end
end
function TrainYourDragonJackPotWinView:onCollectBtnClick()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
        if self.m_JumpOver == nil then
            self.m_JumpOver = gLobalSoundManager:playSound("TrainYourDragonSounds/sound_TrainYourDragon_jackpot_over.mp3")
        end
        local node = self:findChild("m_lb_coins")
        node:setString(util_formatCoins(self.m_winCoins, 50))
        self:updateLabelSize({label = node,sx = 1,sy = 1},625)
        self:jumpCoinsFinish()
        if self.m_JumpSound then
            gLobalSoundManager:stopAudio(self.m_JumpSound)
            self.m_JumpSound = nil
        end
    else
        self:jackpotViewOver(function()
            self.m_click = true
            self:runCsbAction("over")
            performWithDelay(self,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end,1)
            if self.m_showViewId then
                gLobalSoundManager:stopAudio(self.m_showViewId)
                self.m_showViewId = nil
            end
        end)
    end
end


--[[
    自动分享 | 手动分享
]]
function TrainYourDragonJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function TrainYourDragonJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function TrainYourDragonJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function TrainYourDragonJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return TrainYourDragonJackPotWinView