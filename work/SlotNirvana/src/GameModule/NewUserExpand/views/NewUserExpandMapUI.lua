--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-08 15:06:32
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-08 15:06:44
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandMapUI.lua
Description: 扩圈系统大厅 mapUI
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NewUserExpandMapUI = class("NewUserExpandMapUI", BaseView)

function NewUserExpandMapUI:initDatas(_gameData, _mainView)
    NewUserExpandMapUI.super.initDatas(self)

    self.m_mainView = _mainView
    self.m_loadGameViewList = {}
    self.m_loadStopViewList = {}
    self.m_chapterGameViewList = {}
    self.m_loadBUpViewList = {}
    self.m_loadBDownViewList = {}
    self.m_loadBFrontViewList = {}

    self.m_gameData = _gameData
    self.m_gameTaskList = self.m_gameData:getTaskGameLsit() 
    self.m_chapterMissionList = self.m_gameData:getTaskMisssionLsit() 
end

function NewUserExpandMapUI:getCsbName()
    return "NewUser_Expend/Activity/csd/NewUser_map.csb"
end

-- 初始化节点
function NewUserExpandMapUI:initCsbNodes()
    -- 地图背景节点s
    self.m_nodeBgList = self:findChild("node_bg"):getChildren()
    -- 地图道路节点s
    self.m_nodeRoadList = self:findChild("node_road"):getChildren()
    -- 地图游戏任务节点s
    self.m_nodeGameList = self:findChild("node_game"):getChildren()
    -- 地图游戏章节障碍节点s
    self.m_nodeStopList = self:findChild("node_stop"):getChildren()
    -- 地图游戏建筑物up节点s
    self.m_nodeBUpList = self:findChild("node_build_up"):getChildren()
    -- 地图游戏建筑物down节点s
    self.m_nodeBDownList = self:findChild("node_build_down"):getChildren()
    -- 地图游戏建筑物front节点s
    self.m_nodeBFrontList = self:findChild("node_build_front"):getChildren()
    -- 地图 comingsoon
    self.m_spComingSoon = self:findChild("sp_comingSoon")
end

-- 背景和路显隐
function NewUserExpandMapUI:updateBgRoadSpVisible()
    -- 背景
    for _, spNode in pairs(self.m_nodeBgList) do
        local bVisible = self:checkNodeInScreen(spNode)
        spNode:setVisible(bVisible)
    end

    -- 路
    for _, spNode in pairs(self.m_nodeRoadList) do
        local bVisible = self:checkNodeInScreen(spNode)
        spNode:setVisible(bVisible)
    end
end
-- spComingSoon
function NewUserExpandMapUI:updateComingSoonVisible()
    local bVisible = self:checkNodeInScreen(self.m_spComingSoon)
    self.m_spComingSoon:setVisible(bVisible)
end

-- 游戏 任务节点
function NewUserExpandMapUI:updateTaskGameUI()
    for _, _node in pairs(self.m_nodeGameList) do
        self:checkGameNodeLoadOrVisible(_node)
    end
end
function NewUserExpandMapUI:createTaskGameNode(_idx, _parent)
    local taskData = self.m_gameTaskList[_idx]
    if not taskData then
        local view = util_createView("GameModule.NewUserExpand.views.ExpandTaskBaseUI")
        _parent:addChild(view)
        return view
    end
    
    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandTaskUI", taskData)
    _parent:addChild(view)

    local chapterIdx = taskData:getChapterIdx()
    if not self.m_chapterGameViewList[chapterIdx] then
        self.m_chapterGameViewList[chapterIdx] = {}
    end
    table.insert(self.m_chapterGameViewList[chapterIdx], view)

    return view
end
function NewUserExpandMapUI:checkGameNodeLoadOrVisible(_node)
    local nodeName = _node:getName()
    local idx = string.match(nodeName, "node_game_(%d+)")
    if not idx then
        return
    end
    idx = tonumber(idx)
    local gameView = self.m_loadGameViewList[idx]
    if not gameView then
        local bIn = self:checkNodeInScreen(_node, true)
        if bIn then
            gameView = self:createTaskGameNode(idx, _node)
            self.m_loadGameViewList[idx] = gameView
        end
    end

    if gameView then
        gameView:updateVisible()
    end
end

-- 游戏 任务章节障碍节点
function NewUserExpandMapUI:updateTaskChapterLockUI()
    for _, _node in pairs(self.m_nodeStopList) do
        self:checkChapterLockNodeLoadOrVisible(_node)
    end
end
function NewUserExpandMapUI:createChapterLockNode(_idx, _parent)
    local taskData = self.m_chapterMissionList[_idx]
    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandChapterLockUI", taskData)
    _parent:addChild(view)
    return view
end
function NewUserExpandMapUI:checkChapterLockNodeLoadOrVisible(_node)
    local nodeName = _node:getName()
    local idx = string.match(nodeName, "node_stop_(%d+)")
    if not idx then
        return
    end
    idx = tonumber(idx)
    local chapterLockView = self.m_loadStopViewList[idx]
    if not chapterLockView then
        local bIn = self:checkNodeInScreen(_node, true)
        if bIn then
            chapterLockView = self:createChapterLockNode(idx, _node)
            self.m_loadStopViewList[idx] = chapterLockView
        end
    end

    if chapterLockView then
        chapterLockView:updateVisible()
    end
