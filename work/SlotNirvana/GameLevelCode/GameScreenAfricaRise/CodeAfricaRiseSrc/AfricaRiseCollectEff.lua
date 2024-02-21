---
--xcyy
--2018年5月23日
--AfricaRiseCollectEff.lua

local AfricaRiseCollectEff = class("AfricaRiseCollectEff",util_require("base.BaseView"))


function AfricaRiseCollectEff:initUI()
    self:createCsbNode("AfricaRise_jindutiao_effect.csb")
end

function AfricaRiseCollectEff:onEnter()
end


function AfricaRiseCollectEff:onExit()
end

return AfricaRiseCollectEff