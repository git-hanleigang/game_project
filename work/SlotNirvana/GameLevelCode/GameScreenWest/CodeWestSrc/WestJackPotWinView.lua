---
--island
--2018年4月12日
--WestJackPotWinView.lua
local WestJackPotWinView = class("WestJackPotWinView", util_require("base.BaseView"))


WestJackPotWinView.m_isOverAct = false
WestJackPotWinView.m_isJumpOver = false

function WestJackPotWinView:initUI(data)
    self.m_machine = data
    self.m_click = true

    local resourceFilename = "West/JackpotOver.csb"
    self:createCsbNode(resourceFilename)

end

function WestJackPotWinView:initViewData(index,coins,callBackFun,iCol)
    self.m_index = index
    self.m_coins = coins
    self.m_iCol = iCol or 1

    self.m_jackpotIndex = index
    self:createGrandShare(self.m_machine)
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("WestSounds/West_JackPotWinShow.mp3",false,function(  )
        self.m_bgSoundId = nil
    end)

    self.m_soundId = gLobalSoundManager:playSound("WestSounds/West_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("WestSounds/West_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        
    end,4)


    self:runCsbAction("start".. self.m_iCol,false,function(  )
        self.m_click = false
        self:runCsbAction("idle".. self.m_iCol,true)
    end)

    local imgName = {"mohu_grand","mohu_major","mohu_minor","mohu_mini"}
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
    local nodeName = {"grand","major","minor","mini"} 
    for k,v in pairs(nodeName) do
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

function WestJackPotWinView:onEnter()
end

function WestJackPotWinView:onExit()

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

function WestJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "tb_btn" then
        if self:checkShareState() then
            return
        end
    
        
        if self.m_click == true then
            return 
        end

        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        if self.m_updateCoinHandlerID == nil then
            self:jackpotViewOver(function()
                sender:setTouchEnabled(false)
                self.m_click = true
    
                self:runCsbAction("over".. self.m_iCol)
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
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)

            waitTimes = 2

            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("WestSounds/West_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end
            
        

        

        
        

    end
end

function WestJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)

            self.m_isJumpOver = true

            if self.m_soundId then

                gLobalSoundManager:playSound("WestSounds/West_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=0.85,sy=0.85},643)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function WestJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function WestJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function WestJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function WestJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return WestJackPotWinView

