local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandMergeData = class("CoinExpandMergeData", BaseActivityData)

function CoinExpandMergeData:ctor()
    CoinExpandMergeData.super.ctor(self)
    self.p_open = true
end

return CoinExpandMergeData