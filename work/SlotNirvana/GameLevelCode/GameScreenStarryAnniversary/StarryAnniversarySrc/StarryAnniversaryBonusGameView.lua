---
--xcyy
--2018年5月23日
--StarryAnniversaryBonusGameView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseGame = util_require("base.BaseGame")
local PublicConfig = require "StarryAnniversaryPublicConfig"
local StarryAnniversaryBonusGameView = class("StarryAnniversaryBonusGameView",BaseGame )

StarryAnniversaryBonusGameView.m_machine = nil
StarryAnniversaryBonusGameView.m_bonusEndCall = nil
StarryAnniversaryBonusGameView.m_clickPos = nil --点击位置
StarryAnniversaryBonusGameView.m_eggsNodeList = {}
StarryAnniversaryBonusGameView.m_eggsSkinList = {
    golden = "jin",
    blue = "lan",
    green = "lv",
    pink = "zi",
}

local BUTTON_STATUS = {
    NORMAL = 1,
    AUTO = 2,
}

function StarryAnniversaryBonusGameView:initUI(machine)
    self.m_machine = machine

    self:createCsbNode("StarryAnniversary/GameScreenStarryAnniversary_Smash.csb")

    local uiW, uiH = self.m_machine.m_topUI:getUISize()
    local scale = self.m_machine.m_machineRootScale * self.m_machine.m_bonusViewScale
    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    -- jackpot
    self.m_jackPotBarView = util_createView("StarryAnniversarySrc.StarryAnniversaryJackPotBarBonusView")
    self.m_jackPotBarView:initMachine(self)
    self:findChild("Node_jackpots"):addChild(self.m_jackPotBarView)
    local pos = self:findChild("Node_jackpots"):convertToNodeSpace(cc.p(display.cx, display.cy))
    self.m_jackPotBarView:setPositionY((pos.y-uiH-20)/scale)

    -- 传送带
    self.m_chuanSongSpine = util_spineCreate("StarryAnniversary_chuans", true, true)
    self:findChild("Node_left"):addChild(self.m_chuanSongSpine)

    -- 剩余次数框
    self.m_numsKuang = util_createAnimation("StarryAnniversary_Smash_Tries.csb")
    self:findChild("Node_tries"):addChild(self.m_numsKuang)
    local pos = self:findChild("Node_tries"):convertToNodeSpace(cc.p(display.cx, -display.cy))
    self.m_numsKuang:setPositionY((pos.y+70)/scale+105)

    -- 赢钱框
    self.m_winCoinsKuang = util_createAnimation("StarryAnniversary_Smash_Winner.csb")
    self:findChild("Node_winner"):addChild(self.m_winCoinsKuang)
    local pos = self:findChild("Node_winner"):convertToNodeSpace(cc.p(display.cx, -display.cy))
    self.m_winCoinsKuang:setPositionY((pos.y+70)/scale)

    -- 按钮
    self.m_clickBtn = util_createAnimation("StarryAnniversary_Smash_Btn.csb")
    self:findChild("Node_BtnSmash"):addChild(self.m_clickBtn)
    self:addClick(self.m_clickBtn:findChild("Button_1"))
    local pos = self:findChild("Node_BtnSmash"):convertToNodeSpace(cc.p(display.cx, -display.cy))
    self.m_clickBtn:setPositionY((pos.y+70)/scale)
    self:addClick(self.m_clickBtn:findChild("Button_2"))

    self:addClick(self:findChild("Panel_click"))

    -- 角色
    self.m_roleSpine = util_spineCreate("Socre_StarryAnniversary_9", true, true)
    local nullNode = util_createAnimation("StarryAnniversary_Smash_Dan.csb")
    nullNode:findChild("Node_dan"):addChild(self.m_roleSpine)
    util_spinePushBindNode(self.m_chuanSongSpine, "juese", nullNode)
    util_spinePlay(self.m_roleSpine, "idle", true)

    -- 台子
    self.m_taizi = util_createAnimation("StarryAnniversary_Smash_taizi.csb")
    util_spinePushBindNode(self.m_chuanSongSpine, "taizi", self.m_taizi)

    -- 台子
    self.m_taizi2 = util_createAnimation("StarryAnniversary_Smash_taizi_0.csb")
    self:findChild("Node_role"):addChild(self.m_taizi2)

    -- 在台子上被砸的蛋
    self.m_middleEggsSpine = util_spineCreate("StarryAnniversary_dan", true, true)
    self:findChild("Node_smashEggs"):addChild(self.m_middleEggsSpine, 1)
    util_spinePlay(self.m_middleEggsSpine, "idle", true)
    self.m_middleEggsSpine:setScale(1.2)
    self.m_middleEggsSpine:setVisible(false)
    self.m_middleEggsSpine.xingxingSpine = util_spineCreate("StarryAnniversary_dan", true, true)
    self:findChild("Node_smashEggs"):addChild(self.m_middleEggsSpine.xingxingSpine, 2)
    util_spinePlay(self.m_middleEggsSpine.xingxingSpine, "star_idle", true)
    self.m_middleEggsSpine.xingxingSpine:setVisible(false)

    -- 蛋碎之后的奖励
    self.m_rewardNode = util_createAnimation("StarryAnniversary_Smash_Eggs.csb")
    self:findChild("Node_smashEggs"):addChild(self.m_rewardNode, 3)
    local guang = util_createAnimation("StarryAnniversary_Smash_Results.csb")
    self.m_rewardNode:findChild("Results"):addChild(guang)
    guang:runCsbAction("idle", true)
    self.m_rewardZiNode = util_createAnimation("StarryAnniversary_Smash_Results_zi.csb")
    self.m_rewardNode:findChild("Results_zi"):addChild(self.m_rewardZiNode)
    self.m_rewardGuangSpine = util_spineCreate("Socre_StarryAnniversary_Wild", true, true)
    self.m_rewardNode:findChild("wild"):addChild(self.m_rewardGuangSpine)
    self.m_rewardGuangSpine:setVisible(false)
    self.m_rewardNode:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(self.m_rewardNode:findChild("Results"), true)
    util_setCascadeColorEnabledRescursion(self.m_rewardNode:findChild("Results"), true)
    util_setCascadeOpacityEnabledRescursion(self.m_rewardNode:findChild("Results_zi"), true)
    util_setCascadeColorEnabledRescursion(self.m_rewardNode:findChild("Results_zi"), true)
    util_setCascadeOpacityEnabledRescursion(self.m_rewardNode:findChild("wild"), true)
    util_setCascadeColorEnabledRescursion(self.m_rewardNode:findChild("wild"), true)

    self.m_eggsNodeList[1] = {} --左边的蛋
    self.m_eggsNodeList[2] = {} --右边的蛋
    for index = 1, 2 do
        for eggsIndex = 1, 6 do
            self.m_eggsNodeList[index][eggsIndex] = util_createAnimation("StarryAnniversary_Smash_Dan.csb")
            if index == 1 then
                util_spinePushBindNode(self.m_chuanSongSpine, "Lguadian"..eggsIndex, self.m_eggsNodeList[index][eggsIndex])
            else
                util_spinePushBindNode(self.m_chuanSongSpine, "Rguadian"..(eggsIndex+6), self.m_eggsNodeList[index][eggsIndex])
            end
            self.m_eggsNodeList[index][eggsIndex].eggsSpine = util_spineCreate("StarryAnniversary_dan", true, true)
            self.m_eggsNodeList[index][eggsIndex]:findChild("Node_dan"):addChild(self.m_eggsNodeList[index][eggsIndex].eggsSpine, 1)
            util_spinePlay(self.m_eggsNodeList[index][eggsIndex].eggsSpine, "idle", true)

            self.m_eggsNodeList[index][eggsIndex].eggsSpine.xingxingSpine = util_spineCreate("StarryAnniversary_dan", true, true)
            self.m_eggsNodeList[index][eggsIndex]:findChild("Node_dan"):addChild(self.m_eggsNodeList[index][eggsIndex].eggsSpine.xingxingSpine, 2)
            util_spinePlay(self.m_eggsNodeList[index][eggsIndex].eggsSpine.xingxingSpine, "star_idle", true)
        end
    end 

    self.m_timingNode = cc.Node:create()
    self:addChild(self.m_timingNode)
