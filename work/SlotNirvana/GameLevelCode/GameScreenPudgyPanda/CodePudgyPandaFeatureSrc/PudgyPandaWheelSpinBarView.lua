---
--xcyy
--2018年5月23日
--PudgyPandaWheelSpinBarView.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaWheelSpinBarView = class("PudgyPandaWheelSpinBarView", util_require("base.BaseView"))
PudgyPandaWheelSpinBarView.m_leftSpinCount = 0
PudgyPandaWheelSpinBarView.m_totalSpinCount = 0

function PudgyPandaWheelSpinBarView:initUI()
    self:createCsbNode("PudgyPanda_spinbar.csb")
    self:runCsbAction("idle", true)

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function PudgyPandaWheelSpinBarView:refreshLeftCount(_leftCount)
    self.m_leftSpinCount = self.m_leftSpinCount - 1
    self:updateWheelLeftCount()
end

function PudgyPandaWheelSpinBarView:refreshAllCount(_leftCount, _totalCount)
    self.m_leftSpinCount = _leftCount
    self.m_totalSpinCount = _totalCount
    self:updateWheelLeftCount()
end

-- 更新并显示FreeSpin剩余次数
function PudgyPandaWheelSpinBarView:updateWheelLeftCount()
    local curtimes = self.m_totalSpinCount-self.m_leftSpinCount
    local totaltimes = self.m_totalSpinCount
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2"):setString(totaltimes)
end

return PudgyPandaWheelSpinBarView
