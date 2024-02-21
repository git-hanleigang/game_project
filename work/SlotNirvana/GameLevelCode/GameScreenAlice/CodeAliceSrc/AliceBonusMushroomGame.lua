---
--xcyy
--2018年5月23日
--AliceView.lua

local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseGame = util_require("base.BaseGame")
local AliceBonusMushroomGame = class("AliceBonusMushroomGame",BaseGame )

AliceBonusMushroomGame.m_currChooseRow = nil
AliceBonusMushroomGame.m_currResult = nil
AliceBonusMushroomGame.m_totalMultip = nil

local MUSHROOM_ROW = 4
local MUSHROOM_COL = 7

function AliceBonusMushroomGame:initUI(data)

    self.m_isShowTournament = true

    self:createCsbNode("Alice/BonusGame4.csb")
    -- self.m_csbNode:setPosition(display.cx, display.cy)
    self.m_isBonusCollect=true
    -- TODO 输入自己初始化逻辑

    self.m_labStartPrice = self:findChild("m_lb_start")
    self.m_labMultip = self:findChild("m_lab_multip")

    self.m_vecItem = {}
    local iIndex = 0
    
    for iRow = MUSHROOM_ROW, 1, -1 do
        for iCol = 1, MUSHROOM_COL, 1 do
            if self.m_vecItem[iRow] == nil then
                self.m_vecItem[iRow] = {}
            end
            local parent = self:findChild("Mushroom"..iRow.."_"..iCol)
            if parent ~= nil then
                local pos = {row = iRow, col = iCol, index = iIndex}
                local item = util_createView("CodeAliceSrc.AliceBonusMushroomItem", pos)
                self.m_vecItem[iRow][iCol] = item
                local func = function ()
                    self:clickItemCallFunc(item)
                end
                item:setClickFunc(func)
                parent:addChild(item)
            end
            iIndex = iIndex + 1
        end
    end

    self.m_bClickFlag = false

end

function AliceBonusMushroomGame:clickItemCallFunc(item)
    if self.m_bClickFlag == false then
        return 
    end
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    self.m_bClickFlag = false
    self.m_currClickItem = item
    self:sendData(item:getItemIndex())
    
end

--@return {iX,iY}
function AliceBonusMushroomGame:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = MUSHROOM_COL

    local rowIndex = MUSHROOM_ROW - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {row = rowIndex,col = colIndex}
end

function AliceBonusMushroomGame:getIndexByRowAndCol(iRow, iCol)
    local index = (MUSHROOM_ROW - iRow) * MUSHROOM_COL + iCol - 1
    return index
end

function AliceBonusMushroomGame:onEnter()
    BaseGame.onEnter(self)
end

function AliceBonusMushroomGame:onExit()
    BaseGame.onExit(self)

    -- gLobalSoundManager:stopBgMusic()
end

function AliceBonusMushroomGame:initViewData(startPrice, callBackFun)
    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
        self:showItemStart()
    end)

    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self.m_labMultip:setString("")
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)
    self.m_totalMultip = 0
    self.m_callFunc = callBackFun
    self.m_currChooseRow = MUSHROOM_ROW
    -- self:sendStartGame()
    -- gLobalSoundManager:playSound("AZTECSounds/sound_despicablewolf_enter_fs.mp3")
    self.m_startPrice = startPrice
end

