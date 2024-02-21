---
--island
--2018年4月12日
--MonsterPartyJackPotWinView.lua
local MonsterPartyJackPotWinView = class("MonsterPartyJackPotWinView", util_require("base.BaseView"))


MonsterPartyJackPotWinView.m_isOverAct = false
MonsterPartyJackPotWinView.m_isJumpOver = false

function MonsterPartyJackPotWinView:initUI(data)
    self.m_machine = data
    self.m_click = true

    local resourceFilename = "MonsterParty/JackpotWin.csb"
    self:createCsbNode(resourceFilename)

end

function MonsterPartyJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    self.m_coins = coins


    self.m_jackpotIndex = index
    self:createGrandShare(self.m_machine)

    
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JackPotWinShow.mp3",false)

    performWithDelay(self,function (  )
        self.m_bgSoundId = nil
    end,3)

    self.m_soundId = gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1.45,sy=1.45},421)

            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JP_Over.mp3")

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

function MonsterPartyJackPotWinView:onEnter()
end

function MonsterPartyJackPotWinView:onExit()

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

function MonsterPartyJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        if self:checkShareState() then
            return
        end

       
        if self.m_click == true then
            return 
        end

        
        
        gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_taptospin_Click.mp3")
        
        
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

        


        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1.45,sy=1.45},421)

            waitTimes = 2

            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JP_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end
    
            
            
    
        

        
    end
end

function MonsterPartyJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1.45,sy=1.45},421)

            self.m_isJumpOver = true

            if self.m_soundId then

                gLobalSoundManager:playSound("MonsterPartySounds/MonsterParty_JP_Over.mp3")

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
            self:updateLabelSize({label=node,sx=1.45,sy=1.45},421)
        end
        

    end)



end


--[[
    自动分享 | 手动分享
]]
function MonsterPartyJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function MonsterPartyJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function MonsterPartyJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function MonsterPartyJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return MonsterPartyJackPotWinView

