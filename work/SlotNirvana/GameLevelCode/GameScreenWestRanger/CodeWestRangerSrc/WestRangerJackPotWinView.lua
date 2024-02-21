---
--island
--2018年4月12日
--WestRangerJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local WestRangerJackPotWinView = class("WestRangerJackPotWinView", util_require("Levels.BaseLevelDialog"))


WestRangerJackPotWinView.m_isOverAct = false
WestRangerJackPotWinView.m_isJumpOver = false

function WestRangerJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "WestRanger/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    self.m_jackpotRole = util_spineCreate("Socre_WestRanger_Wild", true, true)
    self:findChild("juese"):addChild(self.m_jackpotRole)
    self.m_jackpotRole:setVisible(false)
end

function WestRangerJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins

    self:createGrandShare(machine)
    self.m_jackpotIndex = 4 - index + 1
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("WestRangerSounds/sound_WestRangers_jackpotPopup" .. tostring(index) .. ".mp3", false)

    self.m_soundId = gLobalSoundManager:playSound("WestRangerSounds/sound_WestRangers_jackpotJumpCoin.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},794)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    self.m_jackpotRole:setVisible(true)
    util_spinePlay(self.m_jackpotRole,"TB_star",false)
    util_spineEndCallFunc(self.m_jackpotRole,"TB_star",function ()
        util_spinePlay(self.m_jackpotRole,"TB_idleframe",true)
    end)

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"kuang_mini","kuang_minor","kuang_major","kuang_grand"}
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

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function WestRangerJackPotWinView:onEnter()

    WestRangerJackPotWinView.super.onEnter(self)
end

function WestRangerJackPotWinView:onExit()

    WestRangerJackPotWinView.super.onExit(self)

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

function WestRangerJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

        if self.m_click == true then
            return 
        end

        gLobalSoundManager:playSound("WestRangerSounds/sound_WestRangers_Click_Collect.mp3")

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
            node:setString(util_formatCoins(self.m_coins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},794)
            self:jumpCoinsFinish()

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end
end

function WestRangerJackPotWinView:jumpCoins(coins )

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
            node:setString(util_formatCoins(curCoins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},794)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end


            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            gLobalSoundManager:playSound("WestRangerSounds/sound_WestRangers_jackpotJumpCoinEnd.mp3")
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},794)
        end
        

    end)
end

--[[
    自动分享 | 手动分享
]]
function WestRangerJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WestRangerJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function WestRangerJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WestRangerJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WestRangerJackPotWinView

