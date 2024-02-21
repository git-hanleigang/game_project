--[[
   视频弹窗
]]
local DailybonusAdsView = class("DailybonusAdsView", util_require("base.BaseView"))

DailybonusAdsView.m_watchCallFun = nil
DailybonusAdsView.m_closeCallFun = nil

function DailybonusAdsView:initUI(watchCallFun,closeCallFun)

    self:createCsbNode("Hourbonus_new3/DailyBonusVideoLayer.csb")
    self:findChild("spinnow"):setTouchEnabled(false)
    self:findChild("close"):setTouchEnabled(false)
    self.m_buyCallFun = watchCallFun
    self.m_closeCallFun = closeCallFun
    self:runCsbAction("show",false,function(  )
        self:runCsbAction("idle",false)
        self:findChild("spinnow"):setTouchEnabled(true)
        self:findChild("close"):setTouchEnabled(true)
    end)
end

function DailybonusAdsView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "spinnow" then

    elseif name == "close" then
    end
end


return DailybonusAdsView