--[[
    任务入口按钮基类
]]
local ActivityTaskBottomBase = class("ActivityTaskBottomBase", util_require("base.BaseView"))
local ActivityTaskManager = util_require("manager.ActivityTaskManager")

function ActivityTaskBottomBase:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 or globalData.slotRunData.isPortrait == true then
        isAutoScale = false
    end

    if self.getCsbName ~= nil then
        self:createCsbNode(self:getCsbName(), isAutoScale)
        self:initNode()
        self:registerListener()
        self:updateTaskProgress()
    end
end
--初始化节点
function ActivityTaskBottomBase:initNode()
    if self:getHasProgress() then
        self.m_lbProgressNum = self:findChild("lb_dec") --进度数字（名称固定）
        assert(self.m_lbProgressNum, "必要的节点1")
        self.m_nodeProgress = self:findChild("prg") --进度条（名称固定）
        assert(self.m_nodeProgress, "必要的节点1")
    end
end
--更新任务进度显示
function ActivityTaskBottomBase:updateTaskProgress()
    local activityName = self:getActivityName()
    if activityName then
        local taskDataObj = ActivityTaskManager:getInstance():getCurrentTaskByActivityName(activityName)
        if taskDataObj then
            local paramsList = taskDataObj:getParams()
            local processList = taskDataObj:getProcess()
            local params = paramsList[1]
            local process = processList[1]
            self.m_nodeProgress:setPercent(tonumber(process) / tonumber(params) * 100)

            if taskDataObj:getCompleted() then
                self.m_lbProgressNum:setString("COMPLETED")
                self.m_lbProgressNum:setScale(0.5)
                if not taskDataObj:getReward() then
                    --可以领奖的消息
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_CAN_COMOLETED)
                    return true
                end
            else
                local progressNum = math.floor(tonumber(process) * 100 / tonumber(params))
                self.m_lbProgressNum:setString(tostring(progressNum) .. "%")
            end
        end
    end
end

function ActivityTaskBottomBase:registerListener()
    if self:getHasProgress() then
        gLobalNoticManager:addObserver(
            self,
            function(target, params)
                self:updateTaskProgress()
            end,
            ViewEventType.NOTIFY_ACTIVITY_TASK_UPDATE_DATA
        )
    end
end

function ActivityTaskBottomBase:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
--------------------------  子类重写 ---------------------------
function ActivityTaskBottomBase:getCsbName()
    assert("ActivityTaskBottomBase:getCsbName 必须重写")
end

function ActivityTaskBottomBase:getActivityName()
    assert("ActivityTaskBottomBase:getActivityName 必须重写")
end

function ActivityTaskBottomBase:getHasProgress()
    assert("ActivityTaskBottomBase:getHasProgress 必须重写")
end

return ActivityTaskBottomBase
