--MiningManiaBonusCarView.lua

local BaseDialog = util_require("Levels.BaseDialog")
local MiningManiaBonusCarView = class("MiningManiaBonusCarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MiningManiaPublicConfig"

MiningManiaBonusCarView.m_bonusRootSccale = 1.0

MiningManiaBonusCarView.m_machine = nil
MiningManiaBonusCarView.SYMBOL_SCORE_BONUS_NULL = 120 -- 空信号
MiningManiaBonusCarView.SYMBOL_SCORE_BONUS_5 = 121 -- 绿色
MiningManiaBonusCarView.SYMBOL_SCORE_BONUS_6 = 122 -- 蓝色
MiningManiaBonusCarView.SYMBOL_SCORE_BONUS_7 = 123 -- 红色
MiningManiaBonusCarView.SYMBOL_SCORE_BONUS_8 = 124 -- 黄色
MiningManiaBonusCarView.SYMBOL_SCORE_BONUS_9 = 125 -- 闹钟
MiningManiaBonusCarView.m_intervalDis = 200 -- 奖励中间间隔的像素
MiningManiaBonusCarView.m_bgMidLen = 2428 -- 背景长度
MiningManiaBonusCarView.m_bgMidUpLen = 2728 -- 背景中间最上层背景长度
MiningManiaBonusCarView.m_bgMidTopLen = 2704 -- 背景顶部背景长度
MiningManiaBonusCarView.m_bgMidBottomLen = 2610 -- 背景底部背景长度
MiningManiaBonusCarView.m_roalLen = 1984 -- 单个轨道长度
MiningManiaBonusCarView.m_roalStartLen = 319 -- 轨道开始长度
MiningManiaBonusCarView.m_moveDis = 600 -- 每秒移动的距离-- 根据速度和总长度获取时间；不用服务器给的时间；因为要调速度；只要保证在时间停止时奖励领完即可
MiningManiaBonusCarView.m_curIndex = 0 -- 当前奖励索引
MiningManiaBonusCarView.m_curMoveTotalDis = 0 -- 当前移动的总长度
MiningManiaBonusCarView.m_reduceSpeedTime = 1 -- 减速时间

function MiningManiaBonusCarView:initUI(_data)
    self:createCsbNode("MiningMania/GameScreenMiningMania_SheJiao2.csb")
    self.m_machine = _data.parent

    --收集区域
    local m_collectBar = util_createAnimation("MiningMania_Shejiao2_Shoujiqu.csb")
    self:findChild("Node_shoujiqu"):addChild(m_collectBar)
    self.m_collectText = m_collectBar:findChild("m_lb_num")

    -- 用户
    self.m_playerItems = {}
    -- 箭头节点
    self.m_arrowNodeTbl = {}
    -- 头像父节点
    self.m_seatNodeParent = self:findChild("Node_playerRank")
    for index = 1, 5 do
        local node = self:findChild("Node_Seat_"..(index - 1))
        local item = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarPlayerItem")
        node:addChild(item)
        self.m_playerItems[index] = item

        self.m_arrowNodeTbl[index] = self:findChild("Node_arrow_"..index)
    end

    -- 动态创建背景父节点
    self.m_midBgNode = self:findChild("Node_Bg_Mid")
    self.m_midUpBgNode = self:findChild("Node_Bg_Mid_Up")
    self.m_midTopBgNode = self:findChild("Node_Bg_Mid_Top")
    self.m_midBottomBgNode = self:findChild("Node_Bg_Mid_Bottom")

    -- 移动背景和轨道节点
    self.m_moveNodeTbl = {}
    for i=1, 2 do
        self.m_moveNodeTbl[i] = self:findChild("Node_Bg_Move_"..i)
    end
    -- 移动小车节点
    self.m_moveCarNode = self:findChild("Node_Car")
    -- 轨道移动的节点
    self.m_moveRoadNode = self:findChild("Node_guidao")
    -- 箭头移动节点
    self.m_moveArrowNode = self:findChild("Node_arrow")

    -- 倒计时
    self.m_timeNodeTbl = {}
    -- 轨道
    self.m_roadNodeTbl = {}
    -- 小车节点
    self.m_carNodeTbl = {}
    -- 小车动画
    self.m_carAniTbl = {}
    -- 闸机动画
    self.m_gateAniTbl = {}
    -- 结束标志
    self.m_endTipAniTbl = {}
    for i=1, 3 do
        -- 倒计时红色动画（下边）
        local timeRedAni = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarRedProcess")
        self:findChild("Node_red_"..i):addChild(timeRedAni)

        self.m_timeNodeTbl[i] = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarTimeItem", self, i, timeRedAni)
        self:findChild("Node_time"..i):addChild(self.m_timeNodeTbl[i])

        self.m_roadNodeTbl[i] = self:findChild("Node_guidao_"..i)

        self.m_carNodeTbl[i] = self:findChild("Node_che_"..i)
        self.m_carAniTbl[i] = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarAni", self, i)
        self.m_carNodeTbl[i]:addChild(self.m_carAniTbl[i])

        self.m_gateAniTbl[i] = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarGateAni", self)
        self:findChild("Node_zaji_"..i):addChild(self.m_gateAniTbl[i])

        self.m_endTipAniTbl[i] = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarEndTips", self)
        self:findChild("Node_EndTips_"..i):addChild(self.m_endTipAniTbl[i])
    end

    -- ready go
    self.m_readyGoAni = util_createAnimation("MiningMania_start.csb")
    self:findChild("Node_readyGo"):addChild(self.m_readyGoAni)
    self.m_readyGoAni:setVisible(false)

    -- 奖励节点X位置
    self.m_rewardPosYTbl = {216, 0, -216}
    -- 奖励节点
    self.m_rewardNode = {}
    self.m_rewardNode = self:findChild("Node_reward")

    -- 创建背景
    self:createBg()

    --特效层
    self.m_effectNode = self:findChild("Node_topEffect")

    -- 内存池（小块奖励）
    self.m_rewardNodePool = {}

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_scSecondScheduleNode = cc.Node:create()
    self:addChild(self.m_scSecondScheduleNode)

    self.m_scMoveScheduleNode = cc.Node:create()
    self:addChild(self.m_scMoveScheduleNode)

    local panelClick = self:findChild("Panel_click")
    panelClick:setSwallowTouches(true)
end

function MiningManiaBonusCarView:scaleMainLayer(_scale)
    self.m_bonusRootSccale = _scale
    self:findChild("root"):setScale(_scale)
end

function MiningManiaBonusCarView:onEnter()
    MiningManiaBonusCarView.super.onEnter(self)
end

function MiningManiaBonusCarView:onExit()
    MiningManiaBonusCarView.super.onExit(self)
    self:clearRewardNode()
end

function MiningManiaBonusCarView:clearRewardNode()
    if self.m_scSecondScheduleNode ~= nil then
        self.m_scSecondScheduleNode:unscheduleUpdate()
    end
    if self.m_scMoveScheduleNode ~= nil then
        self.m_scMoveScheduleNode:unscheduleUpdate()
    end
end

function MiningManiaBonusCarView:resetData(_resultData, _bonusCallFunc)
    self.m_result = _resultData
    self.m_endFunc = _bonusCallFunc
    local roadTimes = _resultData.data.secondRndLineNum or {}
    self.m_allRewardData = {}
    -- 实际算出的时间-- 根据速度和总长度获取时间；不用服务器给的时间；因为要调速度；只要保证在时间停止时奖励领完即可
    self.m_initRoadTimeTbl = {}
    if self.m_scSecondScheduleNode ~= nil then
        self.m_scSecondScheduleNode:unscheduleUpdate()
    end
    if self.m_scMoveScheduleNode ~= nil then
        self.m_scMoveScheduleNode:unscheduleUpdate()
    end
    self.m_seatNodeParent:setVisible(true)
    -- 第一阶段小车移动的距离
    self.m_firstPosY = 0
    -- 第二阶段小车移动的间隔距离
    self.m_secondPosY = 0
    -- 拉镜头移动的距离
    self.m_midMovePosX = 0
    -- 当前移动的总长度
    self.m_curMoveTotalDis = 0
    -- 自己的排名
    self.m_myRank = 5
    -- 第一阶段状态
    self.m_firstState = false
    -- 第二阶段状态
    self.m_secondState = false
    for i=1, 3 do
        self.m_initRoadTimeTbl[i] = roadTimes[i]
        self.m_carAniTbl[i]:resetData()
        self.m_carAniTbl[i]:setVisible(true)
        self.m_gateAniTbl[i]:resetData()
        self.m_timeNodeTbl[i]:setVisible(false)
        self.m_endTipAniTbl[i]:resetData()
        self.m_carNodeTbl[i]:setPositionX(-800)
    end
    self.m_rewardNode:setPositionX(0)
    for i=1, 2 do
        self.m_moveNodeTbl[i]:setPositionX(0)
    end
    self.m_moveCarNode:setPositionX(0)
    self.m_moveArrowNode:setPositionX(-400)
    self.m_moveRoadNode:setPositionX(0)
    self.m_rewardMaxLen = 0
    -- 结束状态标志（时间走完后，不再一直获取）
    self.m_curRowOverStateTbl = {}
    -- 时间结束后；小车node移动距离
    self.m_carNodeMoveDis = -400
    -- 最后两秒；小车移动加速度总位移
    self.m_carNodeSpeedMoveTbl = {0, 0 ,0}
    -- 内存池（小块奖励）
    self.m_rewardNodePool = {}
    -- 预创建
    self:perLoadRewardNodes()

    self:creatRewardData()
    self:addFalseRewardData()
    self:refreshCollectScore()
    self.m_curIndex = 0
    self:refreshChairs()
    
    for i=1, 3 do
        -- 为了最后减速状态；+1s；1s减速过程
        self.m_initRoadTimeTbl[i] = self.m_initRoadTimeTbl[i] + self.m_reduceSpeedTime
        -- 重置
        self.m_timeNodeTbl[i]:resetData()
        self.m_timeNodeTbl[i]:addTimes(self.m_initRoadTimeTbl[i], true)
        if self:curRowIsHaveMe(i) then
            self.m_timeNodeTbl[i]:setTextVisibleState(true)
        end
    end
    
    self:setBgPos()
    self:addHeadToCar()
    self:createRewardNode(0)
end

function MiningManiaBonusCarView:showNodeBg(_isState)
    self.m_midBgNode:setVisible(_isState)
    self.m_midUpBgNode:setVisible(_isState)
    self.m_midTopBgNode:setVisible(_isState)
    self.m_midBottomBgNode:setVisible(_isState)
    for i=1, 3 do
        self.m_roadNodeTbl[i]:setVisible(_isState)
    end
end

-- 动态创建背景长度
function MiningManiaBonusCarView:createBg()
    -- 添加两个背景；来回切换
    self.m_midBgTbl = {}
    self.m_midUpTbl = {}
    self.m_midTopTbl = {}
    self.m_midBottomTbl = {}
    for i=1, 2 do
        self.m_midBgTbl[i] = util_createAnimation("MiningMania_Bonus_Bg.csb")
        self.m_midBgNode:addChild(self.m_midBgTbl[i])
        self.m_midBgTbl[i]:setPositionX((i-1)*self.m_bgMidLen)
        
        -- 添加中间背景上层
        self.m_midUpTbl[i] = util_createAnimation("MiningMania_Bonus_Bg_Up.csb")
        self.m_midUpBgNode:addChild(self.m_midUpTbl[i])
        self.m_midUpTbl[i]:setPositionX((i-1)*self.m_bgMidUpLen)

        -- 添加顶部背景
        self.m_midTopTbl[i] = util_createAnimation("MiningMania_Bonus_Bg_Top.csb")
        self.m_midTopBgNode:addChild(self.m_midTopTbl[i])
        self.m_midTopTbl[i]:setPositionX((i-1)*self.m_bgMidTopLen)

        -- 添加底部背景
        self.m_midBottomTbl[i] = util_createAnimation("MiningMania_Bonus_Bg_Bottom.csb")
        self.m_midBottomBgNode:addChild(self.m_midBottomTbl[i])
        self.m_midBottomTbl[i]:setPositionX((i-1)*self.m_bgMidBottomLen)
    end

    -- 添加轨道
    self.m_roadTbl = {}
    for i=1, 3 do
        local tempTbl = {}
        for j=1, 2 do
            tempTbl[j] = util_createAnimation("MiningMania_Shejiao2_Guidao.csb")
            self.m_roadNodeTbl[i]:addChild(tempTbl[j])
            tempTbl[j]:setPositionX((j-1)*self.m_roalLen)
        end
        self.m_roadTbl[i] = tempTbl
    end
end

-- 重置设置背景位置
function MiningManiaBonusCarView:setBgPos()
    self:showNodeBg(true)
    for i=1, 2 do
        self.m_midBgTbl[i]:setPositionX((i-1)*self.m_bgMidLen)
        
        self.m_midUpTbl[i]:setPositionX((i-1)*self.m_bgMidUpLen)

        self.m_midTopTbl[i]:setPositionX((i-1)*self.m_bgMidTopLen)

        self.m_midBottomTbl[i]:setPositionX((i-1)*self.m_bgMidBottomLen)
    end

    for i=1, #self.m_roadTbl do
        local tempTbl = self.m_roadTbl[i]
        for j=1, 2 do
            tempTbl[j]:setPositionX((j-1)*self.m_roalLen)
        end
    end
end

-- 创建小车上对应的头像
function MiningManiaBonusCarView:addHeadToCar()
    local playerData = self:getRopadCarRankData()
    -- 自己+箭头
    self.arrowAni = {}
    for i=1, 5 do
        local curRow = self:getCurRankToRow(i)
        self.m_carAniTbl[curRow]:addHead(playerData[i].p_item, i)

        self.m_arrowNodeTbl[i]:removeAllChildren()
        if i == self.m_myRank then
            self.arrowAni = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarArrow")
            self.m_arrowNodeTbl[i]:addChild(self.arrowAni)
        end
    end

    -- 自己车上的光
    for i=1, 3 do
        self.m_carAniTbl[i]:showLigth(false)
        if self:curRowIsHaveMe(i) then
            self.m_carAniTbl[i]:showLigth(true)
        end
    end
end

-- 初始化三条轨道上的奖励
function MiningManiaBonusCarView:creatRewardData()
    local secondRndLine = self.m_result.data.secondRndLine
    for i=1, 3 do
        if not self.m_allRewardData[i] then
            self.m_allRewardData[i] = {}
        end
        
        local oneLine = secondRndLine[i]
        local lineLen = #oneLine
        self.m_rewardMaxLen = util_max(self.m_rewardMaxLen, lineLen)
        -- 算总时间
        self.m_initRoadTimeTbl[i] = lineLen * self.m_intervalDis / self.m_moveDis

        for k, v in pairs(oneLine) do
            local posX = (k-1)*self.m_intervalDis+100
            local tempTbl = {}
            local rewardType = v[1]
            local rewardMul = v[2]
            tempTbl.p_rewardType = rewardType
            tempTbl.p_rewardMul = rewardMul
            if self:curSymbolIsBonus(rewardType) then
                tempTbl.p_bonus = true
            elseif rewardType == self.SYMBOL_SCORE_BONUS_9 then
                tempTbl.p_times = true
                -- 算出时间类型占用的时间
                local rewardTime = rewardMul/lineLen*self.m_initRoadTimeTbl[i]
                self.m_initRoadTimeTbl[i] = self.m_initRoadTimeTbl[i] - rewardTime
                tempTbl.p_rewardMul = rewardTime
            end
            tempTbl.p_posX = posX
            table.insert(self.m_allRewardData[i], tempTbl)
        end
    end
end

-- 最大轨道再添加五个奖励；其他两个轨道跟最大轨道持平（假的；最后显示作用）
function MiningManiaBonusCarView:addFalseRewardData()
    local maxRoadRewadLen = self.m_rewardMaxLen + 5
    for i=1, 3 do
        local roadRewardData = self.m_allRewardData[i]
        local falseCount = 0
        for j=1, maxRoadRewadLen do
            if not roadRewardData[j] then
                roadRewardData[j] = {}
                local posX = (j-1)*self.m_intervalDis + self.m_intervalDis
                local rewardType, rewardMul = self:getRandomReward()
                -- 假的第一个和第二个必须为空；因为减速原因
                if falseCount < 2 then
                    roadRewardData[j].p_rewardType = self.SYMBOL_SCORE_BONUS_NULL
                    falseCount = falseCount + 1
                else
                    roadRewardData[j].p_rewardType = rewardType
                end
                roadRewardData[j].p_rewardMul = rewardMul
                roadRewardData[j].p_posX = posX
            end
        end
    end
end

-- 获取随机奖励
function MiningManiaBonusCarView:getRandomReward()
    local totalWeight = 20
    local randomTypeData = {121, 122, 123, 124, 125}
    local randomRewardData = {30, 50, 75, 200, 5}
    local randomNum = math.random(1, totalWeight)
    if randomNum > #randomTypeData then
        return self.SYMBOL_SCORE_BONUS_NULL, 0
    end
    return randomTypeData[randomNum], randomRewardData[randomNum]
end

-- 动态创建轨道上的奖励节点
function MiningManiaBonusCarView:createRewardNode(_nowDiffPosX)
    -- 背景；+1000是因为节点相对位置(考虑背景长度；最大长度为屏幕2000)
    local nowDiffPosX = _nowDiffPosX + 1000
    for i=1, 3 do
        local oneRewardData = self.m_allRewardData[i]
        for k, v in pairs(oneRewardData) do
            if not v.p_create and v.p_posX <= nowDiffPosX then
                local rewardType = v.p_rewardType
                local rewardMul = v.p_rewardMul
                local rewardNode = self:getRewardNodeByType(rewardType, rewardMul)
                v.p_create = true
                if rewardNode then
                    v.p_rewardNode = rewardNode
                    rewardNode:setPosition(cc.p(v.p_posX, self.m_rewardPosYTbl[i]))
                end
            end
        end
    end
end

-- 超过屏幕的奖励移除
function MiningManiaBonusCarView:removeOutOfScreenRewardNode(_nowDiffPosX)
    local allRewardNode = self.m_rewardNode:getChildren()
    -- 根据位置判断当前奖励是否超出屏幕
    if allRewardNode and #allRewardNode > 0 then
        local nowDiffPosX = _nowDiffPosX - 1000
        for k, _rewardNode in pairs(allRewardNode) do
            local posX = _rewardNode:getPositionX()
            if not _rewardNode:getRecycleState() and posX < nowDiffPosX then
                _rewardNode:setRecycleState(true)
                self:pushRewardNodeToPool(_rewardNode)
            end
        end
    end
end

-- 创建轨道上的动画
function MiningManiaBonusCarView:createMiningManiaCarSymbol()
    local symbol = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarSymbol", self)
    return symbol
end

-- 预创建10个小块
function MiningManiaBonusCarView:perLoadRewardNodes()
    self.m_rewardNode:removeAllChildren()
    for i = 1, 10 do
        local node = self:createMiningManiaCarSymbol()

        self.m_rewardNodePool[#self.m_rewardNodePool + 1] = node
        self.m_rewardNode:addChild(node)
        node:setRecycleState(false)
        node:setPositionX(100000)
        node:setVisible(false)
    end
end

-- 放进缓存池
function MiningManiaBonusCarView:pushRewardNodeToPool(node)
    self.m_rewardNodePool[#self.m_rewardNodePool + 1] = node
    node:reset()
    node:stopAllActions()
    node:setVisible(false)
end

-- 根据奖励类型获取对应节点
function MiningManiaBonusCarView:getRewardNodeByType(_symbolType, _reward)
    if _symbolType == self.SYMBOL_SCORE_BONUS_NULL then
        return nil
    end

    local rewardNode = nil
    if #self.m_rewardNodePool == 0 then
        local node = self:createMiningManiaCarSymbol()
        rewardNode = node
        self.m_rewardNode:addChild(node)
    else
        local node = self.m_rewardNodePool[1] -- 存内存池取出来
        table.remove(self.m_rewardNodePool, 1)
        rewardNode = node
    end
    rewardNode:changeSymbolCcb(_symbolType, _reward)
    rewardNode:setVisible(true)
    rewardNode:setRecycleState(false)
    rewardNode:setPositionX(100000)
    return rewardNode
end

-- 小车声音轨道
function MiningManiaBonusCarView:playMoveCarSound()
    if not self.m_carSoundsId then
        self.m_carSoundsId = gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_Move, true)
    end
end

function MiningManiaBonusCarView:stopPlayCarSound()
    if self.m_carSoundsId then
        gLobalSoundManager:stopAudio(self.m_carSoundsId)
        self.m_carSoundsId = nil
    end
end

-- 倒计时
function MiningManiaBonusCarView:playEndTimeSound()
    if not self.m_endTimeSoundsId then
        self.m_endTimeSoundsId = gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_EndTime, true)
    end
end

function MiningManiaBonusCarView:stopPlayEndTimeSound()
    if self.m_endTimeSoundsId then
        gLobalSoundManager:stopAudio(self.m_endTimeSoundsId)
        self.m_endTimeSoundsId = nil
    end
end

function MiningManiaBonusCarView:showBonusView()
    self:runCsbAction("idle", true)
    self:carSequenceAppear()
end

-- 小车依次从矿洞出现
function MiningManiaBonusCarView:carSequenceAppear()
    local endPosTbl = {cc.p(-400, 185), cc.p(-400, -31), cc.p(-400, -249)}
    
    gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_CarOut)
    for i=1, 3 do
        self.m_carAniTbl[i]:startMoveAni()
        local tblActionList = {}
        local intervalTime = 0.4
        local delayTime = (i-1)*intervalTime
        tblActionList[#tblActionList+1] = cc.DelayTime:create(delayTime)
        tblActionList[#tblActionList+1] = cc.MoveTo:create(intervalTime, endPosTbl[i])
        tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
            self.m_carAniTbl[i]:setIdle()
            if i == 3 then
                self:playReadyGoAni()
            end
        end)
        local seq = cc.Sequence:create(tblActionList)
        self.m_carNodeTbl[i]:runAction(seq)

        -- 箭头移动
        if self:curRowIsHaveMe(i) then
            local actList = {}
            actList[#actList+1] = cc.DelayTime:create(delayTime)
            actList[#actList+1] = cc.MoveTo:create(intervalTime, cc.p(0, 0))
            actList[#actList+1] = cc.CallFunc:create(function()
                if self.arrowAni then
                    self.arrowAni:startAni()
                end
            end)
            local seq = cc.Sequence:create(actList)
            self.m_moveArrowNode:runAction(seq)
        end
    end
end

-- readyGo
function MiningManiaBonusCarView:playReadyGoAni()
    -- 箭头出来延时；再readyGo
    performWithDelay(self.m_scWaitNode, function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_ReadyGo)
        self.m_readyGoAni:setVisible(true)
        self.m_readyGoAni:runCsbAction("actionframe", false, function()
            self.m_readyGoAni:setVisible(false)
            self:startGateAni()
        end)
    end, 1.0)
end

-- 播闸机动画
function MiningManiaBonusCarView:startGateAni()
    local isRun = true
    local endCallFunc = function()
        if isRun then
            for i=1, 3 do
                self.m_carAniTbl[i]:startMoveAni()
                self.m_timeNodeTbl[i]:setVisible(true)
                self.m_timeNodeTbl[i]:startAni()
            end
            self:startMoveRoad()
        end
    end
    gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_Gate)
    for i=1, 3 do
        self.m_gateAniTbl[i]:playStart(endCallFunc)
    end
end

function MiningManiaBonusCarView:startMoveRoad()
    if self.m_scSecondScheduleNode ~= nil then
        self:playMoveCarSound()
        self.m_scSecondScheduleNode:onUpdate(
            function(delayTime)
                self:secondMoveRoad(delayTime)
            end
        )
    end
end

-- 第二阶段；移动路线和背景
function MiningManiaBonusCarView:secondMoveRoad(_delayTime)
    local delayTime = _delayTime
    -- 每帧移动的距离
    local diffMove = self.m_moveDis*delayTime
    self.m_secondPosY = self.m_secondPosY + diffMove
    self.m_curMoveTotalDis = self.m_curMoveTotalDis + diffMove

    self.m_firstPosY = self.m_firstPosY + diffMove
    -- 第一段距离长度是小车到中心点的位置：X:400(这里知道坐标，直接使用)
    local totaleLen = 400
    -- 第一阶段判断距离（到达中心点）
    if self.m_firstPosY < totaleLen then
        if self.m_firstPosY >= (self.m_intervalDis-diffMove) and not self.m_firstState then
            self.m_firstState = true
            self:collectReward()
        end
        self.m_moveCarNode:setPositionX(self.m_firstPosY)
        self.m_moveArrowNode:setPositionX(self.m_firstPosY)
    else
        if not self.m_secondState then
            self.m_secondPosY = diffMove
            self.m_curMoveTotalDis = diffMove
            self.m_moveCarNode:setPositionX(totaleLen)
            self.m_moveArrowNode:setPositionX(totaleLen)
            self:collectReward()
            self.m_secondState = true
        end
        -- 第二阶段
        local curMaxTime = self:getRoadMaxTime()
        if curMaxTime > 0 then
            for i=1, 2 do
                self.m_moveNodeTbl[i]:setPositionX(-self.m_curMoveTotalDis)
            end
            self.m_moveRoadNode:setPositionX(-self.m_curMoveTotalDis)
            self:addBgAndOther(self.m_curMoveTotalDis)
            self:createRewardNode(self.m_curMoveTotalDis)
            self:removeOutOfScreenRewardNode(self.m_curMoveTotalDis)
            self:addFrameTime(delayTime, diffMove)
            if self.m_secondPosY >= (self.m_intervalDis-diffMove) then
                self.m_secondPosY = self.m_secondPosY - self.m_intervalDis
                self:collectReward()
            end
        else
            self:stopPlayCarSound()
            self:stopPlayEndTimeSound()
            if self.m_scSecondScheduleNode ~= nil then
                self.m_scSecondScheduleNode:unscheduleUpdate()
            end
            performWithDelay(self.m_scWaitNode, function()
                self:showGameOverDialog()
            end, 2.0)
        end
    end
end

-- 触发奖励
function MiningManiaBonusCarView:collectReward()
    for i=1, 3 do
        local rewardInfo = self.m_allRewardData[i][self.m_curIndex]
        if rewardInfo then 
            local curMul = rewardInfo.p_rewardMul
            if rewardInfo.p_bonus then
                self.m_carAniTbl[i]:setMul(curMul)
                if self:curRowIsHaveMe(i) then
                    self.m_carAniTbl[i]:playTriggerAni(true)
                    rewardInfo.p_rewardNode:runAnim(true)
                    if rewardInfo.p_rewardType == self.SYMBOL_SCORE_BONUS_8 then
                        self:collectBigReward(1, curMul, i)
                    end
                else
                    self.m_carAniTbl[i]:playTriggerAni()
                    rewardInfo.p_rewardNode:runAnim(false)
                end
            elseif rewardInfo.p_times then
                if self:curRowIsHaveMe(i) then
                    self.m_carAniTbl[i]:playTriggerAni(true)
                    rewardInfo.p_rewardNode:runAnim(true)
                    self.m_timeNodeTbl[i]:addTimes(curMul, false, true)
                    local curMul = math.round(curMul)
                    self:collectBigReward(2, curMul, i)
                else
                    self.m_carAniTbl[i]:playTriggerAni()
                    rewardInfo.p_rewardNode:runAnim(false)
                    self.m_timeNodeTbl[i]:addTimes(curMul)
                end
            end
        end

        -- 判断下一个是否是大奖励；大奖励的话速度减慢；拉镜头
        local nextRewardInfo = self.m_allRewardData[i][self.m_curIndex+1]
        if self:curRowIsHaveMe(i) and nextRewardInfo and nextRewardInfo.p_bonus and nextRewardInfo.p_rewardType == self.SYMBOL_SCORE_BONUS_8 then
            self:startMoveMidNode(i)
        end
    end
    self.m_curIndex = self.m_curIndex + 1
end

-- 拉镜头
function MiningManiaBonusCarView:startMoveMidNode(_index)
    if self.m_scSecondScheduleNode ~= nil then
        self.m_scSecondScheduleNode:unscheduleUpdate()
    end
    local index = _index
    local targetNode = self.m_carNodeTbl[index]
    local moveNode = self:findChild("Node_3")
    local parentNode = moveNode:getParent()
    
    local params = {
        moveNode = moveNode,--要移动节点
        targetNode = targetNode,--目标位置节点
        parentNode = parentNode,--移动节点的父节点
        time = 1.5,--移动时间
        actionType = 3,
        scale = 2,--缩放倍数
        func = function()
            self:resetMoveNodeStatus()
        end
    }

    gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_MidNode)
    util_moveRootNodeAction(params)
    self.m_midMovePosX = 0

    if self.m_scMoveScheduleNode ~= nil then
        self.m_scMoveScheduleNode:onUpdate(
            function(delayTime)
                self:moveMidNode(delayTime)
            end
        )
    end
