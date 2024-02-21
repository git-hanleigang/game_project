--
-- Quest活动主界面
--

local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local QuestMainView = class("QuestMainView", BaseActivityMainLayer)

--云遮罩相对于箭头的位置
local MapMaskNodeOffX = 350

local MAP_MASKNODE_ENABLE = true --地图迷雾

local MAX_PHASE_COUNT = 6 --阶段数量

QuestMainView.m_questMapControl = nil --地图控制类
QuestMainView.m_questMapScroll = nil --地图滚动类
QuestMainView.m_mapMaskNode = nil --迷雾遮罩

QuestMainView.m_questCellList = {} --关卡列表
QuestMainView.m_boxList = nil --宝箱列表
QuestMainView.m_questArrowList = nil --箭头列表

function QuestMainView:ctor()
    QuestMainView.super.ctor(self)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestMainLayer)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setHideLobbyEnabled(true)
    self:setIgnoreAutoScale(true)

    self:setBgm(QUEST_RES_PATH.QuestBGMPath)
    -- self:mergePlistInfos(QUEST_PLIST_PATH.QuestMainLayer)
    self:setExtendData("QuestMainLayer")
    G_GetMgr(ACTIVITY_REF.Zombie):setSpinData(true)
end

--初始化数据
function QuestMainView:initDatas(_isAutoPop)
    self.m_isAutoPop = _isAutoPop
    globalData.slotRunData.isDeluexeClub = false
    globalData.deluexeHall = false
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self.m_questCellList = {}
    --读取quest配置文件
    G_GetMgr(ACTIVITY_REF.Quest):checkReadMapConfig()
    --请求quest排行数据
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestRank()
end

function QuestMainView:initCsbNodes()
    self.node_title = self:findChild("Node_title") --标题栏父节点
    self.node_logo = self:findChild("Node_log") -- logo节点
    self.node_rank = self:findChild("Node_rank") -- 排行榜节点
    self.node_mythic = self:findChild("Node_mythic") -- 特殊卡册节点
    local rank_posX = self.node_rank:getPositionX()
    self.node_rank:setPositionX(rank_posX - util_getBangScreenHeight())

    self.node_sale = self:findChild("Node_cx") -- 促销节点
    local sale_posX = self.node_sale:getPositionX()
    self.node_sale:setPositionX(sale_posX - util_getBangScreenHeight())

    self.btn_sale = self:findChild("btn_chuxiao")

    self.node_reward = self:findChild("node_reward")

    self.node_bg = self:findChild("questbg")

    self.node_map = cc.Node:create()
    self.node_bg:addChild(self.node_map, 1)
    self.node_bg:setPosition(-display.width / 2, -display.height / 2)
end

--初始化
function QuestMainView:initView()
    self:initLobbyNode()
    self:initScrollBackground()
    self:updateTitle()
    self:initRushActEntryNode()
    self:createRoade()
    self:initPassEntryNode()
    self:initMythicEntryNode()
    self:showAdsItem()
end

function QuestMainView:createRoade()
    if QUEST_CODE_PATH.QuestMainRoadEffect then
        local maproad = util_createView(QUEST_CODE_PATH.QuestMainRoadEffect)
        if maproad then
            maproad:setPosition(display.width / 2, display.height / 2)
            self.node_bg:addChild(maproad, 1)
        end
    end
end

--初始化quest大厅节点
function QuestMainView:initLobbyNode()
    if self.node_title and display.width <= 1152 then
        self.node_title:setScale(display.width / 1152)
    end

    --logo
    if self.node_logo then
        local icon_logo = util_createFindView(QUEST_CODE_PATH.QuestLobbyLogo)
        if icon_logo then
            icon_logo:addTo(self.node_logo)
        end
    end
    --排行
    if self.node_rank then
        local icon_rank = util_createFindView(QUEST_CODE_PATH.QuestLobbyRank)
        if icon_rank then
            icon_rank:addTo(self.node_rank)
        end
    end

    --促销
    if self.node_sale then
        local pData = G_GetMgr(ACTIVITY_REF.QuestSale):getRunningData()
        if pData ~= nil then
            local icon_sale = util_createFindView(QUEST_CODE_PATH.QuestLobbySale)
            if icon_sale then
                icon_sale:addTo(self.node_sale)
            end
        else
            self.node_sale:setVisible(false)
        end
    end

    --标题栏
    if self.node_reward then
        local item_title = util_createFindView(QUEST_CODE_PATH.QuestLobbyTitle)
        if item_title then
            item_title:addTo(self.node_reward)
            self.item_title = item_title
        end
    end
