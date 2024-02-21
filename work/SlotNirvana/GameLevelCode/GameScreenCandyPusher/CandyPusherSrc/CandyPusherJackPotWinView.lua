---
--island
--2018年4月12日
--CandyPusherJackPotWinView.lua
local CandyPusherJackPotWinView = class("CandyPusherJackPotWinView", util_require("Levels.BaseLevelDialog"))

CandyPusherJackPotWinView.m_isOverAct = false
CandyPusherJackPotWinView.m_isJumpOver = false

function CandyPusherJackPotWinView:initUI(pusherMainUi,machine)
    self.m_click = true
    self.m_pusherMainUi = pusherMainUi
    self.m_machine = machine
    local resourceFilename = "CandyPusher/JackPotOver.csb"
    self:createCsbNode(resourceFilename)

    self:createGrandShare(machine)
end

function CandyPusherJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    self.m_callFun = callBackFun
    self.m_jackpotIndex = index
  

    local imgName = {"CandyPusher_grand","CandyPusher_major","CandyPusher_minor","CandyPusher_mini"}
    for i=1,4 do
        local img =  self:findChild(imgName[i])
        if img then
            if i == index then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
        end
    end

    local animList = {"fen","zi","lan","lv"}
    self.m_jpLogo = util_spineCreateDifferentPath("CandyPusher_jackpot_tanban","CandyPusher_jackpot_tanban",true,true)
    self:findChild("xiaochou"):addChild(self.m_jpLogo)
    self.m_jpLogo.m_startName = animList[index].."_tanban_start"
    self.m_jpLogo.m_idleName  = animList[index].."_tanban_idle"
    self.m_jpLogo.m_zhenName  = animList[index].."_tanban_zhen"

    -- self.m_jpLogo:setPosition(cc.p(-10,-250 )) -- 下
    self.m_jpLogo:setPosition(cc.p(-10,-125 ))    -- 上

    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(0.1)
    actList[#actList + 1] = cc.MoveTo:create(0.3,cc.p(0,-150))
    actList[#actList + 1] = cc.DelayTime:create(0.1)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        local viewEndPos = self:getParent():convertToNodeSpace(cc.p(display.center))
        self:runAction(cc.MoveTo:create(0.4,cc.p(viewEndPos)))
    end)
    self.m_jpLogo:runAction(cc.Sequence:create(actList))

    util_spinePlay(self.m_jpLogo,self.m_jpLogo.m_startName)
    util_spineFrameCallFunc(self.m_jpLogo, self.m_jpLogo.m_startName, "show", function(  )
        self:beginlabJumpAnim( )
        local scale = 1
        if display.height >= display.width then
            if display.height <= 1228 then
                scale = self:getUIScalePro()
            end
        else
            if display.width <= 1228 then
                scale = self:getUIScalePro()
            end
        end

        util_playScaleToAction(self:findChild("root"),0.5,scale )
        self:runCsbAction("start",false,function(  )
            self.m_click = false
            self:runCsbAction("idle",true)
        end)
    end, function(  )
        util_spinePlay(self.m_jpLogo,self.m_jpLogo.m_idleName,true)
    end)

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function CandyPusherJackPotWinView:onEnter()
    CandyPusherJackPotWinView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function CandyPusherJackPotWinView:onExit()

    CandyPusherJackPotWinView.super.onExit(self)
    
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
    
    gLobalNoticManager:removeAllObservers(self)
end

function CandyPusherJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        gLobalSoundManager:playSound("CandyPusherSounds/sound_CandyPusher_Click.mp3")  

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            self:jackpotViewOver(function()
                if self.m_callFun then
                    self.m_callFun()
                end
            end)
        end 

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("ml_coin")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("CandyPusherSounds/CandyPusher_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end

    end
end

function CandyPusherJackPotWinView:jumpCoins(coins )

    local node=self:findChild("ml_coin")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧
    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = 0

    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            self.m_isJumpOver = true
            curCoins = coins

            local node=self:findChild("ml_coin")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)

            if self.m_soundId then
                gLobalSoundManager:playSound("CandyPusherSounds/CandyPusher_JPCoinsJump_Over.mp3")
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end


            self:jumpCoinsFinish()
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
        else
            local node=self:findChild("ml_coin")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
        end
    end)
end


function CandyPusherJackPotWinView:beginlabJumpAnim( )
    self.m_bgSoundId =  gLobalSoundManager:playSound("CandyPusherSounds/CandyPusher_JackPotWinShow.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        gLobalNoticManager:postNotification(ViewEventType.COINCIRCUS__NOTIC_CLEARMUSIC)
        
        self.m_soundId = gLobalSoundManager:playSound("CandyPusherSounds/CandyPusher_JackPotWinCoins.mp3",true)
        waitNode:removeFromParent()
    end,68/60)

    self:jumpCoins(self.m_coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("ml_coin")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("CandyPusherSounds/CandyPusher_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)
    
end

--[[
    自动分享 | 手动分享
]]
function CandyPusherJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CandyPusherJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function CandyPusherJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CandyPusherJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CandyPusherJackPotWinView