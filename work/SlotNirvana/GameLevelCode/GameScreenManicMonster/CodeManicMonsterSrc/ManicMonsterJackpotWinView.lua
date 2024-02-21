---
--island
--2018年4月12日
--ManicMonsterJackpotWinView.lua
local ManicMonsterJackpotWinView = class("ManicMonsterJackpotWinView", util_require("base.BaseView"))


ManicMonsterJackpotWinView.m_isOverAct = false
ManicMonsterJackpotWinView.m_isJumpOver = false

function ManicMonsterJackpotWinView:initUI(data)
    self.m_machine = data
    self.m_click = true

    local resourceFilename = "ManicMonster/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

end

function ManicMonsterJackpotWinView:initViewData(jpType,coins,callBackFun)

    self.m_coins = coins
    
    -- self.m_bgSoundId =  gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonster_JackPotWinShow.mp3",false,function(  )
    --     self.m_bgSoundId = nil
    -- end)

    self.m_soundId = gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonster_JackPotWinCoins.mp3",true)
    self:jumpCoins(coins )

    performWithDelay(self,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=1,sy=1},1064)
            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonster_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        
    end,4)


    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)

    local nameList = {"ManicMonster_grand","ManicMonster_major","ManicMonster_minor","ManicMonster_mini"}
    
    local index = 4
    for i=1,#nameList do
        local img = self:findChild(nameList[i])
        img:setVisible(false)
        if jpType == "GRAND" then
            self:findChild(nameList[1]):setVisible(true)
            index = 1
        elseif jpType == "MAJOR" then
            self:findChild(nameList[2]):setVisible(true)
            index = 2
        elseif jpType == "MINOR" then
            self:findChild(nameList[3]):setVisible(true)
            index = 3
        elseif jpType == "MINI" then
            self:findChild(nameList[4]):setVisible(true)
            index = 4
        end
    end

    self.m_jackpotIndex = index
    self:createGrandShare(self.m_machine)

    local name_1 = {"ManicMonster_hong_","ManicMonster_zi_","ManicMonster_lan_","ManicMonster_lv_"} 

    for i=1,18 do
        self:findChild(name_1[1] .. i):setVisible(false)
        self:findChild(name_1[2] .. i):setVisible(false)
        self:findChild(name_1[3] .. i):setVisible(false)
        self:findChild(name_1[4] .. i):setVisible(false)
        if jpType == "GRAND" then
            self:findChild(name_1[1] .. i):setVisible(true)
        elseif jpType == "MAJOR" then
            self:findChild(name_1[2].. i):setVisible(true)
        elseif jpType == "MINOR" then
            self:findChild(name_1[3].. i):setVisible(true)
        elseif jpType == "MINI" then
            self:findChild(name_1[4].. i):setVisible(true)
        end
    end



    self.m_callFun = callBackFun

end

function ManicMonsterJackpotWinView:onEnter()
end

function ManicMonsterJackpotWinView:onExit()

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

function ManicMonsterJackpotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_4" then
        if self:checkShareState() then
            return
        end
    
        
        if self.m_click == true then
            return 
        end

        
        
        -- gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonster_Click.mp3")
        
        
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
            self:updateLabelSize({label=node,sx=1,sy=1},1064)

            waitTimes = 2

            self:jumpCoinsFinish()
        end

        if self.m_soundId then

            gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonster_JPCoinsJump_Over.mp3")

            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil

            
        end
            

        
        
        
        

    end
end

function ManicMonsterJackpotWinView:jumpCoins(coins )

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
            self:updateLabelSize({label=node,sx=1,sy=1},1064)

            self.m_isJumpOver = true

            if self.m_soundId then

                gLobalSoundManager:playSound("ManicMonsterSounds/ManicMonster_JPCoinsJump_Over.mp3")

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
            self:updateLabelSize({label=node,sx=1,sy=1},1064)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function ManicMonsterJackpotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function ManicMonsterJackpotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function ManicMonsterJackpotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function ManicMonsterJackpotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return ManicMonsterJackpotWinView

