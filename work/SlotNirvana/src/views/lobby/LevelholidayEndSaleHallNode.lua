--
-- 大厅展示图
--
local LevelFeature = util_require("views.lobby.LevelFeature")
local Promotion_HolidayBoxHallNode = class("Promotion_HolidayBoxHallNode", LevelFeature)

function Promotion_HolidayBoxHallNode:createCsb()
    self.m_saleData = G_GetMgr(G_REF.HolidayEnd):getRunningData()
    if self.m_saleData then 
        self:initView()
        self:checkTime()
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "close"})
    end
end

function Promotion_HolidayBoxHallNode:initView()
    self:createCsbNode("Icons/HolidayBox_Hall.csb")
    
    self.m_discount = self:findChild("lb_zhekou")
    local discounts = self.m_saleData:getDiscounts()
    self.m_discount:setString("" .. discounts .. "%")
    util_scaleCoinLabGameLayerFromBgWidth(self.m_discount, 73, 1)
end

function Promotion_HolidayBoxHallNode:checkTime()
    local gameData = self.m_saleData
    local updateTimeLable = function()
        if gameData == nil or not gameData:isRunning() or gameData:isPay() then
            self:stopAllActions()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOLIDAY_END_SALE, {type = "close"})
        end
    end
    util_schedule(self, updateTimeLable, 1)
    updateTimeLable()
end

--点击回调
function Promotion_HolidayBoxHallNode:clickFunc(sender)
    if self.m_isTouch then
        return
    end

    self.m_isTouch = true
    local name = sender:getName()
    self:clickLayer(name)
end

function Promotion_HolidayBoxHallNode:clickLayer(name)
    local view = G_GetMgr(G_REF.HolidayEnd):showMainLayer()
    self.m_isTouch = false
end

return Promotion_HolidayBoxHallNode
