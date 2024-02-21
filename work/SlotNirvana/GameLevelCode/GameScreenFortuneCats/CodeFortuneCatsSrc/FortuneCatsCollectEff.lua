---
--xcyy
--2018年5月23日
--FortuneCatsCollectEff.lua

local FortuneCatsCollectEff = class("FortuneCatsCollectEff",util_require("base.BaseView"))


function FortuneCatsCollectEff:initUI()
    self:createCsbNode("FortuneCats_jindutiao_effect.csb")
end

function FortuneCatsCollectEff:onEnter()
end


function FortuneCatsCollectEff:onExit()
end

return FortuneCatsCollectEff