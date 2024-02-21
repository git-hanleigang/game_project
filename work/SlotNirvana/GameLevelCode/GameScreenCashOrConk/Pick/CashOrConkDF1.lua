local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CashOrConkDF1 = class("CashOrConkDF1",CashOrConkDFBase)

function CashOrConkDF1:initUI(data)
    self:setDelegate(data.machine)
    -- self:createCsbNode("CashOrConk/GameScreenCashOrConk_sanxuanyi.csb")
end

function CashOrConkDF1:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return CashOrConkDF1