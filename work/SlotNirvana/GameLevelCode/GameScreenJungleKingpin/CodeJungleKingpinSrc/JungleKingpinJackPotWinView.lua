---
--island
--2018年4月12日
--JungleKingpinJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JungleKingpinJackPotWinView = class("JungleKingpinJackPotWinView", util_require("base.BaseView"))

function JungleKingpinJackPotWinView:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "JungleKingpin/JackpotWinView.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
end


function JungleKingpinJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)

    self.m_index = index
    self.m_StrType = "mini"
    if self.m_index == 4 then
        self.m_StrType = "mini"
        self.m_index = 1
        self.m_jackpotIndex = 3
    elseif self.m_index == 5 then
        self.m_StrType = "major"
        self.m_index = 2
        self.m_jackpotIndex = 2
    elseif self.m_index == 6 then
        self.m_StrType = "grand"
        self.m_index = 3
        self.m_jackpotIndex = 1
    end
    
    self:findChild("jackpot_grand"):setVisible(false)
    self:findChild("jackpot_major"):setVisible(false)
    self:findChild("jackpot_mini"):setVisible(false)

    if self.m_index == 3 then
        self:findChild("jackpot_grand"):setVisible(true)
    elseif self.m_index == 2 then
        self:findChild("jackpot_major"):setVisible(true)
    elseif self.m_index == 1 then
        self:findChild("jackpot_mini"):setVisible(true)
    end

    self:runCsbAction("start",false,function(  )
        if self.m_JumpOver == nil then
            self.m_JumpOver = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
        end
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},634)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_win.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function JungleKingpinJackPotWinView:jumpCoins(coins )
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
            self:updateLabelSize({label=node,sx=1,sy=1},634)
            self:jumpCoinsFinish()

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},634)
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
                    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
                end
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_winCoins,50))
                self:updateLabelSize({label=node,sx=1,sy=1},634)
                self:jumpCoinsFinish()
            end
        end,
        5
    )
end

function JungleKingpinJackPotWinView:onEnter()

end

function JungleKingpinJackPotWinView:onExit()
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

function JungleKingpinJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_collect" then
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpOver == nil then 
                self.m_JumpOver = gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_jackpot_over.mp3")
            end
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},634)
            self:jumpCoinsFinish()
            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end
            self:runCsbAction("idle",true)
        else
            self.m_click = true
            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    self:closeUI()
                end)
            end
            
        end
    end
end

function JungleKingpinJackPotWinView:closeUI( )
   
    self:runCsbAction("over",false,function(  )
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

--[[
    自动分享 | 手动分享
]]
function JungleKingpinJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function JungleKingpinJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function JungleKingpinJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function JungleKingpinJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return JungleKingpinJackPotWinView