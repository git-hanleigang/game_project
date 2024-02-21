---
--island
--2018年4月12日
--PepperBlastJackPotWinView.lua
---- respin 玩法结算时中 mini mijor等提示界面
local PepperBlastJackPotWinView = class("PepperBlastJackPotWinView", util_require("base.BaseView"))


PepperBlastJackPotWinView.m_isOverAct = false
PepperBlastJackPotWinView.m_isJumpOver = false

function PepperBlastJackPotWinView:onEnter()
end

function PepperBlastJackPotWinView:onExit()
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

function PepperBlastJackPotWinView:initUI(data)
    self.m_click = true
    
    local resourceFilename = "PepperBlast/JackpotWinView.csb"
    self:createCsbNode(resourceFilename)

    self.m_csbFire = {}
    self.m_csbFire.node,self.m_csbFire.act = util_csbCreate("PepperBlast/JackpotWinView_Fire.csb")
    self.m_csbGlow = {}
    self.m_csbGlow.node,self.m_csbGlow.act = util_csbCreate("PepperBlast/JackpotWinView_Glow.csb")

    self:findChild("Node_3"):addChild(self.m_csbFire.node)
    self:findChild("Node_6"):addChild(self.m_csbGlow.node)

    util_csbPlayForKey(self.m_csbFire.act, "idle", true)
    util_csbPlayForKey(self.m_csbGlow.act, "idle", true)
end

function PepperBlastJackPotWinView:initViewData(index, collectNum, coins, lajiaoShowType, callBackFun)
    self.m_coins = coins
    self.m_callFun = callBackFun
    --添加辣椒展示
    local lajiaoNode,lajiaoAct = util_csbCreate("PepperBlastJackpot_LaJiao.csb")
    local parent = self:findChild("lajiao")
    parent:addChild(lajiaoNode)
    --展示类型 带不带火
    local showType = lajiaoShowType
    lajiaoNode:getChildByName("Node_2"):setVisible(1 == showType)
    lajiaoNode:getChildByName("Node_1"):setVisible(2 == showType)

    --收集数量 起始索引 7

    local node = {}
    for img_index=7,15 do
        node = self:findChild("Image_" .. img_index)
        node:setVisible(collectNum == img_index)
        img_index = img_index+1
    end

    self.m_bgSoundId =  gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_Jackpot_Jiesuan.mp3",false)
    --数字上涨音效
    self.m_soundId = gLobalSoundManager:playSound("PepperBlastSounds/music_PepperBlast_JackpotView_WinCoins.mp3",true)
    self:jumpCoins(coins)

    local waitNode = cc.Node:create()
    self:addChild(waitNode)

    performWithDelay(waitNode,function(  )
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
            self.m_updateCoinHandlerID = nil
            local node=self:findChild("m_lb_coins")
            node:setString(util_formatCoins(self.m_coins,50))
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
        end

        if self.m_soundId then
            gLobalSoundManager:stopAudio(self.m_soundId)
            self.m_soundId = nil
        end
        waitNode:removeFromParent()
    end,4)

    local actionName = "start"
    self:runCsbAction(actionName, false, function(  )
        self.m_click = false
        self:runCsbAction("idle",true)
    end)
    --第50帧播放 狗头人出现 -> 40帧 04.26
    local time = 40 / 60 --util_csbGetAnimKeyFrameTimes(self.m_csbAct, actionName, 50, 60)

    local waitNode2 = cc.Node:create()
    self:addChild(waitNode2)
    performWithDelay(waitNode2, function()
        self:playSpineJuese()

        waitNode2:removeFromParent()
    end,time)
    
    --通知jackpot
    globalData.jackpotRunData:notifySelfJackpot(coins,index)
end
--播放狗头人出现动画
function PepperBlastJackPotWinView:playSpineJuese()
    if(not self.m_jueseSpine)then
        local parent = self:findChild("Node_11")
        self.m_jueseSpine = util_spineCreate("PepperBlast_Juese", true, true)
        parent:addChild(self.m_jueseSpine)
    end

    local animName = "actionframe5"
    util_spinePlay(self.m_jueseSpine,animName,false)
    util_spineEndCallFunc(self.m_jueseSpine, animName, function()
        util_spinePlay(self.m_jueseSpine,"idleframe5",true)  
    end)
end

--点击回调
function PepperBlastJackPotWinView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        --使用通用按钮点击音效
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_click == true then
            if(self.m_updateCoinHandlerID)then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_coins,50))
                self:updateLabelSize({label=node,sx=0.5,sy=0.5},1312)
            end
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil 
            end

            return 
        end
        if self.m_updateCoinHandlerID == nil then
            self.m_click = true
            sender:setTouchEnabled(false)

            self:runCsbAction("over", false, function(  )
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end)

        else
            if(self.m_updateCoinHandlerID)then
                scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
                self.m_updateCoinHandlerID = nil
                local node=self:findChild("m_lb_coins")
                node:setString(util_formatCoins(self.m_coins,50))
                self:updateLabelSize({label=node,sx=0.5,sy=0.5},1312)
            end
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil 
            end
        end 

        
    end
end

function PepperBlastJackPotWinView:jumpCoins( coins )
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
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)

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
            self:updateLabelSize({label=node,sx=0.5,sy=0.5},1252)
        end
    end)
end


return PepperBlastJackPotWinView

