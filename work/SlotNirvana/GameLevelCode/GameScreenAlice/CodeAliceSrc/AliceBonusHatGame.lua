---
--xcyy
--2018年5月23日
--AliceView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AliceBonusHatGame = class("AliceBonusHatGame",BaseGame )

AliceBonusHatGame.m_currMultip = nil
AliceBonusHatGame.m_leftPickNum = nil

local CAKE_TOTAL_NUM = 6

local CAKE_TOTAL_DELAY = {1.1, 1.05, 1, 0.95, 0.9, 0.85}

function AliceBonusHatGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("Alice/BonusGame5.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    self.m_labStartPrice = self:findChild("m_lb_start")
    self.m_labMultip = self:findChild("m_lab_multip")
    self.m_labPickNum = self:findChild("pickNum")

    self.m_vecItem = {}
    local itemTag = 1
    local index = 1
    while true do
        local node = self:findChild("Hat_" .. index )
        if node ~= nil then
            local item = util_createView("CodeAliceSrc.AliceBonusHatItem", index)
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

    self.m_bClickFlag = false

end

function AliceBonusHatGame:initBonusBoard(vecInfo)
    local boardInfo = {}
    for key, value in pairs(vecInfo) do
        boardInfo[tonumber(key)] = util_string_split(value,";")
    end

    self.m_vecBoard = {}
    local boardTag = 1
    local index = 1
    while true do
        local node = self:findChild("Node_" .. index )
        if node ~= nil then
            local info = {}
            info.index = index
            info.table = boardInfo[index]
            local board = util_createView("CodeAliceSrc.AliceBonusHatBoard", info)
            self.m_vecBoard[index] = board
            board:setTag(boardTag)
            node:addChild(board)
            boardTag = boardTag + 1
        else
            break
        end
        index = index + 1
    end
end

function AliceBonusHatGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self:sendData(item:getTag())
    self:subPickNum()
end

function AliceBonusHatGame:onEnter()
    BaseGame.onEnter(self)
end
function AliceBonusHatGame:onExit()
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AliceBonusHatGame:initViewData(startPrice, callBackFun)
    self:runCsbAction("start", false, function ()
        self.m_bClickFlag = true
        self:runCsbAction("idle", true)
        self:showItemStart()
    end)
    self.m_leftPickNum = 5
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self.m_labPickNum:setString(self.m_leftPickNum)
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)

    self.m_callFunc = callBackFun
    self.m_startPrice = startPrice
    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
    
end

function AliceBonusHatGame:resetView(startPrice, featureData, callBackFun)
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

    self.m_leftPickNum = 5
    if featureData ~= nil and featureData.p_bonus.extra.clickPoses ~= nil then
        local vecClickPoses = featureData.p_bonus.extra.clickPoses
        local vecResult = featureData.p_bonus.extra.hatResult
        for i = 1, #vecClickPoses, 1 do
            local index = tonumber(vecClickPoses[i])
            local result = vecResult[i]
            local item = self.m_vecItem[index]
            item:showSelected(result.type)
            local board = self.m_vecBoard[result.type]
            board:showBoardIdle()
            self.m_leftPickNum = result.leftPickNum
        end
        self.m_startClick = true
    end
    self.m_labPickNum:setString(self.m_leftPickNum)

end

function AliceBonusHatGame:subPickNum()
    self.m_leftPickNum = self.m_leftPickNum - 1
    self.m_labPickNum:setString(self.m_leftPickNum)
end

function AliceBonusHatGame:showItemStart()
    for i = 1, #self.m_vecItem, 1 do
        self.m_vecItem[i]:showItemStart()
    end
end

--默认按钮监听回调
function AliceBonusHatGame:clickItem(func)
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

