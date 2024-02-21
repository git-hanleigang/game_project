--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local BingoWildBallData = class("BingoWildBallData", BaseActivityData)

function BingoWildBallData:ctor()
    BingoWildBallData.super.ctor(self)
    self.p_open = true
end

return BingoWildBallData
