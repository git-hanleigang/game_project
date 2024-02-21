---
--island
--2018年4月12日
--HogHustlerJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local HogHustlerJackPotWinView = class("HogHustlerJackPotWinView", util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

HogHustlerJackPotWinView.m_isOverAct = false
HogHustlerJackPotWinView.m_isJumpOver = false

function HogHustlerJackPotWinView:initUI(data)
    self.m_click = true
    self.m_machine = data

    local resourceFilename = "HogHustler/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

end

function HogHustlerJackPotWinView:initViewData(index,coins,callBackFun,callFunClick)
    self.m_index = index
    self.m_coins = coins

    self.m_jackpotIndex = 4 - index + 1
    self:createGrandShare(self.m_machine)
    
    local num = 1
    if index >= 1 and index <= 4 then
        num = index
    end 
    self.m_bgSoundId =  gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_jackpot_popup_" .. num .. ".mp3",false)

    self.m_soundId = gLobalSoundManager:playSound("HogHustlerSounds/sound_HogHustler_jackpot_num_jump_runing.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},732)

            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self.m_machine:addPopupCommonRole(self)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    -- local imgName = {"Node_grand","Node_major","Node_minor","Node_mini"}
    local imgName = {"Node_mini","Node_minor","Node_major","Node_grand"}
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
    self.m_callFunClick = callFunClick


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function HogHustlerJackPotWinView:onEnter()

    HogHustlerJackPotWinView.super.onEnter(self)
end

function HogHustlerJackPotWinView:onExit()

    HogHustlerJackPotWinView.super.onExit(self)

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

function HogHustlerJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        if self:checkShareState() then
            return
        end
        
        -- gLobalSoundManager:playSound("levelsTempleSounds/music_levelsTemples_Click_Collect.mp3")
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_click)
        
        if self.m_updateCoinHandlerID == nil then
            self:jackpotViewOver(function (  )
                sender:setTouchEnabled(false)
                self.m_click = true

                self:runCsbAction("over")
                if self.m_callFunClick then
                    self.m_callFunClick()
                end
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_jackpot_popup_over)
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
            
        end 

        


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},732)

            waitTimes = 2

            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end

        
        

    end
end

function HogHustlerJackPotWinView:jumpCoins(coins )

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
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},732)

            self.m_isJumpOver = true

            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_jackpot_num_jump_over)

            if self.m_soundId then
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
            self:updateLabelSize({label=node,sx=1,sy=1},732)
        end
        

    end)



end


--[[
    自动分享 | 手动分享
]]
function HogHustlerJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function HogHustlerJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function HogHustlerJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function HogHustlerJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return HogHustlerJackPotWinView