end

-- 游戏 建筑物
function NewUserExpandMapUI:updateBuildUI()
    -- up
    for _, _node in pairs(self.m_nodeBUpList) do
        self:checkBuildUpNodeLoadOrVisible(_node)
    end
    -- down
    for _, _node in pairs(self.m_nodeBDownList) do
        self:checkBuildDownNodeLoadOrVisible(_node)
    end
    -- front
    for _, _node in pairs(self.m_nodeBFrontList) do
        self:checkBuildFrontNodeLoadOrVisible(_node)
    end
end
function NewUserExpandMapUI:createBuildNode(_buildType, _parent)
    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandBuildingUI", _buildType)
    _parent:addChild(view)
    return view
end
function NewUserExpandMapUI:checkBuildUpNodeLoadOrVisible(_node)
    local nodeName = _node:getName()
    local idx, _buildType = string.match(nodeName, "node_up_(%d+)_(%d+)")
    if not idx or not _buildType then
        return
    end
    idx = tonumber(idx)
    local buildUpView = self.m_loadBUpViewList[idx]
    if not buildUpView then
        local bIn = self:checkNodeInScreen(_node)
        if bIn then
            buildUpView = self:createBuildNode(_buildType, _node)
            self.m_loadBUpViewList[idx] = buildUpView
        end
    end

    if buildUpView then
        buildUpView:updateVisible()
    end
end
function NewUserExpandMapUI:checkBuildDownNodeLoadOrVisible(_node)
    local nodeName = _node:getName()
    local idx, _buildType = string.match(nodeName, "node_down_(%d+)_(%d+)")
    if not idx or not _buildType then
        return
    end
    idx = tonumber(idx)
    local buildDownView = self.m_loadBDownViewList[idx]
    if not buildDownView then
        local bIn = self:checkNodeInScreen(_node)
        if bIn then
            buildDownView = self:createBuildNode(_buildType, _node)
            self.m_loadBDownViewList[idx] = buildDownView
        end
    end

    if buildDownView then
        buildDownView:updateVisible()
    end
end
function NewUserExpandMapUI:checkBuildFrontNodeLoadOrVisible(_node)
    local nodeName = _node:getName()
    local idx, _buildType = string.match(nodeName, "node_front_(%d+)_(%d+)")
    if not idx or not _buildType then
        return
    end
    idx = tonumber(idx)
    local buildFrontView = self.m_loadBFrontViewList[idx]
    if not buildFrontView then
        local bIn = self:checkNodeInScreen(_node)
        if bIn then
            buildFrontView = self:createBuildNode("front_".._buildType, _node)
            self.m_loadBFrontViewList[idx] = buildFrontView
        end
    end

    if buildFrontView then
        buildFrontView:updateVisible()
    end
end

function NewUserExpandMapUI:udpateScrollEvt()
    -- 背景和路显隐
    self:updateBgRoadSpVisible()
    -- spComingSoon
    self:updateComingSoonVisible()
    -- 游戏 任务节点
    self:updateTaskGameUI()
    -- 游戏 任务章节障碍节点
    self:updateTaskChapterLockUI()
    -- 游戏 建筑物
    self:updateBuildUI()
end

