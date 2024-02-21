---
--xcyy
--2018年5月23日
--AliceView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AliceBonusCardGame = class("AliceBonusCardGame",BaseGame )

AliceBonusCardGame.m_currChooseRow = nil
AliceBonusCardGame.m_currResult = nil
AliceBonusCardGame.m_totalMultip = nil
AliceBonusCardGame.ALL_CARD_TYPE = {"A", "B", "C", "D", "E"}

local MULTIP_TABLE = {150, 132, 120, 108, 90, 72, 60, 48, 36, 30}
local TABLE_PAY = 
{
    {"A", "B", "C"},
    {"A", "B", "D"},
    {"A", "C", "E"},
    {"A", "C", "D"},
    {"E", "D", "A"},
    {"B", "C", "E"},
    {"B", "C", "D"},
    {"B", "A", "E"},
    {"E", "D", "B"},
    {"C", "E", "D"}
}
local MUSHROOM_COL = 7

function AliceBonusCardGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("Alice/BonusGame6.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    self.m_labStartPrice = self:findChild("m_lb_start")
    self.m_labMultip = self:findChild("m_lab_multip")

    self.m_vecItem = {}
    local itemTag = 1
    local index = 1
    while true do
        local node = self:findChild("Card" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusCardItem", index)
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

    self.m_vecPayTable = {}
    index = 1
    while true do
        local node = self:findChild("Node" .. index )
        if node ~= nil then
            local info = {}
            info.multipe = MULTIP_TABLE[index]
            info.pay = TABLE_PAY[index]
            local item = util_createView("CodeAliceSrc.AliceBonusCardPay", info)
            self.m_vecPayTable[index] = item
            node:addChild(item)
        else
            break
        end
        index = index + 1
    end

    self.m_bClickFlag = false

end

function AliceBonusCardGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self:sendData(item:getTag())
    
end


function AliceBonusCardGame:onEnter()
    BaseGame.onEnter(self)
end

function AliceBonusCardGame:onExit()
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AliceBonusCardGame:initViewData(startPrice, callBackFun)
    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
        self.m_bClickFlag = true
        self:showItemStart()
    end)

    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)
    self.m_totalMultip = 0
    self.m_callFunc = callBackFun
    self.m_startPrice = startPrice
    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
end

function AliceBonusCardGame:resetView(startPrice, featureData, callBackFun)
    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
        self.m_bClickFlag = true
        if self.m_startClick ~= true then
            self:showItemStart()
        end
    end)

    self.m_totalMultip = 0
    self.m_startPrice = startPrice
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)
    self.m_labMultip:setString("")
    self.m_callFunc = callBackFun

    if featureData ~= nil and featureData.p_bonus.extra.clickPoses ~= nil then
        local vecPos = featureData.p_bonus.extra.clickPoses
        local vecResult = featureData.p_bonus.extra.cardResult.sequence
        for i = 1, #vecPos, 1 do
            local index = tonumber(vecPos[i])
            local result = vecResult[i]
            local item = self.m_vecItem[index]
            item:showSelected(result)
            for i = 1, #self.m_vecPayTable, 1 do
                self.m_vecPayTable[i]:showIdle(result)
            end
            for i = 1, #self.ALL_CARD_TYPE, 1 do
                if self.ALL_CARD_TYPE[i] == result then
                    table.remove(self.ALL_CARD_TYPE, i)
                    break
                end
            end
        end
        self.m_startClick = true
    end
    
end

function AliceBonusCardGame:showItemStart()
    for i = 1, #self.m_vecItem, 1 do
        self.m_vecItem[i]:showItemStart()
    end
end

--默认按钮监听回调
function AliceBonusCardGame:clickItem()
    if self.m_startClick ~= true then
        for i = 1, #self.m_vecItem, 1 do
            if self.m_vecItem[i] ~= self.m_currClickItem then
                self.m_vecItem[i]:showItemIdle()
            end
        end
        self.m_startClick = true
    end
    if self.m_bGameOver == true then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_collect.mp3")
    end
    self.m_currClickItem:showResult(self.m_currResult, function()
        self:clickCallBack()
    end)
    
end

