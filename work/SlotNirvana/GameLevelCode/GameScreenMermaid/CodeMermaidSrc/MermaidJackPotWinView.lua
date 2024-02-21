---
--island
--2018年4月12日
--MermaidJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local MermaidJackPotWinView = class("MermaidJackPotWinView", util_require("base.BaseView"))

---
--island
--2018年4月12日
--MermaidJackPotWinView.lua
local MermaidJackPotWinView = class("MermaidJackPotWinView", util_require("base.BaseView"))


MermaidJackPotWinView.m_isOverAct = false
MermaidJackPotWinView.m_isJumpOver = false

function MermaidJackPotWinView:initUI(data)
    self.m_click = true
    self.m_machine = data.machine

    local resourceFilename = "Mermaid/Jackpotover.csb"
    self:createCsbNode(resourceFilename)


    self.m_Girl = util_spineCreate("Mermaid_guochang",true,true)
    self:findChild("Node_Girls"):addChild(self.m_Girl)

    local node=self:findChild("m_lb_coins")
    node:setString("")

    self:addClick(self:findChild("Button_1"))



    self.m_actNode_1 = cc.Node:create()
    self:addChild(self.m_actNode_1)

    self.m_actNode_2 = cc.Node:create()
    self:addChild(self.m_actNode_2)
end

function MermaidJackPotWinView:initViewData(index,coins,callBackFun,NotAutoRemove)
    self:createGrandShare(self.m_machine)
    self.m_jackpotIndex = index
    
    self.m_NotAutoRemove = NotAutoRemove

    util_spinePlay(self.m_Girl,"guochang3")

    util_spineEndCallFunc(
        self.m_Girl,
        "guochang3",
        function()
            util_spinePlay(self.m_Girl,"guochang3over")
        end
    )

    self.m_index = index
    self.m_coins = coins
    self.m_callFun = callBackFun

    self.m_bgSoundId =  gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_JackpotView.mp3",false)
    performWithDelay(self,function (  )
        self.m_bgSoundId = nil
    end,5.5)

    performWithDelay(self,function(  )
        gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Jp_yu_FeiWen.mp3")


        self.m_soundId = gLobalSoundManager:playSound("MermaidSounds/Mermaid_JackPotWinCoins.mp3",true)
        self:jumpCoins(coins )

        performWithDelay(self.m_actNode_1,function(  )
            if self.m_updateCoinHandlerID ~= nil then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil


                gLobalSoundManager:playSound("MermaidSounds/Mermaid_JackPotWinCoins_end.mp3")

                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_coins,50))
                self:updateLabelSize({label=node,sx=0.54,sy=0.54},1184)
                self:jumpCoinsFinish()

            end

            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end

            if self.m_click == false then

                self.m_click = true

                performWithDelay(self.m_actNode_1,function(  )
                    
                    if self.m_NotAutoRemove then

                        if self.m_callFun then
                            self.m_callFun()
                        end
        
                    else


                        self:runCsbAction("over",false,function(  )
                            if self.m_callFun then
                                self.m_callFun()
                            end
                            self:removeFromParent()
                        end)
                    end

                end,0.5)
                
            end
        end,5)

    end,54/30)

    self:runCsbAction("start",false,function(  )
        self.m_click = false
        self:runCsbAction("idle",true)

    end)


    

    gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Jp_yu_shengQi.mp3")
  
    local imgName = {"jtb_grand","jtb_major","jtb_minor","jtb_mini"}
    local status = self.m_machine.m_jackpot_status
    if index == 1 and status ~= "Normal" then
        self:findChild("jtb_mega"):setVisible(status == "Mega")
        self:findChild("jtb_super"):setVisible(status == "Super")
        for k,v in pairs(imgName) do
            local img =  self:findChild(v)
            if img then
                img:setVisible(false)
            end
        end
    else
        self:findChild("jtb_mega"):setVisible(false)
        self:findChild("jtb_super"):setVisible(false)
        for k,v in pairs(imgName) do
            local img =  self:findChild(v)
            if img then
                img:setVisible(false)
                if k == index then
                    img:setVisible(true)
                end
                
            end
        end
    end
    
    
    
    
    

    


    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end