end

function StarryAnniversaryBonusGameView:onEnter()
    BaseGame.onEnter(self)
    
end
function StarryAnniversaryBonusGameView:onExit()
    BaseGame.onExit(self)
end

--[[
    砸蛋次数 少于2次时 闪烁
]]
function StarryAnniversaryBonusGameView:playNumsKuangEffect(_nums, _isPlaySound)
    if _nums <= 2 then
        self.m_numsKuang:runCsbAction("idle2", true)
        if _isPlaySound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_tries_flicker)
        end
    else
        self.m_numsKuang:runCsbAction("idle1", true)
    end
end

--[[
    游戏开始之前 刷新界面 数据
]]
function StarryAnniversaryBonusGameView:updateBonusGame()
    self.m_bonusInfo = self.m_machine.m_runSpinResultData.p_selfMakeData
    -- 刷新砸 次数
    self.m_numsKuang:findChild("m_lb_coins"):setString(self.m_bonusInfo.initTimes)
    self.m_numsKuang:findChild("m_lb_coins_red"):setString(self.m_bonusInfo.initTimes)
    self:playNumsKuangEffect(self.m_bonusInfo.initTimes)

    -- 刷新赢钱
    local bonusCoins = 0
    if self.m_machine.m_runSpinResultData.p_bonusWinCoins then
        bonusCoins = self.m_machine.m_runSpinResultData.p_bonusWinCoins
    end
    if bonusCoins == 0 then
        self.m_winCoinsKuang:findChild("m_lb_coins"):setString("")
    else
        self.m_winCoinsKuang:findChild("m_lb_coins"):setString(util_formatCoins(bonusCoins, 50))
        local info={label = self.m_winCoinsKuang:findChild("m_lb_coins"),sx = 0.7,sy = 0.7}
        self:updateLabelSize(info, 668)
    end
    
    -- 刷新人物状态
    local bonusInfo = #self.m_bonusInfo.leftQueue == 6 and self.m_bonusInfo.leftQueue[1] or self.m_bonusInfo.rightQueue[1]
    local smashedNums = bonusInfo.totalTimes - bonusInfo.times --已经砸的次数
    if smashedNums < 2 then
        self:playRoleIdleEffect()
    elseif smashedNums < 4 then
        util_spinePlay(self.m_roleSpine, "idle3", true)
    else
        util_spinePlay(self.m_roleSpine, "idle4", true)
    end
    -- jackpot
    self.m_jackPotBarView:initJackpot()
    -- 刷新蛋
    self:updateEggsComeeIn()

    self.m_taizi:runCsbAction("idle1")
    self.m_middleEggsSpine:setVisible(false)
    self.m_middleEggsSpine.xingxingSpine:setVisible(false)
    self.m_rewardNode:setVisible(false)

    self:setBtnState(false)

    if smashedNums ~= 0 then
        self.m_middleEggsSpine:setSkin(self.m_middleEggsSkin)
        self.m_middleEggsSpine:setVisible(true)
        self:showMiddleEggsXingXing(bonusInfo)
        if smashedNums <= 1 then
            util_spinePlay(self.m_middleEggsSpine, "2idle", true)
        elseif smashedNums <= 3 then
            util_spinePlay(self.m_middleEggsSpine, "3idle", true)
        else
            util_spinePlay(self.m_middleEggsSpine, "4idle", true)
        end

        util_spinePlay(self.m_chuanSongSpine, "idleframe")
    end

    self.m_button_status = BUTTON_STATUS.NORMAL
    self.m_clickBtn:findChild("Button_1"):setVisible(true)
    self.m_clickBtn:findChild("Button_2"):setVisible(false)
    self.m_clickBtn:runCsbAction("idle1", true)
end

--[[
    中奖的金蛋显示星星
]]
function StarryAnniversaryBonusGameView:showMiddleEggsXingXing(bonusInfo)
    self.m_middleEggsSpine.xingxingSpine:setSkin("jin")
    if bonusInfo.color == "golden" then
        self.m_middleEggsSpine.xingxingSpine:setVisible(true)
    else
        self.m_middleEggsSpine.xingxingSpine:setVisible(false)
    end
end

--[[
    传送带上的金蛋显示星星
]]
function StarryAnniversaryBonusGameView:showChuanSongEggsXingXing(spineNode, color)
    spineNode.xingxingSpine:setSkin("jin")
    if color == "golden" then
        spineNode.xingxingSpine:setVisible(true)
    else
        spineNode.xingxingSpine:setVisible(false)
    end
