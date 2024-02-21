--[[
    
    author:徐袁
    time:2021-03-19 20:19:08
]]
local StatuePickMainLayer = class("StatuePickMainLayer", BaseLayer)

StatuePickMainLayer.ActionType = "Common"

local BOX_COUNT = 15

function StatuePickMainLayer:ctor()
    StatuePickMainLayer.super.ctor(self)

    self:setLandscapeCsbName("CardRes/season202102/Statue/StatuePickMain.csb")

    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setPauseSlotsEnabled(true)
    -- test
    -- self:setKeyBackEnabled(true)

    -- 宝箱节点
    self.m_tbNodeItems = {}
    -- 宝箱
    self.m_tbBoxItems = {}
    -- 宝箱坐标
    self.m_tbNodePos = {}

    self:setExtendData("StatuePickMainLayer")
end

--[[
    @desc: 初始化csb节点
    author:徐袁
    time:2021-03-19 20:19:08
    @return:
]]
function StatuePickMainLayer:initCsbNodes()
    self.m_itemNode = self:findChild("itemNodes")
    -- 宝箱节点
    self.m_tbNodeItems = {}
    -- 节点位置
    self.m_tbNodePos = {}
    for i = 1, BOX_COUNT do
        local _node = self:findChild("itemNode_" .. i)
        if _node then
            self.m_tbNodeItems[i] = _node
            local _posX, _posY = _node:getPosition()
            self.m_tbNodePos[i] = cc.p(_posX, _posY)
        end
    end

    self.m_nodePicks = self:findChild("picksNode")
    self.m_txtPicks = self:findChild("font_times")

    self.m_fntTitle = self:findChild("fnt_title")
end

--[[
    @desc: 初始化界面显示
    author:徐袁
    time:2021-03-19 20:19:08
    @return:
]]
function StatuePickMainLayer:initView()
    self.m_itemNode:setVisible(false)
    -- 初始化箱子
    self.m_tbBoxItems = {}
    for i = 1, BOX_COUNT do
        local _item = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickItemNode", i)
        local _node = self.m_tbNodeItems[i]
        if _item and _node then
            _node:addChild(_item)
            self.m_tbBoxItems[i] = _item
        end
    end
end

--[[
    @desc: 刷新界面显示
    author:徐袁
    time:2021-03-19 20:19:08
    @return:
]]
function StatuePickMainLayer:updateView()
    self:updatePicks()
    self:updateBoxsInfo()
end

-- 刷新Picks数
function StatuePickMainLayer:updatePicks()
    local picks = StatuePickGameData:getPicks()
    if picks > 1 then
        self.m_fntTitle:setString("PICKS LEFT")
    else
        self.m_fntTitle:setString("PICK LEFT")
    end
    self.m_txtPicks:setString(tostring(picks))
end

-- 注册消息事件
function StatuePickMainLayer:registerListener()
    StatuePickMainLayer.super.registerListener(self)

    -- 开始游戏
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:setPrepareStatus(false)
            self:showBoxsAction()
            self:updateView()
        end,
        ViewEventType.STATUS_PICK_GAME_START
    )

    -- 展示宝箱阵列
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:showBoxsAction()
            self:updateView()
        end,
        ViewEventType.STATUS_PICK_SHOW_BOX_ARRAY
    )

    -- 点击宝箱后开始打开宝箱
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.status == "clearShake" then
                -- 清除晃动计时器
                self:clearShakeTimer()
            elseif params.status == "resumeShake" then
                self:clearShakeTimer()
                self:randomShakeBox()
            end
        end,
        ViewEventType.STATUS_PICK_SHAKE_TIMER
    )

    -- 打开箱子
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local _index = params.index

            self:openBox(_index)
            self:updatePicks()
        end,
        ViewEventType.STATUS_PICK_OPEN_BOX
    )

    -- PICKS数量没了
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if StatuePickGameData:getBuyTimes() > 0 and StatuePickGameData:isHasBuyTimes() then
                -- 购买过 且 还能购买
                self:showBuyPick()
            else
                self:boxLvUpStart()
            end
        end,
        ViewEventType.STATUS_PICK_PICKS_FINISHED
    )

    -- 购买PICKS数量结构
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuccess = params.result
            if isSuccess then
                self:updatePicks()
                -- 晃动
                gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_SHAKE_TIMER, {status = "resumeShake"})
            end
        end,
        ViewEventType.STATUS_PICK_BUY_PICKS_RESULT
    )

    -- 领取奖励完成
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:closeUI()
            StatuePickControl:exitStatuePickSys()
        end,
        ViewEventType.STATUS_PICK_COLLECT_REWARD_COMPLETED
    )

    -- 领取奖励结果
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local isSuccess = params.result or false
            if isSuccess then
                self.m_nodePicks:setVisible(false)
                self.m_itemNode:setVisible(false)
            end
        end,
        ViewEventType.STATUS_PICK_COLLECT_REWARD_RESULT
    )