end

--标题的显示隐藏 刷新标题数据
function QuestMainView:updateTitle()
    if not self.node_title then
        return
    end

    if G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
        self.node_title:setVisible(false)
    else
        self.node_title:setVisible(true)
    end

    if self.item_title then
        self.item_title:updatePhaseReward()
    end
end

--初始化背景
function QuestMainView:initScrollBackground()
    --背景条信息
    local nodeInfoList = {}
    for i = 1, QUEST_RES_PATH.QuestMapBgCount do
        local path = QUEST_RES_PATH.QuestMapCellPath .. (i - 1) .. ".png"
        nodeInfoList[#nodeInfoList + 1] = {path, QUEST_RES_PATH.QuestMapBgWidth}
    end

    --连线动画
    self.m_questLines = util_createFindView(QUEST_CODE_PATH.QuestDrawLine)
    self.node_map:addChild(self.m_questLines, 2)
    self.m_questLines:setPosition(0, -display.height / 2)

    --宝箱
    self:initBox()

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
    self:initQuestLayer(startStageIndex)
    self.m_questMapScroll:move(startX)
    self.m_questMapControl:initDisplayNode(startX)
    --迷雾遮罩
    self:initFogMask()
end

-- 初始化宝箱
function QuestMainView:initBox()
    --宝箱
    self.m_boxList = {}
    -- 优先初始化当前段位的箱子
    local curPhase = self.m_config:getPhaseIdx()
    self:initBoxByIndex(curPhase)

    local i = 1
    self.m_boxSchedule =
        schedule(
        self,
        function()
            if i > #QUEST_MAPBOX_LIST then
                if self.m_boxSchedule then
                    self:stopAction(self.m_boxSchedule)
                    self.m_boxSchedule = nil
                end
                return
            end

            if i ~= curPhase then
                self:initBoxByIndex(i)
            end

            i = i + 1
        end,
        0.05
    )
end

-- 初始化单个宝箱
function QuestMainView:initBoxByIndex(i)
    local pos = QUEST_MAPBOX_LIST[i]
    local stageNum = 6
    if self.m_config then
        if self.m_config.p_phases and self.m_config.p_phases[i] then
            stageNum = #self.m_config.p_phases[i].p_stages
        end
    end
    local unLockIndex = i * (stageNum + 1)
    local boxNode = util_createFindView(QUEST_CODE_PATH.QuestBox, i, handler(self, self.unLockFunc))
    self.node_map:addChild(boxNode, self:getZOrderByIndex(unLockIndex))
    boxNode:setTag(unLockIndex)
    self.m_boxList[i] = boxNode
    boxNode:setPosition(pos.x, pos.y - display.height / 2)
    if boxNode:IsUnLock() then
        self:unLockFunc(unLockIndex)
    end
end

-- 初始化迷雾
function QuestMainView:initFogMask()
    if self.m_mapMaskNode then
        self.m_mapMaskNode:removeFromParent()
        self.m_mapMaskNode = nil
    end
    if self.m_config and self.m_config:getPhaseIdx() == MAX_PHASE_COUNT then
        --最后一个阶段不需要迷雾
        return
    end
    if MAP_MASKNODE_ENABLE then
        --迷雾
        self.m_mapMaskNode = util_createAnimation(QUEST_RES_PATH.QuestMapMask)
        self.node_map:addChild(self.m_mapMaskNode, 99)
        self.m_mapMaskNode:playAction("idle", true)
        self.m_mapMaskNode:setScale(display.height / 768)
        self:updateMapMaskNode()
    end
end

-- 增加quest挑战活动入口
function QuestMainView:initRushActEntryNode()
    local bOpenLoad = gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.QuestRush)
    if not bOpenLoad then
        return
    end

    if tolua.isnull(self.btn_sale) or tolua.isnull(self.node_sale) then
        return
    end

    local bFinish = false
    if self.m_config then
        bFinish = self.m_config:IsTaskAllFinish(self.m_config:getPhaseIdx())
    end
    local nodeRushEntry = util_createFindView(QUEST_CODE_PATH.QuestRushEntry, not bFinish)
    if tolua.isnull(nodeRushEntry) then
        return
    end

    nodeRushEntry:setScale(0.62)
    nodeRushEntry:addTo(self.node_sale:getParent())
    local pos = cc.p(self.node_sale:getPosition())
    local posY = pos.y
    if self.node_sale:isVisible() then
        local size = self.btn_sale:getContentSize()
        local offsetY = 0 -- -30
        posY = pos.y - size.height + offsetY
    end
    nodeRushEntry:move(pos.x, posY)
    self.m_nodeRushEntry = nodeRushEntry
