--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-06-17 12:18:14
]]
local GuideTestCtrl = require("GameModule.Guide.test.GuideTestCtrl")
local GuideTestLayer1 = class("GuideTestLayer1", BaseLayer)

function GuideTestLayer1:initDatas(ctrl, stepInfo)
    self:setLandscapeCsbName("GameModule/Guide/test/res/GuideTestLayer1.csb")
    self:setHasGuide(true)
end

function GuideTestLayer1:onShowedCallFunc()
    -- local btn1 = self:findChild("btn_1")
    -- btn1:setSwallowTouches(false)
    self:triggerGuideStep()
end

function GuideTestLayer1:triggerGuideStep()
    GuideTestCtrl:getInstance():triggerGuide(self, "testGuide", "testRef")
end

function GuideTestLayer1:onClickMask()
end

function GuideTestLayer1:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_1" or senderName == "btn_2" then
    elseif senderName == "btn_3" then
        self:closeUI(
            function()
                local _testGuideLayer2 = util_createView("GameModule.Guide.test.GuideTestLayer2")
                gLobalViewManager:showUI(_testGuideLayer2, ViewZorder.ZORDER_UI)
            end
        )
    end
    printInfo("GuideClick:" .. senderName)
end

return GuideTestLayer1
