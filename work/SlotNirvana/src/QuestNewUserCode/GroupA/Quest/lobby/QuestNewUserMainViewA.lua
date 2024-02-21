-- Created by jfwang on 2019-05-21.
-- Quest活动主界面
--

local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local QuestNewUserMainViewA = class("QuestNewUserMainViewA", BaseActivityMainLayer)

--云遮罩相对于箭头的位置
local MapMaskNodeOffX = 350
local MAX_PHASE_COUNT = 1 --阶段数量
local STAGE_COUNTS_IN_PHASE = 7 -- 章节关卡数

function QuestNewUserMainViewA:ctor()
    QuestNewUserMainViewA.super.ctor(self)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestMainLayer)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setHideLobbyEnabled(true)
    self:setIgnoreAutoScale(true)
    self:setBgm(QUEST_RES_PATH.QuestBGMPath)
    self:setExtendData("QuestMainLayer")
end

function QuestNewUserMainViewA:getQuestData()
    local questData = G_GetMgr(ACTIVITY_REF.Quest):getData()
    if questData and questData:isNewUserQuest() then
        return questData
    end
end

--初始化数据
function QuestNewUserMainViewA:initDatas()
    globalData.slotRunData.isDeluexeClub = false
    globalData.deluexeHall = false
    self.m_config = self:getQuestData()
    self.m_questCellList = {}
    --读取quest配置文件
    G_GetMgr(ACTIVITY_REF.Quest):checkReadMapConfig()
end

function QuestNewUserMainViewA:initCsbNodes()
    self.node_reward = self:findChild("node_reward")
    self.node_logo = self:findChild("Node_log")
    self.node_bg = self:findChild("questbg")

    self.node_map = cc.Node:create()

    self.node_bg:addChild(self.node_map, 1)
    self.node_bg:setPosition(-display.width / 2, -display.height / 2)
end

function QuestNewUserMainViewA:initLogo()
    if self.node_logo then
        local icon_logo = util_createFindView(QUEST_CODE_PATH.QuestLobbyLogo)
        if icon_logo then
            icon_logo:addTo(self.node_logo)
        end
    end
end

function QuestNewUserMainViewA:initTitle()
    if self.node_reward then
        local item_title = util_createFindView(QUEST_CODE_PATH.QuestLobbyTitle)
        if item_title then
            item_title:addTo(self.node_reward)
            self.item_title = item_title
        end
    end
end

function QuestNewUserMainViewA:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestNewUserMainViewA:initView()
    self:initLogo()
    self:initTitle()

    self:initScrollBackground()

    local startX, startIdx = self:getStartPosX()
    self:initQuestLayer(startIdx)
    self:initBox()

    local questConfig = self:getQuestData()
    if questConfig and questConfig.p_expireAt then
        gLobalDataManager:setBoolByField("quest_fristGudie" .. questConfig.p_expireAt, false)
    end
end

-- 更新顶部的阶段奖励
function QuestNewUserMainViewA:updateTitle()
    if self.item_title then
        self.item_title:updatePhaseReward()
    end
end

