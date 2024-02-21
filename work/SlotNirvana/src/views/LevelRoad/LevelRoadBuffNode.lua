-- 等级里程碑 buff节点
local LevelRoadBuffNode = class("LevelRoadBuffNode", util_require("base.BaseView"))

function LevelRoadBuffNode:initUI()
    LevelRoadBuffNode.super.initUI(self)
    self:initView()
end

function LevelRoadBuffNode:initDatas(_buffId)
    self.m_buffId = _buffId or 1
    self.m_buffType = self.m_buffId == 1 and BUFFTYPY.BUFFTYPY_DOUBLE_EXP or BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN
end

function LevelRoadBuffNode:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "LevelRoad/csd/Main_Portrait/LevelRoad_main_message_buff_Portrait.csb"
    end
    return "LevelRoad/csd/LevelRoad_main_message_buff.csb"
end

function LevelRoadBuffNode:initCsbNodes()
    self.m_lb_buff_time = self:findChild("lb_buff_time")
end

function LevelRoadBuffNode:initView()
    self:initBuff()
    self:showDownTimer()
end

function LevelRoadBuffNode:initBuff()
    for i = 1, 2, 1 do
        local icon = self:findChild("sp_buff_icon_" .. i)
        local iconMask = self:findChild("sp_buff_icon_" .. i .. "_black")
        if icon then
            icon:setVisible(i == self.m_buffId)
        end
        if iconMask then
            iconMask:setVisible(false)
        end
    end
end

--显示倒计时
function LevelRoadBuffNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function LevelRoadBuffNode:updateLeftTime()
    local buffLeftTime = globalData.buffConfigData:getBuffLeftTimeByType(self.m_buffType)
    if buffLeftTime > 0 then
        local timeStr = util_count_down_str(buffLeftTime)
        if buffLeftTime > 86400 then
            timeStr = math.ceil((buffLeftTime) / 86400) .. " DAYS"
        end
        self.m_lb_buff_time:setString(timeStr)
    else
        self.m_lb_buff_time:setString("00:00:00")
        local iconMask = self:findChild("sp_buff_icon_" .. self.m_buffId .. "_black")
        if iconMask then
            iconMask:setVisible(true)
        end
        self:stopTimerAction()
    end
end

function LevelRoadBuffNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

return LevelRoadBuffNode
