---
--island
--2018年4月12日
--PirateJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PirateJackPotWinView = class("PirateJackPotWinView", util_require("base.BaseView"))

function PirateJackPotWinView:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "Pirate/JackpotWinView.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
    self.m_isJumpOver = false
end

function PirateJackPotWinView:initViewData(index,coins,mainMachine,callBackFun)
    
    self.m_index = index
    self.m_StrType = "mini"
    if self.m_index == 1002 then
        self.m_StrType = "mini"
        self.m_index = 1
    elseif self.m_index == 1003 then
        self.m_StrType = "minor"
        self.m_index = 2
    elseif self.m_index == 1004 then
        self.m_StrType = "major"
        self.m_index = 3
    elseif self.m_index == 1005 then
        self.m_StrType = "grand"
        self.m_index = 4
    end
    
    self:findChild("grand"):setVisible(false)
    self:findChild("major"):setVisible(false)
    self:findChild("minor"):setVisible(false)
    self:findChild("mini"):setVisible(false)

    if self.m_index == 4 then
        self:findChild("grand"):setVisible(true)
    elseif self.m_index == 3 then
        self:findChild("major"):setVisible(true)
    elseif self.m_index == 2 then
        self:findChild("minor"):setVisible(true)
    elseif self.m_index == 1 then
        self:findChild("mini"):setVisible(true)
    end
    self.m_jackpotIndex = 4 - self.m_index + 1
    self:runCsbAction("start",false,function(  )
        if self.m_JumpOver == nil then
            self.m_JumpOver = gLobalSoundManager:playSound("PirateSounds/sound_pirate_jackpot_over.mp3")
        end
        self:createGrandShare(mainMachine)
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},765)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("PirateSounds/sound_pirate_jackpot.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function PirateJackPotWinView:jumpCoins(coins )
    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒30帧

    local str = string.gsub(tostring(coinRiseNum),"0", math.random(1,5) )
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    util_schedule(node,function()
        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then
            self.m_isJumpOver = true
            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},765)

            self:jumpCoinsFinish()

            node:stopAllActions()
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("PirateSounds/sound_Pirate_jackpot_over.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},765)
        end
    end,1 / 120)

    performWithDelay(
        self,
        function()
            if not tolua.isnull(node) then
                node:stopAllActions()
            end
            
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("PirateSounds/sound_Pirate_jackpot_over.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},765)
            self:jumpCoinsFinish()
        end,
        5
    )
end

function PirateJackPotWinView:onEnter()
end

function PirateJackPotWinView:onExit()
    if self.m_JumpOver then
        gLobalSoundManager:stopAudio(self.m_JumpOver)
        self.m_JumpOver = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end
end

function PirateJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then
        if self.m_click == true then
            return 
        end
        local bShare = self:checkShareState()
        if not bShare then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            
            if not self.m_isJumpOver then
                self.m_isJumpOver = true
                local node=self:findChild("m_lb_coins")
                node:stopAllActions()

                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},765)
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
end

function PirateJackPotWinView:closeUI( )
   
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
function PirateJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function PirateJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function PirateJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function PirateJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return PirateJackPotWinView