function QuestNewUserMainViewA:initScrollBackground()
    --背景条
    local nodeInfoList = {}
    for i = 1, QUEST_RES_PATH.QuestMapBgCount do
        local path = QUEST_RES_PATH.QuestMapCellPath .. (i - 1) .. ".jpg"
        nodeInfoList[#nodeInfoList + 1] = {path, QUEST_RES_PATH.QuestMapBgWidth}
    end

    --地图控制类
    self.m_questMapControl = util_createFindView(QUEST_CODE_PATH.QuestMapControl, self.node_map, nodeInfoList)
    local function funcMove(x)
        self.m_questMapControl:updateMap(x)
    end
    --地图滑动类
    self.m_questMapScroll = util_createFindView(QUEST_CODE_PATH.QuestMapScroll, self.node_map, cc.p(0, display.cy), funcMove)
    local contentLen = self.m_questMapControl:getContentLen()
    local mapLimitLen = display.width - contentLen
    self.m_questMapScroll:setMoveLen(mapLimitLen)

    --初始位置计算
    local startX, startStageIndex = self:getStartPosX()
    self.m_questMapScroll:move(startX)
    self.m_questMapControl:initDisplayNode(self.m_questMapScroll:getCurrentOffset())
end

-- 初始化宝箱
function QuestNewUserMainViewA:initBox()
    if not self.m_config then
        return
    end
    --宝箱
    self.m_boxList = {}
    -- 优先初始化当前段位的箱子
    local phase_idx = self.m_config:getPhaseIdx()
    local stage_idx = self.m_config:getStageIdx()
    self:initBoxByIndex(phase_idx, stage_idx)

    local phase_data = self.m_config:getCurPhaseData()
    local idx = 1
    self.m_boxSchedule =
        schedule(
        self,
        function()
            if idx > #QUEST_MAPBOX_LIST then
                if self.m_boxSchedule then
                    self:stopAction(self.m_boxSchedule)
                    self.m_boxSchedule = nil
                end
                return
            end

            if idx ~= stage_idx and idx <= #phase_data.p_stages then
                self:initBoxByIndex(phase_idx, idx)
            end

            idx = idx + 1
        end,
        0.05
    )
end

-- 初始化单个宝箱
function QuestNewUserMainViewA:initBoxByIndex(phase_idx, stage_idx)
    local pos = QUEST_MAPBOX_LIST[stage_idx]
    local stageNum = STAGE_COUNTS_IN_PHASE

    local unLockIndex = (phase_idx - 1) * (stageNum + 1) + stage_idx
    local boxNode
    if stage_idx ~= stageNum then
        boxNode = util_createFindView(QUEST_CODE_PATH.QuestGift, phase_idx, stage_idx)
    else
        boxNode = util_createFindView(QUEST_CODE_PATH.QuestBox, phase_idx, stage_idx)
    end

    self.node_map:addChild(boxNode, self:getZOrderByIndex(unLockIndex))
    boxNode:setTag(unLockIndex)
    local idx = (phase_idx - 1) * STAGE_COUNTS_IN_PHASE + stage_idx
    self.m_boxList[idx] = boxNode
    if stage_idx == STAGE_COUNTS_IN_PHASE then
        boxNode:setPosition(pos.x + QUEST_CONFIGS.box_offset, pos.y - display.height / 2)
    else
        boxNode:setPosition(pos.x, pos.y - display.height / 2)
    end
end

function QuestNewUserMainViewA:onEnter()
    QuestNewUserMainViewA.super.onEnter(self)

    gLobalSendDataManager:getLogQuestNewUserActivity():sendQuestUILog("QuestLobby", "Open")
    local newCount = gLobalDataManager:getNumberByField("Activity_Quest_New", 0)
    newCount = newCount + 1
    gLobalDataManager:setNumberByField("Activity_Quest_New", newCount)

    -- 关卡播放完成动画后，处理轮盘的解锁动画
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:changeStageHandler()
            self:questCellUnlock(params.index)
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                self:showBoxOpen()
            end
        end,
        ViewEventType.NOTIFY_QUEST_CELL_REWARD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not tolua.isnull(self) then
                self:showRewardLayer()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_STAGE_COMPLETE
    )

    gLobalPopViewManager:setPause(true)
    self:checkShowWheelGuide()
end

function QuestNewUserMainViewA:showBoxOpen()
    local quest_data = self:getQuestData()
    if not quest_data then
        return
    end
    if self.m_boxList and table.nums(self.m_boxList) > 0 then
        for i, box_item in pairs(self.m_boxList) do
            if box_item then
                local record_data = G_GetMgr(ACTIVITY_REF.Quest):getRecordRewardData()
                if record_data.phase_idx == box_item.phase_idx and record_data.stage_idx == box_item.stage_idx then
                    local state_data = quest_data:getStageData(box_item.phase_idx, box_item.stage_idx)
                    if state_data.p_status == "FINISHED" or state_data:getIsLast() then
                        box_item:openBox()
                        break
                    end
                end
            end
        end
    end
