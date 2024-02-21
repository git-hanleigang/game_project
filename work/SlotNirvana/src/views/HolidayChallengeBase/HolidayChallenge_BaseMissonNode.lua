
local HolidayChallenge_BaseMissonNode = class("HolidayChallenge_BaseMissonNode",BaseView)

function HolidayChallenge_BaseMissonNode:getCsbName()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return self.m_activityConfig.RESPATH.MISSION_NODE
end

function HolidayChallenge_BaseMissonNode:initCsbNodes()
    self.m_lb_mission = self:findChild("lb_mission")
    self.m_lb_number = self:findChild("lb_number")
    self.m_lb_icon = self:findChild("lb_icon")
end

function HolidayChallenge_BaseMissonNode:initUI(_data)
    HolidayChallenge_BaseMissonNode.super.initUI(self)
    
    self:setDescription(_data)
end

function HolidayChallenge_BaseMissonNode:setDescription(_data)
    local taskDesc = _data:getDescription()
    local desList = util_string_split(taskDesc,";")
    local firstStr = desList[1]
    local secondStr = desList[2]
    self.m_lb_mission:setString(firstStr .. " " .. secondStr)
    
    local completeCount = _data:getCompleteCount() or 0
    local countLimit = _data:getCountLimit() or 0
    if countLimit <= 0 then
        self.m_lb_number:setVisible(false)
    else
        local size = self.m_lb_mission:getContentSize()
        local missionPosX = self.m_lb_mission:getPositionX()
        self.m_lb_number:setString("(" .. _data:getCompleteCount() .. "/" .. _data:getCountLimit() .. ")")
        self.m_lb_number:setPositionX(missionPosX + size.width/2 + 2)
    end
    
    self.m_lb_icon:setString("X".._data:getPoints())
end

function HolidayChallenge_BaseMissonNode:getSize()
    local content = self:findChild("content")
    local size = content:getContentSize()
    return size
end

return HolidayChallenge_BaseMissonNode