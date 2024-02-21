--[[
    两周年新版聚合挑战 滑动背景
    author:csc
    time:2021-07-20
]]
local HolidayChallenge_BaseRoadLayer = class("HolidayChallenge_BaseRoadLayer", BaseLayer)
local moveDis = 180

function HolidayChallenge_BaseRoadLayer:ctor()
    HolidayChallenge_BaseRoadLayer.super.ctor(self)

    -- 不需要播放动画
    self.m_isShowActionEnabled = false
    self.m_isHideActionEnabled = false
    self.m_isMaskEnabled = false

    -- 所有路面节点信息 -- pos , node
    self.m_mapNodeInfo = {}
    self.m_startX = 0
    self.m_startIndex = 0
    self.m_mapNodePos = {} -- csc 2021-12-08 新版聚合需要读取路面坐标来摆放

    -- self.m_bLoadOk = false
    self.m_actionStarList = {}
    self.m_moveNum = 0
    self.m_firstFillDis = 0

    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.MAPROAD_LAYER)
end

function HolidayChallenge_BaseRoadLayer:initCsbNodes()
    --酒杯起始节点
    self.m_nodeCup = self:findChild("node_glasses")
    --地图背景
    self.m_sprBg = self:findChild("sp_road")
    --路节点
    self.m_nodeRoad = self:findChild("node_road")

    self.m_sp_npc = self:findChild("sp_npc")
end

-- 重写父类
function HolidayChallenge_BaseRoadLayer:setAutoScale(_autoScale)
    -- 因为是滑动层 继承了baselayer 不希望被缩放
end

function HolidayChallenge_BaseRoadLayer:initView()
    self.m_config = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()

    self:initBoxsPos()
    self:updateStartPos()
    self:initEatSpine()
    self:frameLoadBoxs()
end

---------------------------------- 初始化 部分 ----------------------------------
-- 初始化酒杯节点坐标
function HolidayChallenge_BaseRoadLayer:initBoxsPos()
    -- 初始化所有节点的位置
    if self.m_config.ROAD_CONFIG.ROAD_NODE_USE_MAP_POINT then
        for i = 1,self.m_config.ROAD_CONFIG.ROAD_NODE_NUM do
            local nodeBox = self:findChild("node_box"..i)
            local pos = cc.p(nodeBox:getPosition())
            local worldPos = nodeBox:getParent():convertToWorldSpace(pos)
            pos = self.m_nodeRoad:convertToNodeSpace(worldPos)
            local data = {
                nodePos = pos,
                pos = worldPos
            }
            table.insert(self.m_mapNodeInfo,data)
        end
    else
        -- 初始化所有 酒杯的位置,递增间距排列
        local startPos = cc.p(self.m_nodeCup:getPosition())
        local interval = self.m_config.ROAD_CONFIG.ROAD_CUP_INTERVAL
        local nodeVal = 0
        local bBigNodeVal = false
        local tbRewardPoint = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasPayRewardPoint()
        local frontPos_x = -1000
        for i = 1, self.m_config.ROAD_CONFIG.ROAD_NODE_NUM do
            if i == self.m_config.ROAD_CONFIG.ROAD_NODE_NUM then -- 如果当前是最后一个节点的话， 更换间距
                nodeVal = nodeVal + (self.m_config.ROAD_CONFIG.ROAD_LAST_CUP_INTERVAL or 0)
            end
            local rewardPointKey = table_keyof(tbRewardPoint, i)
            if rewardPointKey and i ~= self.m_config.ROAD_CONFIG.ROAD_NODE_NUM or bBigNodeVal then
                nodeVal = nodeVal + (self.m_config.ROAD_CONFIG.ROAD_BIG_NODE_INTERVAL or 0)
                bBigNodeVal = not bBigNodeVal
            end
            local pos = cc.p(startPos.x + (interval * (i - 1)) + nodeVal, startPos.y)
            local worldPos = self.m_nodeCup:getParent():convertToWorldSpace(pos)
            local nodeEatPos = cc.p(frontPos_x ,pos.y)
            if frontPos_x == -1000 then
                nodeEatPos = cc.p(pos.x - 180 ,pos.y)
            end
            frontPos_x = pos.x
            local data = {
                nodePos = pos,
                nodeEatPos = nodeEatPos,
                pos = worldPos
            }
            table.insert(self.m_mapNodeInfo, data)
        end
    end
    
