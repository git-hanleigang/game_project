---
--island
--2018年4月12日
--FortuneGodJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local FortuneGodJackPotWinView = class("FortuneGodJackPotWinView", util_require("Levels.BaseLevelDialog"))


FortuneGodJackPotWinView.m_isOverAct = false
FortuneGodJackPotWinView.m_isJumpOver = false

function FortuneGodJackPotWinView:initUI(_machine)
    self.m_click = true

    local resourceFilename = "FortuneGod/LockSpinJackpot.csb"
    self:createCsbNode(resourceFilename)
    self:createGrandShare(_machine)

    self:addClick(self:findChild("Panel_dianji"))
    
end

function FortuneGodJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    self.m_jackpotIndex = 4 - index + 1
    -- self.m_bgSoundId =  gLobalSoundManager:playSound("FortuneGodSounds/FortuneGod_JackPotWinShow.mp3",false)



    --创建spine
    self.spinePeople = util_spineCreate("Socre_jp_tanban",true,true)
    self:findChild("Node_renwu"):addChild(self.spinePeople)
    --将钱数挂在spine上
    self.jump_coins = util_createAnimation("Socre_FortuneGod_font_5.csb")
    self.jump_coins:findChild("Particle_1"):stopSystem()--移动结束后将拖尾停掉
    util_spinePushBindNode(self.spinePeople,"anniubaidian88",self.jump_coins)
    --根据index切换皮肤
    local skinName = self:changeSpineShow()
    self.spinePeople:setSkin(skinName)

    self.m_soundId = gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpot_coinsJump.mp3",true)
    self:jumpCoins(coins )

    util_spinePlay(self.spinePeople,"start",false)
    performWithDelay(self,function (  )
        self.m_click = false

        util_spinePlay(self.spinePeople,"idleframe",true)
    end,1)

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node = self.jump_coins:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1.08,sy=1.08},575)
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpot_coinsOver.mp3")
            self.m_soundId = nil
        end
    end,4)

    self.m_callFun = callBackFun

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function FortuneGodJackPotWinView:changeSpineShow()
    if self.m_index == 1 then
        return "zhongban3"
    elseif self.m_index == 2 then
        return "zhongban4"
    elseif self.m_index == 3 then
        return "zhongban2"
    elseif self.m_index == 4 then
        return "zhongban1" 
    end
end

function FortuneGodJackPotWinView:onExit()
    FortuneGodJackPotWinView.super.onExit(self)

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

function FortuneGodJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_dianji" then
        if self:checkShareState() then
            return
        end
        if self.m_click == true then
            return 
        end

        if self.m_updateCoinHandlerID ~= nil then
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpot_coinsOver.mp3")
                
                self.m_soundId = nil
            end
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self.jump_coins:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1.08,sy=1.08},575)
            self:jumpCoinsFinish()
        else
            sender:setTouchEnabled(false)
            self.m_click = true
            self:jackpotViewOver(function()
                util_spinePlay(self.spinePeople,"over",false)
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,0.5)
            end)
        end
 
    end
end

function FortuneGodJackPotWinView:jumpCoins(coins )

    local node=self.jump_coins:findChild("m_lb_coins")
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

            local node=self.jump_coins:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1.08,sy=1.08},575)
            self:jumpCoinsFinish()
            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                gLobalSoundManager:playSound("FortuneGodSounds/music_FortuneGod_jackpot_coinsOver.mp3")
                self.m_soundId = nil
            end


            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self.jump_coins:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1.08,sy=1.08},575)
        end

    end)
end

--[[
    自动分享 | 手动分享
]]
function FortuneGodJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function FortuneGodJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function FortuneGodJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function FortuneGodJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FortuneGodJackPotWinView