end

function QuestNewUserMainViewA:showRewardLayer()
    local data = G_GetMgr(ACTIVITY_REF.Quest):getRecordRewardData()
    if not data then
        return
    end
    local _index = data.stage_idx
    local view = util_createView("QuestNewUserCode.GroupA.Quest.pop.QuestNewUserRewardView", data)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK, {index = _index}) --执行下一个服务器弹窗
    end
end

function QuestNewUserMainViewA:changeStageHandler()
    local config = self:getQuestData()
    if config and config:checkIsLastRound() then
        -- cxc 2023年11月30日15:02:44  新手quest 结束 监测弹（评分, 绑定Fb, 绑定邮箱）
        local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Quest", "QuestChapter_1")
        if view then
            view:setOverFunc(util_node_handler(self, self.showOverLayer))
        else
            self:showOverLayer()
        end
    else
        self:checkResetMapPos()
        self:updateTitle()
    end
end

-- 新手quest完成 结束弹板
function QuestNewUserMainViewA:showOverLayer()
    G_GetMgr(ACTIVITY_REF.Quest):showOverLayer(
        function()
            self:closeUI()
        end,
        true
    )
end

function QuestNewUserMainViewA:onExit()
    QuestNewUserMainViewA.super.onExit(self)
    if self.m_config ~= nil then
        self.m_config.m_isQuestLobby = false
    end
end

function QuestNewUserMainViewA:checkResetMapPos()
    local questConfig = self:getQuestData()
    if not questConfig then
        return
    end
    if questConfig:getIsFirstStage() then
        self.m_questMapScroll:move(0)
        self.m_questMapControl:initDisplayNode(0)
        self:updateLevelCell()
    end
    -- local phase_idx = questConfig:getPhaseIdx()
    -- if phase_idx > 1 then
    --     self:unlockNextLevel((phase_idx - 1) * STAGE_COUNTS_IN_PHASE)
    -- end
    local stage_idx = questConfig:getStageIdx()
    self:unlockNextLevel(stage_idx - 1)
end

--获得关卡节点宽度
function QuestNewUserMainViewA:getCellWidth()
    local maxStageCount = self.m_config:getStageCount()
    local cWidth = 1660 / STAGE_COUNTS_IN_PHASE
    if maxStageCount > 0 then
        cWidth = QUEST_RES_PATH.QuestMapBgCount * QUEST_RES_PATH.QuestMapBgWidth / maxStageCount
    end

    return cWidth
end

--初始化箭头
function QuestNewUserMainViewA:initArrow()
    if not self.m_config then
        return
    end
    self.m_questArrowList = {}
    for i = 1, #QUEST_CONFIGS.arrow_posX do
        if i > self.m_config:getPhaseCount() then
            return
        end

        local arrow = util_createAnimation(QUEST_RES_PATH.QuestMapArrow)
        self.node_map:addChild(arrow, 1)
        self.m_questArrowList[i] = arrow
        local cellWidth = self:getCellWidth()
        arrow:playAction("idle", true)
        arrow:setPosition(QUEST_CONFIGS.arrow_posX[i], QUEST_CONFIGS.arrow_posY[i])
        local m_lb_num = arrow:findChild("m_lb_num")
        if m_lb_num then
            m_lb_num:setString(i)
        end
    end
end

-- 获得当前地图中的位置
function QuestNewUserMainViewA:getStartPosX()
    local _curStageIndex = 0
    local questData = self.m_config
    local phase_idx = questData:getPhaseIdx()
    local phasesList = questData.p_phases or {}
    for i = 1, #phasesList do
        local stageData = phasesList[i]
        local stageNum = #stageData.p_stages
        if i < phase_idx then
            _curStageIndex = _curStageIndex + stageNum
        elseif i == phase_idx then
            _curStageIndex = _curStageIndex + questData:getStageIdx()
            break
        end
    end

    local curPosX = self:getOffsetByIndex(_curStageIndex)
    --最小值判断
    local moveLen = self.m_questMapScroll:getMoveLen()
    curPosX = math.max(curPosX, moveLen)

    return curPosX, _curStageIndex
