
local BaseActivityData = require("baseActivity.BaseActivityData")
local LuckySpinUpgradeData = class("LuckySpinUpgradeData", BaseActivityData)
function LuckySpinUpgradeData:ctor()
    LuckySpinUpgradeData.super.ctor(self)

    self.p_open = true
end

-- -- 检查完成条件
-- function LuckySpinUpgradeData:checkCompleteCondition()
--     return not globalData.shopRunData:getLuckySpinIsOpen()  
-- end

return LuckySpinUpgradeData