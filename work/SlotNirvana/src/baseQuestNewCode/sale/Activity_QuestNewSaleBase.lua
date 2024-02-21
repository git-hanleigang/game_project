-- Created by jfwang on 2019-05-05.
-- quest 活动促销
--
local Activity_QuestNewSaleBase = class("Activity_QuestNewSaleBase", BaseLayer)

function Activity_QuestNewSaleBase:ctor()
    Activity_QuestNewSaleBase.super.ctor(self)
    self:setLandscapeCsbName(self:getSaleCsbName())
    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)
    self:setExtendData("Promotion_QuestNew")
end

-- 子类重写 
function Activity_QuestNewSaleBase:getSaleCsbName()
    -- body
end

function Activity_QuestNewSaleBase:initUI(data)
    if data and data.activityId then
        self.m_activityId = data.activityId
    end
    Activity_QuestNewSaleBase.super.initUI(self)
end

function Activity_QuestNewSaleBase:initCsbNodes()

    
    self.m_lb_spins1 = self:findChild("lb_spins1")
    self.m_lb_spins2 = self:findChild("lb_spins2")
    self.m_lb_spins3 = self:findChild("lb_spins3")


    self.m_btnClose = self:findChild("btn_close")
end

function Activity_QuestNewSaleBase:initView()
    local activityData = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if activityData == nil then
        self:closeUI(false)
        return
    end
    self.m_saleData = activityData:getSaleData()
    if self.m_saleData == nil then
        self:closeUI(false)
        return
    end

    self.m_lb_spins1:setString("" .. self.m_saleData.p_spinTimes[1].." SPINS")
    self.m_lb_spins2:setString("" .. self.m_saleData.p_spinTimes[2].." SPINS")
    self.m_lb_spins3:setString("" .. self.m_saleData.p_spinTimes[3].." SPINS")

    self:setButtonLabelContent("btn_buy1", self.m_saleData.p_gems[1])
    self:setButtonLabelContent("btn_buy2", self.m_saleData.p_gems[2])
    self:setButtonLabelContent("btn_buy3", self.m_saleData.p_gems[3])
    
end

function Activity_QuestNewSaleBase:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

--如果在关卡内打开，会用到暂停spin
function Activity_QuestNewSaleBase:onEnter()
    Activity_QuestNewSaleBase.super.onEnter(self)

    self:runCsbAction("idle", true, nil, 60)
    
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.QuestNew then
                target:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.type == "success" then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
                self:closeUI()
            else
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_REQUEST_AFTER_BUYSALE
    )

end

function Activity_QuestNewSaleBase:buySale(gemIndex)
    local userGemsNum = globalData.userRunData.gemNum or 0 -- 当前玩家的宝石数
    if userGemsNum < self.m_saleData.p_gems[gemIndex] then
        -- 去商城
        local params = {shopPageIndex = 2, dotKeyType = "btn_buy", dotUrlType = DotUrlType.UrlName, dotIsPrep = false}
        local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
        view.buyShop = true
        return
    end
    G_GetMgr(ACTIVITY_REF.QuestNew):doQuestBySaleUseGem(gemIndex)
end


function Activity_QuestNewSaleBase:clickFunc(sender)
    local name = sender:getName()
    if name ~= "btn_close" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end
    if name == "btn_buy1" then
        self:buySale(1)
    elseif name == "btn_buy2" then
        self:buySale(2)
    elseif name == "btn_buy3" then
        self:buySale(3)
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function Activity_QuestNewSaleBase:closeUI()
    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end
    Activity_QuestNewSaleBase.super.closeUI(self, callFunc)
end

return Activity_QuestNewSaleBase
