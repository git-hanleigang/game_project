---
--xcyy
--2018年5月23日
--AliceView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AliceBonusCastleGame = class("AliceBonusCastleGame",BaseGame )

AliceBonusCastleGame.m_currMultip = nil
local WIN_TYPE = 
{
    win_jackpot = 1,
    win_90 = 2,
    win_60 = 3,
    win_30 = 4,
}

function AliceBonusCastleGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("Alice/BonusGame1.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    self.m_labStartPrice = self:findChild("m_lb_start")
    self.m_labJackpot = self:findChild("m_lb_jackpot")

    self.m_vecItem = {}
    local itemTag = 1
    local index = 1
    while true do
        local node = self:findChild("tubiao_" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusCastleItem", index)
            self.m_vecItem[index] = item
            item:setTag(itemTag)
            local func = function ()
                self:clickItemCallFunc(item)
            end
            item:setClickFunc(func)
            node:addChild(item)
            itemTag = itemTag + 1
        else
            break
        end
        index = index + 1
    end
    
    self.m_vecBar = {}
    index = 1
    while true do
        local node = self:findChild("Node_" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusCastleBar", index)
            self.m_vecBar[index] = item
            node:addChild(item)
        else
            break
        end
        index = index + 1
    end

    self.m_bClickFlag = false
    self.m_vecSelectedItem = {}
end

function AliceBonusCastleGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self:sendData(item:getTag())
    
end

function AliceBonusCastleGame:onEnter()
    BaseGame.onEnter(self)
end
function AliceBonusCastleGame:onExit()
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AliceBonusCastleGame:initViewData(startPrice, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        self:showItemStart()
    end)

    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)

    self.m_callFunc = callBackFun
    self.m_startPrice = startPrice
    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
    
end

function AliceBonusCastleGame:resetView(startPrice, featureData, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        if self.m_startClick ~= true then
            self:showItemStart()
        end
    end)
    self.m_startPrice = startPrice
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)

    self.m_callFunc = callBackFun

    if featureData ~= nil and featureData.p_bonus.extra.clickPoses ~= nil then
        local vecClickPoses = featureData.p_bonus.extra.clickPoses
        local vecMultiples = featureData.p_bonus.extra.castleResult
        for i = 1, #vecClickPoses, 1 do
            local index = tonumber(vecClickPoses[i])
            local result = vecMultiples[i]
            local item = self.m_vecItem[index]
            item:showSelected(result.type)
            index = WIN_TYPE["win_"..result.type]
            self.m_vecBar[index]:showSelected()
            if self.m_vecSelectedItem["win"..result.type] == nil then
                self.m_vecSelectedItem["win"..result.type] = {}
            end
            self.m_vecSelectedItem["win"..result.type][#self.m_vecSelectedItem["win"..result.type] + 1] = item
        end
        self.m_startClick = true
    end
    
    for key, value in pairs(self.m_vecSelectedItem) do
        if #value == 2 then
            for i = 1, #value, 1 do
                local item = value[i]
                item:idleSeleted2()
            end
        end
    end

end

function AliceBonusCastleGame:initJackpot(jackpot)
    self.m_labJackpot:setString(util_formatCoins(jackpot,50))
    self:updateLabelSize({label = self.m_labJackpot,sx = 0.7,sy = 0.7}, 320)
end

function AliceBonusCastleGame:showItemStart()
    for i = 1, #self.m_vecItem, 1 do
        self.m_vecItem[i]:showItemStart()
    end
end

function AliceBonusCastleGame:showGuideHand(func)
    self.m_removeCall = func
end

--默认按钮监听回调
function AliceBonusCastleGame:clickItem(func)
    if self.m_startClick ~= true then
        for i = 1, #self.m_vecItem, 1 do
            if self.m_vecItem[i] ~= self.m_currClickItem then
                self.m_vecItem[i]:showItemIdle()
            end
        end
        self.m_startClick = true
    end
    self.m_currClickItem:showResult(self.m_currMultip, function()
        self:clickCallBack()
    end, func)
    
end

function AliceBonusCastleGame:clickCallBack()
    local index = WIN_TYPE["win_"..self.m_currMultip]
    
    self:flyParticleEffect(self.m_currClickItem, self.m_vecBar[index], function()
        if self.m_bGameOver ~= true then
            if #self.m_vecSelectedItem["win"..self.m_currMultip] == 2 then
                local vecItem = self.m_vecSelectedItem["win"..self.m_currMultip]
                for i = 1, #vecItem, 1 do
                    local item = vecItem[i]
                    item:animationSelected2()
                end
            end
            self.m_bClickFlag = true
        else
            local vecItem = self.m_vecSelectedItem["win"..self.m_currMultip]
            for i = 1, #vecItem, 1 do
                local item = vecItem[i]
                item:animationReward()
            end

            for key, value in pairs(self.m_vecSelectedItem) do
                if key ~= "win"..self.m_currMultip then
                    for i = 1, #value, 1 do
                        local item = value[i]
                        item:showFailed()
                    end
                end
            end

            self:runCsbAction("actionframe"..index)

            local leftID = 1
            for i = 1, #self.m_vecItem, 1 do
                local item = self.m_vecItem[i]
                if item:showItemStatus() ~= true then
                    local result = self.m_leftResult[leftID].type
                    item:showUnselected(result)
                    leftID = leftID + 1
                end
            end
            if self.m_callFunc ~= nil then
                self.m_callFunc()
            end
            performWithDelay(self, function()
                gLobalSoundManager:stopBgMusic()
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_end.mp3")
            end, 2.5)
            performWithDelay(self, function()
                
                self:showBonusOver()
                
            end, 6)
        end
    end)

end

function AliceBonusCastleGame:flyParticleEffect(startNode, endNode, func)
    local parent = self:findChild("Node_15")
    local startPos = cc.p(startNode:getParent():getPosition())
    local collectNum = endNode:getCollectNum() + 1
    local endPos = cc.p(endNode:getParent():getPosition())
    endPos.x = endPos.x + (collectNum - 2) * 31
    local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
    parent:addChild(particle)
    particle:setPosition(startPos)
    local distance = ccpDistance(startPos, endPos)
    local flyTime = distance / 600
    local moveTo = cc.MoveTo:create(flyTime, endPos)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_jackpot_fly.mp3")
    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
        function()
            endNode:showResult(func)
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_jackpot_fly_down.mp3")
            performWithDelay(self, function()
                particle:removeFromParent()
            end, 0.2)
        end
    )))