end

-- 更新quest挑战活动入口
function QuestMainView:updateRushEntry(_delayTime)
    if tolua.isnull(self.m_nodeRushEntry) then
        return
    end

    _delayTime = _delayTime or 0
    performWithDelay(
        self,
        function()
            if tolua.isnull(self.m_nodeRushEntry) then
                return
            end
            self.m_nodeRushEntry:updateProgressUI()
        end,
        _delayTime
    )
end

function QuestMainView:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "MainView"
end

-- pass入口
function QuestMainView:initPassEntryNode()
    if self.m_passEntry then
        self.m_passEntry:updateView()
        return
    end

    local data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    local node = self:findChild("node_passEntry")
    if data and data.getPassData and data:getPassData() and node then
        self.m_passEntry = util_createFindView(QUEST_CODE_PATH.QuestPassEntryNode)
        self.m_passEntry:addTo(node)
    end
end

-- 特殊卡册入口
function QuestMainView:initMythicEntryNode()
    if not self.node_mythic then
        return
    end
    local specialClanEntry = G_GetMgr(G_REF.CardSpecialClan):createSpecialClanEntry()
    if specialClanEntry then
        self.node_mythic:setScale(1.1)
        self.node_mythic:addChild(specialClanEntry)
        self.m_specialClanEntry = specialClanEntry
    end
end

function QuestMainView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

function QuestMainView:onEnter()
    QuestMainView.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            local pre_idx = params.index - 1
            local cue_idx = params.index
            if (pre_idx % 6 == 0) and (cue_idx % 6 == 1) then
                self:checkResetMapPos()
                self:updateTitle()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_OPEN
    )

    -- 关卡播放完成动画后，处理轮盘的解锁动画
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:questCellUnlock(params.index)
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK
    )

    -- 新关解锁 弹出难度选择界面
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showDifficultView()
        end,
        ViewEventType.NOTIFY_QUEST_NEWSTAGE_UNLOCK
    )
    --选择难度成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateTitle()
            self:updatePhaseCells()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_DIFFICULTY
    )

    --选择难度关闭
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_DIFFICULTY_CLOSED
    )

    ---- 活动结束事件
    --gLobalNoticManager:addObserver(
    --    self,
    --    function(self, params)
    --        if params.name == ACTIVITY_REF.Quest then
    --            --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_VIEW_HIDE)
    --            self:closeUI()
    --        elseif params.name == ACTIVITY_REF.QuestRush then
    --            self:resetQuestRushState()
    --        end
    --    end,
    --    ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    --)

    -- 刷新 挑战活动 入口UI
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateRushEntry()
        end,
        ViewEventType.NOTIFY_QUEST_RUSH_ENTERY_UPDATE
    )

    -- 弹出轮盘界面
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if not quest_data then
                return
            end

            local bl_complete = false
            local box_data = nil
            local wheel_data = nil
            if params and type(params.bl_complete) == "boolean" then
                bl_complete = params.bl_complete
                local phase_data = quest_data:getCurPhaseData()
                if phase_data then
                    wheel_data = phase_data.p_wheel
                end
            end
            if bl_complete == true and self.m_config then
                box_data = quest_data:getPhaseReward()
            else
                box_data = params.box_data
            end
            self:showWheelView(bl_complete, box_data, wheel_data)
        end,
        ViewEventType.NOTIFY_QUEST_WHEEL_SHOW
    )
    self:showDifficultView()
