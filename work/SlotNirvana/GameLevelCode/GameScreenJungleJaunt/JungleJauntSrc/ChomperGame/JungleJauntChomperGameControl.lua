---
--xcyy
--2018年5月23日
--JungleJauntChomperGameControl.lua
local PBC = require "JungleJauntPublicConfig"
local JungleJauntChomperGameControl = class("JungleJauntChomperGameControl")

function JungleJauntChomperGameControl:initData_(_machine)
    self.m_machine = _machine

end

function JungleJauntChomperGameControl:initSpineUI()
    self.m_chomperPar = util_createAnimation("JungleJaunt_base_buff3.csb")
    self.m_chomperPar:runCsbAction("idle",true) 
    self.m_machine:findChild("base_buff3"):addChild(self.m_chomperPar)
    self.m_chomper = util_spineCreate("JungleJaunt_base_buff3",true,true) 
    self.m_chomperPar:findChild("hua"):addChild(self.m_chomper)
    self.m_chomperLab = util_createAnimation("JungleJaunt_base_buff3_coin.csb")
    self.m_chomperPar:findChild("Node_coin"):addChild(self.m_chomperLab)
    self.m_chomperLabC = util_createAnimation("JungleJaunt_base_buff3_coin_0.csb")
    self.m_chomperLab:findChild("Node_5"):addChild(self.m_chomperLabC)
    util_setCascadeOpacityEnabledRescursion(self.m_chomperPar, true)
    self.m_chomperPar:setVisible(false)

    util_spineMix(self.m_chomper, "start", "idleframe1", 0.2)
    util_spineMix(self.m_chomper, "switch1", "idleframe2", 0.2)
    util_spineMix(self.m_chomper, "switch2", "idleframe3", 0.2)
    util_spineMix(self.m_chomper, "actionframe3", "over", 0.2) 
         

    util_spineMix(self.m_chomper, "idleframe1", "switch1", 0.2) 
    util_spineMix(self.m_chomper, "idleframe2", "switch2", 0.2) 
    
    self.m_machine:findChild("Panel_StopBuff3"):setVisible(false)
end

function JungleJauntChomperGameControl:updateLabCoins(_coins,_visLevel)
    for i=1,3 do
        local lab = self.m_chomperLabC:findChild("m_lb_coins_"..i) 
        local mini = self.m_chomperLabC:findChild("mini")
        local minor = self.m_chomperLabC:findChild("minor")
        mini:setVisible(false)  
        minor:setVisible(false)  
        if type(_coins) == "string" and _coins == "" then
            lab:setString("")  
        else
            lab:setString(util_formatCoinsLN(_coins,6))  

            local totalbet = globalData.slotRunData:getCurTotalBet()
            mini:setVisible(_coins == (totalbet * 10))  
            minor:setVisible(_coins == (totalbet * 20)) 
            if  mini:isVisible() or minor:isVisible() then
                lab:setVisible(false)
            else
                lab:setVisible(_visLevel == i) 
            end
        end
        
    end
    
end

