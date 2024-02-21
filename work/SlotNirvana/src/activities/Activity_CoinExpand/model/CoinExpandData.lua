local BaseActivityData = require "baseActivity.BaseActivityData"
local CoinExpandData = class("CoinExpandData", BaseActivityData)

function CoinExpandData:ctor(data)
    BaseActivityData.ctor(self, data)
    self.p_open = true
end

function CoinExpandData:parseData(data)
    BaseActivityData.parseData(self, data)
end

function CoinExpandData:parseNormalActivityData(_data)
    BaseActivityData.parseNormalActivityData(self,_data)
end

function CoinExpandData:isRunning(_data)
    return BaseActivityData.isRunning(self,_data)
end


return CoinExpandData