end

-- 拉镜头刷帧
function MiningManiaBonusCarView:moveMidNode(_delayTime)
    local delayTime = _delayTime
    -- 每帧移动的距离
    -- local diffMove = self.m_moveDis*delayTime
    local diffMove = self.m_intervalDis/2*delayTime
    if self.m_secondState then
        self.m_curMoveTotalDis = self.m_curMoveTotalDis + diffMove
        self.m_midMovePosX = self.m_midMovePosX + diffMove
        if self.m_midMovePosX < self.m_intervalDis then
            for i=1, 2 do
                self.m_moveNodeTbl[i]:setPositionX(-self.m_curMoveTotalDis)
            end
            self.m_moveRoadNode:setPositionX(-self.m_curMoveTotalDis)
        else
            -- 用的总共时间
            local totalTime = self.m_intervalDis / self.m_moveDis
            self:addFrameTime(totalTime, diffMove)
            self.m_secondPosY = self.m_secondPosY + self.m_intervalDis
            self:startMoveRoad()
            if self.m_scMoveScheduleNode ~= nil then
                self.m_scMoveScheduleNode:unscheduleUpdate()
            end
        end
    else
        self.m_firstPosY = self.m_firstPosY + diffMove
        self.m_midMovePosX = self.m_midMovePosX + diffMove

        if self.m_midMovePosX < self.m_intervalDis then
            self.m_moveCarNode:setPositionX(self.m_firstPosY)
            self.m_moveArrowNode:setPositionX(self.m_firstPosY)
        else
            -- 用的总共时间
            self.m_firstPosY = self.m_firstPosY + self.m_intervalDis
            self:startMoveRoad()
            if self.m_scMoveScheduleNode ~= nil then
                self.m_scMoveScheduleNode:unscheduleUpdate()
            end
        end
    end
