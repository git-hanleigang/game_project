---
--xcyy
--2018年5月23日
--AliceView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AliceBonusTreeGame = class("AliceBonusTreeGame",BaseGame )

AliceBonusTreeGame.m_gameResult = nil
AliceBonusTreeGame.m_currMultip = nil
AliceBonusTreeGame.m_collectKeysNum = nil

function AliceBonusTreeGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("Alice/BonusGame3.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    self.m_labStartPrice = self:findChild("m_lb_start")
    self.m_labMultip = self:findChild("m_lab_multip")

    self.m_vecItem = {}
    local itemTag = 1
    local index = 1
    while true do
        local node = self:findChild("Cup" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusTreeItem", index)
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

    self.m_vecKeys = {}
    index = 1
    while true do
        local node = self:findChild("Key" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusTreeKey")
            self.m_vecKeys[index] = item
            node:addChild(item)
        else
            break
        end
        index = index + 1
    end

    self.m_vecLocks = {}
    index = 1
    while true do
        local node = self:findChild("Lock" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusTreeLock", index)
            self.m_vecLocks[index] = item
            node:addChild(item)
        else
            break
        end
        index = index + 1
    end
    
    self.m_bClickFlag = false

end

function AliceBonusTreeGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self:sendData(item:getTag())
    
end

function AliceBonusTreeGame:onEnter()
    BaseGame.onEnter(self)
end
function AliceBonusTreeGame:onExit()
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AliceBonusTreeGame:initViewData(startPrice, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        self:showItemStart()
    end)

    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)
    self.m_collectKeysNum = 0
    self.m_callFunc = callBackFun
    self.m_startPrice = startPrice
    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
    
end

function AliceBonusTreeGame:resetView(startPrice, featureData, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        if self.m_startClick ~= true then
            self:showItemStart()
        end
    end)
    self.m_startPrice = startPrice
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)

    self.m_callFunc = callBackFun
    self.m_collectKeysNum = 0
    if featureData ~= nil and featureData.p_bonus.extra.clickPoses ~= nil then
        local vecClickPoses = featureData.p_bonus.extra.clickPoses
        self.m_collectKeysNum = #vecClickPoses
        local keyNum = 0
        for i = 1, self.m_collectKeysNum, 1 do
            local index = tonumber(vecClickPoses[i])
            local item = self.m_vecItem[index]
            item:setVisible(false)
            local key = self.m_vecKeys[i]
            key:showCollect()
        end
        local len = math.floor(self.m_collectKeysNum / 3)
        for i = 1, len, 1 do
            self.m_vecLocks[i]:showCollect()
        end
        self.m_startClick = true
    end
    

end

function AliceBonusTreeGame:showItemStart()
    for i = 1, #self.m_vecItem, 1 do
        self.m_vecItem[i]:showItemStart()
    end
end

--默认按钮监听回调
function AliceBonusTreeGame:clickItem(func)
    self.m_collectKeysNum = self.m_collectKeysNum + 1
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

function AliceBonusTreeGame:clickCallBack()
    if self.m_bGameOver ~= true then
        local flyNode = self:findChild("Cup"..self.m_currClickItem:getTag())
        local endNode = self:findChild("Key"..self.m_collectKeysNum)
        local distance = ccpDistance(cc.p(flyNode:getPosition()), cc.p(endNode:getPosition()))
        local flyTime = distance / 600
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_fly.mp3")
        local moveTo = cc.MoveTo:create(flyTime, cc.p(endNode:getPosition()))
        local collectKeysNum = self.m_collectKeysNum
        flyNode:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
            flyNode:setVisible(false)
            self.m_bClickFlag = true
            self.m_vecKeys[collectKeysNum]:animationCollect(function()
                if collectKeysNum % 3 == 0 then
                    self.m_vecLocks[collectKeysNum / 3]:animationCollect(function()
                        -- self.m_bClickFlag = true
                    end)
                else
                    -- self.m_bClickFlag = true
                end
            end)
        end)))
    else
        self:bonusGameOver()
    end
    
end

function AliceBonusTreeGame:bonusGameOver()
    for i = 1, #self.m_vecItem, 1 do
        local item = self.m_vecItem[i]
        if item ~= self.m_currClickItem then
            item:showUnselected()
        end
    end
    performWithDelay(self, function()
        local lockNum = math.floor((self.m_collectKeysNum - 1) / 3)
        local startNode = self.m_vecLocks[lockNum]
        self.m_currMultip = self.m_gameResult.keyMultiple
        self:FlyParticleEffect(startNode, self.m_labMultip, function()
            self.m_currMultip = self.m_currMultip * self.m_gameResult.multiple
            self:FlyParticleEffect(self.m_currClickItem, self.m_labMultip, function()
                performWithDelay(self, function()
                    gLobalSoundManager:stopBgMusic()
                    gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_end.mp3")
                end, 1)
                performWithDelay(self, function()
                    
                    self:showBonusOver()
                    
                end, 3.5)
            end)
        end)
        
    end, 0.5)
    
    
end

function AliceBonusTreeGame:FlyParticleEffect(startNode, endNode, func)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_game_over.mp3")
    
    local parent = self:findChild("Node_15")
    local posWorld = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos = parent:convertToNodeSpace(posWorld)
    local endPos = cc.p(endNode:getPosition())
    local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
    parent:addChild(particle)
    particle:setPosition(startPos)
    local distance = ccpDistance(startPos, endPos)
    local flyTime = distance / 600
    local moveTo = cc.MoveTo:create(flyTime, endPos)

    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
        function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
            self:addMultipEffect()
            self.m_totalMultip = self.m_currMultip
            self.m_labMultip:setString(self.m_currMultip)
            if func ~= nil then
                func()
            end
            performWithDelay(self, function()
                particle:removeFromParent()
            end, 0.2)
        end
    )))

end

function AliceBonusTreeGame:addMultipEffect()
    local effect, act = util_csbCreate("BonusGame_fankuilizi.csb")
    self.m_labMultip:getParent():addChild(effect)
    effect:setPosition(self.m_labMultip:getPosition())
    util_csbPlayForKey(act, "actionframe", false, function()
        effect:removeFromParent()
    end)
end

function AliceBonusTreeGame:showBonusOver()
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
function AliceBonusTreeGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AliceBonusTreeGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    
    self.p_status = featureData.p_status
    
    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)
        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})

        self.m_gameResult = featureData.p_bonus.extra.treeResult
        self.m_currMultip = self.m_gameResult.multiple
        self.m_bGameOver = true
    end
    self:clickItem()
end

--弹出结算界面前展示其他宝箱数据
function AliceBonusTreeGame:showOther()
    
end

--开始结束流程
function AliceBonusTreeGame:gameOver()
    
end

--弹出结算奖励

function AliceBonusTreeGame:sortNetData( data)
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

function AliceBonusTreeGame:featureResultCallFun(param)
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
return AliceBonusTreeGame