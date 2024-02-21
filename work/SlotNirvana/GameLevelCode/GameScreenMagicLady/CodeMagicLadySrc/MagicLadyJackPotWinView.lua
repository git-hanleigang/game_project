---
--island
--2018年4月12日
--MagicLadyJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local MagicLadyJackPotWinView = class("MagicLadyJackPotWinView", util_require("base.BaseView"))

function MagicLadyJackPotWinView:initUI(data)
    self.m_click = false
    self.m_machine = data.machine

    local resourceFilename = "MagicLady/JackpotLayer.csb"
    self:createCsbNode(resourceFilename)

    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
    end)
end

function MagicLadyJackPotWinView:initViewData(index,coins,callBackFun)
    self:createGrandShare(self.m_machine)
    self.m_jackpotIndex = 4 - index + 1
    
    self.m_index = index

    local status = self.m_machine.m_jackpot_status
    if index == 4 and status ~= "Normal" then
        self:findChild("jtb_super"):setVisible(status == "Super")
        self:findChild("jtb_mega"):setVisible(status == "Mega")
    else
        self:findChild("jtb_"..self.m_index):setVisible(true)
    end
    

    local coinString = self:findChild("m_lb_coins")

    self.m_callFun = callBackFun
    self.m_winCoins = coins
    -- coinString:setString(coins)
    -- self:updateLabelSize({label = coinString,sx = 0.8,sy = 0.8},815)
    self:jumpCoins(coins)
    self.m_JumpSound = gLobalSoundManager:playSound("MagicLadySounds/sound_MagicLady_jackpot_jump.mp3",true)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function MagicLadyJackPotWinView:jumpCoins(coins)
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
                self:updateLabelSize({label = node,sx = 0.8,sy = 0.8},815)
                self:jumpCoinsFinish()

                if self.m_updateCoinHandlerID ~= nil then
                    scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                    self.m_updateCoinHandlerID = nil
                end
                if self.m_JumpSound then
                    gLobalSoundManager:stopAudio(self.m_JumpSound)
                    self.m_JumpSound = nil
                    gLobalSoundManager:playSound("MagicLadySounds/sound_MagicLady_jackpot_over.mp3")
                end
            else
                node:setString(util_formatCoins(curCoins, 50))
                self:updateLabelSize({label = node,sx = 0.8,sy = 0.8},815)
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
                    gLobalSoundManager:playSound("MagicLadySounds/sound_MagicLady_jackpot_over.mp3")
                end
                node:setString(util_formatCoins(self.m_winCoins, 50))
                self:updateLabelSize({label = node,sx = 0.8,sy = 0.8},815)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end



function MagicLadyJackPotWinView:onEnter()
end

function MagicLadyJackPotWinView:onExit()
    
end

function MagicLadyJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return 
        end
        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then
                self.m_JumpOver = gLobalSoundManager:playSound("MagicLadySounds/sound_MagicLady_jackpot_over.mp3")
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins, 50))
            self:updateLabelSize({label = node,sx = 0.8,sy = 0.8},815)
            self:jumpCoinsFinish()
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
        else
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
    end
end

--[[
    自动分享 | 手动分享
]]
function MagicLadyJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MagicLadyJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function MagicLadyJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MagicLadyJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MagicLadyJackPotWinView