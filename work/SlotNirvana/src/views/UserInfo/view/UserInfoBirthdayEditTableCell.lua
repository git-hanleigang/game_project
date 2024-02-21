local UserInfoBirthdayEditTableCell = class("UserInfoBirthdayEditTableCell", BaseView)

function UserInfoBirthdayEditTableCell:initUI()
    UserInfoBirthdayEditTableCell.super.initUI(self)
    self:initView()
end

function UserInfoBirthdayEditTableCell:getCsbName()
    return "Activity/csd/Information/Iformation_EditBirthdayCell.csb"
end

function UserInfoBirthdayEditTableCell:initView()
    self.m_lb_select = self:findChild("lb_select")
    self.m_lb_select_light = self:findChild("lb_select_light")
    self:setLabelHighLight(false)
end

function UserInfoBirthdayEditTableCell:updataCell(_data, _idx)
    self.m_data = _data
    self.m_index = _idx
    self.m_lb_select:setString("" .. _data)
    self.m_lb_select_light:setString("" .. _data)
    self:setLabelHighLight(false)
end

function UserInfoBirthdayEditTableCell:setLabelHighLight(_bool)
    if _bool ~= nil then
        self.m_lb_select:setVisible(not _bool)
        self.m_lb_select_light:setVisible(_bool)
    end
end

function UserInfoBirthdayEditTableCell:getIndex()
    return self.m_index or 0
end

return UserInfoBirthdayEditTableCell