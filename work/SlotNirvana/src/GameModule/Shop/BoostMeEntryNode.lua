-- Created by jfwang on 2019-05-21.
-- BoostMe活动展示node，位置关卡内右下角
--
local BoostMeEntryNode = class("BoostMeEntryNode", util_require("GameModule.Shop.EntryNode"))

function BoostMeEntryNode:onEnter()
    self:registerListener()
end
function BoostMeEntryNode:initDatas(data)
    BoostMeEntryNode.super.initDatas(self)
    self.doShowAction = data.doShowAction
end

function BoostMeEntryNode:initView( )
    self.m_config = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    self.m_closeTimeCount = 5
    --等级尾数4，默认弹出
    self.m_boostMeTipsView = false
    -- if self:IsShowEntryNode() then
    --     self:showBoostMeTips()
    -- end

    self:updateTime()
    schedule(self,function()
        if self.isClose then
            return
        end
        if self and self.updateTime then
            self:updateTime()
        end
    end,1)
    if self:IsHaveBuff() and self:IsActivityOpen() and self.doShowAction then
        self:showEntryInfoView()
    end
end
--显示boostMetishi
function BoostMeEntryNode:showBoostMeTips()
    self.m_boostMeTipsView = true
    local curLevel = globalData.userRunData.levelNum
    local BoostMeTip = util_createView("GameModule.Shop.BoostMeTip",2,{curLevel})
    if BoostMeTip then
        self:addChild(BoostMeTip)
        BoostMeTip:setPosition(-40,0)
        BoostMeTip:setOverFunc(function(  )
            self.m_boostMeTipsView = false
        end)
    end
end

--刷新界面
function BoostMeEntryNode:updateView()
    self.m_config = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    if not self.m_config then
        return
    end

    --更新buff倒计时
    local buffExpireTime = self.m_config.p_buffExpire or 0
    if buffExpireTime < 0 or not self.m_config.p_active then
        buffExpireTime = 0
    end

    if self.m_config.p_buffs and #self.m_config.p_buffs > 0 and buffExpireTime > 0 then
        if self.m_buffNode then
            self.m_buffNode:setVisible(true)
            self.m_leftBuffCount = self:findChild("IB_shuzi")
            self.m_leftBuffCount:setString(#self.m_config.p_buffs)
        end
    else
        if self.m_buffNode then
            self.m_buffNode:setVisible(false)
        end
    end
    if buffExpireTime <= 0 and self.m_config.p_buffs and #self.m_config.p_buffs > 1 then
        if not self.m_sendData then
            self.m_sendData = true
            gLobalActivityManager:refreshCashBackBuff()
        end
    end

    --设置倒计时状态
    self:setTimerValue(util_count_down_str(buffExpireTime),buffExpireTime==0)

    local coinsValue = self.m_config.p_coins
    local rateValue = self.m_config.p_currentRate
    self:setEntryInfoView(util_getFromatMoneyStr(coinsValue),rateValue.."%")
end

function BoostMeEntryNode:registerListener()
    gLobalNoticManager:addObserver(self,function(target, params)
        if not tolua.isnull(self) then 
            self.m_sendData = false
            if params then 
                if self:IsHaveBuff()  then
                    self:updateView()
                    self:showEntryInfoView()
                end
            else
                self:closeUI()
            end
        end
    end,ViewEventType.NOTIFY_ACTIVITY_CASHBACK_REFRESH)
end

--打开cash活动界面
function BoostMeEntryNode:showActivityView(  )
    self.m_config = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    if not self.m_config then
        return
    end

    -- 判断活动配置中有没有Cashback活动
    local refName = self.m_config:getRefName()
    local _cfg
    if self.m_config:isNovice() then
        _cfg = G_GetMgr(G_REF.UserNovice):getActivityConfigByRef(refName)
    else
        _cfg = globalData.GameConfig:getActivityConfigByRef(refName)
    end
    if not _cfg then
        return
    end
    
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen","cashbackIcon")
    local curActivityId = self.m_config.p_activityId
    -- local data = globalData.commonActivityData:getActivityData(curActivityId)
    local data = self.m_config
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():setClickUrl(DotEntrySite.LeftView,DotEntryType.Game,"lockClick")
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BROADCAST_HALL,{id=curActivityId,d=data})

end

--锁着时，点击处理
function BoostMeEntryNode:onLockClick(  )
    local isActivityOpen = self:IsActivityOpen()
    if isActivityOpen then
        --打开活动弹版
        self:showActivityView()
    else
        if self.m_boostMeTipsView == false then
            --self:showBoostMeTips()
        end
    end

end

function BoostMeEntryNode:IsShowEntryNode()
    local isBuffOpen = self:IsHaveBuff()
    local curLevel = globalData.userRunData.levelNum or 1
    if not isBuffOpen and curLevel>10 and curLevel%10==4 then
        return true
    end
    return false
end

function BoostMeEntryNode:IsHaveBuff()
    self.m_config = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    if not self.m_config then
        return false
    end

    local buffExpireTime = self.m_config.p_buffExpire or 0
    if buffExpireTime <= 0 or not self.m_config.p_active then
        return false
    end

    return true
end

function BoostMeEntryNode:IsActivityOpen( )
    self.m_config = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
    if not self.m_config then
        return false
    end
    
    local expireTime = self.m_config:getLeftTime() or 0
    if self.m_config.p_activityId == "" or expireTime <= 0 or not self.m_config:getOpenFlag() then
        return false
    end

    return globalData.commonActivityData:IsOpenActivity(self.m_config:getRefName())
end

function BoostMeEntryNode:updateTime()
    if not self.m_config then
        self:closeUI()
        return
    end

    --活动结束时间
    local isBuffOpen = self:IsHaveBuff()
    local isActivityOpen = self:IsActivityOpen()
    local isLevelOpen = self:IsShowEntryNode()
    if isBuffOpen or isActivityOpen or isLevelOpen then
        self:updateView()
    else
        if self.m_config and self.m_config.p_buffs and #self.m_config.p_buffs > 1 then
            if not self.m_sendData then
                self.m_sendData = true
                gLobalActivityManager:refreshCashBackBuff()
            end  
        else
            self:closeUI()
        end
    end

end

function BoostMeEntryNode:getIsCanShow( )
    local isBuffOpen = self:IsHaveBuff()
    local isActivityOpen = self:IsActivityOpen()
    local isLevelOpen = self:IsShowEntryNode()
    if isBuffOpen or isActivityOpen or isLevelOpen then
        return true
    else
        return false
    end
end

return BoostMeEntryNode