end

--[[
    开始bonus游戏
]]
function StarryAnniversaryBonusGameView:startBonusGame()
    local bonusInfo = #self.m_bonusInfo.leftQueue == 6 and self.m_bonusInfo.leftQueue[1] or self.m_bonusInfo.rightQueue[1]
    local smashedNums = bonusInfo.totalTimes - bonusInfo.times --已经砸的次数
    if smashedNums == 0 then
        performWithDelay(self, function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_eggs_start)
            local startName = "start"
            if bonusInfo.color == "golden" then
                startName = "start2"
            end
            util_spinePlay(self.m_chuanSongSpine, startName)
            util_spineEndCallFunc(self.m_chuanSongSpine, startName ,function ()
                self.m_middleEggsSpine:setSkin(self.m_middleEggsSkin)
                self.m_middleEggsSpine:setVisible(true)
                self:showMiddleEggsXingXing(bonusInfo)
                util_spinePlay(self.m_middleEggsSpine, "idle", true)
                self.m_eggsNodeList[1][6].eggsSpine:setVisible(false)
                self.m_eggsNodeList[2][6].eggsSpine:setVisible(false)
                self.m_action = self.ACTION_NONE
                self:setBtnState(true)
            end)

            -- start 的第51帧 蛋的阴影出现
            performWithDelay(self, function()
                self.m_taizi:runCsbAction("start")
            end, 51/30)
        end, 0.5)
    else
        self.m_action = self.ACTION_NONE
        self:setBtnState(true)
    end
end

--[[
    刚进玩法 刷新蛋
]]
function StarryAnniversaryBonusGameView:updateEggsComeeIn( )
    -- 左边
    if #self.m_bonusInfo.leftQueue == 6 then
        self.m_eggsNodeList[1][6].eggsSpine:setVisible(true)
        self.m_eggsNodeList[1][6].eggsSpine:setSkin(self.m_eggsSkinList[self.m_bonusInfo.leftQueue[1].color])
        self:showChuanSongEggsXingXing(self.m_eggsNodeList[1][6].eggsSpine, self.m_bonusInfo.leftQueue[1].color)
        self.m_middleEggsSkin = self.m_eggsSkinList[self.m_bonusInfo.leftQueue[1].color]
        for index = 1, 5 do
            self.m_eggsNodeList[1][index].eggsSpine:setSkin(self.m_eggsSkinList[self.m_bonusInfo.leftQueue[index+1].color])
            self:showChuanSongEggsXingXing(self.m_eggsNodeList[1][index].eggsSpine, self.m_bonusInfo.leftQueue[index+1].color)
        end
    else
        self.m_eggsNodeList[1][6].eggsSpine:setVisible(false)
        self.m_eggsNodeList[1][6].eggsSpine.xingxingSpine:setVisible(false)
        for index = 1, 5 do
            self.m_eggsNodeList[1][index].eggsSpine:setSkin(self.m_eggsSkinList[self.m_bonusInfo.leftQueue[index].color])
            self:showChuanSongEggsXingXing(self.m_eggsNodeList[1][index].eggsSpine, self.m_bonusInfo.leftQueue[index].color)
        end
    end

    -- 右边
    if #self.m_bonusInfo.rightQueue == 6 then
        self.m_eggsNodeList[2][6].eggsSpine:setVisible(true)
        self.m_eggsNodeList[2][6].eggsSpine:setSkin(self.m_eggsSkinList[self.m_bonusInfo.rightQueue[1].color])
        self.m_middleEggsSkin = self.m_eggsSkinList[self.m_bonusInfo.rightQueue[1].color]
        self:showChuanSongEggsXingXing(self.m_eggsNodeList[2][6].eggsSpine, self.m_bonusInfo.rightQueue[1].color)
        for index = 1, 5 do
            self.m_eggsNodeList[2][index].eggsSpine:setSkin(self.m_eggsSkinList[self.m_bonusInfo.rightQueue[index+1].color])
            self:showChuanSongEggsXingXing(self.m_eggsNodeList[2][index].eggsSpine, self.m_bonusInfo.rightQueue[index+1].color)
        end
    else
        self.m_eggsNodeList[2][6].eggsSpine:setVisible(false)
        self.m_eggsNodeList[2][6].eggsSpine.xingxingSpine:setVisible(false)
        for index = 1, 5 do
            self.m_eggsNodeList[2][index].eggsSpine:setSkin(self.m_eggsSkinList[self.m_bonusInfo.rightQueue[index].color])
            self:showChuanSongEggsXingXing(self.m_eggsNodeList[2][index].eggsSpine, self.m_bonusInfo.rightQueue[index].color)
        end
    end

    util_spinePlay(self.m_chuanSongSpine, "start_idle")
end

--[[
    播放角色idle
]]
function StarryAnniversaryBonusGameView:playRoleIdleEffect()
    if self:isVisible() then
        util_spinePlay(self.m_roleSpine, "idle", false)
        util_spineEndCallFunc(self.m_roleSpine, "idle" ,function ()
            util_spinePlay(self.m_roleSpine, "idle", false)
            util_spineEndCallFunc(self.m_roleSpine, "idle" ,function ()
                local random = math.random(1, 100)
                if random <= 30 then
                    util_spinePlay(self.m_roleSpine, "idle2", false)
                    util_spineEndCallFunc(self.m_roleSpine, "idle2" ,function ()
                        self:playRoleIdleEffect()
                    end)
                else
                    self:playRoleIdleEffect()
                end
            end)
        end)
    end
end

--默认按钮监听回调
function StarryAnniversaryBonusGameView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if (name == "Button_1" or name == "Panel_click") and self.m_button_status == BUTTON_STATUS.NORMAL then
        if self:isCanTouch( ) then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_click)
            self:clearAutoSpinTiming()
            self:sendData()
        end
    elseif name == "Button_2" and self.m_button_status == BUTTON_STATUS.AUTO then
        self.m_clickBtn:findChild("Button_1"):setVisible(true)
        self.m_clickBtn:findChild("Button_2"):setVisible(false)
        self.m_button_status = BUTTON_STATUS.NORMAL
        if self.m_clickBtn:findChild("Button_1"):isTouchEnabled() then
            self.m_clickBtn:runCsbAction("idle", true)
        else
            self.m_clickBtn:runCsbAction("idle1", true)
        end
    end
end

