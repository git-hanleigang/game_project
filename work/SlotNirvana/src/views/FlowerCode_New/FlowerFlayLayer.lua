-- 奖励
local FlowerFlayLayer = class("FlowerFlayLayer", util_require("base.BaseView"))

function FlowerFlayLayer:initUI()
    local path = "Flower/Activity/csd/flowerflay.csb"
    self:createCsbNode(path, isAutoScale)
    self:setExtendData("FlowerFlayLayer")
    self:initView()
end

function FlowerFlayLayer:initView()
    local sp = self:findChild("sp_port")
    sp:setScale(0.7)
end

return FlowerFlayLayer
