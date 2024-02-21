---
--island
--2018年4月12日
--CoinCircusJackPotWinView.lua
local CoinCircusJackPotWinView = class("CoinCircusJackPotWinView", util_require("Levels.BaseLevelDialog"))


CoinCircusJackPotWinView.m_isOverAct = false
CoinCircusJackPotWinView.m_isJumpOver = false

function CoinCircusJackPotWinView:initUI(_machine)
    self.m_click = true

    local resourceFilename = "CoinCircus/JackPotOver.csb"
    self:createCsbNode(resourceFilename)

    self:createGrandShare(_machine)
end

function CoinCircusJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    -- Grand Mini Major minor
    local wheelIndexToJpIndex = {
        [1] = 1,
        [2] = 4,
        [3] = 2,
        [4] = 3,
    }
    self.m_jackpotIndex = wheelIndexToJpIndex[index] or index

    self.m_bgSoundId =  gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JackPotWinShow.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function(  )
        
        gLobalNoticManager:postNotification(ViewEventType.COINCIRCUS__NOTIC_CLEARMUSIC)
        
        self.m_soundId = gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JackPotWinCoins.mp3",true)
        waitNode:removeFromParent()
    end,68/60)

    self:jumpCoins(coins )

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
            -- gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )

        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"CoinCircus_grand_9","CoinCircus_mini_6","CoinCircus_major_7","CoinCircus_minor_8"}
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

end

function CoinCircusJackPotWinView:onExit()

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
    
    CoinCircusJackPotWinView.super.onExit(self)
end

function CoinCircusJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end

    local name = sender:getName()
    if name == "Button_1" then
        if self.m_click == true then
            return 
        end
        gLobalSoundManager:playSound("CoinCircusSounds/sound_CoinCircus_Click.mp3")  
        if self.m_soundId then
            -- gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end

        if self.m_updateCoinHandlerID == nil then
            self:jackpotViewOver(function()
                sender:setTouchEnabled(false)
                self.m_click = true

                if self.m_callFun then
                    self.m_callFun()
                end
            end)
        else
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("ml_coin")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
            self:jumpCoinsFinish()
        end
    end
end

function CoinCircusJackPotWinView:jumpCoins(coins )

    local node=self:findChild("ml_coin")
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

            local node=self:findChild("ml_coin")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},621)
            self:jumpCoinsFinish()
            self.m_isJumpOver = true

            if self.m_soundId then
                -- gLobalSoundManager:playSound("CoinCircusSounds/CoinCircus_JPCoinsJump_Over.mp3")
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

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

--[[
    自动分享 | 手动分享
]]
function CoinCircusJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CoinCircusJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function CoinCircusJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CoinCircusJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return CoinCircusJackPotWinView