end
function HolidayChallenge_BaseRoadLayer:frameLoadBoxs()
    --分帧创建 酒杯 spine
    --需要分两步
    --1.需要把当前小车所在位置的这一面 layer 上的星星添加出来
    local layerXPos = math.abs(self.m_startX) + display.width -- 计算出边界位置 = 起始坐标 + 一屏幕的宽度（需要考虑到滑动层已经移动）
    local firstAddStarIndex = {}
    local interval = self.m_config.ROAD_CONFIG.ROAD_CUP_INTERVAL -- 补足一个间距,多加载左右两个酒杯
    local tbRewardPoint = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasPayRewardPoint()
    local nodeVal = 0
    local bBigNodeVal = false
    for i = 1, #self.m_mapNodeInfo do
        local pos = self.m_mapNodeInfo[i].pos
        if i == self.m_config.ROAD_CONFIG.ROAD_NODE_NUM then -- 如果当前是最后一个节点的话， 更换间距
            nodeVal = nodeVal + (self.m_config.ROAD_CONFIG.ROAD_LAST_CUP_INTERVAL or 0)
        end
        local rewardPointKey = table_keyof(tbRewardPoint, i)
        if rewardPointKey and i ~= self.m_config.ROAD_CONFIG.ROAD_NODE_NUM or bBigNodeVal then
            nodeVal = nodeVal + (self.m_config.ROAD_CONFIG.ROAD_BIG_NODE_INTERVAL or 0)
            bBigNodeVal = not bBigNodeVal
        end
        if pos.x >= math.abs(self.m_startX) - (interval + nodeVal) and pos.x < layerXPos + (interval + nodeVal) then --当前这些酒杯是可以先加载的
            table.insert(firstAddStarIndex, i)

            local nodePos = self.m_mapNodeInfo[i].nodePos
            local worldPos = self.m_mapNodeInfo[i].pos
            local nodePath = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRoadNodePath()
            local cupNode = util_createView(nodePath, i)
            cupNode:setPosition(nodePos)
            self.m_nodeRoad:addChild(cupNode)
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
                local nodePos = self.m_mapNodeInfo[curCount].nodePos
                local worldPos = self.m_mapNodeInfo[curCount].pos
                local nodePath = "views.HolidayChallengeBase.HolidayChallenge_BaseGiftNode"
                if self.m_activityConfig and self.m_activityConfig.CODE_PATH.ROAD_NODE then
                    nodePath = self.m_activityConfig.CODE_PATH.ROAD_NODE
                end
                local cupNode = util_createView(nodePath, curCount)
                cupNode:setPosition(nodePos)
                self.m_nodeRoad:addChild(cupNode)
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
function HolidayChallenge_BaseRoadLayer:updateStartPos()
    local currActData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if currActData then
        local currPoint = currActData:getCurrentPoints()
        self.m_startIndex = currPoint
        if currPoint > 0 then
            local startPos = self.m_mapNodeInfo[currPoint].pos
            if startPos.x > display.cx then
                local moveX = startPos.x - display.cx -- 移动的距离 = 小车实时的位置
                self.m_startX = -moveX
            end
        end
    end
end

