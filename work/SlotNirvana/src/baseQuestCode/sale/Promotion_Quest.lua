-- Created by jfwang on 2019-05-05.
-- quest 活动促销
--
local Promotion_Quest = class("Promotion_Quest", BaseLayer)

function Promotion_Quest:ctor()
    Promotion_Quest.super.ctor(self)
    self:setLandscapeCsbName("Activity/Promotion_base/QuestSaleLayer_Base.csb")
    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)
    self:setExtendData("Promotion_Quest")
end

function Promotion_Quest:initUI(data)
    if data and data.activityId then
        self.m_activityId = data.activityId
    end
    Promotion_Quest.super.initUI(self)
end

function Promotion_Quest:initCsbNodes()
    self.m_btnClose = self:findChild("btn_close")
    assert(self.m_btnClose, "Promotion_Quest 缺少必要的资源节点1")
    -- buff 时间
    self.lb_time = self:findChild("lb_time")
    assert(self.lb_time, "Promotion_Quest 缺少必要的节点2")

    self.node_Logo = self:findChild("node_Logo")
    assert(self.node_Logo, "Promotion_Quest 缺少必要的节点3")
end

function Promotion_Quest:initView()
    self.m_saleData = G_GetMgr(ACTIVITY_REF.QuestSale):getRunningData()
    if self.m_saleData == nil then
        self:closeUI(false)
        return
    end

    -- buff 时间
    if self.m_saleData.p_items and #self.m_saleData.p_items > 0 then
        local buffData = self.m_saleData.p_items[1]
        if buffData and buffData.p_buffInfo then
            local buffInfo = buffData.p_buffInfo
            if buffInfo and buffInfo.buffDuration then
                self.lb_time:setString(buffInfo.buffDuration)
            end
        end
    end

    --价格
    if self.m_saleData.p_gemPrice then
        self:setButtonLabelContent("btn_buy", self.m_saleData.p_gemPrice)
    end

    self:initLogo()
end

-- 子类重写 创建logo
function Promotion_Quest:initLogo()
end

function Promotion_Quest:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
    self:playLogoAnim()
end

-- 子类重写 播放logo动画
function Promotion_Quest:playLogoAnim()
end

--如果在关卡内打开，会用到暂停spin
function Promotion_Quest:onEnter()
    Promotion_Quest.super.onEnter(self)

    self:runCsbAction("idle", true, nil, 60)
    self:playLogoAnim()

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                target:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function Promotion_Quest:buySale()
    local userGemsNum = globalData.userRunData.gemNum or 0 -- 当前玩家的宝石数
    if userGemsNum < self.m_saleData.p_gemPrice then
        -- 去商城
        local params = {shopPageIndex = 2, dotKeyType = "btn_buy", dotUrlType = DotUrlType.UrlName, dotIsPrep = false}
        local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
        view.buyShop = true
        return
    end

    gLobalSendDataManager:getNetWorkFeature():sendQuestGemsBuy(
        function()
            if not tolua.isnull(self) then
                self:buySuccess()
            end
        end,
        function()
            if not tolua.isnull(self) then
                self:buyFailed()
            end
        end
    )
end

function Promotion_Quest:buySuccess()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_BUY_FINISH)
    self:closeUI()
end

function Promotion_Quest:buyFailed()
    self:closeUI()
end

function Promotion_Quest:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buySale()
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function Promotion_Quest:closeUI()
    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end
    Promotion_Quest.super.closeUI(self, callFunc)
end

return Promotion_Quest
