local GamePusherStagePerView = class("CoinPusherCardLayer", util_require("base.BaseView"))
local Config    = require("CoinCircusSrc.GamePusherMain.GamePusherConfig")

function GamePusherStagePerView:initUI(data)

    self._PerCentLb = self:findChild("lb_jiacheng")

    self._PerCentLb:setString(tostring(data))
end


function GamePusherStagePerView:updatePercent(percent)
    if tonumber(percent) == 0 then
        self:setVisible(false)
    else
        self:setVisible(true)
        self._PerCentLb:setString(string.format("%d",percent).. "%")
    end
end
return GamePusherStagePerView