--[[
Author: cxc
Date: 2022-04-19 14:40:28
LastEditTime: 2022-04-19 14:40:29
LastEditors: cxc
Description: 头像框 任务 主界面
FilePath: /SlotNirvana/src/views/AvatarFrame/main/AvatarFrameMainUI.lua
--]]
local AvatarFrameMainUI = class("AvatarFrameMainUI", BaseLayer)
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function AvatarFrameMainUI:ctor(_callFunc)
    AvatarFrameMainUI.super.ctor(self)

    self:setPauseSlotsEnabled(true) 
    self:setKeyBackEnabled(true)
    self:setExtendData("AvatarFrameMainUI")
    self:setLandscapeCsbName("Activity/csb/Frame_mainUi.csb")
    self:setPortraitCsbName("Activity/csb/Frame_mainUi_vertical.csb")
end

function AvatarFrameMainUI:initDatas(_slotId)
    AvatarFrameMainUI.super.initDatas(self)

    self.m_slotId = _slotId
    self.m_selTaskIdx = 1
    self.m_taskNodeList = {}
    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    self.m_slotTaskData = data:getSlotTaskBySlotId(_slotId)
end

function AvatarFrameMainUI:initCsbNodes()
    self.m_nodeSlotIcon = self:findChild("node_slotIcon")
    self.m_lbTaskDesc = self:findChild("txt_challenge")
    self.m_lbReward = self:findChild("lb_reward")
    self.m_nodeReward = self:findChild("node_reward")
    self.m_nodeMiniGameCountRed = self:findChild("sp_redPoint")
    self.m_lbMiniGameCountRed = self:findChild("lb_miniGameCount")
    self.m_nodeMiniGameCountRed:setVisible(false)
end

function AvatarFrameMainUI:onShowedCallFunc()
    self:dealGuideLogic() 
end

-- 初始化界面显示
function AvatarFrameMainUI:initView()
   -- 头像框 slotIcon
   self:initSlotIconUI()
   -- 任务UI（头像框进度）
   self:initTaskUI()
   -- 更新任务选择状态
   self:updateTaskSelectState()
   -- 任务描述 奖励
   self:updateTaskDescUI()
   -- 小游戏 小红点
   self:updateMiniGameCountUI()
   -- 小游戏入口按钮 state
   self:updateMiniGameBtnState()
end

-- 头像框 slotIcon
function AvatarFrameMainUI:initSlotIconUI()
    local view = G_GetMgr(G_REF.AvatarFrame):createSlotTaskIconUI(self.m_slotId)
    self.m_nodeSlotIcon:addChild(view)
end

-- 任务UI（头像框进度）
function AvatarFrameMainUI:initTaskUI()
    if not self.m_slotTaskData then
        return
    end

    local taskDataList = self.m_slotTaskData:getTaskList()
    self.m_selTaskIdx = self.m_slotTaskData:getCurSeq()
    for i=1, #taskDataList do
        local parent = self:findChild("node_frame" .. i)
        local data = taskDataList[i]
        local taskNode = self:createTaskNode(i, data)
        parent:addChild(taskNode)
        table.insert(self.m_taskNodeList, taskNode)
    end
end

function AvatarFrameMainUI:createTaskNode(_idx, _data)
    local view = util_createView("views.AvatarFrame.main.AvatarFrameCell", _idx, _data)
    view:setName("AvatarFrameCell")
    return view
end

-- 更新任务选择状态
function AvatarFrameMainUI:updateTaskSelectState()
    for i, node in ipairs(self.m_taskNodeList) do
        node:updateSelectState(i == self.m_selTaskIdx) 
    end
end

