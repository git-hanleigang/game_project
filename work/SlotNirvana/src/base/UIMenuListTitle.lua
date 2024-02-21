--[[
]]
local UIMenuListTitle = class("UIMenuListTitle", BaseView)

function UIMenuListTitle:initDatas(_data, _clickBtnSelect)
    self.m_data = _data
    self.m_clickBtnSelect = _clickBtnSelect
end

function UIMenuListTitle:setSelected(_isSelected)
    self.m_isSelected = _isSelected
end

function UIMenuListTitle:getContentSize()
    return cc.size(600, 150)
end

function UIMenuListTitle:getCsbName()
    return "InBox/TestTitleNode.csb"
end

function UIMenuListTitle:initCsbNodes()
    self.m_lbText = self:findChild("lb_text")
end

function UIMenuListTitle:initUI()
    UIMenuListTitle.super.initUI(self)
    self:initView()
end

function UIMenuListTitle:initView()
    self:initText()
end

function UIMenuListTitle:initText()
    self.m_lbText:setString("This is title")
end

function UIMenuListTitle:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_select" then
        if self.m_clickBtnSelect then
            self.m_clickBtnSelect(self.m_data.id, self.m_data.key, self.m_data.num)
        end
    end
end

return UIMenuListTitle