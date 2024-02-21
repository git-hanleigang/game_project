--[[--
    小红点
]]
local BaseView = util_require("base.BaseView")
local InboxPage_redPoint = class("InboxPage_redPoint", BaseView)
function InboxPage_redPoint:initUI()
    self:createCsbNode("InBox/FBCard/InboxPage_RedPoint.csb")
    self.m_redNum = self:findChild("redNum")
end

function InboxPage_redPoint:updateNum(num)
    self.m_redNum:setString(num)
    self:updateLabelSize({label=self.m_redNum},25)
end

return InboxPage_redPoint