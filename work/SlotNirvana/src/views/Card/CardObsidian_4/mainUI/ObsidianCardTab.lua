--[[
    特殊卡册页签小点-购物主题
]]
local ObsidianCardTab = class("ObsidianCardTab", BaseView)

function ObsidianCardTab:initDatas(_index)
    self.m_index = _index
end

function ObsidianCardTab:getCsbName()
    return "CardRes/CardObsidian_4/csb/main/ObsidianAlbum_checkbox.csb"
end

function ObsidianCardTab:initCsbNodes()
    self.m_checkbox = self:findChild("CheckBox_1")
    self.m_checkbox:setTouchEnabled(false)
end

function ObsidianCardTab:updateUI(_pageIndex)
    self.m_checkbox:setSelected(self.m_index == _pageIndex)
end

function ObsidianCardTab:getTabSize()
    return cc.size(50, 50)
end

return ObsidianCardTab