function AliceBonusMushroomGame:resetView(startPrice, featureData, callBackFun)
    self:runCsbAction("start", false, function ()
        self:runCsbAction("idle", true)
        self:showItemStart()
    end)
    self.m_startPrice = startPrice
    self.m_totalMultip = 0
    self.m_labStartPrice:setString(util_formatCoins(startPrice,50))
    self:updateLabelSize({label = self.m_labStartPrice,sx = 1,sy = 1}, 222)
    self.m_callFunc = callBackFun

    if featureData ~= nil and featureData.p_bonus.extra.clickPoses ~= nil then
        self.m_currChooseRow = MUSHROOM_ROW - #featureData.p_bonus.extra.clickPoses
        local index = 1
        for i = MUSHROOM_ROW, self.m_currChooseRow + 1, -1 do
            local result = featureData.p_bonus.extra.mushroomResult[index]
            local arrayItems = self.m_vecItem[i]
            if result.type == "WinAll" then
                for j = 1, #arrayItems, 1 do
                    local item = arrayItems[j]
                    item:showSelected(result.leftTypes[j])
                    if result.leftTypes[j] ~= "WinAll" and result.leftTypes[j] ~= "0" then
                        self.m_totalMultip = self.m_totalMultip + tonumber(result.leftTypes[j])
                    end
                end
            else
                local selectID = tonumber(featureData.p_bonus.extra.clickPoses[index])
                selectID = selectID % MUSHROOM_COL + 1
                local selectItem = arrayItems[selectID]
                selectItem:showSelected(result.leftTypes[selectID])
                self.m_totalMultip = self.m_totalMultip + tonumber(result.leftTypes[selectID])
                for j = 1, #arrayItems, 1 do
                    if j ~= selectID then
                        local item = arrayItems[j]
                        item:showUnselected(result.leftTypes[j])
                    end
                end
            end    
            index = index + 1
        end
        self.m_labMultip:setString(self.m_totalMultip)
    else
        self.m_currChooseRow = MUSHROOM_ROW
        self.m_labMultip:setString("")
    end

end

--默认按钮监听回调
function AliceBonusMushroomGame:clickItem()
    local arrayItems = self.m_vecItem[self.m_currChooseRow + 1]
    for i = 1, #arrayItems, 1 do
        local item = arrayItems[i]
        if item ~= self.m_currClickItem then
            item:showItemIdle()
        end
    end

    self.m_currClickItem:showResult(self.m_currResult.type, function()
        self:clickCallBack()
    end)
    
end

function AliceBonusMushroomGame:clickCallBack()
    
    if self.m_currResult.type == "WinAll" then
        self:showAllAnimation(function()
            self:allFlyEffect(function()
                self:showItemStart()
            end)
        end)
    else
        self:flyParticleEffect(self.m_currClickItem, function()
            self:showItemStart()
        end)
    end

end

function AliceBonusMushroomGame:showItemStart()
    if self.m_bGameOver ~= true then
        local arrayItems = self.m_vecItem[self.m_currChooseRow]
        for i = 1, #arrayItems, 1 do
            local item = arrayItems[i]
            item:showItemStart()
        end
        self.m_currChooseRow = self.m_currChooseRow - 1
        self.m_bClickFlag = true
    else
        gLobalSoundManager:stopBgMusic()
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_bonus_game_end.mp3")
        
        performWithDelay(self, function()
            
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
        end, 2.5)
        
    end
end

function AliceBonusMushroomGame:flyParticleEffect(item, func)
    local delayTime = 1.5
    local col = item:getItemCol()
    local row = item:getItemRow()
    if self.m_currResult.leftTypes[col] ~= "0" then
        gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_game_over.mp3")
        local endPos = cc.p(self.m_labMultip:getPosition())
        local node = self:findChild("Mushroom"..row.."_"..col)
        local startPos = cc.p(node:getPosition())
        local particle = cc.ParticleSystemQuad:create("partical/Alice_tuowei.plist")
        self:findChild("Node_15"):addChild(particle)
        particle:setPosition(startPos)
        local distance = ccpDistance(startPos, endPos)
        local flyTime = distance / 600
        local moveTo = cc.MoveTo:create(flyTime, endPos)
        particle:runAction(cc.Sequence:create(moveTo, cc.CallFunc:create(
            function()
                gLobalSoundManager:playSound("AliceSounds/sound_Alice_tree_key_down.mp3")
                self:addMultipEffect()
                self.m_totalMultip = self.m_totalMultip + tonumber(self.m_currResult.leftTypes[col])
                self.m_labMultip:setString(self.m_totalMultip)
                performWithDelay(self, function()
                    particle:removeFromParent()
                end, 0.2)
            end
        )))
    end
    if self.m_currResult.type ~= "WinAll" then
        self:showLostAnimation()
    end
    
    if func ~= nil then
        performWithDelay(self, function()
            func()
        end, delayTime)
    end
