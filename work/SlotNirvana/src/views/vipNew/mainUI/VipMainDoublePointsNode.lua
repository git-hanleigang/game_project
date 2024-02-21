--[[
]]
local VipMainDoublePointsNode = class("VipMainDoublePointsNode", BaseView)

function VipMainDoublePointsNode:initDatas()
    self.m_des = gLobalLanguageChangeManager:getStringByKey("VipMainDoublePointsNode:lb_des")
end

function VipMainDoublePointsNode:getCsbName()
    return "VipNew/csd/mainUI/VipMain_doublePoints.csb"
end

function VipMainDoublePointsNode:initCsbNodes()
    self.m_lbDes = self:findChild("lb_dec")
end

function VipMainDoublePointsNode:initUI()
    VipMainDoublePointsNode.super.initUI(self)
    self:initView()
end

function VipMainDoublePointsNode:initView()
    self:updateLabel()
    self:initTimer()
end

function VipMainDoublePointsNode:updateLabel()
    local doublePointsData = G_GetMgr(ACTIVITY_REF.VipDoublePoint):getData()
    if doublePointsData and doublePointsData:isRunning() then
        local expireAt = doublePointsData:getExpireAt()
        self.m_lbDes:setString(self.m_des .. " " .. util_daysdemaining(expireAt))
    else
        self.m_lbDes:setString(self.m_des .. " 00:00:00")
    end
end

function VipMainDoublePointsNode:initTimer()
    if self.m_sche then
        self:stopAction(self.sche)
        self.sche = nil
    end
    local function updateLabel()
        self:updateLabel()
    end
    self.sche = util_schedule(self, updateLabel, 1)
end

--
return VipMainDoublePointsNode
