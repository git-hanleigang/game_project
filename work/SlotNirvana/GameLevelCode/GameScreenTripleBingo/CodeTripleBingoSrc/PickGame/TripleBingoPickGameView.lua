--[[
    N选1玩法:

    工程节点结构:
        Node_pickItem       翻牌节点的父节点
        Node_pickItem%d     翻牌节点的坐标点
]]
local TripleBingoPickGameView = class("TripleBingoPickGameView", util_require("base.BaseView"))
local PublicConfig = require "TripleBingoPublicConfig"
function TripleBingoPickGameView:initDatas(_machine)
    self.m_machine     = _machine

    self.m_bClickState = false        --点击状态
    self.m_bonusData = {
        index        = 1,             --点击进度/玩法进度
        process      = {              --翻开奖励顺序列表
        },            
        extraProcess = {             --未翻开列表
        },            
        reward       = {             --最终赢得的奖励类型和金额
        },
    }

    --道具相关
    self.m_itemConfig = {
        maxLine   = 5,
        lineCount = {6, 5, 4, 3, 2},
    }

    self.m_clickIndexList = {}     --已翻开卡片的索引
    self.m_finishCount    = 0      --飞行完成奖励数量
    self.m_rewardQueue    = {}     --等待执行翻牌表现的队列
    self.m_shakeCount     = 0      --播放本轮卡牌idle时,随机抖动的数量
end
function TripleBingoPickGameView:initUI()
    self:createCsbNode("TripleBingo_PickEm.csb")
    self:initArrow()
    self:initWinnerBar()
    self:initPickItem()
end

--再次进入玩法重置ui状态
function TripleBingoPickGameView:resetPickGameView()
    self.m_clickIndexList = {}
    self.m_finishCount    = 0
    self.m_rewardQueue  = {}

    self:resetPickItemList()
    self:resettWinnerBar()
    self:resetArrow()
end

function TripleBingoPickGameView:startGame(_data, _fun)
    self.m_bonusData = _data
    self.m_endFun    = _fun

    self:startNextPick()
end
function TripleBingoPickGameView:endGame()
    local fnEnd = function() 
        if self.m_endFun then
            self.m_endFun()
            self.m_endFun = nil
        end
    end
    self:stopPickItemIdleAnim()
    self:stopCountDownPickItemIdle()
    -- self:endGameShowOtherReward(function()
        self:playWinnerBarTriggerAnim(fnEnd)
    -- end)
end



function TripleBingoPickGameView:startNextPick()
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index > maxIndex then
        performWithDelay(self, function()
            self:endGame()
        end, 0.5)
        return
    end
    self:startPickItemShakeIdleCountDown()
    self:startPickItemIdleAnim()
    self.m_bClickState = true
end

--[[
    收集流程
]]
function TripleBingoPickGameView:addReward(_pickItem, _clickIndex)
    table.insert(self.m_rewardQueue, {_pickItem, _clickIndex})
    if #self.m_rewardQueue > 1 then
        return
    end
    self:collectStart(_pickItem, _clickIndex)
end
function TripleBingoPickGameView:collectStart(_pickItem, _clickIndex)
    local rewardData = self:getRewardDataByClickIndex(_clickIndex)

    self:playWinnerBarCollectAnim(_pickItem, rewardData, function()
        self:collectOver()
    end)
end

function TripleBingoPickGameView:collectOver()
    self.m_finishCount = self.m_finishCount + 1
    table.remove(self.m_rewardQueue, 1)
    -- 队列不为空
    if #self.m_rewardQueue > 0 then
        local pickItem    = self.m_rewardQueue[1][1]
        local rewardIndex = self.m_rewardQueue[1][2]
        self:collectStart(pickItem, rewardIndex)
    else
        self:playArrowUpAnim(self.m_bonusData.index, function()
            self:startNextPick()
        end)
    end
end