--数据发送
function StarryAnniversaryBonusGameView:sendData()
    if not self:isCanTouch( ) then
        return
    end

    self.m_numsKuang:findChild("m_lb_coins"):setString(self.m_bonusInfo.initTimes-1)
    self.m_numsKuang:findChild("m_lb_coins_red"):setString(self.m_bonusInfo.initTimes-1)
    self:playNumsKuangEffect(self.m_bonusInfo.initTimes-1, true)

    self.m_action = self.ACTION_SEND
    self:setBtnState(false)
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg = MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,self.m_isShowTournament)
end

--开始结束流程
function StarryAnniversaryBonusGameView:gameOver(isContinue)

end

--弹出结算奖励
function StarryAnniversaryBonusGameView:showReward()

end

function StarryAnniversaryBonusGameView:featureResultCallFun(param)
    if self:isVisible() then
        if param[1] == true then
            local spinData = param[2]
            local userMoneyInfo = param[3]
            self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
            self.m_totleWimnCoins = spinData.result.winAmount
            globalData.userRate:pushCoins(self.m_serverWinCoins)
            globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
            if spinData.action == "FEATURE" then
                self.m_featureData:parseFeatureData(spinData.result)
                self.m_spinDataResult = spinData.result
                self.m_bonusInfo = spinData.result.selfData
                self:recvBaseData(self.m_featureData)
            elseif self.m_isBonusCollect then
                self.m_featureData:parseFeatureData(spinData.result)
                self:recvBaseData(self.m_featureData)
            else
                dump(spinData.result, "featureResult action"..spinData.action, 3)
            end
        else
            -- 处理消息请求错误情况
            --TODO 佳宝 给与弹板玩家提示。。
            gLobalViewManager:showReConnect(true)
        end
    end 
end

function StarryAnniversaryBonusGameView:isCanTouch( )
    if self.m_action == self.ACTION_SEND then
        return false
    end

    if self.m_bonusInfo.initTimes and self.m_bonusInfo.initTimes <= 0 then
        return false
    end

    return true
end

function StarryAnniversaryBonusGameView:setEndCall(func)
    self.m_bonusEndCall = function( )
        local coins = self.m_featureData.p_data.bonus.bsWinCoins or 0
        local isUpdateTopUI = true     
        self.m_machine:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS) 
        globalData.slotRunData.lastWinCoin = 0
        local params = {coins, isUpdateTopUI, true}
        params[self.m_machine.m_stopUpdateCoinsSoundIndex] = true
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
        globalData.slotRunData.lastWinCoin = coins
        if func then
            func(coins)
        end  
    end 
end

--[[
   播放砸的相关动画
]]
function StarryAnniversaryBonusGameView:recvBaseData(featureData)
    local bonusInfo = #self.m_bonusInfo.leftQueue == 6 and self.m_bonusInfo.leftQueue[1] or self.m_bonusInfo.rightQueue[1]
    self:playRoleEffect(bonusInfo)
    performWithDelay(self, function()
        self:playEggsEffect(bonusInfo)
    end, 19/30)
end

--[[
    播放人物相关动画
]]
function StarryAnniversaryBonusGameView:playRoleEffect(bonusInfo)
    local smashedNums = bonusInfo.totalTimes - bonusInfo.times --已经砸的次数
    if self.m_bonusInfo.smashEgg then --表示刚好砸碎
        if self.m_bonusInfo.smashEgg[1].color == "golden" then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_goldEggs_sui)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_eggs_sui)
        end
        smashedNums = self.m_bonusInfo.smashEgg[1].totalTimes - self.m_bonusInfo.smashEgg[1].times --已经砸的次数
        local smashActionName, actionName = self:getActionNameByNums(smashedNums)
        util_spinePlay(self.m_roleSpine, smashActionName, false)
        util_spineEndCallFunc(self.m_roleSpine, smashActionName ,function ()
            util_spinePlay(self.m_roleSpine, actionName, false)
            util_spineEndCallFunc(self.m_roleSpine, actionName ,function ()
                self:playRoleIdleEffect()
            end)
        end)
    else -- 没有砸碎
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_eggs_nosui)
        if smashedNums <= 2 then --砸了两次还没碎
            util_spinePlay(self.m_roleSpine, "juese_actionframe", false)
            if smashedNums ~= 2 then -- 砸了1次
                util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe" ,function ()
                    self.m_action = self.ACTION_NONE
                    self:setBtnState(true, true)
                    self:playRoleIdleEffect()
                end)
            else -- 刚好砸够2次
                util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe" ,function ()
                    util_spinePlay(self.m_roleSpine, "juese_actionframe2", false)
                    util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe2" ,function ()
                        if self.m_bonusInfo.initTimes == 0 then
                            self:playChangeRoleEffect("juese_over3")
                            util_spinePlay(self.m_roleSpine, "idle3", true)
                        else
                            self.m_action = self.ACTION_NONE
                            self:setBtnState(true, true)
                            util_spinePlay(self.m_roleSpine, "idle3", true)
                        end
                    end)
                end)
            end
        elseif smashedNums <= 4 then
            util_spinePlay(self.m_roleSpine, "juese_actionframe3", false)
            if smashedNums ~= 4 then -- 砸了3次
                util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe3" ,function ()
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_almost_there)
                    if self.m_bonusInfo.initTimes == 0 then
                        self:playChangeRoleEffect("juese_over3")
                        util_spinePlay(self.m_roleSpine, "idle3", true)
                    else
                        self.m_action = self.ACTION_NONE
                        self:setBtnState(true, true)
                        util_spinePlay(self.m_roleSpine, "idle3", true)
                    end
                end)
            else -- 刚好砸够4次
                util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe3" ,function ()
                    util_spinePlay(self.m_roleSpine, "juese_actionframe4", false)
                    util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe4" ,function ()
                        if self.m_bonusInfo.initTimes == 0 then
                            self:playChangeRoleEffect("juese_over4")
                            util_spinePlay(self.m_roleSpine, "idle4", true)
                        else
                            self.m_action = self.ACTION_NONE
                            self:setBtnState(true, true)
                            util_spinePlay(self.m_roleSpine, "idle4", true)
                        end
                    end)
                end)
            end
        else -- 砸超过4次
            util_spinePlay(self.m_roleSpine, "juese_actionframe5", false)
            util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe5" ,function ()
                if self.m_bonusInfo.initTimes == 0 then
                    self:playChangeRoleEffect("juese_over4")
                    util_spinePlay(self.m_roleSpine, "idle4", true)
                else
                    self.m_action = self.ACTION_NONE
                    self:setBtnState(true, true)
                    util_spinePlay(self.m_roleSpine, "idle4", true)
                end
            end)
        end
    end
