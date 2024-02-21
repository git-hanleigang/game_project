-- 按钮的状态
local SPIN_BTN_STATE = {
    SPIN_NORMAL = 1,
    SPIN_ANXIA = 2,
    SPIN_JINYONG = 3,
    STOP_NORMAL = 4,
    STOP_ANXIA = 5
}
-- local BaseView = util_require("base.BaseView")
local CardNadoWheelMainUI = class("CardNadoWheelMainUI", BaseLayer)

function CardNadoWheelMainUI:ctor()
    CardNadoWheelMainUI.super.ctor(self)
    self.ActionType = "Common"
    self:setPauseSlotsEnabled(true)
end

function CardNadoWheelMainUI:initDatas()
    self.m_playShowAction = true
    self.m_oneOffSpin = false
    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.CardNadoWheelLayerRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self:setPortraitCsbName(string.format(CardResConfig.commonRes.CardNadoWheelLayerPortraitRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
end

function CardNadoWheelMainUI:initUI()
    CardNadoWheelMainUI.super.initUI(self)
    self:setExtendData("CardNadoWheelMainUI")
    self:runCsbAction("idle")
end

function CardNadoWheelMainUI:initCsbNodes()
    self.m_topCoinLb = self:findChild("lb_left_count")
    self.m_topCoinTxt = self:findChild("txt_spin_left")
    self.m_btnPrize = self:findChild("Button_prize")
    self.m_btnOneSpin = self:findChild("Button_onespin")
    self.m_wheelNode = self:findChild("Node_wheel")
    self.m_spinNode = self:findChild("Node_spin")
    self.m_spinHandleNode = self:findChild("node_bashou")
end

function CardNadoWheelMainUI:initView()
    self:initWheel()
    self:initLeftCount()
    self:initCheckPrize(true)
    self:initOneSpin()
end

function CardNadoWheelMainUI:onShowedCallFunc()
    self.m_playShowAction = false
    self:showIdle()
end

function CardNadoWheelMainUI:showIdle()
    self:runCsbAction("idle", true)
end

function CardNadoWheelMainUI:getOnOffSpin()
    return self.m_oneOffSpin
end

function CardNadoWheelMainUI:getLeftCount()
    -- local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    -- return linkGameData and linkGameData.nadoGames or 0
    return CardSysRuntimeMgr:getNadoGameLeftCount() or 0
end

function CardNadoWheelMainUI:getReward()
    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    if linkGameData.reward then
        local reward = CardSysRuntimeMgr:getNadoGameReward(linkGameData.reward)
        local index = 0
        for k, v in pairs(reward) do
            index = index + 1
        end
        if index > 0 then
            return reward
        end
    end
    return
end

function CardNadoWheelMainUI:initLeftCount()
    -- self.m_topCoinLb:setString(self:getLeftCount().." SPINS LEFT")
    local count = self:getLeftCount()
    self.m_topCoinLb:setString(count)
    if count > 1 then
        self.m_topCoinTxt:setString("SPINS LEFT")
    else
        self.m_topCoinTxt:setString("SPIN LEFT")
    end
end

function CardNadoWheelMainUI:initWheel()
    self.m_wheelBody = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelBody", self)
    self.m_wheelNode:addChild(self.m_wheelBody)
end

function CardNadoWheelMainUI:initOneSpin()
    if self.m_wheelBody and self.m_wheelBody.getSpinUI and self.m_btnOneSpin ~= nil then
        local state = self.m_wheelBody:getSpinUI():getState()
        if state == SPIN_BTN_STATE.SPIN_NORMAL then
            local count = self:getLeftCount()
            if count > 0 then
                self.m_btnOneSpin:setTouchEnabled(true)
                self.m_btnOneSpin:setBright(true)
            else
                self.m_btnOneSpin:setTouchEnabled(false)
                self.m_btnOneSpin:setBright(false)
            end
        else
            self.m_btnOneSpin:setTouchEnabled(false)
            self.m_btnOneSpin:setBright(false)
        end
    end
end

function CardNadoWheelMainUI:initCheckPrize(enabled)
    if enabled == true then
        if self:getReward() ~= nil then
            self.m_btnPrize:setTouchEnabled(true)
            self.m_btnPrize:setBright(true)
        else
            self.m_btnPrize:setTouchEnabled(false)
            self.m_btnPrize:setBright(false)
        end
    else
        self.m_btnPrize:setTouchEnabled(false)
        self.m_btnPrize:setBright(false)
    end
end

function CardNadoWheelMainUI:showRule()
    local view = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelRule")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardNadoWheelMainUI:showPrize(hideLater, closeMainUI)
    if self.m_isShowPrize then
        return
    end
    self.m_isShowPrize = true
    local view = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelOver", self, hideLater, closeMainUI)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function CardNadoWheelMainUI:onEnter()
    CardNadoWheelMainUI.super.onEnter(self)
    -- 如果没有次数了，但是还没有收集奖励
    -- 主动弹出结算界面
    if self:getLeftCount() == 0 and self:getReward() ~= nil then
        self:showPrize(true)
    end

    -- 关闭后要刷新数据可以点击进入结算界面
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self.m_isShowPrize = false
            self:initCheckPrize(true)
        end,
        CardSysConfigs.ViewEventType.CARD_NADO_WHEEL_REWARD_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            -- 新赛季开启的时候退出集卡所有界面
            CardSysManager:closeNadoMachine()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

function CardNadoWheelMainUI:closeUI(overFunc)
    if self.m_closed then
        return
    end
    self.m_closed = true

    if self.m_wheelBody and self.m_wheelBody.hideItemsParticle then
        self.m_wheelBody:hideItemsParticle()
    end

    local callback = function()
        if overFunc then
            overFunc()
        end
        -- 更新diy任务数据
        self:sendDiyTaskUpdate()
    end
    CardNadoWheelMainUI.super.closeUI(self, callback)
end

function CardNadoWheelMainUI:sendDiyTaskUpdate()
    local mgr = G_GetMgr(ACTIVITY_REF.DIYFeatureMission)
    if nil == mgr then
        return nil
    end
    local actData = mgr:getRunningData()
    if not actData then
        return nil
    end
    --更新数据
    mgr:sendDiyTaskUpdate()
end

function CardNadoWheelMainUI:clickFunc(sender)
    local name = sender:getName()
    if self.m_playShowAction then
        return
    end
    if name == "Button_x" then
        -- 如果是spin，不做任何事情
        -- 如果是autospin，停掉autospin
        -- 其他情况都走正常流程
        if self.m_oneOffSpin == true then
            return
        end
        if self.m_wheelBody and self.m_wheelBody.getSpinUI then
            local state = self.m_wheelBody:getSpinUI():getState()
            if state == SPIN_BTN_STATE.SPIN_ANXIA then
                -- do nothing
            elseif state == SPIN_BTN_STATE.STOP_NORMAL then
                self.m_wheelBody:getSpinUI():overAutoSpin()
            else
                if self:getReward() ~= nil then
                    self:showPrize(true, true)
                else
                    gLobalSoundManager:playSound(SOUND_ENUM.SOUND_HIDE_VIEW)
                    CardSysManager:closeNadoMachine()
                end
            end
        end
    elseif name == "Button_info" then
        self:showRule()
    elseif name == "Button_prize" then
        if self.m_oneOffSpin == true then
            return
        end
        self:showPrize()
    elseif name == "Button_onespin" then
        local popui = util_createView("GameModule.Card.commonViews.CardNadoMachine.CardNadoWheelOneSpinPopUI", handler(self, self.onOneSpin))
        gLobalViewManager:showUI(popui, ViewZorder.ZORDER_UI)
    end
end

function CardNadoWheelMainUI:onOneSpin()
    self.m_oneOffSpin = true

    -- 后端数据更改，更新轮盘数据
    if self.m_wheelBody and self.m_wheelBody.updateWheelInfo then
        self.m_wheelBody:updateWheelInfo()
    end
    local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    local startTotalCellNum = #linkGameData.cells

    -- 成功回调
    local spinSuccess = function(tInfo)
        -- if not tolua.isnull(self) and self.m_wheelBody then
        --     local linkGameData = CardSysRuntimeMgr:getLinkGameData()
        --     local rollIndex = math.min(linkGameData.index + 1, startTotalCellNum)
        --     self.m_wheelBody:recvData(rollIndex)
        -- end
    end
    -- 失败回调
    local spinFaild = function()
        gLobalViewManager:showReConnect()
    end
    local updateMainUI = function()
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_NADO_WHEEL_ROLL_OVER)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO)

        if not tolua.isnull(self) and self.initLeftCount and self.initOneSpin and self.showPrize then
            self.m_oneOffSpin = false
            self:initLeftCount()
            self:initOneSpin()
            self:showPrize(true)
        end
    end
    -- 发送spin消息 --
    local times = CardSysRuntimeMgr:getNadoGameLeftCount() or 0
    CardSysNetWorkMgr:sendCardLinkPlayRequest({status = 3, times = times}, spinSuccess, spinFaild, updateMainUI)
end

return CardNadoWheelMainUI