-- 任务描述 奖励
function AvatarFrameMainUI:updateTaskDescUI()
    if not self.m_slotTaskData then
        return
    end

    self.m_nodeReward:setVisible(false)
    self.m_lbTaskDesc:setVisible(false)
    local taskData = self.m_slotTaskData:getTaskDataByIdx(self.m_selTaskIdx)
    if not taskData then
        return
    end

    self.m_lbTaskDesc:setVisible(true)
    -- 0未激活， 1正在进行， 2已完成
    local status = taskData:getStatus()
    local str = ""
    if status == 0 then
        str = taskData:getDesc()
        local preTaskData = self.m_slotTaskData:getTaskDataByIdx(self.m_selTaskIdx - 1)
        if preTaskData then
            local desc = preTaskData:getFrameLevelDesc()
            str = string.format("Complete the %s to unlock", desc)
        end
    elseif status == 1 then
        str =  "GAME GOAL: " .. taskData:getDesc()
        self:updateTaskRewardNum(taskData)
    elseif status == 2 then
        local time = taskData:getCompleteTime()
        str = self:getformatTimeStr(time)
    end
    self.m_lbTaskDesc:setString(str)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbTaskDesc, 600) 
end

function AvatarFrameMainUI:updateTaskRewardNum(_taskData)
    if not _taskData then
        return
    end

    local count = _taskData:getRewardFrameMiniGameCount()
    if count < 1 then
        return
    end
    self.m_lbReward:setString("X" .. count)
    self.m_nodeReward:setVisible(true)
end

-- 小游戏 小红点
function AvatarFrameMainUI:updateMiniGameCountUI()
    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    local miniGameData = data:getMiniGameData()
    local count = miniGameData:getPropsNum()
    self.m_nodeMiniGameCountRed:setVisible(count > 0)
    self.m_lbMiniGameCountRed:setString(count)
    util_scaleCoinLabGameLayerFromBgWidth(self.m_lbMiniGameCountRed, 26)
end

-- 小游戏入口按钮 state
function AvatarFrameMainUI:updateMiniGameBtnState()
    -- 新手期集卡 不可玩 头像框小游戏
    local bCardNovice = CardSysManager:isNovice()
    self:setButtonLabelDisEnabled("btn_game", not bCardNovice)
end

function AvatarFrameMainUI:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_frame" then
        -- 跳转个人信息页
        G_GetMgr(G_REF.UserInfo):showMainLayer(2)
    elseif name == "btn_game" then
        -- 跳转到小游戏
        local view = G_GetMgr(G_REF.AvatarGame):showMainLayer()
        if not view then
            return
        end
        view:setOverFunc(function()
            self:updateMiniGameCountUI()
        end)
    end
end

-- 点击选择头像框任务
function AvatarFrameMainUI:onSelectTaskCellEvt(_idx)
    self.m_selTaskIdx = _idx
    self:updateTaskSelectState()
    self:updateTaskDescUI()
end

-- 个人信息页背包跳转 关闭本界面
function AvatarFrameMainUI:closeUINoActionEvt(_idx)
    self:setHideActionEnabled(false)
    self:closeUI()
end

-- 注册消息事件
function AvatarFrameMainUI:registerListener()
    AvatarFrameMainUI.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onSelectTaskCellEvt", AvatarFrameConfig.EVENT_NAME.CLICK_SELECT_TASK_CELL)
    gLobalNoticManager:addObserver(self, "closeUINoActionEvt", ViewEventType.NOTIFY_CLOSE_OPEN_USER_INFO_LAYER_SYSTEM)
end

-- 获取格式化 时间str
function AvatarFrameMainUI:getformatTimeStr(_time)
    local t = os.date("*t", _time)
    return string.format("%s %02d, %d", FormatMonth[t.month], t.day, t.year)
end

-- 处理 引导 逻辑
function AvatarFrameMainUI:dealGuideLogic()
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.AvatarFrameMainUI.id) -- 第一次进入公会主页
    if bFinish then
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.AvatarFrameMainUI)

    local nodeCurTask = self:findChild("node_frame"..self.m_selTaskIdx) -- 公会基本信息按钮
    if not nodeCurTask then
        return
    end
    local frameCell = nodeCurTask:getChildByName("AvatarFrameCell")
    if not frameCell then
        return
    end
    local guideLayer = util_createView("views.AvatarFrame.other.AvatarFrameGuideLayer", frameCell)
    gLobalViewManager:showUI(guideLayer, ViewZorder.ZORDER_GUIDE)
end

return AvatarFrameMainUI