end

--[[
    重置移动节点状态
]]
function MiningManiaBonusCarView:resetMoveNodeStatus()
    local moveNode = self:findChild("Node_3")
    --恢复移动节点状态
    local spawn = cc.Spawn:create({
        cc.MoveTo:create(0.5,cc.p(0,0)),
        cc.ScaleTo:create(0.5,1)
    })
    moveNode:stopAllActions()
    moveNode:runAction(cc.EaseSineInOut:create(spawn))
end

-- 动态添加背景和其他饰件
function MiningManiaBonusCarView:addBgAndOther(_nowDiffPosX)
    -- 背景；-100是因为节点相对位置
    local nowDiffPosX_mid = _nowDiffPosX - self.m_bgMidLen/2 - 100
    -- 中间上层饰件；-100是因为节点相对位置
    local nowDiffPosX_up = _nowDiffPosX - self.m_bgMidUpLen/2 - 100
    -- 顶部饰件；+30相对节点位置
    local nowDiffPosX_top = _nowDiffPosX - self.m_bgMidTopLen/2 + 30
    -- 底部饰件；+60相对节点位置
    local nowDiffPosX_bottom = _nowDiffPosX - self.m_bgMidBottomLen/2 + 60

    for i=1, 2 do
        local m_bg_mid = self.m_midBgTbl[i]
        local m_posX = m_bg_mid:getPositionX()
        if nowDiffPosX_mid - m_posX > self.m_bgMidLen then
            m_bg_mid:setPositionX(m_posX+self.m_bgMidLen*2)
        end

        local m_bg_up = self.m_midUpTbl[i]
        local m_posX = m_bg_up:getPositionX()
        if nowDiffPosX_up - m_posX > self.m_bgMidUpLen then
            m_bg_up:setPositionX(m_posX+self.m_bgMidUpLen*2)
        end

        local m_bg_top = self.m_midTopTbl[i]
        local m_posX = m_bg_top:getPositionX()
        if nowDiffPosX_top - m_posX > self.m_bgMidTopLen then
            m_bg_top:setPositionX(m_posX+self.m_bgMidTopLen*2)
        end

        local m_bg_bottom = self.m_midBottomTbl[i]
        local m_posX = m_bg_bottom:getPositionX()
        if nowDiffPosX_bottom - m_posX > self.m_bgMidBottomLen then
            m_bg_bottom:setPositionX(m_posX+self.m_bgMidBottomLen*2)
        end
    end

    -- 轨道；+364相对节点位置
    local nowDiffPosX_road = _nowDiffPosX - self.m_bgMidLen/2 + 364
    for i=1, 3 do
        local roadTbl = self.m_roadTbl[i]
        for j=1, 2 do
            local m_road = roadTbl[j]
            local m_posX = m_road:getPositionX()
            if nowDiffPosX_road - m_posX > self.m_roalLen then
                m_road:setPositionX(m_posX+self.m_roalLen*2)
            end
        end
    end