end

--[[
    砸蛋次数用完 切换人物表情
]]
function StarryAnniversaryBonusGameView:playChangeRoleEffect(_changeActionName)
    performWithDelay(self, function()
        util_spinePlay(self.m_roleSpine, _changeActionName, false)
        util_spineEndCallFunc(self.m_roleSpine, _changeActionName ,function ()
            self:playRoleIdleEffect()
        end)
    end, 0.5)
end

--[[
    蛋砸碎的时候 根据砸的次数 得到时间线
]]
function StarryAnniversaryBonusGameView:getActionNameByNums(_smashedNums)
    local func = function()
        self:moveRootNodeAction(self:findChild("Node_smashEggs"), 20/30, 1.5)
        performWithDelay(self, function()
            self.m_machine:resetMoveNodeStatus()
        end, 42/30)
    end
    if _smashedNums <= 2 then --砸了两次还没碎
        local actionName = "juese_over2"
        if self.m_bonusInfo.smashEgg[1].type == "egg" then
            actionName = "juese_over1"
        end
        if self.m_bonusInfo.smashEgg[1].color == "golden" then
            func()
            return "juese_actionframe_2", actionName
        end
        return "juese_actionframe", actionName
    elseif _smashedNums <= 4 then
        local actionName = "juese_actionframe7"
        if self.m_bonusInfo.smashEgg[1].type == "egg" then
            actionName = "juese_actionframe6"
        end
        if self.m_bonusInfo.smashEgg[1].color == "golden" then
            func()
            return "juese_actionframe3_2", actionName
        end
        return "juese_actionframe3", actionName
    else
        local actionName = "juese_actionframe9"
        if self.m_bonusInfo.smashEgg[1].type == "egg" then
            actionName = "juese_actionframe8"
        end
        if self.m_bonusInfo.smashEgg[1].color == "golden" then
            func()
            return "juese_actionframe5_2", actionName
        end
        return "juese_actionframe5", actionName
    end
end

--[[
    播放蛋相关动画
]]
function StarryAnniversaryBonusGameView:playEggsEffect(bonusInfo)
    local smashedNums = bonusInfo.totalTimes - bonusInfo.times --已经砸的次数
    if self.m_bonusInfo.smashEgg then --表示刚好砸碎
        smashedNums = self.m_bonusInfo.smashEgg[1].totalTimes - self.m_bonusInfo.smashEgg[1].times --已经砸的次数
        local delayTime = 0
        if self.m_bonusInfo.smashEgg[1].color == "golden" then
            delayTime = 24/30
        end
        performWithDelay(self, function()
            if smashedNums == 1 then
                util_spinePlay(self.m_middleEggsSpine, "actionframe1", false)
            elseif smashedNums == 2 then
                util_spinePlay(self.m_middleEggsSpine, "actionframe2", false)
            elseif smashedNums <= 4 then
                util_spinePlay(self.m_middleEggsSpine, "actionframe3", false)
            else
                util_spinePlay(self.m_middleEggsSpine, "actionframe4", false)
            end
            self:playRewardEffect()
        end, delayTime)
    else
        if smashedNums == 1 then
            util_spinePlay(self.m_middleEggsSpine, "1to2", false)
            util_spineEndCallFunc(self.m_middleEggsSpine, "1to2" ,function ()
                util_spinePlay(self.m_middleEggsSpine, "2idle", true)
            end)
        elseif smashedNums == 2 then
            util_spinePlay(self.m_middleEggsSpine, "2to3", false)
            util_spineEndCallFunc(self.m_middleEggsSpine, "2to3" ,function ()
                util_spinePlay(self.m_middleEggsSpine, "3idle", true)
            end)
        elseif smashedNums == 3 then
            util_spinePlay(self.m_middleEggsSpine, "3", false)
            util_spineEndCallFunc(self.m_middleEggsSpine, "3" ,function ()
                util_spinePlay(self.m_middleEggsSpine, "3idle", true)
            end)
        elseif smashedNums == 4 then
            util_spinePlay(self.m_middleEggsSpine, "3to4", false)
            util_spineEndCallFunc(self.m_middleEggsSpine, "3to4" ,function ()
                util_spinePlay(self.m_middleEggsSpine, "4idle", true)
            end)
        else
            util_spinePlay(self.m_middleEggsSpine, "4", false)
            util_spineEndCallFunc(self.m_middleEggsSpine, "4" ,function ()
                util_spinePlay(self.m_middleEggsSpine, "4idle", true)
            end)
        end
        self.m_numsKuang:findChild("m_lb_coins"):setString(self.m_bonusInfo.initTimes)
        self.m_numsKuang:findChild("m_lb_coins_red"):setString(self.m_bonusInfo.initTimes)
        self:playNumsKuangEffect(self.m_bonusInfo.initTimes)

        local p_bonus = self.m_featureData.p_bonus or {}
        if p_bonus.status ~= "OPEN" then
            performWithDelay(self, function()
                self.m_bonusEndCall()
            end, 1)
        end
    end
end

