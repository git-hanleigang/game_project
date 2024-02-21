--[[--
    listcell中的奖励
]]
local Cell_Center = class("Cell_Center", BaseView)
function Cell_Center:getCsbName()
    return "VipNew/csd/rewardUI/Cell_Center.csb"
end

function Cell_Center:initDatas(_index, _str, _num, _ismy)
    self.m_index = _index
    self.m_str = _str
    self.m_num = _num
    self.m_ismy = _ismy
end

function Cell_Center:initCsbNodes()
    self.m_lbNum = self:findChild("lb_num")
    self.m_nodeg1 = self:findChild("sp_gezi")
    self.m_nodeg2 = self:findChild("sp_gezi2")
end

function Cell_Center:initUI()
    Cell_Center.super.initUI(self)
    self:updateNum()
    self:updateColor()
end

function Cell_Center:updateUI(_str, _num)
    self.m_str = _str
    self.m_num = _num
    self:updateNum()
    self:updateColor()
end

function Cell_Center:updateColor()
    if self.m_nodeg2 then
        if self.m_index%2 == 0 then
            self.m_nodeg2:setVisible(true)
            self.m_nodeg1:setVisible(false)
        else
            self.m_nodeg2:setVisible(false)
            self.m_nodeg1:setVisible(true)
        end
    end
    if self.m_ismy then
        self.m_lbNum:setTextColor(cc.c3b(255, 255, 255))
    else
        self.m_lbNum:setTextColor(cc.c3b(187, 117, 0))
    end
end

function Cell_Center:updateNum()
    self.m_lbNum:setString(string.format(self.m_str, tostring(self.m_num or 99)))
end

return Cell_Center
