--[[
    --新版每日任务pass主界面 标题
    csc 2021-06-21
]]
local DailyMissionThreeLinePassRewardTopUi = class("DailyMissionThreeLinePassRewardTopUi", util_require("base.BaseView"))

function DailyMissionThreeLinePassRewardTopUi:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionThreeLinePassRewardTopUi:initUI()
    self:createCsbNode(self:getCsbName())

    -- 读取csb 节点
    self.m_nodeBuyTicket = self:findChild("node_ticket")
    self.m_nodeLevelStore = self:findChild("node_levelstore")
    self.m_nodeClaimAll = self:findChild("node_claimall")

    --
    self.m_btnMapPos = {
        ["level"] = cc.p(self.m_nodeLevelStore:getPosition()),
        ["ticket"] = cc.p(self.m_nodeBuyTicket:getPosition()),
        ["all"] = cc.p(self.m_nodeClaimAll:getPosition())
    }

    self:updateView()
    self:startButtonAnimation("btn_claimAll", "sweep")
    self:startButtonAnimation("btn_levelStore", "sweep")
end

function DailyMissionThreeLinePassRewardTopUi:getCsbName()
    if self.m_isPortrait then
        return DAILYPASS_RES_PATH.DailyMissionPass_RewardTopUi_Vertical_ThreeLine 
    else
        return DAILYPASS_RES_PATH.DailyMissionPass_RewardTopUi_ThreeLine 
    end
end

function DailyMissionThreeLinePassRewardTopUi:updateView()
    -- 默认全部按钮都隐藏
    self.m_nodeBuyTicket:setVisible(false)
    self.m_nodeLevelStore:setVisible(false)
    self.m_nodeClaimAll:setVisible(false)

    -- 更新按钮状态
    self:updateBtnVisible()

    -- 更新按钮位置
    --self:updateBtnPos()
end

function DailyMissionThreeLinePassRewardTopUi:updateBtnVisible()
    -- 计算当前按钮展示状态
    -- 先判断是否解锁
    if not self:isBuyALl() then
        self.m_nodeBuyTicket:setVisible(true)
    end

    -- 判断一键领取按钮是否展示
    if G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum() > 0 then
        self.m_nodeClaimAll:setVisible(true)
    end

    -- 判断当前能否展示等级商店
    if not G_GetMgr(ACTIVITY_REF.NewPass):getIsMaxPoints() and self:isBuyAtLeastOne() then
        self.m_nodeLevelStore:setVisible(true)
    end
end

function DailyMissionThreeLinePassRewardTopUi:updateBtnPos()
    -- 位置重置
    self.m_nodeBuyTicket:setPosition(self.m_btnMapPos["ticket"])
    self.m_nodeClaimAll:setPosition(self.m_btnMapPos["all"])
    self.m_nodeLevelStore:setPosition(self.m_btnMapPos["level"])
    -- 有五种排序情况
    -- 1.门票 + all
    if self:isBuyALl() then
        if G_GetMgr(ACTIVITY_REF.NewPass):getIsMaxPoints() then
            if G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum() > 0 then
                self.m_nodeClaimAll:setPosition(cc.p(0, self.m_btnMapPos["all"].y))
            end
        else
            if G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum() > 0 then
                self.m_nodeLevelStore:setPosition(self.m_btnMapPos["level"])
                self.m_nodeClaimAll:setPosition(self.m_btnMapPos["all"])
            else
                self.m_nodeLevelStore:setPosition(cc.p(0, self.m_btnMapPos["level"].y))
            end
        end
    elseif self:isBuyAtLeastOne() then
        if G_GetMgr(ACTIVITY_REF.NewPass):getIsMaxPoints() then
            if G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum() > 0 then
                self.m_nodeBuyTicket:setPosition(cc.p(self.m_btnMapPos["level"].x, self.m_btnMapPos["ticket"].y))
                self.m_nodeClaimAll:setPosition(self.m_btnMapPos["all"])
            else
                self.m_nodeBuyTicket:setPosition(self.m_btnMapPos["ticket"])
            end
        else
            if G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum() > 0 then
                self.m_nodeBuyTicket:setPosition(self.m_btnMapPos["ticket"])
                self.m_nodeLevelStore:setPosition(self.m_btnMapPos["level"])
                self.m_nodeClaimAll:setPosition(self.m_btnMapPos["all"])
            else
                self.m_nodeLevelStore:setPosition(self.m_btnMapPos["level"])
                self.m_nodeBuyTicket:setPosition(cc.p(self.m_btnMapPos["all"].x, self.m_btnMapPos["ticket"].y))
            end
        end
    else
        if G_GetMgr(ACTIVITY_REF.NewPass):getCanClaimNum() > 0 then
            self.m_nodeBuyTicket:setPosition(cc.p(self.m_btnMapPos["level"].x, self.m_btnMapPos["ticket"].y))
            self.m_nodeClaimAll:setPosition(self.m_btnMapPos["all"])
        else
            self.m_nodeBuyTicket:setPosition(self.m_btnMapPos["ticket"])
        end
    end
end

function DailyMissionThreeLinePassRewardTopUi:isBuyALl()
    return G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():isUnlocked() and G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getCurrIsPayHigh()
end

function DailyMissionThreeLinePassRewardTopUi:isBuyAtLeastOne()
    return G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():isUnlocked() or G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getCurrIsPayHigh()
end

function DailyMissionThreeLinePassRewardTopUi:getTicketNodePos()
    local pos = self.m_nodeBuyTicket:getParent():convertToWorldSpace(cc.p(self.m_nodeBuyTicket:getPosition()))
    return pos
end

function DailyMissionThreeLinePassRewardTopUi:clickFunc(_sender)
    local name = _sender:getName()
    if self.m_bClick then
        return
    end
    self.m_bClick = true
    if name == "btn_levelStore" then
        local buyLayer = util_createView(DAILYPASS_CODE_PATH.DailyMissionPass_BuyLevelStoreLayer)
        gLobalViewManager:showUI(buyLayer, ViewZorder.ZORDER_UI)
    elseif name == "btn_claimAll" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local isNewUser = gLobalDailyTaskManager:isWillUseNovicePass()
        gLobalDailyTaskManager:sendActionPassRewardCollect(nil, 2, true, isNewUser,true,true)
    elseif name == "btn_buy" then
        G_GetMgr(ACTIVITY_REF.NewPass):showBuyTicketLayer(false,true)
    end
    performWithDelay(
        self,
        function()
            self.m_bClick = false
        end,
        0.1
    )
end

return DailyMissionThreeLinePassRewardTopUi
