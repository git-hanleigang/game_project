---
--island
--2018年4月12日
--BlackFridayJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local BlackFridayJackPotWinView = class("BlackFridayJackPotWinView", util_require("Levels.BaseLevelDialog"))


BlackFridayJackPotWinView.m_isOverAct = false
BlackFridayJackPotWinView.m_isJumpOver = false

function BlackFridayJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "BlackFriday/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    -- 弹板上的光
    local tanbanShine = util_createAnimation("BlackFriday_FreeSpin_guang.csb")
    self:findChild("guang"):addChild(tanbanShine)
    tanbanShine:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("guang"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("guang"), true)

    -- 弹板上的跑马灯
    local tanbanDeng = util_createAnimation("BlackFriday_shanshuo_1.csb")
    self:findChild("shanshuo"):addChild(tanbanDeng)
    tanbanDeng:runCsbAction("idle",true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("shanshuo"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("shanshuo"), true)

    -- 角色
    self.m_jiaoSe = util_spineCreate("BlackFriday_juese",true,true)
    self:findChild("juese"):addChild(self.m_jiaoSe)
    util_spinePlay(self.m_jiaoSe, "idleframe_tanban", true)

end

function BlackFridayJackPotWinView:initViewData(index,coins,callBackFun,machine)
    self.m_index = index
    self.m_coins = coins
    self.m_machine = machine
    self.m_jackpotIndex = index
    self:createGrandShare(machine)

    self.m_bgSoundId = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig["sound_BlackFriday_jackpot"..index])

    self.m_soundId = gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_jackpotJumpCoin)

    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},647)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    self.m_machine:waitWithDelay(2/60,function()
        local imgName = {"Node_grand","Node_major","Node_minor","Node_mini"}
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
    end)
    
    self.m_callFun = callBackFun

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function BlackFridayJackPotWinView:onEnter()

    BlackFridayJackPotWinView.super.onEnter(self)
end

function BlackFridayJackPotWinView:onExit()

    BlackFridayJackPotWinView.super.onExit(self)

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

function BlackFridayJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        
        gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_click)

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true
            local bShare = self:checkShareState()
            if not bShare then
                self:jackpotViewOver(function()
                    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_jackpot_over)

                    self:runCsbAction("over",false,function()
                        if self.m_callFun then
                            self.m_callFun()
                        end
                        self:removeFromParent()
                    end)
                end)
            end
        end 

        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},647)
            self:jumpCoinsFinish()

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end
end

function BlackFridayJackPotWinView:jumpCoins(coins )

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
            node:setString(util_formatCoins(curCoins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},647)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_BlackFriday_jackpotJumpCoinEnd)
        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,30))
            self:updateLabelSize({label=node,sx=1,sy=1},647)
        end
    end)
end

--[[
    自动分享 | 手动分享
]]
function BlackFridayJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function BlackFridayJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function BlackFridayJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function BlackFridayJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return BlackFridayJackPotWinView

