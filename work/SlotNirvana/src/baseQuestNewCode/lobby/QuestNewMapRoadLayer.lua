--[[
    两周年新版聚合挑战 滑动背景
    author:csc
    time:2021-07-20
]]
local QuestNewMapRoadLayer = class("QuestNewMapRoadLayer", BaseLayer)

function QuestNewMapRoadLayer:ctor()
    QuestNewMapRoadLayer.super.ctor(self)

    -- 不需要播放动画
    self.m_isShowActionEnabled = false
    self.m_isHideActionEnabled = false
    self.m_isMaskEnabled = false

    -- 所有路面节点信息 -- pos , node
    self.m_mapNodeInfo = {}
    self.m_startX = 0
    self.m_startIndex = 0
    self.m_mapNodePos = {} -- csc 2021-12-08 新版聚合需要读取路面坐标来摆放
    self:setHasGuide(true)
    self:setLandscapeCsbName(QUESTNEW_RES_PATH.QuestNewMapRoadLayer)
end

function QuestNewMapRoadLayer:initDatas(data)
    self.m_chapterId = data.chapterId
    self.m_chapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterDataByChapterId(self.m_chapterId)
    self.m_allPointData = G_GetMgr(ACTIVITY_REF.QuestNew):getALLPointDataByChapterId(self.m_chapterId)
end

function QuestNewMapRoadLayer:initCsbNodes()

    self.m_node_BG = self:findChild("node_BG")

    self.node_cell = self:findChild("node_cell")

    self.m_allPointNode = {}
    for i = 1, 15 do
        local point_node = self:findChild("Node_"..i)
        if point_node then
            self.m_allPointNode[#self.m_allPointNode + 1] = point_node
        end
    end

    self.m_node_wheel = self:findChild("node_wheel")
    self.m_node_bg = self:findChild("node_bg")
end

-- 重写父类
function QuestNewMapRoadLayer:setAutoScale(_autoScale)
    -- 因为是滑动层 继承了baselayer 不希望被缩放
end

function QuestNewMapRoadLayer:initView()
    self:initBg()
    self:initBoxsPos()
    self:updateStartPos()
    --self:frameLoadBoxs()
    self:initWheelNode()
end

---------------------------------- 初始化 部分 ----------------------------------
function QuestNewMapRoadLayer:initBg()
    local dis_x = 0
    for i=1,2 do
        local p_sprite = util_createSprite(QUESTNEW_RES_PATH.QuestNewMainMap_BG_PATH .. self.m_chapterId .."_" .. i ..".png")
        p_sprite:setAnchorPoint(cc.p(0, 0.5))
        p_sprite:setPosition(cc.p(dis_x, 0))
        dis_x = p_sprite:getContentSize().width
        self.m_node_bg:addChild(p_sprite)
    end
end

-- 初始化酒杯节点坐标
function QuestNewMapRoadLayer:initBoxsPos()
    -- 初始化所有节点的位置
    -- 初始化所有 酒杯的位置,递增间距排列

    for index, one_node in ipairs(self.m_allPointNode) do
        local oneData = self.m_allPointData[index]
        if oneData then
            local pos = cc.p(one_node:getPosition())
            local worldPos = self.node_cell:getParent():convertToWorldSpace(pos)
            local data = {
                cell_node = one_node,
                pos = worldPos
            }
            table.insert(self.m_mapNodeInfo, data)
        end
    end

    for i = 1, #self.m_mapNodeInfo do
        local pos = self.m_mapNodeInfo[i].pos

        local cell_node = self.m_mapNodeInfo[i].cell_node
        local worldPos = self.m_mapNodeInfo[i].pos
        local boxNode = cell_node:getChildByName("node_box")
        local cupNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapCellNode, {chapterId = self.m_chapterId,index = i,boxNode = boxNode})
        cell_node:addChild(cupNode)

        local cupInfo = {pos = worldPos, node = cupNode, add = true}
        if boxNode then
            local pos_x, pos_y = boxNode:getPosition()
            cupInfo.pos_gift = cc.p(worldPos.x + pos_x,worldPos.y + pos_y)
        end
        self.m_mapNodeInfo[i] = cupInfo
    end

end