function AliceBonusCardGame:clickCallBack()

    gLobalSoundManager:playSound("AliceSounds/sound_Alice_little_card.mp3")
    for i = 1, #self.m_vecPayTable, 1 do
        self.m_vecPayTable[i]:showChoosed(self.m_currResult)
    end
    for i = 1, #self.ALL_CARD_TYPE, 1 do
        if self.ALL_CARD_TYPE[i] == self.m_currResult then
            table.remove(self.ALL_CARD_TYPE, i)
            break
        end
    end
    performWithDelay(self, function()
        if self.m_bGameOver ~= true then
            self.m_bClickFlag = true
        else
            for i = 1, #self.m_vecItem, 1 do
                local item = self.m_vecItem[i]
                if item.isShowItem ~= true then
                    local index = math.random(1, #self.ALL_CARD_TYPE)
                    local result = self.ALL_CARD_TYPE[index]
                    table.remove(self.ALL_CARD_TYPE, index)
                    item:showUnselected(result)
                end
            end
            local index = self.m_overResult.index + 1
            local payTable = self.m_vecPayTable[index]
            local startNode = payTable:getStartNode()
            self.m_vecPayTable[index]:showReward(function()
                self:flyParticleEffect(startNode, function()
                    gLobalSoundManager:stopBgMusic()
                    gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_end.mp3")
                    
                    performWithDelay(self, function()
                        
                        self:bonusGameOver()
                        
                    end, 2.5)
                    
                end)
            end)
        end
    end, 0.5)
    
end

function AliceBonusCardGame:flyParticleEffect(startNode, func)
    local delayTime = 0.8
    
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_game_over.mp3")
    local parent = self:findChild("Node_15")
    local posWorld = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos = parent:convertToNodeSpace(posWorld)
    local endPos = cc.p(self.m_labMultip:getPosition())
    local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
    parent:addChild(particle)
    particle:setPosition(startPos)
    local distance = ccpDistance(startPos, endPos)
    local flyTime = distance / 600
    local moveTo = cc.MoveTo:create(flyTime, endPos)

    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
        function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
            self.m_totalMultip = self.m_overResult.multiple
            self.m_labMultip:setString(self.m_overResult.multiple)
            self:addMultipEffect()
            performWithDelay(self, function()
                particle:removeFromParent()
            end, 0.2)
        end
    )))
    
    if func ~= nil then
        performWithDelay(self, function()
            func()
        end, delayTime)
    end
end

function AliceBonusCardGame:addMultipEffect()
    local effect, act = util_csbCreate("BonusGame_fankuilizi.csb")
    self.m_labMultip:getParent():addChild(effect)
    effect:setPosition(self.m_labMultip:getPosition())
    util_csbPlayForKey(act, "actionframe", false, function()
        effect:removeFromParent()
    end)
end

function AliceBonusCardGame:showLostAnimation(func)
    
end

function AliceBonusCardGame:bonusGameOver()
    
    local bonusOver = util_createView("CodeAliceSrc.AliceBonusGameOver") 
    bonusOver:initViewData(self.m_startPrice, self.m_totalMultip, self.m_totleWimnCoins, function()
        self:runCsbAction("over", false, function()
            performWithDelay(self, function()
                if self.m_callFunc ~= nil then
                    self.m_callFunc()
                end
                self:removeFromParent()
            end, 0.8)
        end)
    end)
    gLobalViewManager:showUI(bonusOver)
end

--数据发送
function AliceBonusCardGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AliceBonusCardGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end

    self.p_status = featureData.p_status
    self.m_currResult = featureData.p_bonus.extra.cardResult.sequence[#featureData.p_bonus.extra.clickPoses]
    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})

        self.m_bGameOver = true
        self.m_overResult = featureData.p_bonus.extra.cardResult
    end
    self:clickItem()
end

--弹出结算界面前展示其他宝箱数据
function AliceBonusCardGame:showOther()
    
end

--开始结束流程
function AliceBonusCardGame:gameOver()
    
end

--弹出结算奖励

function AliceBonusCardGame:sortNetData( data)
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

function AliceBonusCardGame:featureResultCallFun(param)
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
return AliceBonusCardGame