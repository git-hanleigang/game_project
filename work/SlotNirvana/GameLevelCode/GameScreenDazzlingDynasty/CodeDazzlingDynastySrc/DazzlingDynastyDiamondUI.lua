--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-08-01 20:38:13
]]

local DazzlingDynastyDiamondUI = class("DazzlingDynastyDiamondUI", util_require("base.BaseView"))

function DazzlingDynastyDiamondUI:initUI()
    self:createCsbNode("DazzlingDynasty_diamonds.csb")
    self:runCsbAction("idle",true)
end

return DazzlingDynastyDiamondUI