--[[
    箭头 | 底光
]]
function TripleBingoPickGameView:initArrow()
    --底光
    self.m_lightCsb = util_createAnimation("TripleBingo_PickEm_Lights.csb")
    self:findChild("Node_light"):addChild(self.m_lightCsb)
    --箭头
    self.m_arrowCsb = util_createAnimation("TripleBingo_PickEm_Arrows.csb")
    self:findChild("Node_Arrows"):addChild(self.m_arrowCsb)
    self.m_arrowCsb:runCsbAction("idle",true)
end
function TripleBingoPickGameView:resetArrow()
    self.m_lightCsb:runCsbAction("idle",true)
    self.m_arrowCsb:runCsbAction("idle",true)
    self:setArrowPos(1)
end
function TripleBingoPickGameView:setArrowPos(_lineIndex)
    local posNode = self:findChild( string.format("Node_Light%d", _lineIndex) )
    if not posNode then
        return
    end
    self.m_lightCsb:setPosition(util_convertToNodeSpace(posNode, self.m_lightCsb:getParent()))
    self.m_arrowCsb:setPosition(util_convertToNodeSpace(posNode, self.m_arrowCsb:getParent()))
end
function TripleBingoPickGameView:getLightPos(_posNode)
    local lightPos = util_convertToNodeSpace(_posNode, self.m_lightCsb:getParent())
    lightPos.x = lightPos.x - 10
    lightPos.y = lightPos.y + 10
    return lightPos
end
function TripleBingoPickGameView:playArrowUpAnim(_lineIndex, _fun)
    local posNode = self:findChild( string.format("Node_Light%d", _lineIndex) )
    if not posNode or _lineIndex > #self.m_bonusData.process then
        --淡出
        self.m_lightCsb:runCsbAction("over")
        self.m_arrowCsb:runCsbAction("over")
        return _fun()
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_43"])
    
    local lightPos = util_convertToNodeSpace(posNode, self.m_lightCsb:getParent())
    local arrowPos = util_convertToNodeSpace(posNode, self.m_arrowCsb:getParent())
    local moveTime = 0.5
    self.m_lightCsb:runAction(cc.Sequence:create(
        cc.MoveTo:create(moveTime, lightPos),
        cc.CallFunc:create(function()
            _fun()
        end)
    ))
    self.m_arrowCsb:runAction(cc.MoveTo:create(moveTime, arrowPos))
end

--[[
    金币收集栏
]]
function TripleBingoPickGameView:initWinnerBar()
    self.m_winnerBarCsb = util_createAnimation("TripleBingo_PickEm_winner.csb")
    self:findChild("Node_Pickwinner"):addChild(self.m_winnerBarCsb)

    self.m_winnerBarCsb.m_bigWinView = util_spineCreate("TripleBingo_bigwin_tb", true, true)
    self.m_winnerBarCsb:findChild("Node_glow2"):addChild(self.m_winnerBarCsb.m_bigWinView)
    self.m_winnerBarCsb.m_bigWinView:setVisible(false)

    

    local labWinner = self.m_winnerBarCsb:findChild("m_lb_coins")
    local labSize = labWinner:getContentSize()
    self.m_labWinnerInfo = {
        label = labWinner, 
        sx = labWinner:getScaleX(), 
        sy = labWinner:getScaleY(),
        width = labSize.width,
    }
    self.m_winnerCoins = 0
end
function TripleBingoPickGameView:resettWinnerBar()
    self:settWinnerBarCoins(0)
end
function TripleBingoPickGameView:settWinnerBarCoins(_coins)
    self.m_winnerCoins = _coins
    local sCoins = ""
    if toLongNumber(self.m_winnerCoins) > toLongNumber(0) then 
        sCoins = util_formatCoins(self.m_winnerCoins, 30)
    end
    self.m_labWinnerInfo.label:setString(sCoins)
    self:updateLabelSize(self.m_labWinnerInfo, self.m_labWinnerInfo.width)