function JungleJauntChomperGameControl:playLabChangeAnim(_level,_func)
    gLobalSoundManager:playSound(PBC.SoundConfig.buff2CJump)
    
    -- level1 [0.8,1.1] 变化区间
    -- level2 [0.8,1.1] 变化区间
    -- level3 [0.8,1.1] 变化区间
    local rand = {
        {75,110}, 
        {75,110},
        {75,110}
    }

    local miniShowIndex = nil
    local minorShowIndex = nil

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local dice_game2_list = selfData.dice_game2_list -- 次滚动的值
    local totalWinCoins = selfData.dice_game2_win
    local endCoins = dice_game2_list[_level]
    local waitTime = 0.5

    local playTime = {2,20-2,36-20,52-36,66-52,80-66,92-80,104-92,124-104}
    self.m_chomperLabC:runCsbAction("switch")
    local time = self.m_chomper:getAnimationDurationTime("switch1") - (playTime[9]/60)
    
    local acitonList = {}
    for i=1,8 do
        acitonList[#acitonList + 1] = cc.DelayTime:create(playTime[i]/60)
        acitonList[#acitonList + 1] = cc.CallFunc:create(function()
            if miniShowIndex == i then
                local totalbet = globalData.slotRunData:getCurTotalBet()
                self:updateLabCoins(totalbet * 10,_level)  
            elseif minorShowIndex == i then
                local totalbet = globalData.slotRunData:getCurTotalBet()
                self:updateLabCoins(totalbet * 20,_level) 
            else
                self:updateLabCoins(endCoins * math.random(rand[_level][1],rand[_level][2]) /100,_level)  
            end
            
        end)
    end
    acitonList[#acitonList + 1] = cc.DelayTime:create(playTime[9]/60)
    acitonList[#acitonList + 1] = cc.CallFunc:create(function()
        self:updateLabCoins(endCoins,_level)
    end)
    if _level == 3 then
        acitonList[#acitonList + 1] = cc.DelayTime:create(time) 
    end
    acitonList[#acitonList + 1] = cc.CallFunc:create(function()
        if _func then
            _func()
        end
    end)
    
    self.m_chomperLab:findChild("jinekuang"):runAction(cc.Sequence:create(acitonList))
end

function JungleJauntChomperGameControl:coinsJumpLevel1()
    
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_29)
    self.m_chomperLab:runCsbAction("start",false,function()
        self.m_chomperLab:runCsbAction("idle1",true)

        self.m_machine:findChild("Panel_StopBuff3"):setVisible(true)
        self:playLabChangeAnim(1,function()
            self:coinsJumpLevel2()
        end)
    end)
end

function JungleJauntChomperGameControl:coinsJumpLevel2()

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_30)

    self.m_chomperLab:runCsbAction("switch1",false,function()
        self.m_chomperLab:runCsbAction("idle2",true)
    end)
    local time = self.m_chomper:getAnimationDurationTime("switch1")
    util_spinePlay(self.m_chomper,"switch1")
    util_spineEndCallFunc(self.m_chomper,"switch1",function()
        util_spinePlay(self.m_chomper,"idleframe2",true)
    end)

    time = util_max(time,1+1.5) -- 等待时间+数字跳变
    performWithDelay(self.m_chomper,function()
        self:playLabChangeAnim(2,function()
            
        end)
    end,30/30)

    performWithDelay(self.m_chomperLab:findChild("Node_5"),function()
        self:coinsJumpLevel3()
    end,time)
    
end

function JungleJauntChomperGameControl:coinsJumpLevel3()

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_30)

    self.m_chomperLab:runCsbAction("switch2",false,function()
        self.m_chomperLab:runCsbAction("idle3",true)
    end)

    local time = self.m_chomper:getAnimationDurationTime("switch2")

    util_spinePlay(self.m_chomper,"switch2")
    util_spineEndCallFunc(self.m_chomper,"switch2",function()
        util_spinePlay(self.m_chomper,"idleframe3",true)
    end)

    time = time + 0.7 
    performWithDelay(self.m_chomper,function()
        self:playLabChangeAnim(3,function() 
        end)
    end,30/30)

    performWithDelay(self.m_chomperLab:findChild("Node_5"),function()
        self:playGameEndAnim()
    end,time)
end

function JungleJauntChomperGameControl:playGameEndAnim()

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local totalWinCoins = selfData.dice_game2_win
    local winCoins = self.m_machine.m_runSpinResultData.p_winAmount
    
    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_32)

    self.m_machine:findChild("Panel_StopBuff3"):setVisible(false)

    self.m_chomperLab:runCsbAction("jiesuan",false,function()
    end)
    
    util_spinePlay(self.m_chomper,"actionframe3")
    util_spineEndCallFunc(self.m_chomper,"actionframe3",function()

        local currfunc = function()
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_33)
        
            self.m_chomperLab:runCsbAction("over",false,function()
            end)
            util_spinePlay(self.m_chomper,"over")
            util_spineEndCallFunc(self.m_chomper,"over",function()
                self.m_chomperPar:setVisible(false)
                if self.m_overCallFunc then
                    self.m_overCallFunc()
                    self.m_overCallFunc = nil
                end
            end)
        end

        local totalbet = globalData.slotRunData:getCurTotalBet()

        if  totalWinCoins == (totalbet * 10)  then
            self.m_machine:showJackpotView(totalWinCoins, "mini", function()
                currfunc()
            end)
            
        elseif totalWinCoins == (totalbet * 20) then
            self.m_machine:showJackpotView(totalWinCoins, "minor", function()
                currfunc()
            end)
        else
            currfunc()
        end

        
    end)
    
    performWithDelay(self.m_chomperPar,function()
        -- 飞行收集
        local winLbl = self.m_machine.m_bottomUI:getNormalWinLabel()
        self:flyParticleAni(winLbl,function()
        
            gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_31)

            -- 更新下UI赢钱
            self.m_machine:setLastWinCoin(winCoins)
            self.m_machine:playCoinWinEffectUI(nil,"actionframe2")

            local params = {selfData.dice_game2_win, true, true}
            params[self.m_machine.m_stopUpdateCoinsSoundIndex] = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

        end)
    end,2)
    