end

function QuestNewUserMainViewA:initQuestLayer(startStageIndex)
    self.m_questCellList = {}
    if self.m_config == nil or self.node_map == nil then
        return 0
    end

    --本阶段所有的关卡数据
    local phasesList = self.m_config.p_phases
    if phasesList == nil or #phasesList <= 0 then
        return 0
    end

    -- 箭头
    self:initArrow()
    self:initLevelCells(phasesList, startStageIndex)
end

-- 初始化关卡Cell
function QuestNewUserMainViewA:initLevelCells(phasesList, curCellIndex)
    local phasesList = phasesList or {}
    local cellWidth = self:getCellWidth()
    local len = #phasesList
    local index = 1
    -- 关卡cell信息
    local levelCellDatas = {}

    for i = 1, len do
        local stageData = phasesList[i]
        local stageNum = #stageData.p_stages
        if stageData.p_stages ~= nil and stageNum > 0 then
            for j = 1, stageNum do
                local unLockIndex = (i - 1) * (stageNum + 1) + j
                levelCellDatas[index] = {
                    phase = i,
                    stage = j,
                    index = index,
                    unLockIndex = unLockIndex
                }
                index = index + 1
            end
        end
    end

    -- 创建关卡cell
    local createCell = function(cellIndex)
        if cellIndex < 1 or cellIndex > #levelCellDatas then
            return
        end

        local cellInfo = levelCellDatas[cellIndex]
        self:createLevelCell(cellInfo) -- , handler(self, self.unLockFunc)
    end

    -- 定时加载，从当前节点的左右两侧加载，先创建3个
    local cellIdx = curCellIndex or 1
    createCell(cellIdx)
    local cellIdxL = cellIdx - 1
    createCell(cellIdxL)
    local cellIdxR = cellIdx + 1
    createCell(cellIdxR)

    self.m_cellSchedule =
        schedule(
        self.node_map,
        function()
            cellIdxL = cellIdxL - 1
            cellIdxR = cellIdxR + 1
            if cellIdxR > #levelCellDatas and cellIdxL < 1 then
                if self.m_cellSchedule then
                    self.node_map:stopAction(self.m_cellSchedule)
                    self.m_cellSchedule = nil
                end
                return
            end

            -- 创建左边的节点
            createCell(cellIdxL)

            -- 创建右边的节点
            createCell(cellIdxR)
        end,
        0.05
    )
end

function QuestNewUserMainViewA:createLevelCell(stageData)
    if not stageData then
        return
    end
    local index = stageData.index
    if not QUEST_MAPCELL_LIST[index] then
        return
    end

    local maxStageCount = self.m_config:getStageCount()
    local unLockIndex = stageData.unLockIndex

    local cell = util_createView(QUEST_CODE_PATH.QuestCell, stageData)
    cell:setPosition(QUEST_MAPCELL_LIST[index].x, QUEST_MAPCELL_LIST[index].y - display.height * 0.5)
    cell:setTag(index)

    self.node_map:addChild(cell, self:getZOrderByIndex(unLockIndex))
    self.m_questCellList[index] = cell

    return cell
end

function QuestNewUserMainViewA:updateLevelCell()
    local phasesList = self.m_config.p_phases
    if not phasesList then
        return
    end
    
    for i = 1, #self.m_questCellList do
        local cell = self.m_questCellList[i]
        if not tolua.isnull(cell) then
            cell:initState()
        end
    end
end