function MermaidJackPotWinView:onEnter()
end

function MermaidJackPotWinView:onExit()

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

function MermaidJackPotWinView:clickFunc(sender)

    local name = sender:getName()
    if name == "Button_1" then

        if self.m_click == true then
            return 
        end

        sender:setTouchEnabled(false)
        self.m_click = true
        self.m_actNode_1:stopAllActions()

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        local bShare = self:checkShareState()
        if not bShare then
            self:jackpotViewOver(function()
                self:onCollectBtnClick()
            end)
        end
    end
end

function MermaidJackPotWinView:onCollectBtnClick( )
    
    if self.m_updateCoinHandlerID == nil then
    
        performWithDelay(self.m_actNode_2,function(  )
            
            if self.m_NotAutoRemove then

                if self.m_callFun then
                    self.m_callFun()
                end

            else

                self:runCsbAction("over",false,function(  )
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end)
            end

        end,0.5)
        

    end 

    
    if self.m_updateCoinHandlerID ~= nil then

        gLobalSoundManager:playSound("MermaidSounds/Mermaid_JackPotWinCoins_end.mp3")

        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        self.m_updateCoinHandlerID = nil
        local node=self:findChild("m_lb_coins")
        node:setString(util_formatCoins(self.m_coins,50))
        self:updateLabelSize({label=node,sx=0.54,sy=0.54},1184)
        self:jumpCoinsFinish()

        performWithDelay(self.m_actNode_2,function(  )
            
            if self.m_NotAutoRemove then

                if self.m_callFun then
                    self.m_callFun()
                end

            else

                self:runCsbAction("over",false,function(  )
                    if self.m_callFun then
                        self.m_callFun()
                    end
                    self:removeFromParent()
                end)
            end

        end,0.5)

    end

    if self.m_soundId then

        -- gLobalSoundManager:playSound("MermaidSounds/Mermaid_JPCoinsJump_Over.mp3")

        gLobalSoundManager:stopAudio(self.m_soundId)
        self.m_soundId = nil

        
    end
end

function MermaidJackPotWinView:jumpCoins(coins )

    local node=self:findChild("m_lb_coins")
    node:setString("")

    local coinRiseNum =  coins / (5 * 60)  -- 每秒60帧

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
            self:updateLabelSize({label=node,sx=0.54,sy=0.54},1184)
            self:jumpCoinsFinish()
            gLobalSoundManager:playSound("MermaidSounds/Mermaid_JackPotWinCoins_end.mp3")

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
            self:updateLabelSize({label=node,sx=0.54,sy=0.54},1184)
        end
        

    end)



end

--[[
    自动分享 | 手动分享
]]
function MermaidJackPotWinView:createGrandShare(_machine)
    local parent = self:findChild("Node_share")
    if parent then
        self.m_grandShare = util_createFindView("Levels/BaseGrandShare", { machine = _machine })
        if self.m_grandShare then
            parent:addChild(self.m_grandShare)
        end
    end
end

function MermaidJackPotWinView:jumpCoinsFinish()
    if nil ~= self.m_grandShare then
        self.m_grandShare:jumpCoinsFinish(self.m_jackpotIndex)
    end
end

function MermaidJackPotWinView:checkShareState()
    local bShare = false
    if nil ~= self.m_grandShare then
        bShare = self.m_grandShare:checkShareState()
    end
    return bShare
end

function MermaidJackPotWinView:jackpotViewOver(_fun)
    if nil ~= self.m_grandShare then
        self.m_grandShare:jackpotViewOver(_fun)
    else
        _fun()
    end
end

return MermaidJackPotWinView