--[[
    蛋碎之后 播放奖励出现相关
]]
function StarryAnniversaryBonusGameView:playRewardEffect( )
    if self.m_bonusInfo.smashEgg then
        if self.m_bonusInfo.smashEgg[1].type == "egg" then
            self.m_rewardZiNode:findChild("Node_coins"):setVisible(true)
            self.m_rewardZiNode:findChild("Node_jackpot"):setVisible(false)
            self.m_rewardZiNode:findChild("m_lb_coins"):setString(util_formatCoins(self.m_bonusInfo.smashEgg[1].reward, 3))
        else
            self.m_rewardZiNode:findChild("Node_coins"):setVisible(false)
            self.m_rewardZiNode:findChild("Node_jackpot"):setVisible(true)
            self.m_rewardZiNode:findChild("grand"):setVisible(self.m_bonusInfo.smashEgg[1].type == "Grand")
            self.m_rewardZiNode:findChild("major"):setVisible(self.m_bonusInfo.smashEgg[1].type == "Major")
            self.m_rewardZiNode:findChild("minor"):setVisible(self.m_bonusInfo.smashEgg[1].type == "Minor")
            self.m_rewardZiNode:findChild("mini"):setVisible(self.m_bonusInfo.smashEgg[1].type == "Mini")
        end

        if self.m_bonusInfo.addInitTimes and self.m_bonusInfo.addInitTimes > 0 then
            self.m_rewardZiNode:findChild("Node_cishu"):setVisible(true)
            if self.m_bonusInfo.addInitTimes == 1 then
                self.m_rewardZiNode:findChild("TRY"):setVisible(true)
                self.m_rewardZiNode:findChild("TRIES"):setVisible(false)
            else
                self.m_rewardZiNode:findChild("TRY"):setVisible(false)
                self.m_rewardZiNode:findChild("TRIES"):setVisible(true)
            end
        else
            self.m_rewardZiNode:findChild("Node_cishu"):setVisible(false)
        end

        self.m_rewardNode:setVisible(true)
        self.m_rewardZiNode:runCsbAction("idle1", false)
        local actionName = "start"
        if self.m_bonusInfo.smashEgg[1].type ~= "egg" then
            actionName = "start2"
        end
        self.m_rewardNode:runCsbAction(actionName, false, function()
            for index = 1, 2 do
                local particle = self.m_rewardNode:findChild("Particle_"..index)
                if particle then
                    particle:resetSystem()
                end
            end
            if self.m_bonusInfo.addInitTimes and self.m_bonusInfo.addInitTimes > 0 then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_addNums)
                self.m_rewardZiNode:findChild("m_lb_num"):setString("+"..self.m_bonusInfo.addInitTimes)
                self.m_rewardZiNode:runCsbAction("switch", false, function()
                    performWithDelay(self, function()
                        if self.m_bonusInfo.smashEgg[1].type == "egg" then
                            self:playHideEggsEffect()

                            self:playFlySmashEggNumsEffect()
                            performWithDelay(self, function()
                                self:playFlyCoinsEffect(function()
                                    self:beginPlayGetRewardAfterProcess(true)
                                end)
                            end, 0.1)
                        else
                            self:playFlySmashEggNumsEffect(function()
                                self:playWinJackpotEffect()
                            end)
                            self.m_rewardZiNode:runCsbAction("switch2", false)
                        end
                    end, 0.5)
                end)
            else
                performWithDelay(self, function()
                    if self.m_bonusInfo.smashEgg[1].type == "egg" then
                        self:playHideEggsEffect()

                        self:playFlyCoinsEffect(function()
                            self:beginPlayGetRewardAfterProcess(true)
                        end)
                    else
                        self:playWinJackpotEffect()
                    end
                end, 0.5)
            end
        end)
    end
end

--[[
    飞砸蛋次数
]]
function StarryAnniversaryBonusGameView:playFlySmashEggNumsEffect(_func)
    local startPos = util_convertToNodeSpace(self.m_rewardZiNode:findChild("Node_cishu"), self.m_effectNode)
    local endPos = util_convertToNodeSpace(self.m_numsKuang:findChild("m_lb_coins"), self.m_effectNode)
    
    local flyNode = util_createAnimation("StarryAnniversary_Smash_Results_zi.csb")
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:findChild("Node_coins"):setVisible(false)
    flyNode:findChild("Node_jackpot"):setVisible(false)
    flyNode:findChild("m_lb_num"):setString("+"..self.m_bonusInfo.addInitTimes)
    flyNode:setScale(1.2)
    if self.m_bonusInfo.addInitTimes == 1 then
        flyNode:findChild("TRY"):setVisible(true)
        flyNode:findChild("TRIES"):setVisible(false)
    else
        flyNode:findChild("TRY"):setVisible(false)
        flyNode:findChild("TRIES"):setVisible(true)
    end
    
    self.m_rewardZiNode:findChild("Node_cishu"):setVisible(false)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_reward_fly)
    flyNode:runCsbAction("fly")
    local seq = cc.Sequence:create({
        cc.EaseSineOut:create(cc.BezierTo:create(20/60, {startPos, cc.p(endPos.x, startPos.y), endPos})),
        cc.CallFunc:create(function()
            self.m_numsKuang:findChild("m_lb_coins"):setString(self.m_bonusInfo.initTimes)
            self.m_numsKuang:findChild("m_lb_coins_red"):setString(self.m_bonusInfo.initTimes)
            self:playNumsKuangEffect(self.m_bonusInfo.initTimes)
            self.m_numsKuang:runCsbAction("actionframe", false, function()
                if self.m_bonusInfo.initTimes <= 2 then
                    self.m_numsKuang:runCsbAction("idle2", true)
                end
            end)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_reward_fly_end)

            for index = 1, 2 do
                local particle = self.m_numsKuang:findChild("Particle_"..index)
                if particle then
                    particle:resetSystem()
                end
            end
        end),
        cc.RemoveSelf:create(true)
    })
    flyNode:runAction(seq)

    performWithDelay(self, function()
        if type(_func) == "function" then
            _func()
        end
    end, 1)
end

--[[
    飞砸金币
]]
function StarryAnniversaryBonusGameView:playFlyCoinsEffect(_func)
    local startPos = util_convertToNodeSpace(self.m_rewardZiNode:findChild("Node_coins"), self.m_effectNode)
    local endPos = util_convertToNodeSpace(self.m_winCoinsKuang:findChild("m_lb_coins"), self.m_effectNode)
    
    local flyNode = util_createAnimation("StarryAnniversary_Smash_Results_zi.csb")
    self.m_effectNode:addChild(flyNode)
    flyNode:setPosition(startPos)
    flyNode:findChild("Node_cishu"):setVisible(false)
    flyNode:findChild("Node_jackpot"):setVisible(false)
    flyNode:findChild("m_lb_coins"):setString(util_formatCoins(self.m_bonusInfo.smashEgg[1].reward, 3))

    self.m_rewardZiNode:findChild("Node_coins"):setVisible(false)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_reward_fly)
    flyNode:runCsbAction("fly")
    local seq = cc.Sequence:create({
        cc.EaseSineOut:create(cc.BezierTo:create(20/60, {startPos, cc.p(endPos.x, startPos.y), endPos})),
        cc.CallFunc:create(function()
            self.m_winCoinsKuang:findChild("m_lb_coins"):setString(util_formatCoins(self.m_featureData.p_data.bonus.bsWinCoins, 50))
            local info={label = self.m_winCoinsKuang:findChild("m_lb_coins"),sx = 0.7,sy = 0.7}
            self:updateLabelSize(info, 668)

            self.m_winCoinsKuang:runCsbAction("actionframe")
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_reward_fly_end)
            for index = 1, 4 do
                local particle = self.m_winCoinsKuang:findChild("Particle_"..index)
                if particle then
                    particle:resetSystem()
                end
            end
        end),
        cc.RemoveSelf:create(true)
    })
    flyNode:runAction(seq)

    performWithDelay(self, function()
        if type(_func) == "function" then
            _func()
        end
    end, 1)