function QuestNewUserMainViewA:onKeyBack()
    --引导期间不能点击返回键
    local questConfig = self:getQuestData()
    if questConfig and questConfig.p_expireAt then
        --不是第一关 可能是清除本地数据
        if questConfig:getIsFirstStage() then
            local isWheelGuide = gLobalDataManager:getBoolByField("quest_wheelGuide" .. questConfig.p_expireAt, true)
            if isWheelGuide then
                return
            end
        end
    end
    local view =
        gLobalViewManager:showDialog(
        "Dialog/ExitGame_Lobby.csb",
        function()
            if not tolua.isnull(self) then
                self:closeUI()
            end
        end
    )
    view:setLocalZOrder(ViewZorder.ZORDER_LOADING)
end

function QuestNewUserMainViewA:checkShowWheelGuide()
    local questConfig = self:getQuestData()
    if questConfig and questConfig.p_expireAt then
        local isWheelGuide = gLobalDataManager:getBoolByField("quest_wheelGuide" .. questConfig.p_expireAt, true)
        --不是第一关 可能是清除本地数据
        if not questConfig:getIsFirstStage() then
            gLobalDataManager:setBoolByField("quest_wheelGuide" .. questConfig.p_expireAt, false)
            isWheelGuide = false
        end
        -- cxc 2023年08月21日12:23:08 关闭新手quest 引导
        isWheelGuide = false
        -- test
        -- isWheelGuide = true
        --显示轮盘引导
        if isWheelGuide then
            local width = 500
            local infoList = {} --抠图信息
            local startX = self:getOffsetByIndex(1)
            local endX = self.m_questMapScroll:getMoveLen()

            local pos = QUEST_MAPBOX_LIST[7]
            local offsetX = 50
            local offsetY = 70
            infoList[1] = {pos.x + offsetX + endX, pos.y + offsetY, width}
            self:moveTo(
                startX,
                endX,
                -1,
                function()
                    local baseNode =
                        globalNoviceGuideManager:addSimpleMaskUI(
                        infoList,
                        4.5,
                        function()
                            gLobalDataManager:setBoolByField("quest_wheelGuide" .. questConfig.p_expireAt, false)
                            --确认类还存在
                            if self.moveTo and self.unlockNextLevel then
                                self:moveTo(endX, startX, 1)
                            end
                        end
                    )
                    if baseNode then
                        local sp_hero = util_spineCreate("GuideNewUser/Other/xiaoqiche", false, true, 1)
                        baseNode:addChild(sp_hero)
                        util_spinePlay(sp_hero, "idle2", true)
                        --描述文字
                        local spTitle = util_createSprite("QuestNewUser/Activity/NewQuestOther/quest_guide_msg.png")
                        baseNode:addChild(spTitle)
                        if display.width <= 1024 then
                            spTitle:setScale(0.8)
                            spTitle:setPosition(display.cx - 300, 550)
                            sp_hero:setPosition(display.cx - 220, 300)
                        else
                            sp_hero:setScale(1.4)
                            local offX = math.max(0, (display.width - DESIGN_SIZE.width) * 0.8)
                            spTitle:setPosition(display.cx - 370 + offX, 600)
                            sp_hero:setPosition(display.cx - 100 + offX, 300)
                        end
                    end
                end
            )
        end
    end
end

--默认按钮监听回调
function QuestNewUserMainViewA:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function QuestNewUserMainViewA:closeUI()
    if self.m_moveMaskLayer then
        self.m_moveMaskLayer:removeFromParent()
        self.m_moveMaskLayer = nil
    end

    -- 修改bug 去除控件添加的遮罩
    local cell_mask = gLobalViewManager:getViewByName("questNewUserCellMask")
    if cell_mask then
        cell_mask:removeFromParent()
        cell_mask = nil
    end

    QuestNewUserMainViewA.super.closeUI(
        self,
        function()
            -- csc 2021-11-22 18:27:12 添加新手quest 也需要弹队列
            if gLobalPopViewManager:isPopView() then
                gLobalPopViewManager:setPause(false)
                if gLobalPopViewManager:isEventType("configPushView") then
                    gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT) --执行下一个服务器弹窗
                else
                    --弹窗逻辑执行下一个事件
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
            else
                --直接尝试执行初始化弹窗逻辑
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWUSER_LOBBY_INITNOOB)
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MULEXP_END)
        end
    )
