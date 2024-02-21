---
--island
--2018年4月12日
--PussJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PussJackPotWinView = class("PussJackPotWinView", util_require("base.BaseView"))


local GrandId = 1
local MajorId = 2
local MinorId = 3

function PussJackPotWinView:initUI(data)
    local isAutoScale =false
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end

    self.m_JPSound = gLobalSoundManager:playSound("PussSounds/music_Puss_ShowJackPot.mp3")

    self.m_click = false

    local resourceFilename = "Puss/JackpotOver.csb"
    self:createCsbNode(resourceFilename,isAutoScale)

    self.m_click = true

end

function PussJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index
    self.m_index = index

    self:findChild("Puss_tanban_Grand"):setVisible(false)
    self:findChild("Puss_tanban_Major"):setVisible(false)
    self:findChild("Puss_tanban_Minor"):setVisible(false)


    if self.m_index == GrandId then
        self:findChild("Puss_tanban_Grand"):setVisible(true)
    elseif self.m_index == MajorId then
        self:findChild("Puss_tanban_Major"):setVisible(true)
    elseif self.m_index == MinorId then
        self:findChild("Puss_tanban_Minor"):setVisible(true)
    end

    
    self.m_winCoins = coins


    self.m_JumpSound =  gLobalSoundManager:playSound("PussSounds/music_Puss_ShowJackPot_Coins_jump.mp3",true)
    self:jumpCoins(coins )

    self.m_click = true

    self:runCsbAction("start",false,function(  )

        self.m_click = false

        self:runCsbAction("idle",true)

    end)

    self.m_callFun = callBackFun
    
    -- local node1=self:findChild("m_lb_coins")
    -- node1:setString(coins)
    -- self:updateLabelSize({label=node1,sx=1,sy=1},592)
    

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function PussJackPotWinView:onEnter()
end

function PussJackPotWinView:onExit()

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

function PussJackPotWinView:closeUI( )
    local bShare = self:checkShareState()
    if not bShare then
        self:jackpotViewOver(function()
            -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:runCsbAction("over",false,function(  )
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end)
        end)
    end
end

function PussJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_2" then

        if self.m_click == true then
            return 
        end

        sender:setTouchEnabled(false)

        if self.m_JPSound then
            gLobalSoundManager:stopAudio(self.m_JPSound)
            self.m_JPSound = nil
        end

        gLobalSoundManager:playSound("PussSounds/music_Puss_Click_Collect.mp3")
        
        self.m_click = true

        if self.m_JumpSound  then
            gLobalSoundManager:stopAudio(self.m_JumpSound)
            self.m_JumpSound = nil
        end

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_winCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},592)
            self:jumpCoinsFinish()

            performWithDelay(self,function(  )
                self:closeUI()
            end,1.5)

        else
            self:closeUI()
        end

        
        


    end
end

function PussJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (3 * 60)  -- 每秒60帧

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
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},592)
            self:jumpCoinsFinish()

            if self.m_JumpSound  then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                self.m_JumpSound = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},592)
        end
        

    end)


end

--[[
    自动分享 | 手动分享
]]
function PussJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function PussJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function PussJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function PussJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return PussJackPotWinView