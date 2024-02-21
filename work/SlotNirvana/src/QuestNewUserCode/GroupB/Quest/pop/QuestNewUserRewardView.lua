-- Created by jfwang on 2019-05-21.
-- Quest任务完成界面
--
local QuestNewUserRewardView = class("QuestNewUserRewardView", BaseLayer)

function QuestNewUserRewardView:initDatas(state_data)
    self.state_data = state_data

    local res
    if self.state_data and self.state_data:getIsLast() then
        if self.state_data.phase_idx == 3 then
            res = QUEST_RES_PATH.QuestFinalReward
        else
            res = QUEST_RES_PATH.QuestBoxReward
        end
    else
        res = QUEST_RES_PATH.QuestGiftReward
    end

    if res then
        self:setLandscapeCsbName(res)
    end
    self:setExtendData("QuestNewUserRewardView")
    self:initCallFunc()
end

function QuestNewUserRewardView:initCallFunc()
    local dropFunList = {}
    table.insert(dropFunList, handler(self, self.triggerFreePig))
    table.insert(dropFunList, handler(self, self.triggerVipBoost))
    self.m_dropFunList = dropFunList
end

function QuestNewUserRewardView:initCsbNodes()
    self.btn_collect = self:findChild("btn_collect")
    self.m_lb_coins = self:findChild("lb_coins")
    self.m_sp_coins = self:findChild("sp_coins")
end

function QuestNewUserRewardView:initView()
    --金币处理
    if self.state_data and self.state_data.p_coins then
        --quest活动倍数加成
        local totalCoins = tonumber(self.state_data.p_coins)
        self.m_lb_coins:setString(util_formatCoins(totalCoins, 30))

        util_alignCenter(
            {
                {node = self.m_sp_coins, alignX = 0},
                {node = self.m_lb_coins, alignX = 0}
            }
        )
    end
end

function QuestNewUserRewardView:playShowAction()
    gLobalSoundManager:playSound("QuestNewUser/Activity/QuestNewUserSounds/questNewUser_finalReward.mp3")
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "show",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewUserRewardView.super.playShowAction(self, userDefAction)
end

function QuestNewUserRewardView:onShowedCallFunc()
    self:runCsbAction("idleframe", true, nil, 60)
end

function QuestNewUserRewardView:onKeyBack()
    if self:isShowing() or self:isHiding() then
        return
    end
    self:flyCoins()
end

function QuestNewUserRewardView:onClickMask()
    self:onClickCollect()
end

function QuestNewUserRewardView:onClickCollect()
    if not self.btn_collect then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self.btn_collect:setTouchEnabled(false)
    self:flyCoins()
end

function QuestNewUserRewardView:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:onClickCollect(sender)
    end
end

function QuestNewUserRewardView:flyCoins()
    if self.isClick then
        return
    end
    self.isClick = true

    local coins = self.state_data.p_coins

    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local startPos = self.btn_collect:getParent():convertToWorldSpace(cc.p(self.btn_collect:getPosition()))
        local flyList = {}
        if coins and coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = coins, startPos = startPos})
        end

        curMgr:playFlyCurrency(
            flyList,
            function()
                if CardSysManager:needDropCards("Quest Box Award") == true then
                    CardSysManager:doDropCards(
                        "Quest Box Award",
                        function()
                            if not tolua.isnull(self) then
                                self:closeUI()
                            end
                        end
                    )
                else
                    if not tolua.isnull(self) then
                        self:closeUI()
                    end
                end
            end
        )
    else
        self:closeUI()
    end
end

function QuestNewUserRewardView:playHideAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "over",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewUserRewardView.super.playHideAction(self, userDefAction)
end

function QuestNewUserRewardView:closeUI()
    QuestNewUserRewardView.super.closeUI(
        self,
        function()
            if not tolua.isnull(self) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK, {index = self.state_data.m_index}) --执行下一个服务器弹窗
                self:triggerNextFunc()
            end
        end
    )
end

function QuestNewUserRewardView:triggerNextFunc()
    if #self.m_dropFunList == 0 then
        return
    end
    local func = table.remove(self.m_dropFunList, 1)
    if func then
        func()
    end
end

function QuestNewUserRewardView:triggerFreePig()
    local itemDatas = self.state_data.p_items
    if itemDatas and #itemDatas > 0 and G_GetMgr(G_REF.PiggyBank):checkFreePig(itemDatas) then
        G_GetMgr(G_REF.PiggyBank):showFreeLayer(
            function()
                if not tolua.isnull(self) then
                    self:triggerNextFunc()
                end
            end
        )
    else
        self:triggerNextFunc()
    end
end

function QuestNewUserRewardView:triggerVipBoost()
    local vipboostItem = G_GetMgr(ACTIVITY_REF.Quest):getRewardVipBoostItem(self.state_data)
    if vipboostItem then
        local vipLevel = globalData.userRunData.vipLevel
        if vipLevel < VipConfig.MAX_LEVEL then
            G_GetMgr(G_REF.Vip):showBoostLayer(
                vipLevel,
                function()
                    if not tolua.isnull(self) then
                        self:triggerNextFunc()
                    end
                end
            )
        end
    else
        self:triggerNextFunc()
    end
end

return QuestNewUserRewardView