---------------------------------- 动画 部分 ----------------------------------
-- 星星动画
function HolidayChallenge_BaseRoadLayer:showCupAction()
    local moveNum = self.m_moveNum --走几个星星

    if moveNum == 0 then
        return
    end

    local endIndex = self.m_startIndex + moveNum
    local playStarActFuncV1 = function()
        local currentX = math.abs(self.m_startX)
        local targetPos = self.m_mapNodeInfo[endIndex].pos
        targetPos.x = targetPos.x - display.cx
        local changeNum = math.abs(currentX - targetPos.x)
        local frameMoveX = display.cx
        local count = 1
        local moveFrame = 1 / 60 -- 刷新帧率
        local moveRate = moveFrame * 2
        local playing = false
        local firstShow = false
        -- print("---- currentX "..currentX.. " targetPos.x = "..targetPos.x)
        --创建自动滑动用来展示星星动画 -- 暂时不用
        self.m_CGMoveTick =
            schedule(
            self,
            function()
                frameMoveX = frameMoveX + changeNum / moveNum * moveRate
                local startX = currentX + frameMoveX
                local moveX = startX - display.cx

                if not playing then
                    playing = true
                    if self.m_startIndex + count <= endIndex then
                        local starNode = self.m_mapNodeInfo[self.m_startIndex + count].node
                        local overFunc = function()
                            count = count + 1
                            playing = false
                        end
                        self:creatEatEffect(cc.p(starNode:getPosition()))
                        local hasNext = self.m_startIndex + count < endIndex
                        local isBigPoint = starNode:getIsBigPoint()
                        local useLongDis = isBigPoint or starNode:getIsForntBigPoint()
                        local isLastPoint = starNode:isLastBigPoint()
                        if self.m_SpineEatAct then
                            self:playEatSpine(function ()
                                -- 进行下一个亮灯
                                overFunc()
                            end,function()
                                starNode:playShow()
                            end,isBigPoint,hasNext,useLongDis,isLastPoint)
                        else
                            if isBigPoint and G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_BIG_POINT then
                                if isLastPoint and G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_LAST_POINT then
                                    gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_LAST_POINT)
                                else
                                    gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_BIG_POINT)
                                end
                            else
                                gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_NORMAL)
                            end
                            starNode:playShowAct(firstShow,overFunc,true)
                        end
                        
                        -- if count > 1 or moveNum == 1 then -- 只有一个酒杯要加的话,不需要播放第一个展示
                        --     firstShow = false
                        -- end
                        -- starNode:playShow(firstShow, overFunc, true)
                    end
                end
                -- 停止逻辑
                -- if count >= moveNum then
                local min = math.min(moveX, targetPos.x)
                if count >= moveNum and min >= targetPos.x then
                    self:stopAction(self.m_CGMoveTick)
                    self.m_CGMoveTick = nil
                    performWithDelay(
                        self,
                        function()
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = true})
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_OVER)
                        end,
                        0.5
                    )
                    self.m_startIndex = self.m_startIndex + moveNum
                end
                if min < targetPos.x then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_CAR, {moveX = -moveX})
                    -- print("----moveX = "..moveX)
                    self.m_startX = -moveX
                end
            end,
            moveFrame
        )
    end

    local playStarActFuncV2 = function()
        -- 默认直接播放n 个星星动画
        local actionList = {}
        for i = self.m_startIndex, endIndex do
            local starNode = self.m_mapNodeInfo[i + 1].node
            if i + 1 > endIndex then
                self.m_endActionStar = starNode
                break
            end
            table.insert(self.m_actionStarList, starNode)
        end
        self:playStarAction(true)
    end

    -- 如果当前目标奖杯位置没有超过屏幕一半，不需要做移动动画
    if self.m_mapNodeInfo[endIndex].pos.x > display.cx then
        playStarActFuncV1()
    else
        playStarActFuncV2()
    end
end

function HolidayChallenge_BaseRoadLayer:playStarAction(_firstShow)
    if next(self.m_actionStarList) then
        local starNode = self.m_actionStarList[1]
        self:creatEatEffect(cc.p(starNode:getPosition()))
        local hasNext = #self.m_actionStarList > 1
        local isBigPoint = starNode:getIsBigPoint()
        local useLongDis = isBigPoint or starNode:getIsForntBigPoint()
        local isLastPoint = starNode:isLastBigPoint()
        if self.m_SpineEatAct then
            self:playEatSpine(function ()
                -- 进行下一个亮灯
                table.remove(self.m_actionStarList, 1)
                self:playStarAction(false)
            end,function()
                starNode:playShow()
            end,isBigPoint,hasNext,useLongDis,isLastPoint)
        else
            starNode:playShow(_firstShow,function()
                -- 进行下一个亮灯
                table.remove(self.m_actionStarList,1)
                self:playStarAction(false)
            end)
        end
    else
        --设置滑动层 恢复触摸
        self.m_startEat = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_OVER)
        self.m_startIndex = self.m_startIndex + self.m_moveNum
    end
end

