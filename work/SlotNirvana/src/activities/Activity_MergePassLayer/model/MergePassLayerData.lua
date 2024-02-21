local BaseActivityData = require("baseActivity.BaseActivityData")
local MergePassLayerData = class("MergePassLayerData", BaseActivityData)

function MergePassLayerData:ctor()
    MergePassLayerData.super.ctor(self)
    self.p_open = true
end

return MergePassLayerData