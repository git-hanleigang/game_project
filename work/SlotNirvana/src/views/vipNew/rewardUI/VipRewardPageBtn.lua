--[[
    页签按钮
]]
local VipRewardPageBtn = class("VipRewardPageBtn", BaseView)

function VipRewardPageBtn:initDatas(_pageIndex, _clickPageFunc)
    self.m_pageIndex = _pageIndex
    self.m_clickPageFunc = _clickPageFunc
end

function VipRewardPageBtn:getCsbName()
    return "VipNew/csd/rewardUI/VipRewardPageBtn.csb"
end

function VipRewardPageBtn:initCsbNodes()
    self.m_spUp = self:findChild("sp_up")
    self.m_spDown = self:findChild("sp_down")
    self.m_panelTouch = self:findChild("Panel_touch")
    self:addClick(self.m_panelTouch)
end

function VipRewardPageBtn:initUI()
    VipRewardPageBtn.super.initUI(self)
end

function VipRewardPageBtn:updateBtn(_isSelected)
    self.m_spUp:setVisible(_isSelected == true)
    self.m_spDown:setVisible(_isSelected == false)
end

function VipRewardPageBtn:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        if self.m_clickPageFunc then
            self.m_clickPageFunc(self.m_pageIndex)
        end
    end
end

return VipRewardPageBtn