end

-- 获取大钻石（黄色）;时间
function MiningManiaBonusCarView:collectBigReward(_rewardType, _curMul, _selfRow)
    local rewardType = _rewardType
    local curMul = _curMul
    local selfRow = _selfRow
    self.m_effectNode:removeAllChildren()
    if self.m_scSecondScheduleNode ~= nil then
        self.m_scSecondScheduleNode:unscheduleUpdate()
    end
    
    for i=1, 3 do
        self.m_timeNodeTbl[i]:pauseAction()
    end
    self:stopPlayCarSound()
    -- 粒子打打到时间上
    local endCallFunc = function()
        if rewardType == 1 then
            for i=1, 3 do
                self.m_timeNodeTbl[i]:resumeAction()
            end
            self:startMoveRoad()
        else
            self:flyTimeParticle(selfRow)
        end
    end
    -- 小车触发播完后出弹板
    performWithDelay(self.m_scWaitNode, function()
        local rewardWinView = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarGotReward", rewardType)
        self:addChild(rewardWinView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
        local tempTbl = {}
        tempTbl.p_mul = curMul
        tempTbl.p_callFunc = endCallFunc
        rewardWinView:initViewData(tempTbl)
    end, 35/60)
end

-- 时间奖励飞粒子
function MiningManiaBonusCarView:flyTimeParticle(_selfRow)
    local selfRow = _selfRow
    local particleNode = util_createAnimation("MiningMania_time_tuowei.csb")
    local m_particleTbl = {}
    for i=1, 2 do
        m_particleTbl[i] = particleNode:findChild("Particle_"..i)
        m_particleTbl[i]:setPositionType(0)
        m_particleTbl[i]:setDuration(-1)
        m_particleTbl[i]:resetSystem()
    end

    local startPos = cc.p(0, 0)
    local endPos = util_convertToNodeSpace(self:findChild("Node_time"..selfRow), self.m_effectNode)
    particleNode:setPosition(startPos)
    self.m_effectNode:addChild(particleNode)

    local tblActionList = {}
    local delayTime = 0.4
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_AddTime)
        self:stopPlayEndTimeSound()
        for i=1, 3 do
            self.m_timeNodeTbl[i]:resumeAction()
        end
        self:startMoveRoad()
    end)
    tblActionList[#tblActionList + 1] = cc.MoveTo:create(delayTime, endPos)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        for i=1, 2 do
            m_particleTbl[i]:stopSystem()
        end
        self.m_timeNodeTbl[selfRow]:addTimesRefresh(true)
    end)
    tblActionList[#tblActionList + 1] = cc.DelayTime:create(delayTime)
    tblActionList[#tblActionList + 1] = cc.CallFunc:create(function()
        particleNode:removeFromParent()
    end)

    particleNode:runAction(cc.Sequence:create(tblActionList))
end

-- 根据排名返回当前所在的行
function MiningManiaBonusCarView:getCurRankToRow(_curRank)
    local curRank = _curRank
    if curRank >= 4 and curRank <= 5 then
        return 3
    elseif curRank >= 2 and curRank <= 3 then
        return 2
    else
        return 1
    end
end

-- 判断当前行是否有自己
function MiningManiaBonusCarView:curRowIsHaveMe(_curRow)
    local curRow = _curRow
    local myRow = nil
    if self.m_myRank == 5 or self.m_myRank == 4 then
        myRow = 3
    elseif self.m_myRank == 3 or self.m_myRank == 2 then
        myRow = 2
    else
        myRow = 1
    end
    if myRow and myRow == curRow then
        return true
    end
    return false
end

-- 获取三行对应的倍数
function MiningManiaBonusCarView:getCurRowRewardMul(_index)
    local secondUserMul = clone(self.m_result.data.secondRndUserMultiple)
    table.sort(secondUserMul)
    if _index == 1 then
        return secondUserMul[1]
    elseif _index == 2 then

    elseif _index == 3 then

    end
    return 0
end

-- 三条轨道设置时间；用来总时间减少
function MiningManiaBonusCarView:addFrameTime(_intervalTime, _diffMove)
    -- 不再同一帧播放同样的音效
    local isPlay = true
    for i=1, 3 do
        self.m_timeNodeTbl[i]:addFrameTime(_intervalTime)
        self.m_timeNodeTbl[i]:addTimes(-_intervalTime)

        -- 剩余时间
        local curCarTime = self.m_timeNodeTbl[i]:getTimes()

        -- 小于1s时；减速
        if curCarTime > 0 then
            if curCarTime <= 3 and self:curRowIsHaveMe(i) then
                self:playEndTimeSound()
            end
            if curCarTime <= self.m_reduceSpeedTime then
                -- 加速度公式算出位移 S=vt-（at^2）/2
                local totalDiffMove = 300 / 2 * math.pow((self.m_reduceSpeedTime - curCarTime), 2)
                self.m_carNodeSpeedMoveTbl[i] = self.m_carNodeMoveDis - totalDiffMove
                self.m_carNodeTbl[i]:setPositionX(self.m_carNodeSpeedMoveTbl[i])

                self.m_carAniTbl[i]:reduceSpeedMove()

                -- 箭头移动
                if self:curRowIsHaveMe(i) then
                    self.m_moveArrowNode:setPositionX(self.m_carNodeSpeedMoveTbl[i]+800)
                end
            end
        else
            self.m_carNodeSpeedMoveTbl[i] = self.m_carNodeSpeedMoveTbl[i] - _diffMove
            self.m_carNodeTbl[i]:setPositionX(self.m_carNodeSpeedMoveTbl[i])
            -- 箭头移动
            if self:curRowIsHaveMe(i) then
                self.m_moveArrowNode:setPositionX(self.m_carNodeSpeedMoveTbl[i]+800)
            end
            if not self.m_curRowOverStateTbl[i] then
                self.m_curRowOverStateTbl[i] = true
                self.m_carAniTbl[i]:setIdle()
                local curRowMul = self.m_carAniTbl[i]:getMul()
                if self:curRowIsHaveMe(i) then
                    self:stopPlayEndTimeSound()
                    if isPlay then
                        self.m_endTipAniTbl[i]:startAni(curRowMul, true)
                        isPlay = false
                    end
                    if self.arrowAni then
                        self.arrowAni:overAni()
                    end
                else
                    if isPlay then
                        self.m_endTipAniTbl[i]:startAni(curRowMul, false)
                        isPlay = false
                    end
                end
            end
        end
    end
end

-- 获取三条轨道最大时间；通过最大时间判断是否停止；结束
function MiningManiaBonusCarView:getRoadMaxTime()
    local maxTime = 0
    for i=1, 3 do
        local curTime = self.m_timeNodeTbl[i]:getTimes()
        maxTime = util_max(maxTime, curTime)
    end
    return maxTime
end

--[[
    刷新座位
]]
function MiningManiaBonusCarView:refreshChairs()
    local playersInfo, mulDataTemp = self:getUserData()

    for index = 1, 5 do
        local info = playersInfo[index]
        local item = self.m_playerItems[index]
        local mul = mulDataTemp[index]
        item:refreshMulData(0)
        item:refreshUserMul(mul)
        if info then
            item:setVisible(true)
            item:runCsbAction("start", false, function()
                item:runCsbAction("idle", true)
            end)
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)
            --刷新头像
            if udid ~= info.udid then
                item:refreshHead()
            end

            if info.udid and info.udid ~= "" then
                --刷新头像
                if udid ~= info.udid  then
                    item:refreshHead()
                end
            else
                -- 刷新机器人头像
                if robot and robot ~= info.robot  then
                    item:refreshHead()
                end
            end
        else
            item:refreshData(nil)
            item:setVisible(false)
        end
        -- 自己排名的标识
        if item:isMySelf() then
            self.m_myRank = index
        end
    end