function AliceBonusHatGame:clickCallBack()
    local parent = self:findChild("Node_Hat")
    local currBoard = self.m_vecBoard[self.m_currMultip]
    local endNode = currBoard:getEndNode()
    local posWorld = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
    local endPos = parent:convertToNodeSpace(posWorld)
    local index = self.m_currClickItem:getTag()
    local startPos = cc.p(self:findChild("Hat_"..index):getPosition())
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_game_over.mp3")
    local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
    parent:addChild(particle)
    particle:setPosition(startPos)
    local distance = ccpDistance(startPos, endPos)
    local flyTime = distance / 700
    local moveTo = cc.MoveTo:create(flyTime, endPos)
    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
        function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
            currBoard:showBoardAnim(function()
                if self.m_leftPickNum ~= self.m_result.leftPickNum then
                    self.m_leftPickNum = self.m_result.leftPickNum
                    local currBoard = self.m_vecBoard[self.m_currMultip]
                    local pickNode = currBoard:getPickNode()
                    self:boardFlyEffect(pickNode, self.m_labPickNum, function()
                        self:boardAnimCall()
                    end)
                else
                    self:boardAnimCall()
                end
            end)
            performWithDelay(self, function()
                particle:removeFromParent()
            end, 0.2)
        end
    )))

end

function AliceBonusHatGame:addMultipEffect(endNode)
    local effect, act = util_csbCreate("BonusGame_fankuilizi.csb")
    endNode:getParent():addChild(effect)
    effect:setPosition(endNode:getPosition())
    util_csbPlayForKey(act, "actionframe", false, function()
        effect:removeFromParent()
    end)
end

function AliceBonusHatGame:boardAnimCall()
    if self.m_bGameOver ~= true then
        self.m_bClickFlag = true
    else
        local totalDelay = 0
        local delayTime = 0.5
        for i = 1, CAKE_TOTAL_NUM, 1 do
            local board = self.m_vecBoard[i]
            local choose = board:getChooseNum()
            delayTime = CAKE_TOTAL_DELAY[i]
            if choose > 0 then
                performWithDelay(self, function()
                    local node, mul = board:getCollectNodeAndMul(choose)
                    
                    self:boardFlyEffect(node, self.m_labMultip, function()
                        local total = 0
                        if self.m_labMultip:getString() ~= "" then
                            total = tonumber(self.m_labMultip:getString()) + mul
                        else
                            total = mul
                        end
                        
                        -- self:addMultipEffect(self.m_labMultip)
                        self.m_labMultip:setString(total)
                        self.m_totalMultip = total
                    end)
                end, totalDelay)
                totalDelay = totalDelay + delayTime
            end
        end

        performWithDelay(self, function()
            gLobalSoundManager:stopBgMusic()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_end.mp3")
        end, totalDelay + 1)
        performWithDelay(self, function()
            
            self:showBonusOver()
            
        end, totalDelay + 3.5)
    end
end

function AliceBonusHatGame:boardFlyEffect(startNode, endNode, func)
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_game_over.mp3")
    local parent = self:findChild("Node_15")
    local posWorld = startNode:getParent():convertToWorldSpace(cc.p(startNode:getPosition()))
    local startPos = parent:convertToNodeSpace(posWorld)
    local endPos = cc.p(endNode:getPosition())

    local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
    parent:addChild(particle)
    particle:setPosition(startPos)
    local distance = ccpDistance(startPos, endPos)
    local flyTime = distance / 700
    local moveTo = cc.MoveTo:create(flyTime, endPos)

    particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
        function()
            gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
            self:addMultipEffect(endNode)
            self.m_labPickNum:setString(self.m_leftPickNum)
            if func ~= nil then
                func()
            end
            performWithDelay(self, function()
                particle:removeFromParent()
            end, 0.2)
        end
    )))

end

function AliceBonusHatGame:showBonusOver()
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
function AliceBonusHatGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AliceBonusHatGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end
    
    self.p_status = featureData.p_status
    self.m_result = featureData.p_bonus.extra.hatResult[#featureData.p_bonus.extra.clickPoses]
    self.m_currMultip = self.m_result.type
    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})

        self.m_bGameOver = true
    end
    self:clickItem()
end

--弹出结算界面前展示其他宝箱数据
function AliceBonusHatGame:showOther()
    
end

--开始结束流程
function AliceBonusHatGame:gameOver()
    
end

--弹出结算奖励

function AliceBonusHatGame:sortNetData( data)
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

function AliceBonusHatGame:featureResultCallFun(param)
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
return AliceBonusHatGame