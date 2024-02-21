--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local CashPuzzleData = class("CashPuzzleData", BaseActivityData)

function CashPuzzleData:ctor()
    CashPuzzleData.super.ctor(self)
    self.p_open = true
end

return CashPuzzleData