end

-- 获取社交2底部用户数据
function MiningManiaBonusCarView:getUserData()
    -- 头像；排名；倍数
    local playersInfoTemp = {}
    local mulDataTemp = {}

    local playersInfo = self.m_result.data.sets or {}
    local firstRndChairRank = self.m_result.data.firstRndChairRank or {}
    local firMulData = self.m_result.data.firstRndUserMultiple or {}

    -- 排名
    for index = 1, 5 do
        local info = playersInfo[index]
        for j = 1, #firstRndChairRank do
            local chairId = firstRndChairRank[j]
            if info.chairId == chairId then
                playersInfoTemp[j] = info
                mulDataTemp[j] = firMulData[index] or 0
                break
            end
        end
    end

    return playersInfoTemp, mulDataTemp
end

-- 获取小车上的头像数据
function MiningManiaBonusCarView:getRopadCarRankData()
    -- 头像；排名
    local playDataTbl = {}

    local playersInfo = self.m_result.data.sets or {}
    local firstRndChairRank = self.m_result.data.firstRndChairRank or {}
    local firMulData = self.m_result.data.firstRndUserMultiple or {}
    for index = 1, 5 do
        local tempTbl = {}
        local info = playersInfo[index]
        local item = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarPlayerItem")
        tempTbl.p_item = item

        -- 排名
        for j = 1, #firstRndChairRank do
            local chairId = firstRndChairRank[j]
            if info.chairId == chairId then
                tempTbl.p_rank = j
                break
            end
        end

        if info then
            item:setNodeVisible()
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)
            --刷新头像
            if info.udid and info.udid ~= "" then
                item:refreshHead()
            else
                -- 刷新机器人头像
                if robot and robot ~= info.robot  then
                    item:refreshHead()
                end
            end
        else
            item:refreshData(nil)
            item:setVisible(false)
        end
        table.insert(playDataTbl, tempTbl)
    end

    -- 按排名进去排序
    table.sort(playDataTbl, function(a, b)
        if a.p_rank ~= b.p_rank then
            return a.p_rank < b.p_rank
        end
        return false
    end)

    return playDataTbl
