---
--island
--2018年4月12日
--ColorfulCircusJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local ColorfulCircusJackPotWinView = class("ColorfulCircusJackPotWinView", util_require("Levels.BaseLevelDialog"))


function ColorfulCircusJackPotWinView:initUI(_machine)
    self.m_machine = _machine
    local resourceFilename = "ColorfulCircus/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    self.m_click = true

    self.m_flyX2 = false
    self.m_isX2 = false
    self.m_flyBefore = true

    
end

function ColorfulCircusJackPotWinView:initShow(index)
    --人物
    self.jueSe = util_spineCreate("ColorfulCircus_base_xiaochou",true,true)
    self:findChild("ren"):addChild(self.jueSe)
    local guang = util_createAnimation("ColorfulCircus_tanban_guang.csb")
    self:findChild("guang"):addChild(guang)
    guang:playAction("animation0", true)

    local imgName = {{"Node_grand",""},{"Node_major",""},{"Node_minor",""},{"Node_mini",""}}
    for i,v in ipairs(imgName) do
        if i == index then
            self:findChild(v[1]):setVisible(true)
            -- self:findChild(v[2]):setVisible(true)
        else
            self:findChild(v[1]):setVisible(false)
            -- self:findChild(v[2]):setVisible(false)
        end
        
    end
end


function ColorfulCircusJackPotWinView:initViewData(index,coins,callBackFun)
    self.m_index = index
    
    self.m_jackpotIndex = index
    self:createGrandShare(self.m_machine)
    
    self.m_callFun = callBackFun
    if index == 1 then
        self.m_JPSound = gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_jackpot1.mp3",false)
    elseif index == 2 then
        self.m_JPSound = gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_jackpot2.mp3",false)
    elseif index == 3 then
        self.m_JPSound = gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_jackpot3.mp3",false)
    elseif index == 4 then
        self.m_JPSound = gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_jackpot4.mp3",false)
    end
    

    local _coins = coins
    if self.m_machine and self.m_machine.m_respinMulti == 2 then
        self.m_isX2 = true
        _coins = math.floor(_coins / 2)
        self:findChild("ColorfulCircus_respin_shuzi_1"):setVisible(true)
    else
        self:findChild("ColorfulCircus_respin_shuzi_1"):setVisible(false)
    end
    self.m_winCoins = _coins
    self.m_x2WinCoins = coins
    if self.m_isX2 then
        self:jumpCoins(0, _coins, 1)
    else
        self:jumpCoins(0, _coins)
    end
    

    self:initShow(index)
    util_spinePlay(self.jueSe,"idleframe",true)
    -- util_spineEndCallFunc(self.jueSe,"actionframe2",function (  )
    --     util_spinePlay(self.m_spineTanban,"idleframe",true)
    -- end)
    self:runCsbAction("start",false,function(  )
        
            self.m_click = false
            self:runCsbAction("idle",true)
            if self.m_machine and self.m_machine.m_respinMulti == 2 then
                self:findChild("ColorfulCircus_respin_shuzi_1"):setVisible(true)
            else
                self:findChild("ColorfulCircus_respin_shuzi_1"):setVisible(false)
            end

    end)

    -- performWithDelay(self,function(  )
    --     if self.m_updateCoinHandlerID ~= nil then
    --         scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
    --         self.m_updateCoinHandlerID = nil
    --         local node=self:findChild("m_lb_coins")
    --         node:setString(util_formatCoins(self.m_winCoins,50))
    --         self:updateLabelSize({label=node,sx=1,sy=1},700)

    --         self:checkX2()
    --     end

    --     if self.m_JumpSound then
    --         gLobalSoundManager:stopAudio(self.m_JumpSound)
    --         gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_jackpotCoinsOver.mp3")
    --         self.m_JumpSound = nil
    --     end
    -- end,4)
    
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function ColorfulCircusJackPotWinView:onEnter()
    ColorfulCircusJackPotWinView.super.onEnter(self)
    --解决进入横版活动时再切换回关卡 弹板位置不对问题
    -- local _isPortrait = globalData.slotRunData.isPortrait
    -- local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    -- if _isPortrait ~= _isPortraitMachine then
    --     gLobalNoticManager:addObserver(
    --         self,
    --         function(self)
    --             local csbNodeName = self.m_csbNode:getName()
    --             if csbNodeName == "Layer" then
    --                 self:changeVisibleSize(display.size)
    --             else
    --                 if not self.m_isUserDefPos then
    --                     -- 使用的屏幕大小换算的坐标
    --                     local posX, posY = self:getPosition()
    --                     self:setPosition(cc.p(posY, posX))
    --                 end
    --             end
    --         end,
    --         ViewEventType.NOTIFY_RESET_SCREEN
    --     )
    -- end