end
function TripleBingoPickGameView:playWinnerBarCollectAnim(_pickItem, _rewardData, _fun)
    local labWinner = self.m_labWinnerInfo.label
    local addCoins = _rewardData.value
    if addCoins <= 0 then
        return _fun()
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_44"])
    local curCoins    = self.m_winnerCoins
    local targetCoins = curCoins + addCoins
    local jumpTime = 0.3
    local coinRiseNum =  addCoins / (jumpTime * 60)
    local sRandomCoinRiseNum   = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = math.ceil(tonumber(sRandomCoinRiseNum))  
    schedule(labWinner, function()
        curCoins = curCoins + coinRiseNum
        curCoins = LongNumber.min(targetCoins, curCoins)
        self:settWinnerBarCoins(curCoins)
        if toLongNumber(curCoins) >= toLongNumber(targetCoins) then
            if _fun then
                _fun()
                _fun = nil
            end
            labWinner:stopAllActions()
        end
    end,0.008)
end
--结束闪光
function TripleBingoPickGameView:playWinnerBarTriggerAnim(_fun)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_45"])
    self.m_winnerBarCsb:runCsbAction("actionframe", true)
    self.m_winnerBarCsb.m_bigWinView:setVisible(true)
    util_spinePlay(self.m_winnerBarCsb.m_bigWinView,"actionframe2")
    util_spineEndCallFunc(self.m_winnerBarCsb.m_bigWinView,"actionframe2",function()
        self.m_winnerBarCsb:runCsbAction("idle", false)
        performWithDelay(self,function()
            _fun()
        end,0)
    end)
end

--[[
    翻牌列表
]]
function TripleBingoPickGameView:initPickItem()
    self.m_pickItemRootNode = self:findChild("Node_Items")
    self.m_pickItemMaxCount    = 20
    self.m_pickItems        = {}
    
    for _index=1,self.m_pickItemMaxCount do
        local initData  = {}
        initData.itemIndex = _index
        initData.fnClick   = function(_itemIndex)
            self:pickItemClick(_itemIndex)
        end
        local pickItem = util_createView("CodeTripleBingoSrc.PickGame.TripleBingoPickItem", initData)
        local parent = self:findChild(string.format("%d", _index-1))
        parent:addChild(pickItem)
        self.m_pickItems[_index] = pickItem
    end
end
function TripleBingoPickGameView:getItemListByLine(_lineIndex)
    local itemList = {}

    local startIndex = 1
    for lineIndex,_lineCount in ipairs(self.m_itemConfig.lineCount) do
        if lineIndex == _lineIndex then
            local endIndex = startIndex + _lineCount - 1
            for i=startIndex,endIndex do
                table.insert(itemList, self.m_pickItems[i])
            end
            break
        end
        startIndex = startIndex + _lineCount
    end

    return itemList
end
-- 一行内未选中压暗
function TripleBingoPickGameView:playLineItemDark(_lineIndex, _selectItemIndex, _fun)
    local lineItemList     = self:getItemListByLine(_lineIndex)
    local extraProcessList = self.m_bonusData.extraProcess[self.m_bonusData.index]
    for i,_pickItem in ipairs(lineItemList) do
        if _pickItem.m_initData.itemIndex ~= _selectItemIndex then
            local rewardData = extraProcessList[i]
            if not rewardData then
                rewardData = extraProcessList[1]
            end
            _pickItem:setRewardType(rewardData)
            _pickItem:playDarkAnim(rewardData.value)
        end
    end
    self.m_machine:levelPerformWithDelay(self, 30/60, _fun)
end

function TripleBingoPickGameView:resetPickItemList()
    for i,_pickItem in ipairs(self.m_pickItems) do
        _pickItem:resetPickItem()
    end
    local lineItemList = self:getItemListByLine(1)
    for i,_pickItem in ipairs(lineItemList) do
        _pickItem:playIdleAnim()
    end
end
--间隔时间无操作播放抖动
function TripleBingoPickGameView:startPickItemShakeIdleCountDown()
    self:stopCountDownPickItemIdle()
    self.m_shakeCount = 0
    local time = 5
    self.m_updatePickItemIdle = schedule(self,function()
        time = time - 1
        if time <= 0 then
            self:stopCountDownPickItemIdle()
            self.m_shakeCount = 1
        end
    end, 1)
end
function TripleBingoPickGameView:stopCountDownPickItemIdle()
    if self.m_updatePickItemIdle then
        self:stopAction(self.m_updatePickItemIdle)
        self.m_updatePickItemIdle = nil
    end
