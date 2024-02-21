--[[
    工程节点结构:
        Node_jackpotBar     玩法独有奖池挂点
        Node_pickItem       翻牌节点的父节点
        Node_pickItem%d     翻牌节点的坐标点
]]
local TripleBingoJackpotGameView = class("TripleBingoJackpotGameView", util_require("base.BaseView"))
local PublicConfig = require "TripleBingoPublicConfig"
TripleBingoJackpotGameView.JackpotTypeToIndex = {
    grand  = 1,
    major  = 2,
    minor  = 3,
    mini   = 4,
}

function TripleBingoJackpotGameView:initDatas(_machine)
    self.m_machine     = _machine

    self.m_bClickState = false        --点击状态
    self.m_bonusData = {
        index        = 1,             --点击进度/玩法进度
        process      = {              --翻开奖励顺序列表
            {
                name  = "grand",
                value = 100,
            },
        },            
        extraProcess = {             --未翻开列表
            {
                name  = "mini",
                value = 10,
            },
        },            
        reward       = {             --最终赢得的奖励类型和金额
            name = "grand",
            value = 100,
        },
    }

    self.m_clickIndexList = {}     --已翻开卡片的索引
    self.m_finishCount    = 0      --飞行完成奖励数量
    self.m_rewardQueue    = {}     --等待执行翻牌表现的队列
    self.m_shakeCount     = 0      --播放本轮卡牌idle时,随机抖动的数量
end
function TripleBingoJackpotGameView:initUI()
    self:createCsbNode("TripleBingo_dfdc.csb")
    self:initPackGameJackpotBar()
    self:initPickItem()
    self:initJackpotGameTitle()
end

--再次进入玩法重置ui状态
function TripleBingoJackpotGameView:resetPickGameView()
    self.m_clickIndexList = {}
    self.m_finishCount    = 0
    self.m_rewardQueue  = {}

    self:reSetPackGameJackpotBar()
    self:resetPickItemList()
end

function TripleBingoJackpotGameView:saveBonusData(_data)
    self.m_bonusData = _data
end
function TripleBingoJackpotGameView:startGame(_fun)
    self.m_endFun    = _fun
    self:startPickItemShakeIdleCountDown()
    self:startPickItemIdleAnim()
    self:startNextPick()
end
function TripleBingoJackpotGameView:endGame()
    local fnEnd = self.m_endFun or function() end
    self.m_endFun = nil
    self:stopPickItemIdleAnim()
    self:stopCountDownPickItemIdle()
    self:endGameShowOtherReward(fnEnd)
end

function TripleBingoJackpotGameView:startNextPick()
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
function TripleBingoJackpotGameView:addReward(_pickItem, _clickIndex)
    table.insert(self.m_rewardQueue, {_pickItem, _clickIndex})
    if #self.m_rewardQueue > 1 then
        return
    end
    self:collectStart(_pickItem, _clickIndex)
end
function TripleBingoJackpotGameView:collectStart(_pickItem, _clickIndex)
    local rewardData = self:getRewardDataByClickIndex(_clickIndex)
    local jpIndex = self.m_machine.JackpotTypeToIndex[rewardData.name]
    local rewardCount = self:getRewardCountByClickIndex(rewardData.name, _clickIndex)
    --奖池
    if jpIndex then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_37"])
        self:playCollectFlyAnim(_pickItem, jpIndex, rewardCount, function()
            self:collectOver()
        end)
    --其他奖励(增幅,额外一轮)
    else
        self:collectOver()
    end
end
function TripleBingoJackpotGameView:playCollectFlyAnim(_pickItem, _jpIndex, _progressValue, _fun)
    local flyTime  = 30/60
    local startPos = util_convertToNodeSpace(_pickItem, self)
    local endWorldPos = self.m_jackpotBar:getCollectFlyWorldPos(_jpIndex, _progressValue)
    local endPos   = self:convertToNodeSpace(endWorldPos)
    local flyNode  = util_createAnimation("TripleBingo_Bonus_lizi.csb")
    self:addChild(flyNode)
    flyNode:setPosition(startPos)
    local particleName = string.format("Particle_%d", 1)
    local particleNode = flyNode:findChild(particleName)
    particleNode:setVisible(true)
    particleNode:setPositionType(0)
    particleNode:setDuration(-1)
    particleNode:resetSystem()
    local actList = {}
    table.insert(actList, cc.MoveTo:create(flyTime, endPos))
    table.insert(actList, cc.CallFunc:create(function()
        self.m_jackpotBar:playProgressFlyEndAnim(_jpIndex, _progressValue)
        _fun()
        particleNode:stopSystem()
        util_setCascadeOpacityEnabledRescursion(particleNode, true)
        particleNode:runAction(cc.FadeOut:create(0.5))
    end))
    table.insert(actList, cc.DelayTime:create(0.5))
    table.insert(actList, cc.RemoveSelf:create())
    flyNode:runAction(cc.Sequence:create(actList))