end

function ColorfulCircusJackPotWinView:onExit()

    if self.m_JPSound then
        gLobalSoundManager:stopAudio(self.m_JPSound)
        self.m_JPSound = nil
    end

    if self.m_JumpSound then
        gLobalSoundManager:stopAudio(self.m_JumpSound)
        self.m_JumpSound = nil
    end

    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
    end

    ColorfulCircusJackPotWinView.super.onExit(self)
end


function ColorfulCircusJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        if self.m_flyX2 == true then
            return
        end

        if self:checkShareState() then
            return
        end

        if self.m_JPSound then
            gLobalSoundManager:stopAudio(self.m_JPSound)
            self.m_JPSound = nil
        end
        
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_click.mp3")
        if self.m_JumpSound then
            gLobalSoundManager:stopAudio(self.m_JumpSound)
            gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_jackpotCoinsOver.mp3")
            self.m_JumpSound = nil
        end

        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil

            local node = self:findChild("m_lb_coins")
            if self.m_flyBefore then
                node:setString(util_formatCoins(self.m_winCoins,50))
            else
                node:setString(util_formatCoins(self.m_x2WinCoins,50))
            end
            
            self:updateLabelSize({label=node,sx=0.95,sy=1},725)


            if self.m_isX2 == false then
                self:jumpCoinsFinish()
            end

            self:checkX2()

            
        else
            self:jackpotViewOver(function (  )
                self.m_click = true
                self:runCsbAction("over")
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_jackpotPopupOver.mp3")
                performWithDelay(self,function()
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    
                end,23/60)
                performWithDelay(self,function (  )
                    self:removeFromParent()
                end,5/3)
            end)
            
        end

    end
end

function ColorfulCircusJackPotWinView:checkX2()
    if self.m_isX2 then
        self.m_flyX2 = true
        self.m_isX2 = false
        self.m_flyBefore = false

        gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_jackpotX2.mp3")
        self:runCsbAction("actionframe",false,function(  )

        end)
        performWithDelay(self, function()
            self:jumpCoins(self.m_winCoins, self.m_x2WinCoins , 2)
            self.m_flyX2 = false
        end, 35 / 60)
    end
end

function ColorfulCircusJackPotWinView:jumpCoins(beginCoins, coins, isX2Time)
    self.m_JumpSound =  gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_jackpot_jump.mp3",true)

    local node =self:findChild("m_lb_coins")
    node:setString("")

    local time = 3
    if isX2Time then
        time = isX2Time
    end
    local coinRiseNum =  (coins - beginCoins) / (time * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    coinRiseNum = math.ceil(coinRiseNum ) 

    local curCoins = beginCoins


    self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

        print("++++++++++++  " .. curCoins)

        curCoins = curCoins + coinRiseNum

        if curCoins >= coins then

            curCoins = coins

            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.95,sy=1},725)

            if self.m_JumpSound then
                gLobalSoundManager:stopAudio(self.m_JumpSound)
                gLobalSoundManager:playSound("ColorfulCircusSounds/ColorfulCircus_jackpotCoinsOver.mp3")
                self.m_JumpSound = nil
            end

            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil

                if (isX2Time and isX2Time == 2) or isX2Time == nil then
                    self:jumpCoinsFinish()
                end
                
                self:checkX2()

                
            end

        else
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(curCoins,50))
            self:updateLabelSize({label=node,sx=0.95,sy=1},725)
        end
        

    end)


end

--[[
    自动分享 | 手动分享
]]
function ColorfulCircusJackPotWinView:createGrandShare(_machine)
    local parent      = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end
function ColorfulCircusJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end
function ColorfulCircusJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end
function ColorfulCircusJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end


return ColorfulCircusJackPotWinView