function HolidayChallenge_BaseRoadLayer:initEatSpine(forceCreate)
    local eatIndex =  self.m_startIndex + 1
    local allFinish = false
    if eatIndex > self.m_config.ROAD_CONFIG.ROAD_NODE_NUM then
        eatIndex = self.m_config.ROAD_CONFIG.ROAD_NODE_NUM
        allFinish = true
    end
    local currentEatPos = self.m_mapNodeInfo[eatIndex].nodeEatPos
    if  self.m_config.RESPATH["SPINE_PATH_EAT"] then
        self.m_SpineEatAct = util_spineCreate(self.m_config.RESPATH["SPINE_PATH_EAT"], true, true, 1)
        self.m_SpineEatAct:setScale(1)
        self.m_SpineEatAct:setPosition(currentEatPos)
        self.m_nodeRoad:addChild(self.m_SpineEatAct,200,200)
        if allFinish then
            util_spinePlay(self.m_SpineEatAct, "start1_over2", true)
        else
            util_spinePlay(self.m_SpineEatAct, "idle", true)
        end  
    end
end

function HolidayChallenge_BaseRoadLayer:playEatSpine(nextFun,showFun,isBig,hasNext,useLongDis,isLastPoint)
    local dis_move = moveDis
    if useLongDis then
        dis_move = dis_move + (self.m_config.ROAD_CONFIG.ROAD_BIG_NODE_INTERVAL or 0)
    end
    if isBig then
        gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_SPECIAL)
    else
        gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.GIFT_LIGHT_MP3_NORMAL)
    end
    if not self.m_startEat  then
        self.m_startEat = true
        util_spinePlay(self.m_SpineEatAct, "idle_start1", false)
        util_spineEndCallFunc(self.m_SpineEatAct, "idle_start1",function()
            if isBig then
                util_spinePlay(self.m_SpineEatAct, "start2", false)
                util_spineEndCallFunc(self.m_SpineEatAct, "start2",function()
                    if hasNext then
                        --util_spinePlay(self.m_SpineEatAct, "idle_start1", true)
                    else
                        util_spinePlay(self.m_SpineEatAct, "idle", true)
                    end
                    if isBig then
                        self.m_startEat = false
                        if showFun then
                            showFun()
                        end
                        if nextFun then
                            nextFun()
                        end
                    end
                    
                end)
            else
                if isLastPoint then
                    util_spinePlay(self.m_SpineEatAct, "start1_over", false)
                    util_spineEndCallFunc(self.m_SpineEatAct, "start1_over",function()
                        util_spinePlay(self.m_SpineEatAct, "start1_over2", true)
                        if showFun then
                            showFun()
                        end
                        if nextFun then
                            nextFun()
                        end
                    end)
                else
                    if showFun then
                        showFun()
                    end
                    util_spinePlay(self.m_SpineEatAct, "start1", true)
                end
            end
            if not isLastPoint then
                local actionList = {}
                actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveBy:create(0.5, cc.p(dis_move,0)),1)
                actionList[#actionList + 1] = cc.CallFunc:create(function()
                    if not isBig then
                        if not hasNext then
                            util_spinePlay(self.m_SpineEatAct, "idle", true)
                            self.m_startEat = false
                        end
                        if nextFun then
                            nextFun()
                        end
                    end
                end)
                self.m_SpineEatAct:runAction(cc.Sequence:create(actionList)) 
            end
        end)
    else
        if isLastPoint then
            util_spinePlay(self.m_SpineEatAct, "start1_over", false)
            util_spineEndCallFunc(self.m_SpineEatAct, "start1_over",function()
                util_spinePlay(self.m_SpineEatAct, "start1_over2", true)
            end)
            if showFun then
                showFun()
            end
            if nextFun then
                nextFun()
            end
        else
            if isBig then
                util_spinePlay(self.m_SpineEatAct, "start2", false)
                util_spineEndCallFunc(self.m_SpineEatAct, "start2",function()
                    if hasNext then
                        util_spinePlay(self.m_SpineEatAct, "start1", true)
                    else
                        util_spinePlay(self.m_SpineEatAct, "idle", true)
                    end
                    if showFun then
                        showFun()
                    end
                    if nextFun then
                        nextFun()
                    end
                end)
            else
                if showFun then
                    showFun()
                end
            end
            local actionList = {}
            actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveBy:create(0.5, cc.p(dis_move,0)),1)
            actionList[#actionList + 1] = cc.CallFunc:create(function()
                if not isBig then
                    if not hasNext then
                        util_spinePlay(self.m_SpineEatAct, "idle", true)
                        self.m_startEat = false
                    end
                    if nextFun then
                        nextFun()
                    end
                end
            end)
            self.m_SpineEatAct:runAction(cc.Sequence:create(actionList)) 
        end
    end
