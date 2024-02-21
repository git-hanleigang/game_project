--[[
]]
local UIMenuListItem = class("UIMenuListItem", BaseView)

function UIMenuListItem:initDatas(_data, _clickBtnCollect)
    self.m_data = _data
    self.m_clickBtnCollect = _clickBtnCollect
end

function UIMenuListItem:setSelected(_isSelected)
    self.m_isSelected = _isSelected
end

function UIMenuListItem:isSelected()
    return self.m_isSelected
end

function UIMenuListItem:getContentSize()
end

function UIMenuListItem:getCsbName()
end

function UIMenuListItem:initUI()
    UIMenuListItem.super.initUI(self)
    self:initView()
end

function UIMenuListItem:initView()
end

function UIMenuListItem:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        if self.m_clickBtnCollect then
            self.m_clickBtnCollect()
        end
    end
end

return UIMenuListItem