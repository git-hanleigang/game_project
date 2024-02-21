---
--island
--2018年4月12日
--PandaDeluxeJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PandaDeluxeJackPotWinView = class("PandaDeluxeJackPotWinView", util_require("base.BaseView"))


PandaDeluxeJackPotWinView.m_isOverAct = false
PandaDeluxeJackPotWinView.m_isJumpOver = false

function PandaDeluxeJackPotWinView:initUI(data)
    self.m_machine = data

    local resourceFilename = "PandaDeluxe/JackPotover.csb"
    self:createCsbNode(resourceFilename)

end

function PandaDeluxeJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    self.m_jackpotIndex = index
    self:createGrandShare(self.m_machine)
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_JackPotWinShow.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    self.m_soundId = gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    local actNdoe = cc.Node:create()
    self:addChild(actNdoe)
    performWithDelay(actNdoe,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},620)

            self:jumpCoinsFinish()
        end
        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_JackPotWinCoinsEnd.mp3") 
        end

        
        
    end,4)



    self.m_click = true

    self:runCsbAction("start",false,function(  )
       
        self:runCsbAction("idle",true)

        self.m_click = false
    end)

    local imgName = {"m_lb_grand","m_lb_major","m_lb_minor","m_lb_mini"}
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

function PandaDeluxeJackPotWinView:onEnter()
end

function PandaDeluxeJackPotWinView:onExit()

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

function PandaDeluxeJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

        if self:checkShareState() then
            return
        end

        if self.m_click == true then
            return 
        end

        
            
    
            
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        
        if self.m_updateCoinHandlerID == nil then


            
            self:jackpotViewOver(function()
                self.m_click = true
    
                if self.m_bgSoundId then
                    gLobalSoundManager:stopAudio(self.m_bgSoundId)
                    self.m_bgSoundId = nil
                end
                
                self:runCsbAction("over",false,function(  )
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end)

            end)

        end 

        


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},620)

            self:jumpCoinsFinish()
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_JackPotWinCoinsEnd.mp3")

        end

        

        

        
        
        

    end
end

function PandaDeluxeJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (4 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
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
            self:updateLabelSize({label=node,sx=1,sy=1},620)

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound("PandaDeluxeSounds/PandaDeluxe_JackPotWinCoinsEnd.mp3")

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                self:jumpCoinsFinish()
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},620)
        end
        

    end)



end


--[[
    自动分享 | 手动分享
]]
function PandaDeluxeJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function PandaDeluxeJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function PandaDeluxeJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function PandaDeluxeJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return PandaDeluxeJackPotWinView

