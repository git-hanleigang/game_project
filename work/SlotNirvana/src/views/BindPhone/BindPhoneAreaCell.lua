--[[
    电话区号
    author:{author}
    time:2022-11-15 20:03:23
]]
local BindPhoneAreaCell = class("BindPhoneAreaCell", BaseView)

function BindPhoneAreaCell:initUI()
    self.m_idx = 0
    self:createCsbNode("Dialog/BindPhone_codeCell.csb")
end

function BindPhoneAreaCell:initCsbNodes()
    local _codeTemp = self:findChild("lb_code")
    _codeTemp:setString("")
    _codeTemp:setVisible(true)
    _codeTemp:setTouchEnabled(true)
    _codeTemp:setSwallowTouches(false)
    self:addClick(_codeTemp)
    self.m_lbCode = _codeTemp

    self.m_palCode = self:findChild("Panel_code")
    self.m_palCode:setTouchEnabled(false)
end

function BindPhoneAreaCell:updateView(data, idx)
    -- local _country = string.gsub(data.country, "|", "\n")
    local _country = data.country
    local _txt = "+" .. data.code .. " " .. _country
    self.m_lbCode:setString(_txt)
    self.m_idx = idx

    -- util_wordSwing(self.m_lbCode, 1, self.m_palCode, 2, 30, 2)
end

function BindPhoneAreaCell:setTextContentSize(_size)
    self.m_lbCode:setContentSize(_size)
end

function BindPhoneAreaCell:clickFunc(sender)
    local name = sender:getName()
    if name == "lb_code" then
        gLobalNoticManager:postNotification("notify_choose_areaCode", {index = self.m_idx})
    end
end

return BindPhoneAreaCell