end

function QuestMainView:showDifficultView()
    if G_GetMgr(ACTIVITY_REF.Quest):IsNeedShowDifficultyView() then
        G_GetMgr(ACTIVITY_REF.Quest):showDifficultyView()
    end
end

function QuestMainView:showWheelView(bl_complete, box_data, wheel_data)
    if bl_complete and not box_data then
        return
    end

    local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not quest_data then
        return
    end

    -- local view = util_createView(QUEST_CODE_PATH.QuestWheel, wheel_data, box_data.p_coins, bl_complete)
    -- if not view then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_WHEEL_ROLL_OVER)
    --     return
    -- end
    -- self:addChild(view)
    if gLobalViewManager:getViewByName("QuestJackpotWheelLayer") ~= nil then
        return
    end
    local view = util_createView(QUEST_CODE_PATH.QuestJackpotWheelLayer,{isLookPreview = not bl_complete})
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function QuestMainView:onExit()
    if self.m_config ~= nil then
        self.m_config.m_isQuestLobby = false
    end
    self:stopSchedule()

    QuestMainView.super.onExit(self)
end

--重置地图位置刷新迷雾遮罩
function QuestMainView:checkResetMapPos()
    if not self.m_config then
        return
    end
    if self.m_config:getIsFirstStage() then
        if not self.m_mapMaskNode and MAP_MASKNODE_ENABLE then
            -- 迷雾
            self.m_mapMaskNode = util_createAnimation(QUEST_RES_PATH.QuestMapMask)
            self.node_map:addChild(self.m_mapMaskNode, 99)
            self.m_mapMaskNode:playAction("idle", true)
            self.m_mapMaskNode:setScale(display.height / 768)
        end

        if self.m_questLines then
            self.m_questLines:clearPoints()
        end
        self.m_questMapScroll:move(0)
        self.m_questMapControl:initDisplayNode(0)
        self:updateLevelCell()
    end
    self:updateMapMaskNode()
    local phase_idx = self.m_config:getPhaseIdx()
    if phase_idx > 1 then
        self:unlockNextLevel((phase_idx - 1) * 6)
    end
end
--获得关卡节点宽度
function QuestMainView:getCellWidth()
    local maxStageCount = self.m_config:getStageCount()
    local cWidth = 1660 / 6
    if QUEST_RES_PATH.BG_ROAD_LEN then
        cWidth = QUEST_RES_PATH.BG_ROAD_LEN / maxStageCount -- 取中景层长度 除以关卡数 得到均分的每一个关卡的宽度
    else
        if maxStageCount > 0 then
            cWidth = QUEST_RES_PATH.QuestMapBgCount * QUEST_RES_PATH.QuestMapBgWidth / maxStageCount
        end
    end

    return cWidth
end
--初始化箭头
function QuestMainView:initArrow()
    self.m_questArrowList = {}
    for i = 1, #QUEST_CONFIGS.arrow_posX do
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

--解锁动画
function QuestMainView:unLockFunc(index, func)
    if self.m_questLines then
        self.m_questLines:pushLine(QUEST_MAPLINE_LIST[index - 1], func)
    else
        if func then
            func()
        end
    end
end

-- 获得当前地图中的位置
function QuestMainView:getStartPosX()
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