end

-- 更新base收集分数
function MiningManiaBonusCarView:refreshCollectScore()
    local userScore = self:getUserBaseScore()
    
    local strCoins = util_formatCoins(userScore,50)
    self.m_collectText:setString(strCoins)
    self:updateLabelSize({label=self.m_collectText,sx=0.96,sy=0.96},227)
end

function MiningManiaBonusCarView:getUserBaseScore()
    local userScoreData = self.m_result.data.userScore
    local uuid = globalData.userRunData.userUdid
    local userScore = userScoreData[uuid]
    return userScore
end

function MiningManiaBonusCarView:curSymbolIsBonus(_symbolType)
    if _symbolType == self.SYMBOL_SCORE_BONUS_5
        or _symbolType == self.SYMBOL_SCORE_BONUS_6
        or _symbolType == self.SYMBOL_SCORE_BONUS_7
        or _symbolType == self.SYMBOL_SCORE_BONUS_8 then
            return true
    end
    return false
end

-- 社交2结束弹板
function MiningManiaBonusCarView:showGameOverDialog()
    -- 获取弹板数据
    local userDataFirst = self:getDialogUserData(nil, true)
    local endCallFunc = function(view)
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_OverDialog)
        if not tolua.isnull(view) then
            view:runCsbAction("over", false, function()
                self:showGameOverRankDialog()
                view:removeFromParent()
            end)
        end
    end
    gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_OverStartDialog)
    local view = self.m_machine:showDialog("SheJiaoOver2", nil, nil)
    view.isShowOver = true
    view:findChild("root"):setScale(self.m_bonusRootSccale)
    self.m_seatNodeParent:setVisible(false)
    -- local startTime = view:getAnimTime("start")
    local actTime1 = view:getAnimTime("actionframe1")

    for i=1, 5 do
        local item = userDataFirst[i].p_item
        local mul = userDataFirst[i].p_firstMul
        local roleNode = view:findChild("Node_role_"..i)
        roleNode:addChild(item)
        item:findChild("m_lb_num"):setString("X"..mul)
    end

    -- 显示小车
    local carAniData = self:getDialogCarData()
    for i=1, 3 do
        local carAni = carAniData[i]
        view:findChild("Node_Car_"..i):addChild(carAni)
    end
    
    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.DelayTime:create(50/60)
    -- 弹板小车出来
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_dialogCarAppear)
        if not tolua.isnull(view) then
            view:runCsbAction("actionframe1", false)
        end
        for i = 1, 3 do
            local carAni = carAniData[i]
            if not tolua.isnull(carAni) and carAni.startMoveAni then
                carAni:startMoveAni()
            end
        end
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(actTime1)
    -- 弹板idle；小车fly
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if not tolua.isnull(view) then
            view:runCsbAction("idle2", true)
        end
        for i = 1, 3 do
            local carAni = carAniData[i]
            carAni:playTriggerAni(true)
        end
    end)
    -- 延时12帧+0.5（要求）
    tblActionList[#tblActionList+1] = cc.DelayTime:create(42/60)
    -- 倍数字体开始飞
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_dialogMulFly)
        self:dialogStartFlyNode(view, userDataFirst)
    end)
    -- 延时24帧
    tblActionList[#tblActionList+1] = cc.DelayTime:create(24/60)
    -- 弹板反馈
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if not tolua.isnull(view) then
            view:runCsbAction("fankui", false)
        end
    end)
    -- 延时0.1s切数字
    tblActionList[#tblActionList+1] = cc.DelayTime:create(0.1)
    -- 刷新总倍数
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        local userDataFinal = self:getDialogUserData()
        for i=1, 5 do
            local item = userDataFinal[i].p_item
            local mul = userDataFinal[i].p_finalMul
            local roleNode = view:findChild("Node_role_"..i)
            roleNode:removeAllChildren()
            roleNode:addChild(item)
            item:findChild("m_lb_num"):setString("X"..mul)
        end
    end)
    -- 延时0.5s小车驶出
    tblActionList[#tblActionList+1] = cc.DelayTime:create(1.0)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_dialogCarLeave)
        if not tolua.isnull(view) then
            view:runCsbAction("actionframe2", false)
        end
        for i = 1, 3 do
            local carAni = carAniData[i]
            if not tolua.isnull(carAni) and carAni.startMoveAni then
                carAni:startMoveAni()
            end
        end
    end)
    -- 延时1.0s播actionframe
    tblActionList[#tblActionList+1] = cc.DelayTime:create(1.0)
    -- 结束
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        endCallFunc(view)
    end)
    
    local seq = cc.Sequence:create(tblActionList)
    self.m_scWaitNode:runAction(seq)

    util_setCascadeOpacityEnabledRescursion(view, true)
