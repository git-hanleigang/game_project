--[[
    --新版每日任务pass主界面 花费钻石刷新任务界面
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionReFreshLayer = class("DailyMissionReFreshLayer", BaseLayer)

function DailyMissionReFreshLayer:initDatas(_popType, _costGemNum)
    DailyMissionReFreshLayer.super.initDatas(self)

    self.m_popType = _popType
    self.m_costGemNum = _costGemNum
    -- 设置横屏csb
    self:setLandscapeCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_RefreshConfirm.csb")
    self:setPortraitCsbName(DAILYMISSION_RES_PATH .."csd/Mission_Main/Mission_RefreshConfirm_Vertical.csb")
end

function DailyMissionReFreshLayer:initCsbNodes()
    self.m_labSpendGems = self:findChild("label_1")
    self.m_labTotalGems = self:findChild("lb_totleGems")
end

function DailyMissionReFreshLayer:initView()
    self:startButtonAnimation("btn_start", "sweep")
    self:initGem()
end

function DailyMissionReFreshLayer:initGem()
    self.m_labSpendGems:setString(self.m_costGemNum)

    self.m_labTotalGems:setString("YOUR GEMS:" .. util_formatCoins(tonumber(globalData.userRunData.gemNum), 6))
    if globalData.userRunData.gemNum < self.m_costGemNum then
        --self.m_labTotalGems:setColor(cc.c3b(255, 0, 0))
        self:runCsbAction("idle2", true, nil, 60)
    else
        --self.m_labTotalGems:setColor(cc.c3b(255, 255, 255))
        self:runCsbAction("idle", true, nil, 60)
    end
end

function DailyMissionReFreshLayer:clickFunc(_sender)
    local name = _sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_start" then
        if globalData.userRunData.gemNum < self.m_costGemNum then
            local params = {shopPageIndex = 2 , dotKeyType = name, dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
            G_GetMgr(G_REF.Shop):showMainLayer(params)
        else
            local isNewUserPass = gLobalDailyTaskManager:isWillUseNovicePass()
            gLobalDailyTaskManager:sendActionDailyTaskRefreshTask(self.m_popType, isNewUserPass)
        end
        self:closeUI()
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function DailyMissionReFreshLayer:onEnter()
    DailyMissionReFreshLayer.super.onEnter(self)
    -- 零点时，关闭此弹板
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_ZERO_CLOSE_GEM_POP_UI
    )
end

-- -- 重写父类方法
-- function DailyMissionReFreshLayer:onShowedCallFunc()
--     -- 展开动画
--     self:runCsbAction("idle", true, nil, 60)
-- end

return DailyMissionReFreshLayer