end

function JungleJauntChomperGameControl:playChomperGameStart(_func)

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_28)

    self.m_overCallFunc = _func

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local dice_game2_list = selfData.dice_game2_list -- 次滚动的值

    self.m_chomperPar:setVisible(true)
    self:updateLabCoins("",1)
    self.m_chomperLab:runCsbAction("idleHide")
    util_spinePlay(self.m_chomper,"start")
    util_spineEndCallFunc(self.m_chomper,"start",function()
        util_spinePlay(self.m_chomper,"idleframe1",true)
        self:coinsJumpLevel1()
    end)

    
    
end

--[[
    飞粒子动画
]]
function JungleJauntChomperGameControl:flyParticleAni(endNode,func)
    local flyNode = util_createAnimation("JungleJaunt_base_buff3_coin_fly.csb")
    local startPos = util_convertToNodeSpace(self.m_chomperLab:findChild("Node_5"),self.m_machine)
    local endPos = util_convertToNodeSpace(endNode,self.m_machine)
    self.m_machine:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    flyNode:setScale(self.m_machine.m_machineRootScale * 1.3)
    flyNode:setPosition(startPos)
    local slab = self.m_chomperLabC:findChild("m_lb_coins_3")
    local str = slab:getString()
    flyNode:findChild("m_lb_coins_3"):setString(str)
    local mini = flyNode:findChild("mini")
    local minor = flyNode:findChild("minor")
    mini:setVisible(false)  
    minor:setVisible(false) 

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local totalWinCoins = selfData.dice_game2_win
    local totalbet = globalData.slotRunData:getCurTotalBet()
    mini:setVisible(totalWinCoins == (totalbet * 10))  
    minor:setVisible(totalWinCoins == (totalbet * 20)) 
    if  mini:isVisible() or minor:isVisible() then
        flyNode:findChild("m_lb_coins_3"):setVisible(false)
    else
        flyNode:findChild("m_lb_coins_3"):setVisible(true) 
    end

    
    local actionList = {
        cc.EaseIn:create(cc.MoveTo:create(0.5,endPos),1),
        cc.CallFunc:create(function()
            flyNode:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()
    }
    flyNode:runAction(cc.Sequence:create(actionList))
end

function JungleJauntChomperGameControl:cutOffFunc()

    gLobalSoundManager:playSound(PBC.SoundConfig.JUNGLEJAUNT_SOUND_5)

    self.m_chomperLab:stopAllActions()
    self.m_chomperLab:findChild("jinekuang"):stopAllActions()
    self.m_chomperLab:findChild("Node_5"):stopAllActions()
    util_resetCsbAction(self.m_chomperLab.m_csbAct)
    self.m_chomperLab:runCsbAction("idle3",true)

    self.m_chomperLabC:stopAllActions()
    util_resetCsbAction(self.m_chomperLabC.m_csbAct)
    self.m_chomperLabC:runCsbAction("idle",true)

    self.m_chomperPar:stopAllActions()
    util_resetCsbAction(self.m_chomperPar.m_csbAct)
    self.m_chomperPar:runCsbAction("idle",true) 

    self.m_chomper:stopAllActions()
    self.m_chomper:resetAnimation()

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local totalWinCoins = selfData.dice_game2_win
    self:updateLabCoins(totalWinCoins,3)
    
    self:playGameEndAnim()
end



return JungleJauntChomperGameControl