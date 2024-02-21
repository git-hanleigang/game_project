--[[
Author: cxc
Date: 2022-04-19 15:48:29
LastEditTime: 2022-04-19 15:48:30
LastEditors: cxc
Description: 头像框 任务 
FilePath: /SlotNirvana/src/views/AvatarFrame/main/AvatarFrameCell.lua
--]]
local AvatarFrameCell = class("AvatarFrameCell", BaseView)
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")

function AvatarFrameCell:initDatas(_idx, _taskData)
    AvatarFrameCell.super.initDatas(self)

    self.m_idx = _idx
    self.m_taskData = _taskData
end

function AvatarFrameCell:initUI(_params)
    AvatarFrameCell.super.initUI(self)

    -- 创建头像框
    self:createFrameNode()    
    -- 更新 任务进度
    self:initProgresUI()
    -- 头像框 任务等级
    self:updateTaskLevelUI()
    -- 更新状态
    self:updateStatus()
end

function AvatarFrameCell:initCsbNodes()
    self.m_nodeFrame = self:findChild("node_frame")
    self.m_nodePercent = self:findChild("node_percent")
    self.m_lbProgress = self:findChild("txt_percent")
    self.m_lodingbarProg = self:findChild("progress_frame")
    self.m_lbName = self:findChild("txt_name")
    self.m_spLock = self:findChild("sp_lock")
    self.m_spSel = self:findChild("sp_kuang")
end

function AvatarFrameCell:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "Activity/csb/Frame_cell2.csb"
    end
    return "Activity/csb/Frame_cell.csb"
end

-- 创建头像框
function AvatarFrameCell:createFrameNode()
    local frameId = self.m_taskData:getFrameId()
    local view = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(frameId)
    if not view then
        return
    end

    self.m_nodeFrame:addChild(view) 
    -- 缩放
    local scale = self.m_nodeFrame:getScale()
    local spSelSize = self.m_spSel:getContentSize()
    local viewSize = view:getContentSize()
    if viewSize.width * scale > spSelSize.width then
        self.m_nodeFrame:setScale(scale * spSelSize.width / viewSize.width)
    end
end

-- 更新 任务进度
function AvatarFrameCell:initProgresUI()
    -- 进度文本
    local curNum = self.m_taskData:getProgress()
    local limitNum = self.m_taskData:getLimitNum()
    local percent = 0
    if limitNum > 0 then
        percent = math.floor(curNum / limitNum * 100)
    end
    self.m_lbProgress:setString(percent .. "%")

    -- 进度 条
    self.m_lodingbarProg:setPercent(percent)
end

-- 头像框 任务等级
function AvatarFrameCell:updateTaskLevelUI()
    local frameId = self.m_taskData:getFrameId()
    local desc = self.m_taskData:getFrameLevelDesc()
    self.m_lbName:setString(desc)
end

-- 更新状态
function AvatarFrameCell:updateStatus()
    local status = self.m_taskData:getStatus()
    -- 0未激活， 1正在进行， 2已完成
    if status == 0 then
        self.m_spLock:setVisible(true)
        self.m_nodePercent:setVisible(false)
        self:runCsbAction("dark")
    elseif status == 1 then
        self.m_spLock:setVisible(false)
        self.m_nodePercent:setVisible(true)
        self:runCsbAction("idle")
    elseif status == 2 then
        self.m_spLock:setVisible(false)
        self.m_nodePercent:setVisible(false)
        self:runCsbAction("idle")
    end

    util_setCascadeColorEnabledRescursion(self.m_nodeFrame, true)
end

-- 选中框
function AvatarFrameCell:updateSelectState(_bSel)
    self.m_spSel:setVisible(_bSel)
end

function AvatarFrameCell:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_touch" then
        gLobalNoticManager:postNotification(AvatarFrameConfig.EVENT_NAME.CLICK_SELECT_TASK_CELL, self.m_idx)
    end
end

return AvatarFrameCell