function QuestNewMapRoadLayer:frameLoadBoxs()
    --分帧创建 酒杯 spine
    --需要分两步
    --1.需要把当前小车所在位置的这一面 layer 上的星星添加出来
    local layerXPos = math.abs(self.m_startX) + display.width -- 计算出边界位置 = 起始坐标 + 一屏幕的宽度（需要考虑到滑动层已经移动）
    local firstAddStarIndex = {}
    local interval = 100--self.m_config.ROAD_CONFIG.ROAD_CUP_INTERVAL -- 补足一个间距,多加载左右两个酒杯
    local nodeVal = 0
    for i = 1, #self.m_mapNodeInfo do
        local pos = self.m_mapNodeInfo[i].pos

        if pos.x >= math.abs(self.m_startX) - (interval + nodeVal) and pos.x < layerXPos + (interval + nodeVal) then --当前这些酒杯是可以先加载的
            table.insert(firstAddStarIndex, i)

            local cell_node = self.m_mapNodeInfo[i].cell_node
            local worldPos = self.m_mapNodeInfo[i].pos

            local nodePath = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().CODE_PATH.ROAD_NODE
            local boxNode = cell_node:getChildByName("node_box")
            local cupNode = util_createView(nodePath, {chapterId = self.m_chapterId,index = i,boxNode = boxNode})
            cupNode:setPosition(nodePos)
            cell_node:addChild(cupNode)

            local cupInfo = {pos = worldPos, node = cupNode, add = true}
            self.m_mapNodeInfo[i] = cupInfo
        end
    end
    -- print("----csc 起始位置 x = "..math.abs(self.m_startX))
    -- print("----csc 边界位置 x = "..layerXPos)

    --2.再去分帧添加其他看不到的星星
    local curCount = 1
    local totalCount = #self.m_mapNodeInfo
    self.m_frameLoadAction =
        schedule(
        self,
        function()
            if self.m_mapNodeInfo[curCount].add == nil then

                local cell_node = self.m_mapNodeInfo[i].cell_node
                local worldPos = self.m_mapNodeInfo[curCount].pos

                local nodePath = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().CODE_PATH.ROAD_NODE

                local boxNode = cell_node:getChildByName("node_box")
                local cupNode = util_createView(nodePath, {chapterId = self.m_chapterId,index = curCount,boxNode = boxNode})
                cell_node:addChild(cupNode)

                local cupInfo = {pos = worldPos, node = cupNode, add = true}
                self.m_mapNodeInfo[curCount] = cupInfo
            end
            if curCount == totalCount then
                self:stopAction(self.m_frameLoadAction)
                self.m_frameLoadAction = nil
                --分帧加载完毕 可以开始运动
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_LOADRES_FINISH)
            end
            curCount = curCount + 1
        end,
        1 / 60
    )
end

-- 更新开始位置
function QuestNewMapRoadLayer:updateStartPos()
    local currPoint = self.m_chapterData:getCurrentStage()
    local minCompletedPoint = self.m_chapterData:getMinWillCompletedStage()
    local minUnlockPoint = self.m_chapterData:getMinWillUnlockStage()
    local usePoint = currPoint
    if minCompletedPoint > 0 then
        usePoint = minCompletedPoint
    else
        if minUnlockPoint > 0 then
            usePoint = minUnlockPoint
        end
    end
    self.m_startIndex = usePoint
    if usePoint > 0 then
        local startPos = self.m_mapNodeInfo[usePoint].pos
        if startPos.x > display.cx then
            local moveX = startPos.x - display.cx -- 移动的距离 = 小车实时的位置
            self.m_startX = -moveX
        end
    end
end

function QuestNewMapRoadLayer:initWheelNode()
    local wheelCell= util_createView(QUESTNEW_CODE_PATH.QuestNewMapCellWheelNode, {chapterId = self.m_chapterId})
    self.m_node_wheel:addChild(wheelCell)
    self.m_wheelCell = wheelCell
end


---------------------------------- 对外接口 部分 ----------------------------------
--[[
    @desc: 对外返回 界面长度
]]
function QuestNewMapRoadLayer:getContentLen()
    local len = 0
    for i = 1, 3 do
        local bg = self:findChild("sp_road_" .. i)
        if bg then
            len = len + bg:getContentSize().width
        end
    end
    self.m_conentLen = len
    return len
end

--[[
    @desc: 返回起始位置
]]
function QuestNewMapRoadLayer:getStartX()
    return self.m_startX
end

