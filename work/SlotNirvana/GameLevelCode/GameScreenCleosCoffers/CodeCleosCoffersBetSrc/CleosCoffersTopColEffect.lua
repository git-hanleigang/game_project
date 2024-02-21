---
--xcyy
--2018年5月23日
--CleosCoffersTopColEffect.lua

local CleosCoffersTopColEffect = class("CleosCoffersTopColEffect",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CleosCoffersPublicConfig"

function CleosCoffersTopColEffect:initUI(_params)
    self.m_machine = _params.machine
    self:createCsbNode("CleosCoffers_active_kuangEffect.csb")

    self.m_topColSpineTab = {}
    for index = 1, 5 do
        self.m_topColSpineTab[index] = util_spineCreate("CalacasParade_reel_jinbi",true,true)
        self:findChild("Node_"..index):addChild(self.m_topColSpineTab[index])
        self.m_topColSpineTab[index]:setVisible(false)
    end
end

function CleosCoffersTopColEffect:onEnter()
    CleosCoffersTopColEffect.super.onEnter(self)
end

function CleosCoffersTopColEffect:onExit()
    CleosCoffersTopColEffect.super.onExit(self)
end

function CleosCoffersTopColEffect:showCurColEffect(_col)
    local curEffectSpine = self.m_topColSpineTab[_col]
    if curEffectSpine then
        curEffectSpine:setVisible(true)
        util_spinePlay(curEffectSpine, "actionframe", false)
        util_spineEndCallFunc(curEffectSpine, "actionframe", function()
            curEffectSpine:setVisible(false)
        end)
    end
end

return CleosCoffersTopColEffect