end

--[[
    砸蛋获得jackpot
]]
function StarryAnniversaryBonusGameView:playWinJackpotEffect()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_win_jackpot)

    self.m_rewardGuangSpine:setVisible(true)
    util_spinePlay(self.m_rewardGuangSpine, "actionframe2", false)
    util_spineEndCallFunc(self.m_rewardGuangSpine, "actionframe2" ,function ()
        self.m_rewardGuangSpine:setVisible(false)
    end)
    self.m_rewardZiNode:runCsbAction("actionframe", false)

    util_spinePlay(self.m_roleSpine, "juese_actionframe10", false)
    util_spineEndCallFunc(self.m_roleSpine, "juese_actionframe10", function()
        self:playRoleIdleEffect()

        self.m_machine:showJackpotView(self.m_bonusInfo.smashEgg[1].reward, self.m_bonusInfo.smashEgg[1].type, function()
            self.m_winCoinsKuang:findChild("m_lb_coins"):setString(util_formatCoins(self.m_featureData.p_data.bonus.bsWinCoins, 50))
            local info={label = self.m_winCoinsKuang:findChild("m_lb_coins"),sx = 0.7,sy = 0.7}
            self:updateLabelSize(info, 668)
    
            self.m_jackPotBarView:hideWinJackpotEffect(self.m_bonusInfo.smashEgg[1].type)
            self:beginPlayGetRewardAfterProcess()
        end)
    end)

    self.m_jackPotBarView:playWinJackpotEffect(self.m_bonusInfo.smashEgg[1].type)
end

--[[
    砸蛋 砸碎之后 奖励结算完之后流程
]]
function StarryAnniversaryBonusGameView:beginPlayGetRewardAfterProcess(_isJackpot)
    local p_bonus = self.m_featureData.p_bonus or {}
    if p_bonus.status ~= "OPEN" then
        self.m_bonusEndCall()
    else
        if not _isJackpot then
            self:playHideEggsEffect()
        end
        
        local bonusInfoList = #self.m_bonusInfo.leftQueue == 6 and self.m_bonusInfo.leftQueue or self.m_bonusInfo.rightQueue
        local chuansongType = #self.m_bonusInfo.leftQueue == 6 and 1 or 2

        local bonusInfo = bonusInfoList[1]
        local statActionframeName = "start2R"
        local playGoldEggsSound = false
        if #self.m_bonusInfo.leftQueue == 6 then
            statActionframeName = "start2L"
            self.m_eggsNodeList[1][6].eggsSpine:setVisible(true)
            self:showChuanSongEggsXingXing(self.m_eggsNodeList[1][6].eggsSpine, self.m_bonusInfo.leftQueue[1].color)
            if self.m_bonusInfo.leftQueue[1].color == "golden" then
                statActionframeName = "start2L2"
                playGoldEggsSound = true
            end
        else
            self.m_eggsNodeList[2][6].eggsSpine:setVisible(true)
            self:showChuanSongEggsXingXing(self.m_eggsNodeList[2][6].eggsSpine, self.m_bonusInfo.rightQueue[1].color)
            if self.m_bonusInfo.rightQueue[1].color == "golden" then
                statActionframeName = "start2R2"
                playGoldEggsSound = true
            end
        end

        self:updateChuanSongEggs()
        if playGoldEggsSound then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_newGoldEggs_start)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_bonus_newEggs_start)
        end

        util_spinePlay(self.m_chuanSongSpine, statActionframeName)
        util_spineEndCallFunc(self.m_chuanSongSpine, statActionframeName ,function ()
            self:createFalseEggs()

            self.m_middleEggsSpine:setSkin(self.m_eggsSkinList[bonusInfo.color])
            self.m_middleEggsSpine:setVisible(true)
            self:showMiddleEggsXingXing(bonusInfo)
            util_spinePlay(self.m_middleEggsSpine, "idle", true)

            for index = 1, 5 do
                self.m_eggsNodeList[chuansongType][index].eggsSpine:setSkin(self.m_eggsSkinList[bonusInfoList[index+1].color])
                self:showChuanSongEggsXingXing(self.m_eggsNodeList[chuansongType][index].eggsSpine, bonusInfoList[index+1].color)
            end
            util_spinePlay(self.m_chuanSongSpine, "idleframe")

            -- 滚出来 金色蛋
            if bonusInfo.color == "golden" then
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_goldEggs_start_role)
                util_spinePlay(self.m_roleSpine, "juese_start1", false)
                util_spineEndCallFunc(self.m_roleSpine, "juese_start1" ,function ()
                    self.m_action = self.ACTION_NONE
                    self:setBtnState(true, true)
                    self:playRoleIdleEffect()
                end)
            else
                self.m_action = self.ACTION_NONE
                self:setBtnState(true, true)
            end

            performWithDelay(self, function()
                self.m_effectNode:removeAllChildren()
            end, 0.2)
        end)

        -- start2 的第43帧 蛋的阴影出现
        performWithDelay(self, function()
            self.m_taizi:runCsbAction("start")
        end, 43/30)
    end
end

--[[
    砸碎蛋 之后 重新滚下来之前 刷新蛋
]]
function StarryAnniversaryBonusGameView:updateChuanSongEggs()
    local bonusInfo = #self.m_bonusInfo.leftQueue == 6 and self.m_bonusInfo.leftQueue or self.m_bonusInfo.rightQueue
    local chuansongType = #self.m_bonusInfo.leftQueue == 6 and 1 or 2
    for index = 1, 6 do
        self.m_eggsNodeList[chuansongType][index].eggsSpine:setSkin(self.m_eggsSkinList[bonusInfo[index].color])
        self:showChuanSongEggsXingXing(self.m_eggsNodeList[chuansongType][index].eggsSpine, bonusInfo[index].color)
    end
end