end
--播放idle
function TripleBingoPickGameView:startPickItemIdleAnim()
    self:stopPickItemIdleAnim()
    local idleInterval = 180/60
    -- 随机抖动
    local fnPlayPickItemIdle = function()
        local lineCount = self.m_itemConfig.lineCount[self.m_bonusData.index]
        if not lineCount then
            return self:stopPickItemIdleAnim()
        end
        local startIndex = 1
        for _lineIndex,_lineCount in ipairs(self.m_itemConfig.lineCount) do
            if _lineIndex == self.m_bonusData.index then
                break
            end
            startIndex = startIndex + _lineCount
        end
        local idleIndexList = {}
        local endIndex = startIndex+lineCount-1
        for _itemIndex=startIndex,endIndex do  
            table.insert(idleIndexList, _itemIndex)
        end
        local sharkList = {}
        for _shakeIndex=1,self.m_shakeCount do
            if #idleIndexList < 2 then
                break
            end
            local itemIndex = table.remove(idleIndexList, math.random(1, #idleIndexList))
            table.insert(sharkList, itemIndex)
        end
        --普通idle
        for i,_pickItemndex in ipairs(idleIndexList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            pickItem:playIdleAnim()
        end
        --抖动idle
        for i,_pickItemndex in ipairs(idleIndexList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            pickItem:playShakeIdleAnim()
        end
    end

    fnPlayPickItemIdle()
    schedule(self.m_pickItemRootNode, function()
        fnPlayPickItemIdle()
    end, idleInterval)
end
function TripleBingoPickGameView:stopPickItemIdleAnim()
    self.m_pickItemRootNode:stopAllActions()
end

function TripleBingoPickGameView:pickItemClick(_itemIndex)
    if not self.m_bClickState then
        return
    end
    local curClickIndex  = self.m_bonusData.index
    local lineItemList = self:getItemListByLine(curClickIndex)
    local bLine = false
    for i,_pickItem in ipairs(lineItemList) do
        if _itemIndex == _pickItem.m_initData.itemIndex then
            bLine = true
            break
        end
    end
    if not bLine then
        return
    end

    -- self:insertClickIndex(_itemIndex)
    self.m_bClickState = false

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_42"])
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_6"])
    --停止抖动
    self:stopPickItemIdleAnim()
    self:stopCountDownPickItemIdle()

    local rewardData = self:getRewardDataByClickIndex(curClickIndex)
    local pickItem   = self.m_pickItems[_itemIndex]

    if rewardData.value <= 0 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_57"])
    end

    --翻开奖励
    pickItem:setRewardType(rewardData)
    pickItem:playOpenAnim(rewardData.value, function()
        self.m_bonusData.index = self.m_bonusData.index + 1
        self:addReward(pickItem, curClickIndex)
    end)
    self:playLineItemDark(curClickIndex, _itemIndex, function()
            
    end)
end
--玩法结束 高亮中奖类型,压暗其余类型
function TripleBingoPickGameView:endGameShowOtherReward(_fun)
    if self.m_bonusData.index > self.m_itemConfig.maxLine then
        return _fun()
    end
    for _lineIndex=self.m_bonusData.index-1,self.m_itemConfig.maxLine do
        local lineItemList = self:getItemListByLine(_lineIndex)
        local extraProcessList = self.m_bonusData.extraProcess[_lineIndex]
        for i,_pickItem in ipairs(lineItemList) do
            local rewardData = extraProcessList[i]
            if not rewardData then
                rewardData = extraProcessList[1]
            end
            _pickItem:setRewardType(rewardData)
            _pickItem:playLineDarkAnim(rewardData.value)
        end
    end

    local delayTime = 3
    performWithDelay(self, _fun, delayTime)
end

--玩法数据bonusData-获取某次点击的奖励
function TripleBingoPickGameView:getRewardDataByClickIndex(_clickIndex)
    local process    = self.m_bonusData.process
    local rewardData = process[_clickIndex]
    return rewardData
end

return TripleBingoPickGameView