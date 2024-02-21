--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-19 18:54:19
]]
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local GuideTestCtrl = class("GuideTestCtrl", GameGuideCtrl)

function GuideTestCtrl:initDatas()
    self.m_refName = "testRef"
end

return GuideTestCtrl