end

-- 社交2结束后添加新弹板（在结束弹板和最后零钱弹板中间）
function MiningManiaBonusCarView:showGameOverRankDialog()
    -- 获取弹板数据
    local userDataFinal = self:getDialogUserData(true)
    local userScore = self:getUserBaseScore()
    local userMul = 1
    for i=1, 5 do
        local isMySelf = userDataFinal[i].p_isMySelf
        if isMySelf then
            userMul = userDataFinal[i].p_finalMul
            break
        end
    end
    local endCallFunc = function(view)
        if not tolua.isnull(view) then
            view:runCsbAction("over", false, function()
                self.m_machine:showBonusOverView(userScore, userMul, function()
                    self:clearRewardNode()
                    if type(self.m_endFunc) == "function" then
                        self.m_endFunc()
                        self.m_endFunc = nil
                    end
                    view:removeFromParent()
                end)
            end)
        end
    end

    gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_EndRank)
    local view = self.m_machine:showDialog("SheJiaoOver3", nil, nil)
    view.isShowOver = true
    view:findChild("root"):setScale(self.m_bonusRootSccale)

    -- 倍数
    for i=1, 5 do
        local item = userDataFinal[i].p_item
        local roleNode = view:findChild("Node_role_"..i)
        roleNode:addChild(item)
        
        local mul = userDataFinal[i].p_finalMul
        view:findChild("text_mul_"..i):setString("X"..mul)
    end

    local tblActionList = {}
    tblActionList[#tblActionList+1] = cc.DelayTime:create(120/60)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        if not tolua.isnull(view) then
            view:runCsbAction("idle", false)
        end
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(120/60)
    -- 弹板actionframe
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.Music_BonusCar_dialogFireworks)
        if not tolua.isnull(view) then
            view:runCsbAction("actionframe", false)
        end
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(120/60)
    -- 结束
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        endCallFunc(view)
    end)
    
    local seq = cc.Sequence:create(tblActionList)
    self.m_scWaitNode:runAction(seq)

    util_setCascadeOpacityEnabledRescursion(view, true)