function QuestNewMapRoadLayer:onEnter()
    QuestNewMapRoadLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.type == "success" then
                self:afterGainBoxReward(params)
            end
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_COLLECTGIFT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            -- 加载完全部资源之后 需要先检测当前是否有新手引导
            if self.m_guideSchedule then
                self:stopAction(self.m_guideSchedule)
                self.m_guideSchedule = nil
                if self.m_nextFunc then
                    self.m_nextFunc()
                end
            end
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_NEXT_STEP
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:checkGuide()
        end,
        ViewEventType.NOTIFY_NEWQUEST_STARLAYER_CLOSE
    )
    self:doCheckAct()
    self:checkGuide()
end

function QuestNewMapRoadLayer:afterGainBoxReward(params)
    local stageId = params.stageId
    local cellNode = self.m_mapNodeInfo[stageId].node
    if cellNode then
        cellNode:refreshBoxState()
        local pointData = cellNode:getSelfData()
        local reward = {}
        reward.coin = pointData.p_coins
        reward.items = pointData.p_items
        local rewardView = util_createView(QUESTNEW_CODE_PATH.QuestNewMapRewardLayer,{type = 2,reward = reward})
        if rewardView then
            gLobalViewManager:showUI(rewardView, ViewZorder.ZORDER_UI)
        end
    end
end

function QuestNewMapRoadLayer:doCheckAct()
    self.m_doCheck = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_DOMAPMOVE_FLAG, {flag = false})
    util_performWithDelay(
        self,
        function()
            if not tolua.isnull(self) then
                self:checkCompleteAct()
            end
        end,
        0.5
    )
end

function QuestNewMapRoadLayer:getCellNode(index,isWheel)
    if isWheel then
        return self.m_wheelCell
    end
    if index <= #self.m_mapNodeInfo then
        return self.m_mapNodeInfo[index].node
    end
    return nil
end

function QuestNewMapRoadLayer:checkCompleteAct()
    if not self.m_completeCheckIndex then
        self.m_completeCheckIndex = 1
    else
        self.m_completeCheckIndex = self.m_completeCheckIndex + 1
    end
    if self.m_completeCheckIndex <= self.m_chapterData:getCurrentStage() then
        local cellNode = self.m_mapNodeInfo[self.m_completeCheckIndex].node
        if cellNode and cellNode:isWillDoCompleted() then
            self:doMoveToIndex(cellNode:getIndex(),function ()
                cellNode:doCellCompletedAct(function ()
                    self:checkCompleteAct()
                end)
            end)
        else
            self:checkCompleteAct()
        end
    else
        self.m_completeCheckIndex = nil
        self:checkBoxUnlockAct()
    end
end
function QuestNewMapRoadLayer:checkBoxUnlockAct()
    local currentIndex = self.m_chapterData:getCurrentStage()
    if currentIndex > 1 then
        local cellNode_before = self.m_mapNodeInfo[currentIndex-1].node
        cellNode_before:doBoxCompleteAct(function ()
            self:checkCellUnlockAct()
        end)
    else
        self:checkCellUnlockAct()
    end
end

function QuestNewMapRoadLayer:checkCellUnlockAct()
    local currentIndex = self.m_chapterData:getCurrentStage()
    local cellNode = self.m_mapNodeInfo[currentIndex].node
    if cellNode and cellNode:isWillDoUnlock() then
        self:doMoveToIndex(cellNode:getIndex(),function ()
            cellNode:doCellUnlockAct(function ()
                self:checkWheelUnlock()
            end)
        end)
    else
        self:checkWheelUnlock()
    end
end


function QuestNewMapRoadLayer:checkWheelUnlock()
    if self.m_chapterData:isWillDoWheelUnlock() then
        self.m_chapterData:clearWillDoWheelUnlock()
        self:doMoveToIndex(8,function ()
            if self.m_wheelCell then
                self.m_wheelCell:doUnlockAct(function()
                    self:checkWheelLevelUp()
                end)
            end
        end)
    else
        self:checkWheelLevelUp()
    end
end
function QuestNewMapRoadLayer:checkWheelLevelUp()
    if self.m_chapterData:getWheelData():isWillchangeToLevelThree(true) then
        self:doMoveToIndex(8,function ()
            if self.m_wheelCell then
                self.m_wheelCell:doUnloclLevelThreeAct(function()
                    self.m_doCheck = false
                    self:backToCurrent()
                end)
            end
        end)
    elseif self.m_chapterData:getWheelData():isWillchangeToLevelFour(true) then
        self:doMoveToIndex(8,function ()
            if self.m_wheelCell then
                self.m_wheelCell:doUnloclLevelFourAct(function()
                    self.m_doCheck = false
                    self:backToCurrent()
                end)
            end
        end)
    else
        self.m_doCheck = false
        self:backToCurrent()
    end