end
function TripleBingoJackpotGameView:collectOver()
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
    奖池
]]
function TripleBingoJackpotGameView:initPackGameJackpotBar()
    self.m_jackpotBar = util_createView("CodeTripleBingoSrc.JackpotGame.TripleBingoJackpotGameJackPotBar", self.m_machine)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
end
function TripleBingoJackpotGameView:reSetPackGameJackpotBar()
    self.m_jackpotBar:resetUi()
end

--[[
    翻牌列表
]]
function TripleBingoJackpotGameView:initPickItem()
    self.m_pickItemMaxCount = 12
    self.m_pickItems        = {}
    self.m_pickItemRootNode = self:findChild("Node_pickItemRoot")
    local parent = self.m_pickItemRootNode
    for _index=1,self.m_pickItemMaxCount do
        local initData  = {}
        initData.itemIndex = _index
        initData.fnClick   = function(_itemIndex)
            self:pickItemClick(_itemIndex)
        end
        local pickItem = util_createView("CodeTripleBingoSrc.JackpotGame.TripleBingoJackpotGameItem", initData)
        parent:addChild(pickItem)
        local posNode  = self:findChild(string.format("Node_0_%d", _index))
        pickItem:setPosition(util_convertToNodeSpace(posNode, parent)) 
        self.m_pickItems[_index] = pickItem
    end
end
function TripleBingoJackpotGameView:resetPickItemList()
    for i,_pickItem in ipairs(self.m_pickItems) do
        _pickItem:resetPickItem()
    end
end
--间隔时间无操作播放抖动
function TripleBingoJackpotGameView:startPickItemShakeIdleCountDown()
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
function TripleBingoJackpotGameView:stopCountDownPickItemIdle()
    if self.m_updatePickItemIdle then
        self:stopAction(self.m_updatePickItemIdle)
        self.m_updatePickItemIdle = nil
    end
end
--播放idle
function TripleBingoJackpotGameView:startPickItemIdleAnim()
    self:stopPickItemIdleAnim()
    local idleInterval = 180/60
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
function TripleBingoJackpotGameView:stopPickItemIdleAnim()
    self.m_pickItemRootNode:stopAllActions()
end

function TripleBingoJackpotGameView:pickItemClick(_itemIndex)
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
    self.m_bonusData.index = self.m_bonusData.index + 1
    
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_36"])
    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_6"])
    --翻开奖励
    pickItem:setRewardType(rewardData)
    pickItem:playOpenAnim(function()
        self:addReward(pickItem, curClickIndex)
    end)

    --倒计时重置
    self:startPickItemShakeIdleCountDown()
    --开始下一次点击
    local maxIndex = #self.m_bonusData.process
    if self.m_bonusData.index <= maxIndex then
        self:startNextPick()
    end
end
--玩法结束 高亮中奖类型,压暗其余类型
function TripleBingoJackpotGameView:endGameShowOtherReward(_fun)
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

    gLobalSoundManager:playSound(PublicConfig.SoundConfig["TRIPLEBINGO_SOUND_38"])

    local delayTime = 3
    performWithDelay(self, _fun, delayTime)
end
--[[
    玩法标题
]]
function TripleBingoJackpotGameView:initJackpotGameTitle()
    self.m_titleCsb = util_createAnimation("TripleBingo_dfdc_bar.csb")
    self:findChild("Node_dfdc_bar"):addChild(self.m_titleCsb)
    self.m_titleCsb:runCsbAction("idle", true)
end

--点击列表数据-插入
function TripleBingoJackpotGameView:insertClickIndex(_itemIndex)
    table.insert(self.m_clickIndexList, _itemIndex)
end
--点击列表数据-是否点击过了
function TripleBingoJackpotGameView:isClicked(_itemIndex)
    for i,_pickItemndex in ipairs(self.m_clickIndexList) do
        if _itemIndex == _pickItemndex then
            return true
        end
    end
    return false
end
--点击列表数据-获取列表内最终赢得类型和未赢得类型
function TripleBingoJackpotGameView:getClickIndexListWinData()
    local rewardName = self.m_bonusData.reward.name
    local list1,list2 = {},{}
    for _clickIndex,_itemIndex in ipairs(self.m_clickIndexList) do
        local rewardData = self:getRewardDataByClickIndex(_clickIndex)
        if rewardName == rewardData.name then
            table.insert(list1, _itemIndex)
        else
            table.insert(list2, _itemIndex)
        end
    end

    return list1,list2
end

--玩法数据bonusData-获取某次点击的奖励
function TripleBingoJackpotGameView:getRewardDataByClickIndex(_clickIndex)
    local process    = self.m_bonusData.process
    local rewardData = process[_clickIndex]
    return rewardData
end
--玩法数据bonusData-获取某个奖励在第N次点击时累计的总数
function TripleBingoJackpotGameView:getRewardCountByClickIndex(_rewardName, _clickIndex)
    local count = 0
    for _index=1,_clickIndex do
        local rewardData = self:getRewardDataByClickIndex(_index)
        if _rewardName == rewardData.name then
            count = count + 1
        end
    end
    return count
end

return TripleBingoJackpotGameView