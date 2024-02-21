--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local BingoShowTopData = class("BingoShowTopData", BaseActivityData)

function BingoShowTopData:ctor()
    BingoShowTopData.super.ctor(self)
    self.p_open = true
end

return BingoShowTopData
