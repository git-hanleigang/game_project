---
--island
--2018年4月12日
--CoinManiaJackPotWinView.lua
local CoinManiaJackPotWinView = class("CoinManiaJackPotWinView", util_require("base.BaseView"))


CoinManiaJackPotWinView.m_isOverAct = false
CoinManiaJackPotWinView.m_isJumpOver = false

function CoinManiaJackPotWinView:initUI(data)
    self.m_machine = data
    self.m_click = true

    local resourceFilename = "CoinMania/JackpotWin.csb"
    self:createCsbNode(resourceFilename)

end

function CoinManiaJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins

    self.m_jackpotIndex = index
    self:createGrandShare(self.m_machine)
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JackPotWinShow.mp3",false)
    performWithDelay(self,function (  )
        self.m_bgSoundId = nil
    end,5.5)

    self.m_soundId = gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1.05,sy=1.05},468)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local imgName = {"m_lb_mega","m_lb_grand","m_lb_major","m_lb_minor","m_lb_mini"}
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

function CoinManiaJackPotWinView:onEnter()
end

function CoinManiaJackPotWinView:onExit()

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

function CoinManiaJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self:checkShareState() then
            return
        end
    
        
        if self.m_click == true then
            return 
        end

        -- gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_taptospin_Click.mp3")
        
        if self.m_updateCoinHandlerID == nil then
            self:jackpotViewOver(function()
                sender:setTouchEnabled(false)
                self.m_click = true
    
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
        end 

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1.05,sy=1.05},468)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JPCoinsJump_Over.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        
    end
end

function CoinManiaJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

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
            self:updateLabelSize({label=node,sx=1.05,sy=1.05},468)
            

            self.m_isJumpOver = true
            if self.m_soundId then
                gLobalSoundManager:playSound("CoinManiaSounds/CoinMania_JPCoinsJump_Over.mp3")
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                self:jumpCoinsFinish()
            end
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1.05,sy=1.05},468)
        end
    end)



end

--[[
    自动分享 | 手动分享
]]
function CoinManiaJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function CoinManiaJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function CoinManiaJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function CoinManiaJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return CoinManiaJackPotWinView

