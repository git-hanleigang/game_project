---
--island
--2018年4月12日
--JackpotOfBeerJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local JackpotOfBeerJackPotWinView = class("JackpotOfBeerJackPotWinView", util_require("Levels.BaseLevelDialog"))


JackpotOfBeerJackPotWinView.m_isOverAct = false
JackpotOfBeerJackPotWinView.m_isJumpOver = false

function JackpotOfBeerJackPotWinView:initUI(_machine)
    self.m_click = true

    local resourceFilename = "JackpotOfBeer/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    self.m_jackpotLinkSpineLeft = util_spineCreate("Socre_JackpotOfBeer_Bonus_link", true, true)
    self.m_jackpotLinkSpineRight = util_spineCreate("Socre_JackpotOfBeer_Bonus_link", true, true)
    self:findChild("Node_spine1"):addChild(self.m_jackpotLinkSpineLeft)
    self:findChild("Node_spine2"):addChild(self.m_jackpotLinkSpineRight)
    
    util_spinePlay(self.m_jackpotLinkSpineLeft,"idle_link_jackpot")
    util_spinePlay(self.m_jackpotLinkSpineRight,"idle_link_jackpot")

    self:createGrandShare(_machine)
end

function JackpotOfBeerJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins
    local indexToJackpotIndex = {
        [4] = 1,
        [3] = 2,
        [2] = 3,
        [1] = 4,
    }
    self.m_jackpotIndex = indexToJackpotIndex[index]



    gLobalSoundManager:playSound("JackpotOfBeerSounds/music_JackpotOfBeer_showRespinJackpot.mp3")
    
    self.m_soundId = gLobalSoundManager:playSound("JackpotOfBeerSounds/JackpotOfBeer_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},500)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then
            gLobalSoundManager:playSound("JackpotOfBeerSounds/JackpotOfBeer_JackPotWinCoins_End.mp3")
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)





    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
        globalData.slotRunData:checkViewAutoClick(self,"Button_collect")
    end)

    local imgName = {"Mini","Minor","Major","Grand"}
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
    
    
    

    self.m_callFun = function(  )

        if callBackFun then
            callBackFun()
        end
        
    end 


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins, self.m_jackpotIndex)
end

function JackpotOfBeerJackPotWinView:onExit()

    JackpotOfBeerJackPotWinView.super.onExit(self)

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    if self.m_soundId then
        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil
    end
    
end

function JackpotOfBeerJackPotWinView:clickFunc(sender)
    if self:checkShareState() then
        return
    end
    local name = sender:getName()
    if name == "Button_collect" then
        if self.m_click == true then
            return 
        end

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
            gLobalSoundManager:playSound("JackpotOfBeerSounds/JackpotOfBeer_JackPotWinCoins_End.mp3")
        end

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true
            self:jackpotViewOver(function()
                self:runCsbAction("over")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end,1)
            end)
        else
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},500)
            self:jumpCoinsFinish()
        end 
    end
end

function JackpotOfBeerJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1,sy=1},500)
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
            self:updateLabelSize({label=node,sx=1,sy=1},500)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function JackpotOfBeerJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function JackpotOfBeerJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function JackpotOfBeerJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function JackpotOfBeerJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return JackpotOfBeerJackPotWinView

