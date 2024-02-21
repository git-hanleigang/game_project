--[[
    工程节点结构:
        Node_pickItem       翻牌节点的父节点
        Node_pickItem%d     翻牌节点的坐标点
]]
local PublicConfig = require "CherryBountyPublicConfig"
local CherryBountyPickGameView = class("CherryBountyPickGameView", util_require("base.BaseView"))

function CherryBountyPickGameView:initDatas(_machine)
    self.m_machine     = _machine

    self.m_bClickState = false        --点击状态
    self.m_bonusData = {}

    self.m_clickIndexList = {}     --已翻开卡片的索引
    self.m_finishCount    = 0      --飞行完成奖励数量
    self.m_rewardQueue    = {}     --等待执行翻牌表现的队列
    self.m_shakeCount     = 0      --播放本轮卡牌idle时,随机抖动的数量
end
function CherryBountyPickGameView:initUI()
    self:createCsbNode("CherryBounty_pick.csb")
    self:initPickItem()
end

--再次进入玩法重置ui状态
function CherryBountyPickGameView:resetPickGameView()
    self.m_clickIndexList = {}
    self.m_finishCount    = 0
    self.m_rewardQueue  = {}

    self:resetPickItemList()
end

function CherryBountyPickGameView:startGame(_data, _fun)
    self.m_bonusData = _data
    self.m_endFun    = _fun
    
    self:startPickItemShakeIdleCountDown()
    self:startPickItemIdleAnim()
    self:startNextPick()
end
function CherryBountyPickGameView:endGame()
    local fnEnd = self.m_endFun or function() end
    self.m_endFun = nil
    self:stopPickItemIdleAnim()
    self:stopCountDownPickItemIdle()
    self:endGameShowOtherReward(fnEnd)
end



function CherryBountyPickGameView:startNextPick()
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index > maxIndex then
        performWithDelay(self, function()
            self:endGame()
        end, 0.5)
        return
    end
    self.m_bClickState = true
end

--[[
    收集流程
]]
function CherryBountyPickGameView:addReward(_pickItem, _clickIndex)
    table.insert(self.m_rewardQueue, {_pickItem, _clickIndex})
    if #self.m_rewardQueue > 1 then
        return
    end
    self:collectStart(_pickItem, _clickIndex)
end
function CherryBountyPickGameView:collectStart(_pickItem, _clickIndex)
    local rewardData = self:getRewardDataByClickIndex(_clickIndex)
    local jpIndex    = self.m_machine.JackpotTypeToIndex[rewardData.name]
    --奖池
    if jpIndex then
        local bGrand = 1==jpIndex
        self:playCollectFlyAnim(_pickItem, jpIndex, function()
            self.m_machine.m_pickGameTopTips:playRewardAddAnim(rewardData, function()
                if not bGrand then
                    self:collectOver()
                end
            end)
            if bGrand then
                self.m_machine:playFullUpSpine(function()
                    self:collectOver()
                    --grand效果完毕才能点击
                    local maxIndex = #self.m_bonusData.process
                    if self.m_bonusData.index <= maxIndex then
                        self:startNextPick()
                    end
                end)
            end
        end)
    --其他奖励(增幅,额外一轮)
    else
        self:collectOver()
    end
end
function CherryBountyPickGameView:playCollectFlyAnim(_pickItem, _jpIndex, _fun)
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_PickGame_collect)
    local nodeNameList = {}
    local jpCount = #self.m_machine.JackpotIndexToType
    nodeNameList[#nodeNameList+1] = string.format("Particle_%d", jpCount + 1 - _jpIndex)
    local startNode    = _pickItem
    local endNode      = self.m_machine.m_pickGameTopTips
    local flyTime  = 0.5
    self.m_machine:playParticleFly(nodeNameList, startNode, endNode, flyTime)
    self.m_machine:levelPerformWithDelay(self, flyTime, function()
        gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_PickGame_collectFeedback)
        _fun()
    end)
end
function CherryBountyPickGameView:collectOver()
    self.m_finishCount = self.m_finishCount + 1
    table.remove(self.m_rewardQueue, 1)
    -- 队列不为空
    if #self.m_rewardQueue > 0 then
        local pickItem    = self.m_rewardQueue[1][1]
        local rewardIndex = self.m_rewardQueue[1][2]
        self:collectStart(pickItem, rewardIndex)
    else
        -- 队列为空 并且 已经翻开所有的奖励
        local maxIndex = #self.m_bonusData.process
        if self.m_bonusData.index > maxIndex and self.m_finishCount >= maxIndex then
            self:startNextPick()
        end
    end
end

--[[
    翻牌列表
]]
function CherryBountyPickGameView:initPickItem()
    self.m_pickItemMaxCount    = 13
    self.m_pickItems        = {}
    self.m_pickItemRootNode = self:findChild("Node_pickItem")
    local parent = self.m_pickItemRootNode
    for _index=1,self.m_pickItemMaxCount do
        local initData  = {}
        initData.machine   = self.m_machine
        initData.itemIndex = _index
        initData.fnClick   = function(_itemIndex)
            self:pickItemClick(_itemIndex)
        end
        local pickItem = util_createView("CherryBountySrc.CherryBountyPickItem", initData)
        parent:addChild(pickItem)
        local posNode  = self:findChild(string.format("Node_pickItem%d", _index))
        pickItem:setPosition(util_convertToNodeSpace(posNode, parent)) 
        self.m_pickItems[_index] = pickItem
    end
