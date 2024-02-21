--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-07 16:13:00
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-07 16:21:06
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/views/NewUserExpandTaskUI.lua
Description: 扩圈系统 任务 节点UI
--]]
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local ExpandTaskBaseUI = util_require("GameModule.NewUserExpand.views.ExpandTaskBaseUI")
local NewUserExpandTaskUI = class("NewUserExpandTaskUI", ExpandTaskBaseUI)

function NewUserExpandTaskUI:initDatas(_taskData)
    NewUserExpandTaskUI.super.initDatas(self)

    self.m_taskData = _taskData
end

function NewUserExpandTaskUI:getCsbName()
    return "NewUser_Expend/Activity/csd/NewUser_GameCell.csb"
end

-- 初始化节点
function NewUserExpandTaskUI:initCsbNodes()
    self.m_spBg = self:findChild("sp_gamenode")
    self.m_lbTask = self:findChild("lb_gamenode")
    self.m_btnGoGame = self:findChild("btn_gamenode")
    self.m_btnGoGame:setSwallowTouches(false)

    self.m_size = self.m_spBg:getContentSize()
end

function NewUserExpandTaskUI:onEnter()
    self.m_bEnter = true
end

function NewUserExpandTaskUI:initUI()
    NewUserExpandTaskUI.super.initUI(self)

    -- 任务背景
    self:updateSpBgUI()
    -- 任务Lb
    self:initLbTaskUI()
    -- 更新任务状态
    local state = self.m_taskData:getState()
    self:updateTaskState(state)
end

-- 任务背景
function NewUserExpandTaskUI:updateSpBgUI()
    local status = self.m_taskData:getStatus()
    local resPath = "NewUser_Expend/Activity/ui/NewUser_Expend_gamenode_1.png"
    if status == -1 then
        resPath = "NewUser_Expend/Activity/ui/NewUser_Expend_gamenode_1.png"
    end
    util_changeTexture(self.m_spBg, resPath)
end

-- 任务Lb
function NewUserExpandTaskUI:initLbTaskUI()
    local taskIdx = self.m_taskData:getProgValue()
    self.m_lbTask:setString(taskIdx)
end

-- 更新任务状态
function NewUserExpandTaskUI:updateTaskState(_state)
    if self.m_state and self.m_state >= _state then
        return
    end
    
    self.m_state = _state

    local actName = "idle_locked"
    local cb
    if _state == NewUserExpandConfig.TASK_STATE.UNLOCK_ANI then
        actName = "done"
        cb = function()
            self:updateTaskState(NewUserExpandConfig.TASK_STATE.UNLOCK)
        end
    elseif _state == NewUserExpandConfig.TASK_STATE.UNLOCK then
        actName = "idle_normal"
    elseif _state == NewUserExpandConfig.TASK_STATE.DONE_ANI then
        actName = "dagou"
        cb = function()
            self:updateTaskState(NewUserExpandConfig.TASK_STATE.DONE)
        end
    elseif _state == NewUserExpandConfig.TASK_STATE.DONE then
        actName = "idle_done"
    end

    self:runCsbAction(actName, false, cb)
    self.m_btnGoGame:setEnabled(_state == NewUserExpandConfig.TASK_STATE.UNLOCK)
end

function NewUserExpandTaskUI:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_gamenode" then
        self:gotoGame()
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end
end

-- 点击去玩游戏
function NewUserExpandTaskUI:gotoGame()
    if self.m_state ~= NewUserExpandConfig.TASK_STATE.UNLOCK then
        return
    end

    -- 动画过程中还没 刷新state 用server数据判断下
    local bServerDone = self.m_taskData:checkDone()
    if bServerDone then
        return
    end

    G_GetMgr(G_REF.NewUserExpand):gotoPlayGame()
end

function NewUserExpandTaskUI:updateVisible()
    if not self.m_bEnter then
        return
    end
    local posSelf = self.m_spBg:convertToWorldSpace(cc.p(0, 0))
    local sizeSelf = self.m_size
    local bVisible = cc.rectIntersectsRect(cc.rect(0, 0, display.width, display.height), cc.rect(posSelf.x, posSelf.y, sizeSelf.width, sizeSelf.height))
    self:setVisible(bVisible)
end

function NewUserExpandTaskUI:setSwallowTouches(_bSwallow)
    self.m_btnGoGame:setSwallowTouches(_bSwallow)
end

return NewUserExpandTaskUI