end

function HolidayChallenge_BaseRoadLayer:creatEatEffect(pos)
    if self.m_config.RESPATH.GIFT_NODE_EAT_EFFECT then
        local time = 0.23
        if self.m_startEat then
            time = 0.2
        end
        performWithDelay(self,function(  )
            local eat_effct = util_createAnimation(self.m_config.RESPATH.GIFT_NODE_EAT_EFFECT)
            eat_effct:setPosition(pos)
            self.m_nodeRoad:addChild(eat_effct,300,300)
            performWithDelay(self,function(  )
                eat_effct:removeFromParent()
            end,5 )
        end,time )
    end
end
---------------------------------- 对外接口 部分 ----------------------------------
--[[
    @desc: 对外返回 界面长度
]]
function HolidayChallenge_BaseRoadLayer:getContentLen()
    local len = 0
    for i = 1, 3 do
        local bg = self:findChild("sp_road_" .. i)
        if bg then
            len = len + bg:getContentSize().width
        end
    end
    if self.m_config.ROAD_CONFIG.ROAD_LEN then
        len = self.m_config.ROAD_CONFIG.ROAD_LEN
    end
    self.m_conentLen = len
    return len
end

--[[
    @desc: 返回起始位置
]]
function HolidayChallenge_BaseRoadLayer:getStartX()
    return self.m_startX
end

function HolidayChallenge_BaseRoadLayer:setMoveNum(_moveNum)
    self.m_moveNum = _moveNum
    if self.m_startIndex + self.m_moveNum > self.m_config.ROAD_CONFIG.ROAD_NODE_NUM then
        self.m_moveNum = self.m_config.ROAD_CONFIG.ROAD_NODE_NUM - self.m_startIndex
    end
end

function HolidayChallenge_BaseRoadLayer:playStarMoveAction()
    -- 计算一下当前要移动到的星星坐标
    --设置滑动层不能触摸
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = false})
    if self.m_moveNum > 0 then
        -- 播放音效
        -- gLobalSoundManager:playSound(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig().RESPATH.PUMPKIN_FLYSHOW_MP3)
        --先将当前界面回到初始点 （避免飞行动画还没做的时候就滑动了一些距离）
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_CAR, {moveX = self.m_startX})
        -- 先添加引导动画
        local flyLayerPath = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getFlyLayerPath()
        local view = util_createView(flyLayerPath, self.m_moveNum)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        view:setPosition(display.cx, display.cy)

        local endIndex = self.m_startIndex + 1
        if not self.m_mapNodeInfo then
            release_print("playStarMoveAction : m_mapNodeInfo nil  endIndex:"..endIndex)
        elseif not self.m_mapNodeInfo[endIndex] then
            release_print("playStarMoveAction : m_mapNodeInfo[endIndex] nil  endIndex:"..endIndex)
        end
        local endPos = self.m_mapNodeInfo[endIndex].pos
        local newPos = cc.p(endPos.x - math.abs(self.m_startX), endPos.y)
        view:setMoveActionParam(
            newPos,
            function()
                -- 开始播放酒杯动画
                self:showCupAction()
            end
        )
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = true})
    end
end

---------------------------------- 引导 部分 ----------------------------------
-- 开始播放引导动画
function HolidayChallenge_BaseRoadLayer:startPlayGuideAction()
    if self.m_sp_npc then
        self.m_sp_npc:setVisible(false)
    end
    --设置滑动层不能触摸
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = false})

    -- 创建引导界面
    local guideLayerPath = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getGuideLayerPath()
    self.m_guideLayer = util_createView(guideLayerPath)
    gLobalViewManager:showUI(self.m_guideLayer, ViewZorder.ZORDER_UI)
    if not self.m_activityConfig.ROAD_CONFIG.GUIDE_NO_SET_POS then
        self.m_guideLayer:setPosition(display.cx, display.cy)
    end

    self.data = {
        pos = nil,
        zorder = 1,
        parent = nil
    }

    self.m_guideStep = 1
    self:showGuideStep()
end