end

function AliceBonusCastleGame:showBonusOver()
    
    local bonusOver = nil
    if self.m_currMultip ~= "jackpot" then
        bonusOver = util_createView("CodeAliceSrc.AliceBonusGameOver") 
        bonusOver:initViewData(self.m_startPrice, self.m_currMultip, self.m_totleWimnCoins, function()
            performWithDelay(self, function()
                self:showJackpotMore()
            end, 0.8)
        end)
    else
        bonusOver = util_createView("CodeAliceSrc.AliceBonusGameJackpot") 
        bonusOver:initViewData(self.m_totleWimnCoins, function()
            self:runCsbAction("over", false, function()
                performWithDelay(self, function()
                    if self.m_removeCall ~= nil then
                        self.m_removeCall()
                    end
                    self:removeFromParent()
                end, 0.8)
            end)
        end)
    end
    
    gLobalViewManager:showUI(bonusOver)
end

function AliceBonusCastleGame:showJackpotMore()
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_pop_window.mp3")
    local view = util_createView("CodeAliceSrc.AliceJackpotMore", self.m_jackpotMore)
    view:setRemoveCallBack(function()
        self:runCsbAction("over", false, function()
            performWithDelay(self, function()
                self:removeFromParent()
            end, 0.8)
        end)
    end)
    gLobalViewManager:showUI(view)
end

--数据发送
function AliceBonusCastleGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AliceBonusCastleGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    
    self.p_status = featureData.p_status
    self.m_currMultip = featureData.p_bonus.extra.castleResult[#featureData.p_bonus.extra.clickPoses].type

    if self.m_vecSelectedItem["win"..self.m_currMultip] == nil then
        self.m_vecSelectedItem["win"..self.m_currMultip] = {}
    end
    self.m_vecSelectedItem["win"..self.m_currMultip][#self.m_vecSelectedItem["win"..self.m_currMultip] + 1] = self.m_currClickItem
    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})
        self.m_leftResult = featureData.p_bonus.extra.castleResult[#featureData.p_bonus.extra.clickPoses].leftTypes
        self.m_bGameOver = true
    end
    self:clickItem()
end

--弹出结算界面前展示其他宝箱数据
function AliceBonusCastleGame:showOther()
    
end

--开始结束流程
function AliceBonusCastleGame:gameOver()
    
end

--弹出结算奖励

function AliceBonusCastleGame:sortNetData( data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status
        end
    end 


    localdata = data

    return localdata
end

function AliceBonusCastleGame:featureResultCallFun(param)
    if param[1] == true then
        local spinData = param[2]
        -- dump(spinData.result, "featureResultCallFun data", 3)
        local userMoneyInfo = param[3]
        self.m_serverWinCoins = spinData.result.winAmount  -- 记录下服务器返回赢钱的结果
        self.m_totleWimnCoins = spinData.result.winAmount
        print("赢取的总钱数为=" .. self.m_totleWimnCoins)
        globalData.userRate:pushCoins(self.m_serverWinCoins)
        globalData.userRunData:setCoins(userMoneyInfo.resultCoins)
        if spinData.action == "FEATURE" then
            local data = self:sortNetData(spinData.result)
            self.m_featureData:parseFeatureData(data)
            self:recvBaseData(self.m_featureData)
            if data.selfData.map.jackpotB ~= nil then
                self.m_jackpotMore = data.selfData.map.jackpotB
            end
        elseif self.m_isBonusCollect then
            self.m_featureData:parseFeatureData(spinData.result)
            self:recvBaseData(self.m_featureData)
        else
            -- dump(spinData.result, "featureResult action"..spinData.action, 3)
        end
    else
        -- 处理消息请求错误情况
    end
end
return AliceBonusCastleGame