end

function StatuePickMainLayer:onEnter()
    StatuePickMainLayer.super.onEnter(self)

    local _status = StatuePickGameData:getGameStatus()
    if StatuePickStatus.PREPARE == _status then
        StatuePickControl:showStartLayer()
        self:setPrepareStatus(true)
    elseif StatuePickStatus.PLAYING == _status then
        local picks = StatuePickGameData:getPicks()
        if picks <= 0 then
            -- 检查是否结束，显示购买次数或者结算
            -- 是否能有购买次数
            if not StatuePickGameData:isHasBuyTimes() then
                -- 申请结算
                StatuePickControl:requestCollectRewards()
            else
                StatuePickControl:showPicksOver()
            end
            self:updatePicks()
        else
            self:showBoxsAction()
            self:updateView()
        end
    end
end

function StatuePickMainLayer:onExit()
    self:clearShakeTimer()
    StatuePickMainLayer.super.onExit(self)
end

-- layer显示完成的回调
function StatuePickMainLayer:onShowedCallFunc()
    self:clearShakeTimer()
    self:randomShakeBox()
end

function StatuePickMainLayer:clickFunc(sender)
    local senderName = sender:getName()
end

-- 设置准备状态
function StatuePickMainLayer:setPrepareStatus(isStart)
    self.m_itemNode:setVisible(not isStart)
    self.m_nodePicks:setVisible(not isStart)
end

-- 展示宝箱阵列
function StatuePickMainLayer:showBoxsAction()
    self.m_itemNode:setVisible(true)

    -- self:updateView()
end

-- 隐藏宝箱阵列
function StatuePickMainLayer:hideBoxsAction()
    self.m_itemNode:setVisible(false)
end

-- 更新宝箱阵列信息
function StatuePickMainLayer:updateBoxsInfo()
    for i = 1, BOX_COUNT do
        self.m_tbBoxItems[i]:updateBoxInfo()
        -- 更新打开状态
        local _isOpened = StatuePickGameData:isOpened(i)
        if _isOpened then
            -- 更新奖励
            self.m_tbBoxItems[i]:updateRewardInfo()
        end
        self.m_tbBoxItems[i]:setOpenStatus(_isOpened)
    end
end

-- 打开箱子
function StatuePickMainLayer:openBox(index)
    if not index then
        return
    end

    local boxItem = self.m_tbBoxItems[index]
    if boxItem then
        -- 剩余次数
        local picks = StatuePickGameData:getPicks()
        boxItem:openBox(picks)
    end
end

-- 展示未开启的宝箱奖励
function StatuePickMainLayer:showLockedBoxsReward(isUpgraded)
    local delayTime = 3

    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePickBoxGrey)
    for i = 1, BOX_COUNT do
        local boxItem = self.m_tbBoxItems[i]
        if boxItem then
            boxItem:showLockedBoxReward()
            local secs = boxItem:getAnimSecs("zhanshi") + boxItem:getAnimSecs("idle0")
            delayTime = math.max(secs, delayTime)
        end
    end

    performWithDelay(
        self.m_itemNode,
        function()
            if isUpgraded then
                -- 打乱宝箱顺序
                self:showReorderBoxs()
            else
                -- 升级箱子
                self:showLockedBoxsLvUp()
            end
        end,
        delayTime
    )
end

