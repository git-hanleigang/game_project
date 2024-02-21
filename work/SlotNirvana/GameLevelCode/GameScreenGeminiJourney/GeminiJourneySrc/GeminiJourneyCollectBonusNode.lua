---
--xcyy
--2018年5月23日
--GeminiJourneyCollectBonusNode.lua
local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyCollectBonusNode = class("GeminiJourneyCollectBonusNode",util_require("Levels.BaseLevelDialog"))

function GeminiJourneyCollectBonusNode:initUI()

    self:createCsbNode("GeminiJourney_RespinCounter_Spots.csb")
    self:runCsbAction("idle", true)
end

function GeminiJourneyCollectBonusNode:showStart(_onEnter)
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    if _onEnter then
        self:runCsbAction("idle", true)
    else
        self:runCsbAction("start", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

function GeminiJourneyCollectBonusNode:closeOver(_onEnter)
    util_resetCsbAction(self.m_csbAct)
    if _onEnter then
        self:setVisible(false)
    else
        self:runCsbAction("over", false, function()
            self:setVisible(false)
        end)
    end
end

return GeminiJourneyCollectBonusNode