end
function CherryBountyPickGameView:resetPickItemList()
    for i,_pickItem in ipairs(self.m_pickItems) do
        _pickItem:resetPickItem()
    end
end
--间隔时间无操作播放抖动
function CherryBountyPickGameView:startPickItemShakeIdleCountDown()
    self:stopCountDownPickItemIdle()
    self.m_shakeCount = 0
    local time = 5
    self.m_updatePickItemIdle = schedule(self,function()
        time = time - 1
        if time <= 0 then
            self:stopCountDownPickItemIdle()
            self.m_shakeCount = 3
        end
    end, 1)
end
function CherryBountyPickGameView:stopCountDownPickItemIdle()
    if self.m_updatePickItemIdle then
        self:stopAction(self.m_updatePickItemIdle)
        self.m_updatePickItemIdle = nil
    end
end
--播放idle
function CherryBountyPickGameView:startPickItemIdleAnim()
    self:stopPickItemIdleAnim()
    local idleInterval = 30/30
    -- 随机抖动
    local fnPlayPickItemIdle = function()
        local playCount = 0
        local idleIndexList = {}
        for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
            if not self:isClicked(_itemIndex) then
                table.insert(idleIndexList, _itemIndex)
            end
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
        for i,_pickItemndex in ipairs(sharkList) do
            local pickItem = self.m_pickItems[_pickItemndex]
            pickItem:playShakeIdleAnim()
        end
    end

    fnPlayPickItemIdle()
    schedule(self.m_pickItemRootNode, function()
        fnPlayPickItemIdle()
    end, idleInterval)
end
function CherryBountyPickGameView:stopPickItemIdleAnim()
    self.m_pickItemRootNode:stopAllActions()
end

function CherryBountyPickGameView:pickItemClick(_itemIndex)
    if not self.m_bClickState then
        return
    end
    if self:isClicked(_itemIndex) then
        return
    end
    self:insertClickIndex(_itemIndex)
    self.m_bClickState = false

    local curClickIndex  = self.m_bonusData.index
    local rewardData = self:getRewardDataByClickIndex(curClickIndex)
    local pickItem   = self.m_pickItems[_itemIndex]
    local jpIndex    = self.m_machine.JackpotTypeToIndex[rewardData.name]
    local bGrand     = 1==jpIndex
    self.m_bonusData.index = self.m_bonusData.index + 1

    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_PickGame_click)
    --翻开奖励
    pickItem:setRewardType(rewardData)
    pickItem:playOpenAnim(function()
        self:addReward(pickItem, curClickIndex)
    end)

    --倒计时重置
    self:startPickItemShakeIdleCountDown()
    --开始下一次点击
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index <= maxIndex and not bGrand then
        self:startNextPick()
    end
end
--玩法结束 高亮中奖类型,压暗其余类型
function CherryBountyPickGameView:endGameShowOtherReward(_fun)
    local winList,otherList = self:getClickIndexListWinData()
    --点击后-中奖类型
    for i,_itemIndex in ipairs(winList) do
        local pickItem = self.m_pickItems[_itemIndex]
        pickItem:playTriggerAnim()
    end
    --点击后-未中奖类型
    for i,_itemIndex in ipairs(otherList) do
        local pickItem = self.m_pickItems[_itemIndex]
        pickItem:playDarkAnim()
    end
    --未点击
    local extraProcessIndex = 1
    for _itemIndex,_pickItem in ipairs(self.m_pickItems) do
        if not self:isClicked(_itemIndex) and _pickItem:isVisible() then
            local otherRewardData = self.m_bonusData.extraProcess[extraProcessIndex]
            _pickItem:setRewardType(otherRewardData)
            _pickItem:playDarkAnim()
            extraProcessIndex = extraProcessIndex + 1
        end
    end

    local delayTime = 2.5
    performWithDelay(self, _fun, delayTime)
end

--点击列表数据-插入
function CherryBountyPickGameView:insertClickIndex(_itemIndex)
    table.insert(self.m_clickIndexList, _itemIndex)
end
--点击列表数据-是否点击过了
function CherryBountyPickGameView:isClicked(_itemIndex)
    for i,_pickItemndex in ipairs(self.m_clickIndexList) do
        if _itemIndex == _pickItemndex then
            return true
        end
    end
    return false
end
--点击列表数据-获取列表内最终赢得类型和未赢得类型
function CherryBountyPickGameView:getClickIndexListWinData()
    local list1,list2 = {},{}
    for _clickIndex,_itemIndex in ipairs(self.m_clickIndexList) do
        table.insert(list1, _itemIndex)
    end

    return list1,list2
end

--玩法数据bonusData-获取某次点击的奖励
function CherryBountyPickGameView:getRewardDataByClickIndex(_clickIndex)
    local process    = self.m_bonusData.process
    local rewardData = process[_clickIndex]
    return rewardData
end
--玩法数据bonusData-获取某个奖励在第N次点击时累计的总数
function CherryBountyPickGameView:getRewardCountByClickIndex(_rewardName, _clickIndex)
    local count = 0
    for _index=1,_clickIndex do
        local rewardData = self:getRewardDataByClickIndex(_index)
        if _rewardName == rewardData.name then
            count = count + 1
        end
    end
    return count
end

return CherryBountyPickGameView