--[[
    创建假的 蛋 遮挡
]]
function StarryAnniversaryBonusGameView:createFalseEggs()
    self.m_goldEggsList = {}
    local bonusInfoList = #self.m_bonusInfo.leftQueue == 6 and self.m_bonusInfo.leftQueue or self.m_bonusInfo.rightQueue
    local chuansongType = #self.m_bonusInfo.leftQueue == 6 and 1 or 2
    local scaleList = {1, 0.91, 0.83, 0.75, 0.67}
    for index = 2, 6 do
        local startPos = util_convertToNodeSpace(self.m_eggsNodeList[chuansongType][index].eggsSpine, self.m_effectNode)
        local eggsSpine = util_spineCreate("StarryAnniversary_dan", true, true)
        self.m_effectNode:addChild(eggsSpine, 10-index)
        eggsSpine:setPosition(startPos)
        eggsSpine:setSkin(self.m_eggsSkinList[bonusInfoList[index].color])
        eggsSpine:setScale(scaleList[index-1])
        util_spinePlay(eggsSpine, "idle", true)


        eggsSpine.xingxingSpine = util_spineCreate("StarryAnniversary_dan", true, true)
        self.m_effectNode:addChild(eggsSpine.xingxingSpine, 10-index+10)
        eggsSpine.xingxingSpine:setPosition(startPos)
        eggsSpine.xingxingSpine:setScale(scaleList[index-1])
        util_spinePlay(eggsSpine.xingxingSpine, "star_idle", true)

        self:showChuanSongEggsXingXing(eggsSpine, bonusInfoList[index].color)
    end
end

--[[
    按钮状态处理
]]
function StarryAnniversaryBonusGameView:setBtnState(_isBright, _isNextClick)
    self.m_clickBtn:findChild("Button_1"):setBright(_isBright)
    self.m_clickBtn:findChild("Button_1"):setTouchEnabled(_isBright)
    self:findChild("Panel_click"):setTouchEnabled(_isBright)
    if self.m_clickBtn:findChild("Button_2"):isVisible() then
        self.m_clickBtn:runCsbAction("idle", true)
    else
        if _isBright then
            self.m_clickBtn:runCsbAction("idle", true)
        else
            self.m_clickBtn:runCsbAction("idle1", true)
        end
    end

    if _isNextClick and self.m_button_status == BUTTON_STATUS.AUTO then
        self:sendData()
    end
end

--[[
    奖励飞完之后 蛋消失动画
]]
function StarryAnniversaryBonusGameView:playHideEggsEffect()
    self.m_middleEggsSpine:setVisible(false)
    self.m_middleEggsSpine.xingxingSpine:setVisible(false)
    self.m_rewardNode:runCsbAction("over", false, function()
        self.m_rewardNode:setVisible(false)
    end)
    self.m_taizi:runCsbAction("over")
end

--[[
    屏幕移动
]]
function StarryAnniversaryBonusGameView:moveRootNodeAction(targetNode)
    local moveNode = self.m_machine:findChild("Node_4")
    local parentNode = moveNode:getParent()

    local targetNode = targetNode
    local time = 20/30
    local scale = 1.5
    local func = nil

    local curScale = moveNode:getScale()

    --当前位置
    local curPos = cc.p(moveNode:getPosition())
    --目标位置
    local targetPos = util_convertToNodeSpace(targetNode, parentNode)

    local endPos = cc.p(-targetPos.x, -targetPos.y-100)
    if curScale ~= scale then
        endPos.x = endPos.x * scale
        endPos.y = endPos.y * scale
    end
    if endPos.x + curPos.x > display.width * scale / 2 then
        endPos.x = display.width * scale / 2 - curPos.x
    elseif endPos.x + curPos.x < -display.width * scale / 2 then
        endPos.x = -display.width * scale / 2 - curPos.x
    end

    if endPos.y + curPos.y > display.height * scale / 2 then
        endPos.y = display.height * scale / 2 - curPos.y
    elseif endPos.y + curPos.y < -display.height * scale / 2 then
        endPos.y = -display.height * scale / 2 - curPos.y
    end

    local spawn =
        cc.Spawn:create(
        {
            cc.MoveBy:create(time, endPos),
            cc.ScaleTo:create(time, scale)
        }
    )
    moveNode:stopAllActions()

    local seq =
        cc.Sequence:create(
        cc.EaseCubicActionOut:create(spawn),
        cc.CallFunc:create(
            function()
                if type(func) == "function" then
                    func()
                end
            end
        )
    )
    moveNode:runAction(seq)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_scene_amplify)
end

--[[
    点击事件
]]
function StarryAnniversaryBonusGameView:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:setButtonStatusByBegan(sender)
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:setButtonStatusByMoved(sender)
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickFunc then
            return
        end
        self:setButtonStatusByEnd(sender)
        -- self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        local offy = math.abs(endPos.y - beginPos.y)
        if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil then
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickCancelFunc then
            return
        end
        self:clickCancelFunc(sender, eventType)
    end
end

--[[
    清除变auto的动作
]]
function StarryAnniversaryBonusGameView:clearAutoSpinTiming()
    if self.m_timingNode and not tolua.isnull(self.m_timingNode) then
        self.m_timingNode:stopAllActions()
    end
end

--开始
function StarryAnniversaryBonusGameView:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then
        local Timing = function()
            self.m_button_status = BUTTON_STATUS.AUTO
            self.m_clickBtn:runCsbAction("switch", false)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_StarryAnniversary_btn_changeAuto)
        end
        local Timing1 = function()
            self.m_clickBtn:findChild("Button_1"):setVisible(false)
            self.m_clickBtn:findChild("Button_2"):setVisible(true)
            local particle = self.m_clickBtn:findChild("Particle_1")
            if particle then
                particle:resetSystem()
            end
        end
        local Timing2 = function()
            self:clearAutoSpinTiming()
            self:sendData()
            self.m_clickBtn:runCsbAction("idle", true)
        end

        if self.m_button_status == BUTTON_STATUS.NORMAL and self.m_bonusInfo.initTimes and self.m_bonusInfo.initTimes > 0 then --normal时才能长按
            self:clearAutoSpinTiming()
            performWithDelay(self.m_timingNode, Timing, 0.7)
            performWithDelay(self.m_timingNode, Timing1, 1.7)
            performWithDelay(self.m_timingNode, Timing2, 2.2)
        end
    end
end

return StarryAnniversaryBonusGameView