function HolidayChallenge_BaseRoadLayer:showGuideStep()
    -- 清空暂停点
    self.m_guidePuseX = 0

    local delay = 4
    self.m_nextFunc = nil
    self.m_guideSchedule = nil
    if not self.m_guideLayer then
        return
    end

    local guide_off_x = display.width / 3

    if self.m_guideStep == 1 then
        self.m_guideLayer:updateView(1)
        self.m_nextFunc = function()
            if self.m_guideLayer then
                -- 隐藏所有引导点
                self.m_guideLayer:hideAllGuideNode()
                -- 暂停的坐标
                self.m_guidePuseX = self.m_mapNodeInfo[self.m_config.GUIDE_STEP_LIST[1]].pos.x - guide_off_x
                -- 隐藏遮罩
                self.m_guideLayer:setMaskVisible(false)
            end
            -- 开始滑动
            local currActData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
            if currActData then
                local maxPoint = currActData:getMaxPoints()
                self:guideMoveFunc(self.m_startX, maxPoint, maxPoint, true)
            end
        end
        self.m_guideSchedule = performWithDelay(self, self.m_nextFunc, delay)
    elseif self.m_guideStep == 2 then
        self.m_guideLayer:updateView(2)
        -- 高亮星星
        self:changeGuideNodeZorder(self.m_config.GUIDE_STEP_LIST[1])
        -- 显示遮罩
        self.m_guideLayer:setMaskVisible(true)
        self.m_nextFunc = function()
            if self.m_guideLayer then 
                -- 隐藏所有引导点
                self.m_guideLayer:hideAllGuideNode()
                -- 还原高亮星星
                self:resetGuideNodeZOrder()
                -- 暂停的坐标
                self.m_guidePuseX = self.m_mapNodeInfo[self.m_config.GUIDE_STEP_LIST[2]].pos.x - guide_off_x
                -- 隐藏遮罩
                self.m_guideLayer:setMaskVisible(false)
            end
            
            -- 恢复暂停
            self.m_pauseMove = false
        end
        self.m_guideSchedule = performWithDelay(self, self.m_nextFunc, delay)
    elseif self.m_guideStep == 3 then
        self.m_guideLayer:updateView(3)
        -- 高亮星星
        self:changeGuideNodeZorder(self.m_config.GUIDE_STEP_LIST[2])
        -- 显示遮罩
        self.m_guideLayer:setMaskVisible(true)
        self.m_nextFunc = function()
            if self.m_guideLayer then
                -- 隐藏所有引导点
                self.m_guideLayer:hideAllGuideNode()
                -- 还原高亮星星
                self:resetGuideNodeZOrder()
                -- 隐藏遮罩
                self.m_guideLayer:setMaskVisible(false)
                -- 停止掉原来的定时器
                if self.m_CGMoveTick then
                    self:stopAction(self.m_CGMoveTick)
                    self.m_CGMoveTick = nil
                    self.m_pauseMove = false
                end
            end
            
            -- 回滚到开头
            local currActData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
            if currActData then
                local maxPoint = currActData:getMaxPoints()
                self:guideMoveFunc(self.m_guideMoveX, 1, maxPoint, false)
            end
        end
        self.m_guideSchedule = performWithDelay(self, self.m_nextFunc, delay)
    elseif self.m_guideStep == 4 then
        self.m_guideLayer:updateView(4)
        -- 停止掉原来的定时器
        if self.m_CGMoveTick then
            self:stopAction(self.m_CGMoveTick)
            self.m_CGMoveTick = nil
            self.m_pauseMove = false
        end
        -- 发送消息给 mainUI层 高亮付费按钮
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_CHANGENODEZORDER, {reset = false})
        -- 显示遮罩
        self.m_guideLayer:setMaskVisible(true)
        -- 恢复 ui 层按钮触摸
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = true})
        self.m_nextFunc = function()
            if self.m_guideLayer then
                -- 隐藏所有引导点
                self.m_guideLayer:hideAllGuideNode()
                -- 还原高亮购买按钮
                self:resetGuideNodeZOrder()
                -- 隐藏遮罩
                self.m_guideLayer:setMaskVisible(false)
            end

            self:showGuideStep()
        end
        self.m_guideSchedule = performWithDelay(self, self.m_nextFunc, delay)
    elseif self.m_guideStep == 5 then
        -- 引导结束
        -- 发送消息给 mainUI层 高亮付费按钮
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_CHANGENODEZORDER, {reset = true})
        performWithDelay(
            self,
            function()
                if self.m_guideLayer then
                    self.m_guideLayer:closeUI()
                    self.m_guideLayer = nil
                end
                if self.m_sp_npc then
                    self.m_sp_npc:setVisible(true)
                end
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE, {flag = true})
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_CAR, {moveX = self.m_startX})
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_OVER)
            end,
            0.2
        )
    end

    self.m_guideStep = self.m_guideStep + 1
