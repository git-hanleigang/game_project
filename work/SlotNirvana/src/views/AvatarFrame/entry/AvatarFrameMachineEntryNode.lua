--[[
Author: cxc
Date: 2022-04-18 11:54:34
LastEditTime: 2022-04-18 11:54:35
LastEditors: cxc
Description: 头像框 任务 关卡入口
FilePath: /SlotNirvana/src/views/AvatarFrame/entry/AvatarFrameMachineEntryNode.lua
--]]
local AvatarFrameMachineEntryNode = class("AvatarFrameMachineEntryNode", BaseView)
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function AvatarFrameMachineEntryNode:initDatas(_params)
    AvatarFrameMachineEntryNode.super.initDatas(self, _params)

    self.m_curMachineData = globalData.slotRunData.machineData or {}
    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    self.m_slotId = G_GetMgr(G_REF.AvatarFrame):getCurLevelNormalSlotId()
    self.m_slotTaskData = data:getSlotTaskBySlotId(self.m_slotId)
end

function AvatarFrameMachineEntryNode:initUI(_params)
    AvatarFrameMachineEntryNode.super.initUI(self)

    -- 初始化 关卡 对应icon
    self:initMichineIconUI() 
 
    -- bet变化刷新状态
    self:onBetChangeEvt()

    self:registerListener()
    self:dealGuideLogic() 
end

function AvatarFrameMachineEntryNode:initCsbNodes()
    self.m_nodeSlotIcon = self:findChild("Node_slotIcon")
    self.m_nodePanelSize = self:findChild("Node_PanelSize")
    self:addClick(self.m_nodePanelSize)
end

-- 入口 大小 (工具类会调用 排序 layout)
function AvatarFrameMachineEntryNode:getPanelSize()
    local size = self.m_nodePanelSize:getContentSize()
    return {widht = size.width, height = size.height, launchHeight = size.height}
end

function AvatarFrameMachineEntryNode:getCsbName()
    return "Activity/csb/Frame_slot_entrance.csb"
end

-- 初始化 关卡 对应icon
function AvatarFrameMachineEntryNode:initMichineIconUI()
    local view = G_GetMgr(G_REF.AvatarFrame):createSlotTaskIconUI(self.m_slotId)
    self.m_nodeSlotIcon:addChild(view)
    self.m_nodeSlotIcon:move(0, -2)
    self.m_slotIconObj = view
end

function AvatarFrameMachineEntryNode:clickFunc(sender)
    local name = sender:getName()

    if name == "Node_PanelSize" then
        -- 打开 主面板
        G_GetMgr(G_REF.AvatarFrame):showMainLayer(self.m_slotId)
    end

    -- 移除引导 的气泡
    self:removeGuideBubbleView()
end

-- bet值 切换 入口状态改变
function AvatarFrameMachineEntryNode:onBetChangeEvt(_params)
    if (_params and _params.p_isLevelUp) or not self.m_slotIconObj or not self.m_slotTaskData then
        return
    end

    -- local betValue = globalData.slotRunData:getCurTotalBet()
    local currBetIndex = globalData.slotRunData:getCurBetIndex()
    local limitBetIdx = self.m_slotTaskData:getTaskBetNormalIdx()
    if self.m_curMachineData.p_highBetFlag then
        limitBetIdx = self.m_slotTaskData:getTaskBetHighLimitIdx()
    end
    local bLockVisible = currBetIndex < limitBetIdx
    self.m_slotIconObj:setLockVisible(bLockVisible, (not self.m_bGuide and _params))
end

-- 更新关卡入口任务进度
function AvatarFrameMachineEntryNode:updateProgresUIEvt()
    if self.m_slotIconObj then
        self.m_slotIconObj:updateData()
        self.m_slotIconObj:updateProgresUI()
    end
end

-- 关卡入口左边条方向
function AvatarFrameMachineEntryNode:updateBubbleDirectionEvt()
    if not self.m_guideBubble then
        return
    end

    self:updateBubbleVisible()
end
-- 引导气泡显隐
function AvatarFrameMachineEntryNode:updateBubbleVisible()
    local direction = gLobalActivityManager:getLeftFrameDirection()

    local nodeLeft = self.m_guideBubble:findChild("Node_left")
    local nodeRight = self.m_guideBubble:findChild("Node_right")
    
    nodeLeft:setVisible(direction == "left")
    nodeRight:setVisible(direction == "right")
end


function AvatarFrameMachineEntryNode:registerListener()
    gLobalNoticManager:addObserver(self, "onBetChangeEvt", ViewEventType.NOTIFY_BET_CHANGE)
    gLobalNoticManager:addObserver(self, "updateProgresUIEvt", AvatarFrameConfig.EVENT_NAME.UPDATE_ENTRY_PROGRESS)
    gLobalNoticManager:addObserver(self, "updateBubbleDirectionEvt", ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME)
end

-- 处理 引导逻辑
function AvatarFrameMachineEntryNode:dealGuideLogic()
    local bFinish = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.AvatarFrameMachineEntry.id)
    if bFinish then
        return
    end

    globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.AvatarFrameMachineEntry)
    self.m_bGuide = true
    local bubble = util_createAnimation("Activity/csb/Frame_guide1.csb")
    self:addChild(bubble)
    bubble:playAction("start")
    self.m_guideBubble = bubble
    performWithDelay(self, function()
        self:removeGuideBubbleView()
    end, 2)
    self:updateBubbleVisible()
end

-- 移除引导 的气泡
function AvatarFrameMachineEntryNode:removeGuideBubbleView()
    if self.m_bGuide and self.m_guideBubble then
        self.m_guideBubble:playAction("over", false, function()
            self.m_guideBubble:removeSelf()
            self.m_guideBubble = nil
        end, 60)
        self.m_bGuide = false
    end
end

return AvatarFrameMachineEntryNode