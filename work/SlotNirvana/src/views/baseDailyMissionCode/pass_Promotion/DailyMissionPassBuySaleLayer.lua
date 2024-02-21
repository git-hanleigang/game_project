--[[
    --新版每日任务pass主界面 购买 促销界面
    csc 2021-06-28
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionPassBuySaleLayer = class("DailyMissionPassBuySaleLayer", BaseLayer)

function DailyMissionPassBuySaleLayer:initCsbNodes()
    self.m_labGemsNum = self:findChild("label_1")
    self.m_labBuffDur = self:findChild("lb_bufftime")
end

function DailyMissionPassBuySaleLayer:ctor()
    DailyMissionPassBuySaleLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Promotion/Pass_PromotionSale.csb")
    self:setPortraitCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Promotion/Pass_PromotionSale_Vertical.csb")
end

-- 重写父类方法
function DailyMissionPassBuySaleLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function DailyMissionPassBuySaleLayer:initView()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        self.m_goodInfo = actData:getPayGemsSaleInfo()
        self.m_labGemsNum:setString(self.m_goodInfo:getNeedsGems())
        local buffInfo = self.m_goodInfo:getRewards()[1].p_buffInfo
        if buffInfo then
            self.m_labBuffDur:setString(math.ceil(buffInfo.buffExpire / 60))
        end
    end
end

function DailyMissionPassBuySaleLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_buy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods()
    end
end

-- 购买等级
function DailyMissionPassBuySaleLayer:buyGoods()
    self:sendIapLog()

    -- 直接购买
    if globalData.userRunData.gemNum < self.m_goodInfo:getNeedsGems() then
        local params = {shopPageIndex = 2 , dotKeyType = "btn_buy", dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
        G_GetMgr(G_REF.Shop):showMainLayer(params)
    else
        gLobalDailyTaskManager:sendActionDailyTaskSkipTask(gLobalDailyTaskManager.MISSION_TYPE.PROMOTION_SALE)
    end
end

-- 客户端打点
function DailyMissionPassBuySaleLayer:sendIapLog()
end

function DailyMissionPassBuySaleLayer:onEnter()
    DailyMissionPassBuySaleLayer.super.onEnter(self)

    -- 促销到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.missionType == gLobalDailyTaskManager.MISSION_TYPE.PROMOTION_SALE then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_DAILYPASS_GEMCONSUME_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_DAILY_TASK_UI_CLOSE
    )
end

function DailyMissionPassBuySaleLayer:closeUI(...)
    if self:isShowing() or self:isHiding() then
        return
    end

    DailyMissionPassBuySaleLayer.super.closeUI(self, ...)
end

return DailyMissionPassBuySaleLayer
