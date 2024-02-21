---
--island
--2018年4月12日
--FruitPartyJackPotWinView.lua
local FruitPartyJackPotWinView = class("FruitPartyJackPotWinView", util_require("base.BaseView"))


FruitPartyJackPotWinView.m_isOverAct = false
FruitPartyJackPotWinView.m_isJumpOver = false

function FruitPartyJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "FruitParty/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            self:clickFunc(self:findChild("tb_btn"))
        end,5)
    end
    

end

function FruitPartyJackPotWinView:initViewData(machine,jackpotType,coins,callBackFun)
    self.m_coins = coins
    self:createGrandShare(machine)

    if "Grand" == jackpotType then
        self.m_jackpotIndex = 1
    elseif "Major" == jackpotType then
        self.m_jackpotIndex = 2
    elseif "Minor" == jackpotType then
        self.m_jackpotIndex = 3
    end

    self.m_soundId = gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_jackpot_collect_coins.mp3",true)
    self:jumpCoins(coins)
    

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},573)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("FruitPartySounds/sound_FruitParty_jackpot_jump_over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local nodeName = {
        Grand = "grand",
        Major = "major",
        Minor = "minor"
    } 
    for k,v in pairs(nodeName) do
        local img =  self:findChild(v)
        if img then
            if k == jackpotType then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
            
        end
    end

    self.m_callFun = callBackFun

end

function FruitPartyJackPotWinView:onEnter()
end

function FruitPartyJackPotWinView:onExit()

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

function FruitPartyJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if self.m_click == true then
        return 
    end

    
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if self.m_updateCoinHandlerID == nil then
        sender:setTouchEnabled(false)
        self.m_click = true

        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
        end
    end 

    


    local waitTimes = 0
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
        local node=self:findChild("m_lb_coins")
        node:setString(util_formatCoins(self.m_coins,50))
        self:updateLabelSize({label=node,sx=1,sy=1},573)
        self:jumpCoinsFinish()

        waitTimes = 2
    end

    if self.m_soundId then

        gLobalSoundManager:playSound("sound_FruitPartySounds/sound_FruitParty_jackpot_jump_over.mp3")

        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil

        
    end
end

function FruitPartyJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1,sy=1},573)
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

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},573)
        end
        
    end)



end

--[[
    自动分享 | 手动分享
]]
function FruitPartyJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function FruitPartyJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function FruitPartyJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function FruitPartyJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return FruitPartyJackPotWinView

