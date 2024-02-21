--[[
Author: cxc
Date: 2022-05-02 14:21:47
LastEditTime: 2022-04-27 14:52:46
LastEditors: cxc
Description: 头像框 任务 关卡icon
FilePath: /SlotNirvana/src/GameModule/Avatar/views/base/AvatarFrameSlotIcon.lua
--]]
local AvatarFrameSlotIcon = class("AvatarFrameSlotIcon", BaseView)

function AvatarFrameSlotIcon:initDatas(_slotId)
    AvatarFrameSlotIcon.super.initDatas(self)

    self.m_slotId = _slotId
    self:updateData()
end

function AvatarFrameSlotIcon:updateData()
    local data = G_GetMgr(G_REF.AvatarFrame):getData()
    self.m_slotTaskData = data:getSlotTaskBySlotId(self.m_slotId)
end

function AvatarFrameSlotIcon:initUI(_params)
    AvatarFrameSlotIcon.super.initUI(self)

    -- 初始化 关卡 对应icon
    self:initMichineIconUI() 
    -- 更新 任务进度
    self:updateProgresUI()

    self:runCsbAction("idle", true)
    gLobalNoticManager:addObserver(self, "updateBubbleDirectionEvt", ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME)
end

function AvatarFrameSlotIcon:initCsbNodes()
    self.m_lbProgress = self:findChild("txt_progress")
    self.m_nodeSlotIcon = self:findChild("node_slotIcon")
    self.m_spIcon = self:findChild("sp_icon")
    self.m_nodeQipao = self:findChild("node_qipao")
    self.m_nodeLock = self:findChild("node_lock")
    self.m_nodeLock:setVisible(false)
end

function AvatarFrameSlotIcon:getCsbName()
    return "CommonAvatar/csb/Frame_slot_icon.csb"
end

-- 初始化 关卡 对应icon
function AvatarFrameSlotIcon:initMichineIconUI()
    local frameStaticData = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData() 
    local iconPath = frameStaticData:getSlotImgPath(self.m_slotId)
    self.m_iconPath = iconPath
    local bSuccess = self:updatetMichineIcon()
    if not bSuccess then
        -- 头像框资源下载结束
        gLobalNoticManager:addObserver(self, "updatetMichineIcon", ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE)
    end
end
function AvatarFrameSlotIcon:updatetMichineIcon()
    local bSuccess = util_changeTexture(self.m_spIcon, self.m_iconPath)
    self.m_spIcon:setVisible(bSuccess)
    return bSuccess
end

-- 更新 任务进度
function AvatarFrameSlotIcon:updateProgresUI()
    if not self.m_slotTaskData then
        return
    end
    
    local completeNum = self.m_slotTaskData:getCompleteNum()
    local totalNum = self.m_slotTaskData:getTotalNum()
    self.m_lbProgress:setString(completeNum .. "/" .. totalNum)
end

-- 更新 spLock 显隐
function AvatarFrameSlotIcon:setLockVisible(_bVisible, _showBubble)
    self.m_nodeLock:setVisible(_bVisible)
    self.m_nodeSlotIcon:setVisible(not _bVisible)

    if _bVisible and _showBubble then
        -- 气泡提示
        self:showBubbleTipUI()
    end
end

-- 气泡提示
function AvatarFrameSlotIcon:showBubbleTipUI()
    if not self.m_nodeBubble then
        self.m_nodeBubble = util_createAnimation("CommonAvatar/csb/Frame_slot_icon_bubble.csb")
        self.m_nodeQipao:addChild(self.m_nodeBubble)
        self:updateBubbleDirectionEvt()
    end

    self.m_nodeBubble:stopAllActions()
    self.m_nodeBubble:playAction("show", false, function()
        self.m_nodeBubble:playAction("idle")
        performWithDelay(self.m_nodeBubble, function()
            self.m_nodeBubble:playAction("hide")
        end, 2)
    end, 60)
end

function AvatarFrameSlotIcon:updateBubbleDirectionEvt()
    if not self.m_nodeBubble then
        return
    end
    
    local direction = gLobalActivityManager:getLeftFrameDirection()
    local nodeLeft = self.m_nodeBubble:findChild("node_qipao_L")
    local nodeRight = self.m_nodeBubble:findChild("node_qipao_R")
    nodeLeft:setVisible(direction == "left")
    nodeRight:setVisible(direction == "right")
end

return AvatarFrameSlotIcon