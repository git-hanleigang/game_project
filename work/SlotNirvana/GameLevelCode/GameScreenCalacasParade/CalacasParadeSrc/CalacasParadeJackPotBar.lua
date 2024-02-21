--[[
    --彩金栏
    self.m_jackpotBar = util_createView("CalacasParadeSrc.CalacasParadeJackPotBar", self)
    self:findChild("Node_jackpot"):addChild(self.m_jackpotBar)
]]
local CalacasParadeJackPotBar = class("CalacasParadeJackPotBar", util_require("base.BaseView"))
-- local PublicConfig = require "CalacasParadePublicConfig"

function CalacasParadeJackPotBar:initUI(_machine)
    self.m_machine = _machine

    self:createCsbNode("CalacasParade_jackpotbar.csb")
    self:initJackpotLabInfo()

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function CalacasParadeJackPotBar:onEnter()
    CalacasParadeJackPotBar.super.onEnter(self)

    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end
--[[
    jackpot文本刷新
]]
function CalacasParadeJackPotBar:initJackpotLabInfo()
    self.m_jackpotCsbInfo = {
        -- jackpot索引, 宽度, x缩放, y缩放
        {1, 287, 1, 1},
        {2, 287, 1, 1},
        {3, 245, 1, 1},
        {4, 245, 1, 1},
    }
end
-- 更新jackpot 数值信息
function CalacasParadeJackPotBar:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    for i,_labInfo in ipairs(self.m_jackpotCsbInfo) do
        local label   = self:findChild( string.format("m_lb_coins_%d", _labInfo[1]) )
        local value  = self.m_machine:BaseMania_updateJackpotScore(_labInfo[1])
        label:setString(util_formatCoins(value, 20, nil, nil, true))
        local info = {label=label, sx=_labInfo[3], sy=_labInfo[4]}
        self:updateLabelSize(info, _labInfo[2])
    end
end

--时间线
-- function CalacasParadeJackPotBar:playJackpotBarIdle()
--     self:runCsbAction("idleframe", true)
-- end

return CalacasParadeJackPotBar