end

-- 滚动到轮盘位置
function QuestNewUserMainViewA:moveTo(currentOffset, targetOffset, moveDir, overFunc)
    if targetOffset == currentOffset then
        return
    end
    self.m_moveMaskLayer = util_newMaskLayer()
    gLobalViewManager:getViewLayer():addChild(self.m_moveMaskLayer, ViewZorder.ZORDER_SPECIAL)
    self.m_moveMaskLayer:setOpacity(0)
    local changeNum = math.abs(currentOffset - targetOffset)
    -- 动画tick
    local frameMoveX = 0
    local moveTime = 1
    local moveFrame = 0.03
    local moveNum = moveTime / moveFrame
    local count = 0
    self.m_CGMoveTick =
        schedule(
        self,
        function()
            frameMoveX = frameMoveX + changeNum / moveNum
            if moveDir == -1 then
                local startX = currentOffset - frameMoveX
                self.m_questMapScroll:move(startX)
                self.m_questMapControl:initDisplayNode(startX)
            elseif moveDir == 1 then
                local startX = currentOffset + frameMoveX
                self.m_questMapScroll:move(startX)
                self.m_questMapControl:initDisplayNode(startX)
            end
            -- 停止逻辑
            count = count + 1
            if count >= moveNum then
                self:stopAction(self.m_CGMoveTick)
                self.m_CGMoveTick = nil
                if moveDir == 1 then
                    if self.m_moveMaskLayer then
                        self.m_moveMaskLayer:removeFromParent()
                        self.m_moveMaskLayer = nil
                    end
                elseif moveDir == -1 then
                    if self.m_moveMaskLayer then
                        self.m_moveMaskLayer:removeFromParent()
                        self.m_moveMaskLayer = nil
                    end
                end
                if overFunc then
                    overFunc()
                end
            end
        end,
        moveFrame
    )
end

-- TODO:
function QuestNewUserMainViewA:getOffsetByIndex(index)
    if not index or index == 0 then
        return 0
    end
    
    local cellWidth = self:getCellWidth()
    if index > #QUEST_MAPCELL_LIST then
        index = #QUEST_MAPCELL_LIST
    end
    local curPosX = cellWidth * 0.5 - QUEST_MAPCELL_LIST[index].x
    curPosX = curPosX + display.cx - cellWidth * 0.5
    return curPosX
end

function QuestNewUserMainViewA:getBoxOffsetByIndex(index)
    local cellWidth = self:getCellWidth()
    if index > #QUEST_MAPBOX_LIST then
        index = #QUEST_MAPBOX_LIST
    end
    local curPosX = cellWidth * 0.5 - QUEST_MAPBOX_LIST[index].x
    curPosX = curPosX + display.cx - cellWidth * 0.5
    return curPosX
end

function QuestNewUserMainViewA:getZOrderByIndex(index)
    local maxStageCount = self.m_config:getStageCount()
    return 10 + (maxStageCount - index)
end

--解锁
function QuestNewUserMainViewA:questCellUnlock(lastIndex)
    local pre_cell = self.m_questCellList[lastIndex]
    if not tolua.isnull(pre_cell) then
        pre_cell:initState()
    end

    local index = lastIndex + 1
    local cur_cell = self.m_questCellList[index]
    if not tolua.isnull(cur_cell) then
        cur_cell:initState()
    end
end

function QuestNewUserMainViewA:unlockNextLevel(lastIndex)
    local startX = self:getOffsetByIndex(lastIndex)
    local endX = self:getOffsetByIndex(lastIndex + 1)
    self:moveTo(startX, endX, -1)
end

function QuestNewUserMainViewA:getRefName()
    return ACTIVITY_REF.Quest
end

return QuestNewUserMainViewA
