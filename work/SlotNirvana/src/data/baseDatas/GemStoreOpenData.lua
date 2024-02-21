--
-- 钻石商城开启活动数据
--
local BaseActivityData = require("baseActivity.BaseActivityData")
local GemStoreOpenData = class("GemStoreOpenData", BaseActivityData)

function GemStoreOpenData:ctor()
    GemStoreOpenData.super.ctor(self)
    self.p_open = true
end

return GemStoreOpenData