end

function AliceBonusMushroomGame:addMultipEffect()
    local effect, act = util_csbCreate("BonusGame_fankuilizi.csb")
    self.m_labMultip:getParent():addChild(effect)
    effect:setPosition(self.m_labMultip:getPosition())
    util_csbPlayForKey(act, "actionframe", false, function()
        effect:removeFromParent()
    end)
end

function AliceBonusMushroomGame:allFlyEffect(func)
    local arrayItems = self.m_vecItem[self.m_currChooseRow + 1]
    local delayTime = 0.8
    local particleNum = 0
    for i = 1, #arrayItems, 1 do
        local item = arrayItems[i]
        local col = item:getItemCol()
        local result = self.m_currResult.leftTypes[col]
        
        if result ~= "WinAll" and result ~= "0" then
            performWithDelay(self, function()
                self:flyParticleEffect(item)
            end, particleNum * delayTime)
            particleNum = particleNum + 1
        end
    end
    
    if func ~= nil then
        performWithDelay(self, function()
            func()
        end, particleNum * delayTime + 0.5)
    end
end

function AliceBonusMushroomGame:showLostAnimation(func)
    local arrayItems = self.m_vecItem[self.m_currChooseRow + 1]
    for i = 1, #arrayItems, 1 do
        local item = arrayItems[i]
        if item ~= self.m_currClickItem then
            local result = self.m_currResult.leftTypes[item:getItemCol()]
            item:showLostAnimtion(result)
        end
    end
    if func ~= nil then
        performWithDelay(self, function()
            func()
        end, 0.8)
    end
end

function AliceBonusMushroomGame:showAllAnimation(func)
    local arrayItems = self.m_vecItem[self.m_currChooseRow + 1]
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_rose_click.mp3")
    for i = 1, #arrayItems, 1 do
        local item = arrayItems[i]
        if item ~= self.m_currClickItem then
            local result = self.m_currResult.leftTypes[item:getItemCol()]
            item:showResult(result)
        end
    end
    if func ~= nil then
        performWithDelay(self, function()
            func()
        end, 1)
    end
end

--数据发送
function AliceBonusMushroomGame:sendData(pos)
    self.m_action=self.ACTION_SEND

    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData=nil
    if self.m_isBonusCollect then
        
        messageData={msg = MessageDataType.MSG_BONUS_SELECT , data = pos} -- self.m_collectDataList -- MessageDataType.MSG_BONUS_COLLECT
    end
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData,true)
    
end

function AliceBonusMushroomGame:recvBaseData(featureData)
    --dump(featureData, "featureData", 3)
    self.m_action=self.ACTION_RECV
    if featureData.p_status=="START" then
        self:startGameCallFunc()
        return
    end

    self.p_status = featureData.p_status
    self.m_currResult = featureData.p_bonus.extra.mushroomResult[#featureData.p_bonus.extra.clickPoses]
    
    if featureData.p_status=="CLOSED" then
        self:uploadCoins(featureData)

        -- 更新游戏内每日任务进度条
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        -- 通知bonus 结束， 以及赢钱多少
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BONUS_CLOSED,{self.m_totleWimnCoins, GameEffect.EFFECT_BONUS})

        self.m_bGameOver = true
    else
        
    end
    self:clickItem()
end

--弹出结算界面前展示其他宝箱数据
function AliceBonusMushroomGame:showOther()
    
end

--开始结束流程
function AliceBonusMushroomGame:gameOver()
    
end

--弹出结算奖励

function AliceBonusMushroomGame:sortNetData( data)
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

function AliceBonusMushroomGame:featureResultCallFun(param)
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
return AliceBonusMushroomGame