--初始化关卡节点
function QuestMainView:initQuestLayer(startStageIndex)
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
function QuestMainView:initLevelCells(phasesList, curCellIndex)
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
        self:createLevelCell(cellInfo)
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

--创建关卡节点
function QuestMainView:createLevelCell(stageData)
    if not stageData then
        return
    end
    local maxStageCount = self.m_config:getStageCount()
    local index = stageData.index
    local unLockIndex = stageData.unLockIndex

    local cell = util_createFindView(QUEST_CODE_PATH.QuestCell, stageData)
    cell:setPosition(QUEST_MAPCELL_LIST[index].x, QUEST_MAPCELL_LIST[index].y - display.height * 0.5)
    cell:setScale(0.85)
    cell:setTag(unLockIndex)

    self.node_map:addChild(cell, self:getZOrderByIndex(unLockIndex))
    self.m_questCellList["" .. index] = cell

    local cell_state = cell:getCellState()
    if cell_state == "PLAYING" or cell_state == "FINISHED" or cell_state == "REWARD" or cell_state == "COMPLETE" then
        self:unLockFunc(unLockIndex)
    end

    return cell
end

function QuestMainView:getQuestCell(key)
    local _cell = self.m_questCellList["" .. key]
    if tolua.isnull(_cell) then
        return nil
    else
        return _cell
    end
end

-- 刷新当前章节关卡
function QuestMainView:updatePhaseCells()
    local phasesList = self.m_config.p_phases
    local phase_idx = self.m_config:getPhaseIdx()
    if not phasesList or not phase_idx then
        return
    end

    for key, value in pairs(self.m_questCellList) do
        local cell = self:getQuestCell(key)
        if cell then
            -- if cell.m_curPhase and cell.m_curStage and phase_idx == cell.m_curPhase then
            --     local data = phasesList[cell.m_curPhase].p_stages[cell.m_curStage]
            --     if data then
            --         cell:initState(data)
            --     end
            -- else
            cell:initState()
            -- end
        end
    end
end

--刷新所有关卡
function QuestMainView:updateLevelCell()
    local phasesList = self.m_config.p_phases
    if not phasesList then
        return
    end

    for key, value in pairs(self.m_questCellList) do
        local cell = self:getQuestCell(key)
        if not tolua.isnull(cell) then
            cell:initState()
        end
    end
end

--改变广告位置
function QuestMainView:showAdsItem()
    if globalData.adsRunData.p_isNull or not globalData.adsRunData:CheckAdByPosition(PushViewPosType.LobbyPos) then
        return
    end
    if not self.node_logo then
        return
    end
    local node_base = self.node_logo:getParent()

    if not node_base then
        return
    end

    local offsetX = 20
    local offsetY = 140
    if self.m_specialClanEntry then
        offsetY = 240
    end

    local viewParam = {scene = "Lobby", init = true}
    local vedio = util_createView("views.lobby.AdsRewardIcon", viewParam)
    if vedio then
        vedio:addTo(node_base)

        vedio:setScale(0.7)
        local pos_logo = {}
        pos_logo.x, pos_logo.y = self.node_logo:getPosition()
        vedio:setPosition(cc.p(pos_logo.x + offsetX + util_getBangScreenHeight(), pos_logo.y - offsetY))
    end
end

function QuestMainView:onKeyBack()
    --引导期间不能点击返回键
    if self.m_config and self.m_config.p_expireAt then
        --不是第一关 可能是清除本地数据
        if self.m_config:getIsFirstStage() then
            local isWheelGuide = gLobalDataManager:getBoolByField("quest_wheelGuide" .. self.m_config.p_expireAt, true)
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

--function QuestMainView:playHideAction()
--    local userDefAction = function(callFunc)
--        self:runCsbAction(
--            "over",
--            false,
--            function()
--                --self:setVisible(false)
--                if callFunc then
--                    callFunc()
--                end
--            end,
--            60
--        )
--    end
--    QuestMainView.super.playHideAction(self, userDefAction)
--end

