--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-08-16 12:13:36
]]
local UIMenuListTitle = util_require("base.UIMenuListTitle")
local TestListTitle = class("TestListTitle", UIMenuListTitle)

function TestListTitle:getContentSize()
    return cc.size(855, 150)
end

function TestListTitle:getCsbName()
    return "InBox/TestTitleNode.csb"
end

function TestListTitle:initCsbNodes()
    self.m_lbText = self:findChild("lb_text")
end
function TestListTitle:initView()
    self:initText()
end

function TestListTitle:initText()
    self.m_lbText:setString("This is title")
end

return TestListTitle