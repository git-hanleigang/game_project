---
--xcyy
--2018年5月23日
--GeminiJourneyCollectBtn.lua
local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyCollectBtn = class("GeminiJourneyCollectBtn",util_require("Levels.BaseLevelDialog"))

function GeminiJourneyCollectBtn:initUI(_collectBar, _machine)

    self:createCsbNode("GeminiJourney_RespinCounter_button.csb")
    self:runCsbAction("idle", true)

    self.m_collectBar = _collectBar
    self.m_machine = _machine
end

--默认按钮监听回调
function GeminiJourneyCollectBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_info" and self.m_machine:tipsBtnIsCanClick() then
        self.m_collectBar:showTips()
    end
end

function GeminiJourneyCollectBtn:showBtn(_onEnter)
    util_resetCsbAction(self.m_csbAct)
    if _onEnter then
        self:runCsbAction("idle", true)
    else
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

function GeminiJourneyCollectBtn:closeBtn(_onEnter)
    util_resetCsbAction(self.m_csbAct)
    if _onEnter then
        self:runCsbAction("idle1", true)
    else
        self:runCsbAction("over", false, function()
            self:runCsbAction("idle1", true)
        end)
    end
end

return GeminiJourneyCollectBtn
