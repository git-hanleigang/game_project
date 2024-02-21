---
--island
--2018年4月12日
--TripletroveJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local TripletroveJackPotWinView = class("TripletroveJackPotWinView", util_require("base.BaseView"))


local GrandId = 1
local MajorId = 2
local MinorId = 3
local MiniId  = 4

function TripletroveJackPotWinView:initUI()

    local resourceFilename = "Tripletrove/Jackpot.csb"
    self:createCsbNode(resourceFilename)

    self.m_click = true

end

function TripletroveJackPotWinView:initShow(index)
    for i=1,6 do
        if i == index then
            self:findChild("Node_jackpot_" .. i):setVisible(true)
        else
            self:findChild("Node_jackpot_" .. i):setVisible(false)
        end
    end
end

function TripletroveJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index
    
    self.m_winCoins = coins
    self.m_callFun = callBackFun
    self.m_JumpSound = gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_coinsJump.mp3",true)
    self:jumpCoins(coins )

    self:initShow(index)
    local soundFile = "TripletroveSounds/music_Tripletrove_mini_jackpot.mp3"
    if index == 1 then
        soundFile = "TripletroveSounds/music_Tripletrove_grand_jackpot.mp3"
    elseif index == 2 then
        soundFile = "TripletroveSounds/music_Tripletrove_super_jackpot.mp3"
    elseif index == 3 then
        soundFile = "TripletroveSounds/music_Tripletrove_mega_jackpot.mp3"
    elseif index == 4 then
        soundFile = "TripletroveSounds/music_Tripletrove_major_jackpot.mp3"
    elseif index == 5 then
        soundFile = "TripletroveSounds/music_Tripletrove_minor_jackpot.mp3"
    elseif index == 6 then
        soundFile = "TripletroveSounds/music_Tripletrove_mini_jackpot.mp3"
    end
    self.m_JPSound = gLobalSoundManager:playSound(soundFile)
    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=0.88,sy=0.97},843)
            self:jumpCoinsFinish()
        end

        if self.m_JumpSound then
            gLobalSoundManager:stopAudio(self.m_JumpSound)
            gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_coinsOver.mp3")
            self.m_JumpSound = nil
        end
    end,4)
    
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function TripletroveJackPotWinView:onEnter()
    TripletroveJackPotWinView.super.onEnter(self)
    --解决进入横版活动时再切换回关卡 弹板位置不对问题
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

function TripletroveJackPotWinView:onExit()
    TripletroveJackPotWinView.super.onExit(self)
    if self.m_JPSound then
        gLobalSoundManager:stopAudio(self.m_JPSound)
        self.m_JPSound = nil
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


function TripletroveJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_click.mp3")

        if self.m_JPSound then
            gLobalSoundManager:stopAudio(self.m_JPSound)
            self.m_JPSound = nil
        end
        
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_coinsOver.mp3")
                self.m_JumpSound = nil
            end
            local node = self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=0.88,sy=0.97},843)
            self:jumpCoinsFinish()

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
                        
                    end,0.5)
                    performWithDelay(self,function (  )
                        self:removeFromParent()
                    end,0.6)
                end)
            end
        end

    end
end

function TripletroveJackPotWinView:jumpCoins(coins )

    local node =self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (3 * 60)  -- 每秒60帧

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
            self:updateLabelSize({label=node,sx=0.88,sy=0.97},843)
            self:jumpCoinsFinish()

            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                gLobalSoundManager:playSound("TripletroveSounds/music_Tripletrove_jackpot_coinsOver.mp3")
                self.m_JumpSound = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.88,sy=0.97},843)
        end
        

    end)


end

--[[
    自动分享 | 手动分享
]]
function TripletroveJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function TripletroveJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function TripletroveJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function TripletroveJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return TripletroveJackPotWinView