-- 升级未开启的宝箱
function StatuePickMainLayer:showLockedBoxsLvUp()
    local delayTime = 2

    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.StatuePickBoxLvUp)
    for i = 1, BOX_COUNT do
        local boxItem = self.m_tbBoxItems[i]
        if boxItem then
            boxItem:showLockedBoxLvUp()
            delayTime = math.max(boxItem:getAnimSecs("shengji"), delayTime)
        end
    end

    performWithDelay(
        self.m_itemNode,
        function()
            -- 显示升级后未开箱子的奖励
            self:showLockedBoxsReward(true)
        end,
        delayTime
    )
end

-- 打乱宝箱顺序
function StatuePickMainLayer:showReorderBoxs(callback)
    -- 收起原始箱子动画
    for i = 1, BOX_COUNT do
        local _isOpened = StatuePickGameData:isOpened(i)
        if not _isOpened then
            local _moveTo = cc.MoveTo:create(0.3, cc.p(0, 0))
            local _nodeItem = self.m_tbNodeItems[i]
            if _nodeItem then
                _nodeItem:runAction(_moveTo)
            end
        end
    end

    -- 还原箱子位置
    local resetBoxsPos = function()
        for i = 1, BOX_COUNT do
            local _isOpened = StatuePickGameData:isOpened(i)
            if not _isOpened then
                local _pos = self.m_tbNodePos[i]
                local _moveTo = cc.MoveTo:create(0.3, _pos)
                local _nodeItem = self.m_tbNodeItems[i]
                if _nodeItem then
                    _nodeItem:runAction(_moveTo)
                end
            end
        end

        performWithDelay(
            self.m_itemNode,
            function()
                -- if callback then
                --     callback()
                -- end
                
                self:boxLvUpOver()
            end,
            1
        )
    end

    -- 显示大箱子动画
    local bigBox = util_createView("GameModule.CardMiniGames.Statue.StatuePick.StatuePickBigBox")
    bigBox:setBoxLv(3)
    self.m_itemNode:addChild(bigBox)
    bigBox:startAction(
        function()
            bigBox:idleAction()

            performWithDelay(
                bigBox,
                function()
                    bigBox:overAction(
                        function()
                            bigBox:removeFromParent()
                            bigBox = nil
                        end
                    )
                    resetBoxsPos()
                end,
                1
            )
        end
    )
end

-- 显示购买Picks
function StatuePickMainLayer:showBuyPick()
    self:hideBoxsAction()
    -- 显示购买次数和collect弹板
    StatuePickControl:showPicksOver()
end

-- 清除晃动计时器
-- 已经在晃动的也要停止
function StatuePickMainLayer:clearShakeTimer()
    if self.m_shakeTimer then
        self:stopAction(self.m_shakeTimer)
        self.m_shakeTimer = nil
    end
end

-- 晃动计时器
function StatuePickMainLayer:randomShakeBox()
    local firstDelayTime = 4
    local intervalDelayTime = 2
    self.m_shakeTimer = schedule(self.m_itemNode, function()
        if StatuePickControl:getBoxInLevelup() then
            return
        end
        
        self:shakeBoxOnce()
    end, intervalDelayTime)
end

function StatuePickMainLayer:shakeBoxOnce()
    local shakeList = StatuePickGameData:getUnopenBoxs()
    if #shakeList > 0 then
        local randomIdx = math.random(1, #shakeList)
        local boxIndex = shakeList[randomIdx]
        if self.m_tbBoxItems and self.m_tbBoxItems[boxIndex] and self.m_tbBoxItems[boxIndex].playShakeAction then
            self.m_tbBoxItems[boxIndex]:playShakeAction()
        end
    end
end

function StatuePickMainLayer:boxLvUpStart( )
    StatuePickControl:setBoxInLevelup(true)
    self:showLockedBoxsReward()
end

function StatuePickMainLayer:boxLvUpOver( )
    StatuePickControl:setBoxInLevelup(false)
    self:showBuyPick()
    -- 晃动
    gLobalNoticManager:postNotification(ViewEventType.STATUS_PICK_SHAKE_TIMER, {status = "resumeShake"})
end

return StatuePickMainLayer