end

function HolidayChallenge_BaseRoadLayer:guideMoveFunc(_currentX, _moveNum, _endIndex, _dictRight)
    local targetPos = self.m_mapNodeInfo[_endIndex].pos
    local moveDis = math.abs(_currentX - targetPos.x)
    local frameMoveX = display.cx
    local moveFrame = 1 / 60 -- 刷新帧率
    local moveRate = moveFrame * 7 -- 移动速率

    self.m_CGMoveTick =
        schedule(
        self,
        function()
            if self.m_pauseMove then
                return
            end
            frameMoveX = frameMoveX + moveDis / _moveNum * moveRate
            local startX = _currentX + frameMoveX
            if _dictRight == false then
                startX = _currentX - frameMoveX
            end
            local moveX = startX - display.cx
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_CAR, {moveX = -moveX})

            --csc 2021-10-22 00:00:37 因为有可能路面长度做的不够长,导致摆放的物品没有在正中心,所以这里要额外计算
            -- 如果当前最后一个物品不在中心,需要马上中断
            local moreThanDisplay = false
            if (moveX + display.width) > self.m_conentLen - self.m_config.ROAD_CONFIG.ROAD_DIS then
                moreThanDisplay = true
            end
            -- 引导的时候 滑动了多少距离
            self.m_guideMoveX = moveX
            -- 暂停逻辑
            if moreThanDisplay or (self.m_guidePuseX > 0 and frameMoveX >= self.m_guidePuseX) then
                -- self.m_guideMoveX  = self.m_guideMoveX - (moveDis/_moveNum * moveRate)
                --到达需要暂停的点
                self.m_pauseMove = true
                moreThanDisplay = false
                self:showGuideStep()
                return
            end

            if _dictRight == false then
                -- 停止逻辑
                if frameMoveX >= (targetPos.x) then
                    self.m_pauseMove = true
                    self:showGuideStep()
                end
            end
        end,
        moveFrame
    )
end

function HolidayChallenge_BaseRoadLayer:changeGuideNodeZorder(_index)
    local node = self.m_mapNodeInfo[_index].node
    self.data.node = node
    self.data.zorder = node:getZOrder()
    self.data.parent = node:getParent()
    self.data.pos = cc.p(node:getPosition())

    local nodeWorldPos = self.m_mapNodeInfo[_index].pos
    local newPos = cc.p(nodeWorldPos.x - math.abs(self.m_guideMoveX), nodeWorldPos.y)
    node:setPosition(newPos)

    -- csc 2022-01-20 11:33:12 效果上优化 ，让这个引导点变成高亮的状态
    if node.changeGuideNodeZorder then
        node:changeGuideNodeZorder(true)
    end

    util_changeNodeParent(gLobalViewManager:getViewLayer(), node, ViewZorder.ZORDER_GUIDE + 2)
end

function HolidayChallenge_BaseRoadLayer:resetGuideNodeZOrder()
    if self.data and self.data.node ~= nil then
        if self.data.node.changeGuideNodeZorder then
            self.data.node:changeGuideNodeZorder(false)
        end
        util_changeNodeParent(self.data.parent, self.data.node, self.data.zorder)
        self.data.node:setScale(1)
        self.data.node:setPosition(self.data.pos)
        self.data.parent = nil
        self.data.node = nil
        self.data.zorder = 1
        self.data.pos = nil
    end
end

function HolidayChallenge_BaseRoadLayer:onEnter()
    HolidayChallenge_BaseRoadLayer.super.onEnter(self)

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
    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.HolidayChallenge then
                self:stopGuide()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function HolidayChallenge_BaseRoadLayer:stopGuide()
    self:resetGuideNodeZOrder()
    if self.m_guideSchedule then
        self:stopAction(self.m_guideSchedule)
        self.m_guideSchedule = nil
    end
    if self.m_guideLayer then
        self.m_guideLayer:removeFromParent()
        self.m_guideLayer = nil
    end
end

return HolidayChallenge_BaseRoadLayer
