--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-16 12:13:36
]]
local UIMenuListItem = util_require("base.UIMenuListItem")
local TestListItem = class("TestListItem", UIMenuListItem)

function TestListItem:getContentSize()
    return cc.size(600, 120)
end

function TestListItem:getCsbName()
    return "InBox/TestItemNode.csb"
end

function TestListItem:initCsbNodes()
    self.m_lbText = self:findChild("lb_text")
end

function TestListItem:initView()
    self:initText()
end

function TestListItem:initText()
    self.m_lbText:setString("This is item")
end

return TestListItem