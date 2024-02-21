---
--smy
--2018年4月26日
--WallballJackpotOver.lua

local WallballJackpotOver = class("WallballJackpotOver",util_require("base.BaseView"))
local JACKPOT_ID_ARRAY = 
{
    Grand = 1,
    Major = 2,
    Minor = 3,
}

function WallballJackpotOver:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    local resourceFilename = "Wallball/Jackpotover.csb"
    self:createCsbNode(resourceFilename,isAutoScale)
    self.m_click = true
    self.m_JumpOver = nil 
    
end

function WallballJackpotOver:initViewData(jackpot, coins, mainMachine, callBackFun)
    self.m_jackpotIndex = JACKPOT_ID_ARRAY[jackpot]
    self:createGrandShare(mainMachine)
    self:findChild("Grand"):setVisible(false)
    self:findChild("Major"):setVisible(false)
    self:findChild("Minor"):setVisible(false)

    self:findChild(jackpot):setVisible(true)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)
    self.m_click = false
    self.m_callFun = callBackFun
    
    local node1=self:findChild("m_lb_coins")
    self.m_winCoins = coins
    self:updateLabelSize({label=node1,sx=1,sy=1},652)
    self:jumpCoins(coins )
    self.m_JumpSound = gLobalSoundManager:playSound("WallballSounds/sound_AZTEC_jackpot_up.mp3",true)
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, JACKPOT_ID_ARRAY[jackpot])
end

function WallballJackpotOver:jumpCoins(coins )
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

            self:jumpCoinsFinish()

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end
            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
                gLobalSoundManager:playSound("WallballSounds/sound_Wallball_num_end.mp3")
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
                    gLobalSoundManager:playSound("WallballSounds/sound_Wallball_num_end.mp3")
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

function WallballJackpotOver:onEnter()
    
end

function WallballJackpotOver:onExit()
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

function WallballJackpotOver:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
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
                    self.m_JumpOver = gLobalSoundManager:playSound("WallballSounds/sound_Wallball_num_end.mp3")
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
end

function WallballJackpotOver:closeUI( )
   
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
function WallballJackpotOver:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function WallballJackpotOver:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function WallballJackpotOver:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function WallballJackpotOver:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

-- 如果本界面需要添加touch 事件，则从BaseView 获取
return WallballJackpotOver
