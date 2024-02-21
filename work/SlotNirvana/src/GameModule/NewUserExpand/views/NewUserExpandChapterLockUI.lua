--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-07 16:49:31
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-07 16:57:38
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandChapterLockUI.lua
Description: 扩圈系统 任务章节 锁UI
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NewUserExpandChapterLockUI = class("NewUserExpandChapterLockUI", BaseView)

function NewUserExpandChapterLockUI:initDatas(_taskData)
    NewUserExpandChapterLockUI.super.initDatas(self)

    self.m_taskData = _taskData
end

function NewUserExpandChapterLockUI:getCsbName()
    return "NewUser_Expend/Activity/csd/NewUser_StopCell.csb"
end

function NewUserExpandChapterLockUI:initCsbNodes()
    self.m_btnClick = self:findChild("btn_stopcell")
    self.m_btnClick:setSwallowTouches(false)

    self.m_spStop = self:findChild("sp_stopcell")
    self.m_size = self.m_spStop:getContentSize()
end

function NewUserExpandChapterLockUI:initUI()
    NewUserExpandChapterLockUI.super.initUI(self)

    -- 初始化气泡UI
    self:initBubbleUI()
    -- 任务章节 节点状态
    local bPass = self.m_taskData:checkPass()
    self:updateTaskState(bPass and NewUserExpandConfig.TASK_STATE.DONE or NewUserExpandConfig.TASK_STATE.LOCK)
    local state = self.m_taskData:getState()
    if state == NewUserExpandConfig.TASK_STATE.UNLOCK then
        self:showLockBubble()
    end
end

-- 更新任务状态
function NewUserExpandChapterLockUI:updateTaskState(_state)
    if self.m_state and self.m_state >= _state then
        return
    end
    
    self.m_state = _state

    if _state == NewUserExpandConfig.TASK_STATE.LOCK then
        self:runCsbAction("idle", true)
    elseif _state == NewUserExpandConfig.TASK_STATE.UNLOCK_ANI or
    _state == NewUserExpandConfig.TASK_STATE.UNLOCK then
        self:showLockBubble()
        self:runCsbAction("idle", true)
    elseif _state == NewUserExpandConfig.TASK_STATE.DONE_ANI then
        local cb = function()
            self:updateTaskState(NewUserExpandConfig.TASK_STATE.DONE)
        end
        self:runCsbAction("disappear", false, cb, 60)
    elseif _state == NewUserExpandConfig.TASK_STATE.DONE then
        if self.m_bubbleView then
            self.m_bubbleView:setVisible(false)
        end
        self:runCsbAction("hide")
    end

    self.m_btnClick:setEnabled(_state ~= NewUserExpandConfig.TASK_STATE.DONE)
end

-- 初始化气泡UI
function NewUserExpandChapterLockUI:initBubbleUI()
    local nodeBubble = self:findChild("node_bubble")
    local desc = self.m_taskData:getDesc()
    local view = util_createView("GameModule.NewUserExpand.views.NewUserExpandChapterBubble", desc)
    nodeBubble:addChild(view)
    self.m_bubbleView = view
end

function NewUserExpandChapterLockUI:onEnter()
    self.m_bEnter = true
end

function NewUserExpandChapterLockUI:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_stopcell" then
        self.m_bubbleView:switchBubbleVisible()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end
end

function NewUserExpandChapterLockUI:updateVisible()
    if not self.m_bEnter then
        return
    end
    local posSelf = self.m_spStop:convertToWorldSpace(cc.p(0, 0))
    local sizeSelf = self.m_size
    local bVisible = cc.rectIntersectsRect(cc.rect(0, 0, display.width, display.height), cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
    self:setVisible(bVisible)
end

function NewUserExpandChapterLockUI:showLockBubble()
    self.m_bubbleView:showBubbleVisible()
end

function NewUserExpandChapterLockUI:setSwallowTouches(_bSwallow)
    self.m_btnClick:setSwallowTouches(_bSwallow)
end

return NewUserExpandChapterLockUI