end

-- 获取社交2结束弹板数据(展示的是)
function MiningManiaBonusCarView:getDialogUserData(_notShowMul, _isFirst)
    local rolePosTbl = {cc.p(-426, 0), cc.p(-218, 0), cc.p(0, 0), cc.p(218, 0), cc.p(426, 0)}
    -- 头像；排名
    local playDataTbl = {}
    local playersInfo = self.m_result.data.sets or {}
    local finalChairRank = self.m_result.data.finalChairRank or {}
    local finalMulData = self.m_result.data.finalUserMultiple or {}
    local firstChairRank = self.m_result.data.firstRndChairRank or {}
    local firstMulData = self.m_result.data.firstRndUserMultiple or {}
    for index = 1, 5 do
        local tempTbl = {}
        local info = playersInfo[index]
        local item = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusCarPlayerItem")
        local rewardPosY = item:getRewardNodePosY()
        tempTbl.p_item = item
        tempTbl.p_posY = rewardPosY
        if _notShowMul then
            item:setNodeVisible()
        end

        -- 第一轮排名
        for j = 1, #firstChairRank do
            local chairId = firstChairRank[j]
            if info.chairId == chairId then
                tempTbl.p_firstRank = j
                tempTbl.p_firstPos = rolePosTbl[j]
                break
            end
        end
        -- 最终排名
        for j = 1, #finalChairRank do
            local chairId = finalChairRank[j]
            if info.chairId == chairId then
                tempTbl.p_finalRank = j
                tempTbl.p_finalPos = rolePosTbl[j]
                break
            end
        end

        -- 第一轮倍数
        tempTbl.p_firstMul = firstMulData[index] or 0
        -- 最终倍数
        tempTbl.p_finalMul = finalMulData[index] or 0

        if info then
            local udid = item:getPlayerID()
            local robot = item:getPlayerRobotInfo()
            item:refreshData(info)
            --刷新头像
            if info.udid and info.udid ~= "" then
                item:refreshHead()
            else
                -- 刷新机器人头像
                if robot and robot ~= info.robot  then
                    item:refreshHead()
                end
            end
        else
            item:refreshData(nil)
            item:setVisible(false)
        end
        tempTbl.p_isMySelf = item:isMySelf()
        table.insert(playDataTbl, tempTbl)
    end

    if _isFirst then
        -- 按排名进去排序
        table.sort(playDataTbl, function(a, b)
            if a.p_firstRank ~= b.p_firstRank then
                return a.p_firstRank < b.p_firstRank
            end
            return false
        end)
    else
        -- 按排名进去排序
        table.sort(playDataTbl, function(a, b)
            if a.p_finalRank ~= b.p_finalRank then
                return a.p_finalRank < b.p_finalRank
            end
            return false
        end)
    end

    return playDataTbl
end

-- 获取社交2弹板小车数据
function MiningManiaBonusCarView:getDialogCarData()
    local carDataTbl = {}
    for i=1, 3 do
        local tempTbl = {}
        local carAni = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusDialogCarAni", self, i)
        local curRowMul = self.m_carAniTbl[i]:getMul()
        carAni:setMul(curRowMul)
        carDataTbl[i] = carAni
    end
    return carDataTbl
end

-- 社交2弹板飞行字体数据
function MiningManiaBonusCarView:dialogStartFlyNode(_view, _userData)
    for i=1, 5 do
        local tempTbl = {}
        local flyNode = util_createView("CodeMiningManiaBonusCar.MiningManiaBonusDialogCarAni", self, i)
        flyNode:setNodeVisible()
        local curRowMul = 0
        local carNode = _view:findChild("Node_Car_1")
        if i == 1 then
            curRowMul = self.m_carAniTbl[1]:getMul()
            carNode = _view:findChild("Node_Car_1")
        elseif i >= 2 and i <= 3 then
            curRowMul = self.m_carAniTbl[2]:getMul()
            carNode = _view:findChild("Node_Car_2")
        else
            curRowMul = self.m_carAniTbl[3]:getMul()
            carNode = _view:findChild("Node_Car_3")
        end
        local posY = _userData[i].p_posY
        local textNodePosY = flyNode:getTextNodePosY()
        local roleNode = _view:findChild("Node_role_"..i)
        local curScale = roleNode:getScale()
        posY = posY*curScale-textNodePosY
        carNode:addChild(flyNode)
        flyNode:setScale(1.5)
        flyNode:setMul(curRowMul)
        local endNodePos = util_convertToNodeSpace(roleNode, carNode)
        endNodePos.y = endNodePos.y+posY
        util_playMoveToAction(flyNode, 24/60, endNodePos,function()
            flyNode:setVisible(false)
        end)
    end
end

return MiningManiaBonusCarView