-- 检查节点是否 在屏幕内
function NewUserExpandMapUI:checkNodeInScreen(_node, _bNextPage)
    local posSelf = _node:convertToWorldSpace(cc.p(0, 0))
    local sizeSelf = _node:getContentSize()
    local scale = _node:getScale() 
    sizeSelf = cc.size(sizeSelf.width*scale, sizeSelf.height*scale)
    local bVisible = cc.rectIntersectsRect(cc.rect(0, 0, display.width, display.height), cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
    if not bVisible and _bNextPage then
        -- 查看是否在下一页
        bVisible = cc.rectIntersectsRect(cc.rect(0, 0, display.width*2, display.height), cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
    end
    return bVisible
end

function NewUserExpandMapUI:getContentSize()
    if self.m_contentSize then
        return self.m_contentSize
    end

    local spSize = self.m_spComingSoon:getContentSize()
    self.m_contentSize = cc.size(self.m_spComingSoon:getPositionX()+spSize.width*0.5, display.height)


    -- local lastSpBg = self.m_nodeBgList[#self.m_nodeBgList]
    -- if not lastSpBg then
    --     return cc.size(0, 0)
    -- end

    -- local spSize = lastSpBg:getContentSize()
    -- local spBgScale = lastSpBg:getScale() 
    -- spSize = cc.size(spSize.width*spBgScale, spSize.height*spBgScale)
    -- self.m_contentSize = cc.size(lastSpBg:getPositionX()+spSize.width, spSize.height)

    -- local lastTaskData = self.m_gameData:getLastTaskData()
    -- if not lastTaskData then
    --     return self.m_contentSize
    -- end

    -- local typeIdx = lastTaskData:getCurTypeIdx()
    -- local node
    -- if lastTaskData:checkIsMission() then
    --     node = self.m_nodeStopList[typeIdx]
    -- else
    --     node = self.m_nodeGameList[typeIdx]
    -- end

    -- if not node then
    --     return self.m_contentSize
    -- end

    -- self.m_contentSize = cc.size(node:getPositionX()+200, display.height)
    return self.m_contentSize
end

-- 获取当前 解锁章节 nodePosX
function NewUserExpandMapUI:getLockNodePosXByIdx(_idx)
    local node = self:findChild("node_stop_" .. _idx)
    if not node then
        return
    end

    return node:getPositionX()
end

-- 完成关卡 小游戏返回大厅
function NewUserExpandMapUI:onCompleteMiniGameEvt()
    self:setCheckGuide(true)

    if self.m_curTaskView then
        self.m_curTaskView:updateTaskState(NewUserExpandConfig.TASK_STATE.DONE_ANI)
    end
end

-- 结束当前
function NewUserExpandMapUI:onUpdateTaskStateEvt()
    if self.m_curTaskView then
        self.m_curTaskView:updateTaskState(NewUserExpandConfig.TASK_STATE.DONE_ANI)
    end

    if self.m_nextTaskView then
        self.m_nextTaskView:updateTaskState(NewUserExpandConfig.TASK_STATE.UNLOCK_ANI)
    end

    self:recordTaskView()
    if self.m_bCheckGuide then
        self:dealGuideLogic()
    end
    self:setCheckGuide(false)
end
function NewUserExpandMapUI:recordTaskView()
    self.m_curTaskView = nil
    self.m_nextTaskView = nil

    -- 当前 任务 view
    self:recordCurTaskView()
    -- 下个 任务 view
    self:recordNextTaskView()
   
end
-- 当前 任务 view
function NewUserExpandMapUI:recordCurTaskView()
    local curTaskData = self.m_gameData:getCurTaskData()
    if not curTaskData then
        return
    end
    local curIdx = curTaskData:getCurTypeIdx()
    if curTaskData:checkIsMission() then
        self.m_curTaskView = self.m_loadStopViewList[curIdx]
    else
        self.m_curTaskView = self.m_loadGameViewList[curIdx]
    end
end
-- 当前 任务 view
function NewUserExpandMapUI:recordNextTaskView()
    local nextTaskData = self.m_gameData:getNextTaskData()
    if not nextTaskData then
        return
    end
    local nextIdx = nextTaskData:getCurTypeIdx()
    if nextTaskData:checkIsMission() then
        self.m_nextTaskView = self.m_loadStopViewList[nextIdx]
    else
        self.m_nextTaskView = self.m_loadGameViewList[nextIdx]
    end
end

-- 引导
function NewUserExpandMapUI:dealGuideLogic()
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    if curType ~= NewUserExpandConfig.LOBBY_TYPE.PUZZLE then
        return
    end

    local curTaskData = self.m_gameData:getCurTaskData()
    if not curTaskData then
        return
    end

    if curTaskData:getState() ~= NewUserExpandConfig.TASK_STATE.UNLOCK then
        return
    end

    local guideName
    if curTaskData:getSeq() == 1 then
        -- 引导 2 引导玩第一关
        -- guideName = "EnterExpandMainPlayPass1"
    elseif curTaskData:getSeq() == 2 then
        -- 引导 2 完成第一关 引导第二关
        guideName = "EnterExpandMainPlayPass2"
        self.m_handlerTaskView = self.m_loadGameViewList[2]
    elseif curTaskData:getSeq() == 3 then
        -- 引导 2 完成第二关 引导第三关
        guideName = "EnterExpandMainPlayPass3"
        self.m_handlerTaskView = self.m_loadGameViewList[3]
    elseif curTaskData:checkIsMission() and curTaskData:getCurTypeIdx() == 1 then
        -- 引导 3 障碍物解锁规则
        guideName = "EnterExpandMainMissionUnlock"
        self.m_handlerTaskView = self.m_loadStopViewList[1]
    end

    if not guideName then
        return
    end

    self:setGuideTaskViewSwallow(true)
    local maskLayer = util_newMaskLayer()
    maskLayer:setOpacity(0)
    gLobalViewManager:showUI(maskLayer, ViewZorder.ZORDER_LOADING)
    performWithDelay(self, function()
        maskLayer:removeSelf()

        self.m_mainView:jumpToLeft()
        G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, guideName, G_REF.NewUserExpand)
        G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandGuideLog(guideName)
    end, 1)
    return true
end

function NewUserExpandMapUI:setCheckGuide(_bGuide)
    self.m_bCheckGuide = _bGuide
end

-- 引导的时候 任务 view 吞噬事件不？
function NewUserExpandMapUI:setGuideTaskViewSwallow(_bSwallow)
    if self.m_handlerTaskView and self.m_handlerTaskView.setSwallowTouches then
        self.m_handlerTaskView:setSwallowTouches(_bSwallow)
    end
end

return NewUserExpandMapUI