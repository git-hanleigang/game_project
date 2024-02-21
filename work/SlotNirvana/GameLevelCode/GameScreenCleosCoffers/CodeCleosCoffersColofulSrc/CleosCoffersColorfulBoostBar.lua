---
--xcyy
--2018年5月23日
--CleosCoffersColorfulBoostBar.lua
local PublicConfig = require "CleosCoffersPublicConfig"
local CleosCoffersColorfulBoostBar = class("CleosCoffersColorfulBoostBar",util_require("base.BaseView"))

function CleosCoffersColorfulBoostBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("CleosCoffers_dfdc_boostbar.csb")

    self.m_moreText = self:findChild("m_lb_num")
    
    self.m_lightSpine = util_spineCreate("CleosCoffers_dfdc_jackpot_tx",true,true)
    self:findChild("Node_tx"):addChild(self.m_lightSpine)
    
    self:runIdleAni()
end

--[[
    idle
]]
function CleosCoffersColorfulBoostBar:runIdleAni()
    self:runCsbAction("idle", true)
end

function CleosCoffersColorfulBoostBar:setCurMul(_curMul)
    local curMul = tostring(_curMul*100).."%"
    self.m_moreText:setString(curMul)
    self.m_machine:updateLabelSize({label=self.m_moreText,sx=1.0,sy=1.0},112)
end

--[[
    idle
]]
function CleosCoffersColorfulBoostBar:runStartAni(_curMul)
    self:setCurMul(_curMul)
    if not self:isVisible() then
        self:setVisible(true)
        self.m_lightSpine:setVisible(true)
        self:runCsbAction("start", false, function()
            self:runIdleAni()
        end)
        util_spinePlay(self.m_lightSpine, "boost_start", true)
        util_spineEndCallFunc(self.m_lightSpine, "boost_start", function()
            self.m_lightSpine:setVisible(false)
        end)
    end
end

return CleosCoffersColorfulBoostBar
