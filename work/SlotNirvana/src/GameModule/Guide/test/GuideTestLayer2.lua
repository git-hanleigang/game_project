--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-17 12:18:14
]]
local GuideTestCtrl = require("GameModule.Guide.test.GuideTestCtrl")
local GuideTestLayer2 = class("GuideTestLayer2", BaseLayer)

function GuideTestLayer2:initDatas(ctrl, stepInfo)
    self:setLandscapeCsbName("GameModule/Guide/test/res/GuideTestLayer2.csb")
    self:setHasGuide(true)
end

function GuideTestLayer2:onShowedCallFunc()
    self:triggerGuideStep()
end
function GuideTestLayer2:triggerGuideStep()
    GuideTestCtrl:getInstance():triggerGuide(self, "testGuide2", "testRef")
end

function GuideTestLayer2:onClickMask()
end

function GuideTestLayer2:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_1" then
    elseif senderName == "btn_2" then
    elseif senderName == "btn_3" then
    end
end

return GuideTestLayer2
