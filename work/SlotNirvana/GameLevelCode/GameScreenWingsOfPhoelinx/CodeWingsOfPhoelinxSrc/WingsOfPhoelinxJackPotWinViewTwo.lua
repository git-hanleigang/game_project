---
--island
--2018年4月12日
--WingsOfPhoelinxJackPotWinViewTwo.lua
---- 中多个jackpot使用
local WingsOfPhoelinxJackPotWinViewTwo = class("WingsOfPhoelinxJackPotWinViewTwo", util_require("Levels.BaseLevelDialog"))


WingsOfPhoelinxJackPotWinViewTwo.m_isOverAct = false
WingsOfPhoelinxJackPotWinViewTwo.m_isJumpOver = false

function WingsOfPhoelinxJackPotWinViewTwo:initUI()
    self.m_click = true

    local resourceFilename = "WingsOfPhoelinx/JackpotOver_0.csb"
    self:createCsbNode(resourceFilename)
    self.m_isJumpOver = false
end

--传两个coins和index进来，用于通知不同的jackpot。index3用于展示图片
function WingsOfPhoelinxJackPotWinViewTwo:initViewData(index1,index2,index3,coins1,coins2,callBackFun)
    self.m_coins = coins1 + coins2
    
    self.m_bgSoundId =  gLobalSoundManager:playSound("WingsOfPhoelinxSounds/Jackpot_WingsOfPhoelinx_Win.mp3",false)

    
    
    --将两种jackpot的钱显示出来（coins1,coins2，index1,index2)
    self:showTwoJackpot(coins1,coins2)
    self:showjackpotFen(index1,index2)
    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle")
    end)
    --播时间线进行合并
    performWithDelay(self,function (  )
        --显示jackpot图片
        self:showjackpotHe(index1,index2)
        
            
        self:runCsbAction("actionframe",false,function (  )
            self.m_click = false
            self:runCsbAction("idle1")
            
        end)
        --跳钱数 
        self:jumpCoins(self.m_coins)

        performWithDelay(self,function (  )
            self.m_soundId = gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpCoins.mp3",true)
        end,0.3)
    end,1)

    
    

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins_3")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},714)
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpOverCoins.mp3")
            self.m_soundId = nil
        end
    end,4)

    -- self:runCsbAction("start",false,function(  )
    --     
    --     self:runCsbAction("idle",true)
    -- end)

    --显示
    -- local imgName = {"WingsOfPhoelinx_grand1_2","WingsOfPhoelinx_major1_3","WingsOfPhoelinx_minor1_5","WingsOfPhoelinx_mini1_4"}
    -- 
    
    self.m_callFun = callBackFun

    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins1,index1)
    globalData.jackpotRunData:notifySelfJackpot(coins2,index2)
end

--展示两个jackpot钱数
function WingsOfPhoelinxJackPotWinViewTwo:showTwoJackpot(coins1,coins2)
    --左
    local node1=self:findChild("m_lb_coins_1")
    node1:setString(util_formatCoins(coins1,50))
    self:updateLabelSize({label=node1,sx=0.98,sy=0.98},714)

    --右
    local node2=self:findChild("m_lb_coins_2")
    node2:setString(util_formatCoins(coins2,50))
    self:updateLabelSize({label=node2,sx=0.98,sy=0.98},714)
end

function WingsOfPhoelinxJackPotWinViewTwo:showjackpotFen(index1,index2)
    local leftNameList = {"WingsOfPhoelinx_major1_19","WingsOfPhoelinx_minor1_21","WingsOfPhoelinx_mini1_20"}
    local rightNameList = {"WingsOfPhoelinx_major1_19a","WingsOfPhoelinx_minor1_21a","WingsOfPhoelinx_mini1_20a"}
    for i=2,4 do
        local img =  self:findChild(leftNameList[i-1])
        local img2 = self:findChild(rightNameList[i-1])
        if img then
            if i == index1 then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
        end
        if img2 then
            if i == index2 then
                img2:setVisible(true)
            else
                img2:setVisible(false)
            end
        end
    end

end

function WingsOfPhoelinxJackPotWinViewTwo:showjackpotHe(index1,index2)
    local leftNameList = {"WingsOfPhoelinx_major1","WingsOfPhoelinx_minor1","WingsOfPhoelinx_mini1"}
    local rightNameList = {"WingsOfPhoelinx_major1_3","WingsOfPhoelinx_minor1_5","WingsOfPhoelinx_mini1_4"}
    for i=2,4 do
        local img =  self:findChild(leftNameList[i-1])
        local img2 = self:findChild(rightNameList[i-1])
        if img then
            if i == index1 then
                img:setVisible(true)
            else
                img:setVisible(false)
            end
        end
        if img2 then
            if i == index2 then
                img2:setVisible(true)
            else
                img2:setVisible(false)
            end
        end
    end

end

function WingsOfPhoelinxJackPotWinViewTwo:onEnter()

    WingsOfPhoelinxJackPotWinViewTwo.super.onEnter(self)
end

function WingsOfPhoelinxJackPotWinViewTwo:onExit()

    WingsOfPhoelinxJackPotWinViewTwo.super.onExit(self)

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

function WingsOfPhoelinxJackPotWinViewTwo:clickFunc(sender)
    local name = sender:getName()
    if name == "Button" then

        if self.m_click == true then
            return 
        end

        -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/music_WingsOfPhoelinxs_Click_Collect.mp3")

        if self.m_updateCoinHandlerID == nil then
            sender:setTouchEnabled(false)
            self.m_click = true

            self:runCsbAction("over")
            performWithDelay(self,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end,1)
        end 

        local waitTimes = 0
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins_3")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},714)

            waitTimes = 2
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpOverCoins.mp3")
            self.m_soundId = nil  
        end
    end
end

function WingsOfPhoelinxJackPotWinViewTwo:jumpCoins(coins )
    
    local node=self:findChild("m_lb_coins_3")
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

            local node=self:findChild("m_lb_coins_3")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},714)

            self.m_isJumpOver = true

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                -- gLobalSoundManager:playSound("WingsOfPhoelinxSounds/WingsOfPhoelinx_JackPotWinJumpOverCoins.mp3")
                self.m_soundId = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
            end

        else
            local node=self:findChild("m_lb_coins_3")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.98,sy=0.98},714)
        end
    end)
end

return WingsOfPhoelinxJackPotWinViewTwo

