--[[
    --新版每日任务pass主界面 促销
    csc 2021-06-28
]]
local DailyMissionPassPromotionNode = class("DailyMissionPassPromotionNode", util_require("base.BaseView"))
function DailyMissionPassPromotionNode:initUI()
    self:createCsbNode(self:getCsbName())

    self:initCsbNodes()

    self:updateView()
end

function DailyMissionPassPromotionNode:getCsbName()
    return DAILYMISSION_RES_PATH .."csd/Mission_Promotion/Pass_PromotionIcon.csb"
end

function DailyMissionPassPromotionNode:initCsbNodes()
    self.m_root = self:findChild("root")

    self.m_spTime = self:findChild("sp_time")
    self.m_lbTime = self:findChild("lb_time")
    self.m_plTouch = self:findChild("Panel_touch")
    self:addClick(self.m_plTouch)
end

function DailyMissionPassPromotionNode:updateView()
    -- 判断是否有购买过buff 促销
    if G_GetMgr(ACTIVITY_REF.NewPass):getInBuffTime() == false then
        self.m_spTime:setVisible(false)
        self:runCsbAction("idle", true, nil, 60)
    else
        self.m_spTime:setVisible(true)
        self:checkTimer()
        self:runCsbAction("idle_jihuo", true, nil, 60)
    end
end

function DailyMissionPassPromotionNode:checkTimer()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
    end
    self.activityAction =
        util_schedule(
        self,
        function()
            self:updateSaleState()
        end,
        1
    )
    self:updateSaleState()
end

-- 刷新促销状态
function DailyMissionPassPromotionNode:updateSaleState()
    if G_GetMgr(ACTIVITY_REF.NewPass):getInBuffTime() == false then
        self.m_spTime:setVisible(false)
        -- ui倒计时也关闭
        self:stopAction(self.activityAction)
        self.activityAction = nil
        self:runCsbAction("idle", true, nil, 60)
    else -- ui倒计时刷新
        local buffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BATTLEPASS_BOOSTER)
        local strLeftTime = util_count_down_str(buffTimeLeft)
        self.m_lbTime:setString(strLeftTime)
    end
end

function DailyMissionPassPromotionNode:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "Panel_touch" then
        -- 弹出购买页
        
        if G_GetMgr(G_REF.Flower) then
            if G_GetMgr(G_REF.Flower):getWaterHide() == nil then
            elseif not G_GetMgr(G_REF.Flower):getWaterHide() then
                return
            end
        end
        local buyLayer = util_createView("views.baseDailyMissionCode.pass_Promotion.DailyMissionPassBuySaleLayer")
        gLobalViewManager:showUI(buyLayer, ViewZorder.ZORDER_UI)
    end
end

function DailyMissionPassPromotionNode:onEnter()
    DailyMissionPassPromotionNode.super.onEnter(self)

    -- 促销到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then
                self:removeFromParent()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

return DailyMissionPassPromotionNode