end

function QuestNewMapRoadLayer:backToCurrent()
    local currentStage = self.m_chapterData:getCurrentStage()
    self:doMoveToIndex(currentStage,function ()
        self:checkStarMeter()
    end)
end

function QuestNewMapRoadLayer:setCheckStarMeterFunc(func)
    self.m_checkStarMeterFunc = func
end

function QuestNewMapRoadLayer:checkStarMeter()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_DOMAPMOVE_FLAG, {flag = true})
    if self.m_checkStarMeterFunc then
        self.m_checkStarMeterFunc()
    end
end

-------------------------------------------------移动地图-------------------------------------------------

function QuestNewMapRoadLayer:doMoveToIndex(index,callFunc)
    if self.m_startIndex ~= index then
        self.m_endIndex = index
        self:doMoveAction(callFunc)
    else
        if callFunc then
            callFunc()
        end
    end

end

function QuestNewMapRoadLayer:doMoveAction(callFunc,forGift)
    
    local endIndex = self.m_endIndex
    local moveNum = self.m_endIndex - self.m_startIndex

    local playStarActFuncV1 = function ()
        local currentX = math.abs(self.m_startX) 
        local targetPos = self.m_mapNodeInfo[endIndex].pos
        if forGift then
            targetPos = self.m_mapNodeInfo[endIndex].pos_gift
        end
        if targetPos.x > display.cx then
            targetPos.x  = targetPos.x - display.cx
        else
            targetPos.x = 0
        end
        local changeNum = math.abs(currentX - targetPos.x)
        local frameMoveX = 0
        local count = 1
        local moveFrame = 1/60 -- 刷新帧率
        local moveRate = moveFrame * 2
        local playing = false
        local firstShow = true
        
        --创建自动滑动用来展示星星动画 -- 暂时不用
        self.m_CGMoveTick = schedule(self, function()
            frameMoveX = frameMoveX + changeNum/moveNum * moveRate
            local moveX = currentX + frameMoveX

            -- 停止逻辑
            if moveNum > 0 then
                local min = math.min(moveX,targetPos.x)
                if min >= targetPos.x then
                    self:stopAction(self.m_CGMoveTick)
                    self.m_CGMoveTick = nil
                    performWithDelay(self,function( )
                        if callFunc then
                            callFunc()
                        end
                    end,0.5)
                    self.m_startIndex  = self.m_endIndex
                end
                if min < targetPos.x then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_DOMAPMOVE, {moveX = -moveX})
                    self.m_startX = -moveX
                end
            else
                local max = math.max(moveX,targetPos.x)
                if max <= targetPos.x then
                    self:stopAction(self.m_CGMoveTick)
                    self.m_CGMoveTick = nil
                    performWithDelay(self,function( )
                        if callFunc then
                            callFunc()
                        end
                    end,0.5)
                    self.m_startIndex  = self.m_endIndex
                end
                if max > targetPos.x then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_DOMAPMOVE, {moveX = -moveX})
                    self.m_startX = -moveX
                end
            end
            
        end, moveFrame)
    end
    
    local playStarActFuncV2 = function()
        self.m_startIndex  = self.m_endIndex
        if callFunc then
            callFunc()
        end
    end

    -- 如果当前目标奖杯位置没有超过屏幕一半，不需要做移动动画
    if self.m_mapNodeInfo[endIndex].pos.x > display.cx or moveNum < 0 then
        playStarActFuncV1()
    else
        playStarActFuncV2()
    end
end

function QuestNewMapRoadLayer:triggerGuideStep(guideName, stepId)
    G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():triggerGuide(self, guideName, ACTIVITY_REF.QuestNew)
end

function QuestNewMapRoadLayer:checkGuide()
    local willDoStep1 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_1")
    if willDoStep1 then
        G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():triggerGuide(self, "enterQuestMap_1", ACTIVITY_REF.QuestNew)
    else
        local willDoStep2 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_2")
        if not willDoStep2 then
            local willDoStep3 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_3")
            if willDoStep3 then
                G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():triggerGuide(self, "enterQuestMap_3", ACTIVITY_REF.QuestNew)
            else
                -- local willDoStep4 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_4")
                -- if willDoStep4 then
                --     self:doMoveToIndex(2,function ()
                --         G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():triggerGuide(self, "enterQuestMap_4", ACTIVITY_REF.QuestNew)
                --     end)
                -- end
            end
        end
    end
end

return QuestNewMapRoadLayer
