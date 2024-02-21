---
--island
--2018年4月12日
--AtlantisJackPotWinView.lua
local AtlantisJackPotWinView = class("AtlantisJackPotWinView", util_require("base.BaseView"))


AtlantisJackPotWinView.m_isOverAct = false
AtlantisJackPotWinView.m_isJumpOver = false

function AtlantisJackPotWinView:initUI(data)
    self.m_click = true

    local resourceFilename = "Atlantis/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    local light = util_createAnimation("JackpotWinView_bg_guang.csb")
    light:runCsbAction("idle",true)
    local node = self:findChild("node_jackpotbg_guang")
    node:removeAllChildren(true)
    node:addChild(light)

    if globalData.slotRunData.m_isAutoSpinAction then
        local wait_node = cc.Node:create()
        self:addChild(wait_node)
        performWithDelay(wait_node,function(  )
            self:clickFunc(self:findChild("Button"))
        end,5)
    end
    

end

function AtlantisJackPotWinView:initViewData(machine,index,coins,callBackFun)
    self:createGrandShare(machine)
    self.m_jackpotIndex = index

    self.m_index = index
    self.m_coins = coins

    
    -- self.m_bgSoundId =  gLobalSoundManager:playSound("AtlantisSounds/Atlantis_JackPotWinShow.mp3",false,function(  )
    --     self.m_bgSoundId = nil
    -- end)

    self.m_soundId = gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )
    

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.95,sy=0.95},686)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
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

function AtlantisJackPotWinView:onEnter()
end

function AtlantisJackPotWinView:onExit()

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

function AtlantisJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

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
            self:updateLabelSize({label=node,sx=0.95,sy=0.95},686)
            self:jumpCoinsFinish()

            waitTimes = 2
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("sound_AtlantisSounds/Atlantis_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end
    end
end

function AtlantisJackPotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=0.95,sy=0.95},686)
            self:jumpCoinsFinish()

            self.m_isJumpOver = true

            if self.m_soundId then

                gLobalSoundManager:playSound("AtlantisSounds/sound_Atlantis_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=0.95,sy=0.95},686)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function AtlantisJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function AtlantisJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function AtlantisJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function AtlantisJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return AtlantisJackPotWinView

