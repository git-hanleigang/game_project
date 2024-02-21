--[[
    --新版每日任务pass主界面 钻石消耗界面
    csc 2021-06-22
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionMainGemsConfirmLayer = class("DailyMissionMainGemsConfirmLayer", BaseLayer)

function DailyMissionMainGemsConfirmLayer:ctor()
    DailyMissionMainGemsConfirmLayer.super.ctor(self)
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_SkipConfirm.csb")
    self:setPortraitCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_SkipConfirm_Vertical.csb")
end

function DailyMissionMainGemsConfirmLayer:initCsbNodes()
    self.m_labSpendGems = self:findChild("label_1")
    self.m_labTotalGems = self:findChild("lb_totleGems")
end

function DailyMissionMainGemsConfirmLayer:initView()
    self:startButtonAnimation("btn_start", "sweep")
end

function DailyMissionMainGemsConfirmLayer:updateView(_popType, _num)
    self.m_popType = _popType
    self.m_num = _num
    self.m_labSpendGems:setString(self.m_num)

    self.m_labTotalGems:setString("YOUR GEMS:" .. util_formatCoins(math.max(0, tonumber(globalData.userRunData.gemNum)), 6))
    if globalData.userRunData.gemNum < self.m_num then
        --self.m_labTotalGems:setColor(cc.c3b(255, 0, 0))
        self:runCsbAction("idle2", true, nil, 60)
    else
        --self.m_labTotalGems:setColor(cc.c3b(255, 255, 255))
        self:runCsbAction("idle", true, nil, 60)
    end
end

function DailyMissionMainGemsConfirmLayer:clickFunc(_sender)
    local name = _sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_start" then
        if globalData.userRunData.gemNum < self.m_num then
            local params = {shopPageIndex = 2 , dotKeyType = name, dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
            G_GetMgr(G_REF.Shop):showMainLayer(params)
        else
            gLobalDailyTaskManager:sendActionDailyTaskSkipTask(self.m_popType)
        end
        self:closeUI()
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function DailyMissionMainGemsConfirmLayer:onEnter()
    DailyMissionMainGemsConfirmLayer.super.onEnter(self)
    -- 零点时，关闭此弹板
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_ZERO_CLOSE_GEM_POP_UI
    )
end

-- 重写父类方法
-- function DailyMissionMainGemsConfirmLayer:onShowedCallFunc()
--     -- 展开动画
--     self:runCsbAction("idle", true, nil, 60)
-- end

return DailyMissionMainGemsConfirmLayer
