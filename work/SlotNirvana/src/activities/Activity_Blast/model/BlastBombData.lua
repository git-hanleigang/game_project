--jiaohua
local BaseActivityData = require "baseActivity.BaseActivityData"
local BlastBombData = class("BlastBombData", BaseActivityData)

function BlastBombData:ctor(_data)
    BlastBombData.super.ctor(self,_data)
    self.p_open = true
end

return BlastBombData