--关闭quest
function QuestMainView:closeUI()
    if self.m_moveMaskLayer then
        self.m_moveMaskLayer:removeFromParent()
        self.m_moveMaskLayer = nil
    end

    QuestMainView.super.closeUI(
        self,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_FUN_OVER)
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    )
end

function QuestMainView:stopSchedule()
    if self.m_boxSchedule then
        self:stopAction(self.m_boxSchedule)
        self.m_boxSchedule = nil
    end

    if self.m_cellSchedule then
        self.node_map:stopAction(self.m_cellSchedule)
        self.m_cellSchedule = nil
    end
end

-- 滚动到轮盘位置
function QuestMainView:moveTo(currentOffset, targetOffset, moveDir, overFunc)
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

--获得关卡坐标
function QuestMainView:getOffsetByIndex(index)
    if index == 0 then
        index = 1
    end
    local cellWidth = self:getCellWidth()
    if index > #QUEST_MAPCELL_LIST then
        index = #QUEST_MAPCELL_LIST
    end
    local curPosX = cellWidth * 0.5 - QUEST_MAPCELL_LIST[index].x
    curPosX = curPosX + display.cx - cellWidth * 0.5
    return curPosX
end

--节点层级关卡
function QuestMainView:getZOrderByIndex(index)
    local maxStageCount = self.m_config:getStageCount()
    return 9 + (maxStageCount - index)
end

--解锁
function QuestMainView:questCellUnlock(lastIndex)
    local index = lastIndex + 1
    if index > 6 and (index - 1) % 6 == 0 then
        local cell = self:getQuestCell(index)
        if not tolua.isnull(cell) and cell:getCellState() == "PLAYING" then
            return
        end
        local boxIndex = (index - 1) / 6
        local box = self.m_boxList[boxIndex]
        if box then
            box:openBox()
        end
    else
        local last_cell = self:getQuestCell(lastIndex)
        if last_cell then
            last_cell:initState()
        end

        local cell = self:getQuestCell(index)
        if cell then
            cell:initState()
        end
    end
end

function QuestMainView:unlockNextLevel(lastIndex)
    local startX = self:getOffsetByIndex(lastIndex)
    local endX = self:getOffsetByIndex(lastIndex + 1)
    self:moveTo(startX, endX, -1)
end

function QuestMainView:updateMapMaskNode()
    --去掉迷雾
    local contentLen = self.m_questMapControl:getContentLen()
    local mapLimitLen = display.width - contentLen
    if self.m_config then
        local phase = self.m_config:getPhaseIdx()
        --迷雾位置
        if QUEST_CONFIGS.arrow_posX[phase + 1] then
            mapLimitLen = display.width - QUEST_CONFIGS.arrow_posX[phase + 1] - MapMaskNodeOffX
        else
            --迷雾遮罩
            if self.m_mapMaskNode then
                self.m_mapMaskNode:removeFromParent()
                self.m_mapMaskNode = nil
            end
        end
    end
    self.m_questMapScroll:setMoveLen(mapLimitLen, true)
    if self.m_mapMaskNode then
        self.m_mapMaskNode:setPosition(display.width - mapLimitLen, 0)
    end
end

-- quest挑战活动结束,清楚活动入口
function QuestMainView:resetQuestRushState()
    if tolua.isnull(self.m_nodeRushEntry) then
        return
    end

    self.m_nodeRushEntry:removeSelf()
    self.m_nodeRushEntry = nil
end

--获取背景音乐路径
function QuestMainView:getBgMusicPath()
    return QUEST_RES_PATH.QuestBGMPath
end

function QuestMainView:getRefName()
    return ACTIVITY_REF.Quest
end

-- pass 自动弹出
function QuestMainView:onShowedCallFunc()
    self:checkShowPassLayer()
end

function QuestMainView:checkShowPassLayer(_nextStage)
    if self.m_isAutoPop then
        if G_GetMgr(ACTIVITY_REF.Quest):checkShowPassLayer() then
            G_GetMgr(ACTIVITY_REF.Quest):showPassLayer(_nextStage)
        end
    end
end

return QuestMainView
