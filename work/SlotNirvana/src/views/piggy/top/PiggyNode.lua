local UI_STATUS = {
    LOCK = 1,
    IDLE = 2,
    MAX = 3
}
local PiggyNode = class("PiggyNode", BaseView)

function PiggyNode:initDatas()
    self.m_isTipShowing = false
end

function PiggyNode:getUIStatus()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if not data then
        return UI_STATUS.LOCK
    else
        if not data:isUnlock() then
            return UI_STATUS.LOCK
        elseif data:isMax() then
            return UI_STATUS.MAX
        else
            return UI_STATUS.IDLE
        end
    end
end

function PiggyNode:getCsbName()
    return "GameNode/Piggy.csb"
end

function PiggyNode:initCsbNodes()
    self.m_spLock = self:findChild("sp_lock")

    self.Particle_1 = self:findChild("Particle_1")
    self.Particle_2 = self:findChild("Particle_2")
    self.Particle_1:stopSystem()
    self.Particle_2:stopSystem()
    self.m_panelTouch = self:findChild("touch_layer")
    self:addClick(self.m_panelTouch)
    self.m_panelTouch1 = self:findChild("touch_layer1")

    self.m_nodeNoviceTip = self:findChild("node_noviceTip")
    self.m_nodeTip = self:findChild("node_tip")

    self.m_nodeMax = self:findChild("node_max")
    self.m_nodeFree = self:findChild("node_free")
end

function PiggyNode:getTipWorldPos()
    local worldPos = self.m_nodeTip:getParent():convertToWorldSpace(cc.p(self.m_nodeTip:getPosition()))
    local localPos = gLobalViewManager:getViewLayer():convertToNodeSpace(worldPos)
    return localPos
end

function PiggyNode:initUI()
    PiggyNode.super.initUI(self)
    self:updateUnlock()
    -- 新手首购折扣 等级提升 会与活动 折扣叠加 隐藏折扣标签
    -- self:initPiggyNoviceDiscount()
    self:updateMax()
    self:updateFree()
    self:updateUIStatus()
end

function PiggyNode:updateUI()
    self:updateUnlock()
    -- 新手首购折扣 等级提升 会与活动 折扣叠加 隐藏折扣标签
    -- self:updatePigNoviceDiscount()
    self:updateMax()
    self:updateFree()
    self:updateUIStatus()
end

function PiggyNode:updateUIStatus()
    local UIStatus = self:getUIStatus()
    if UIStatus == self.m_UIStatus then
        return
    end
    self.m_UIStatus = UIStatus
    if self.m_UIStatus == UI_STATUS.IDLE then
        self:playIdle()
    elseif self.m_UIStatus == UI_STATUS.LOCK then
        self:playLock()
    elseif self.m_UIStatus == UI_STATUS.MAX then
        self:playMax()
    end
end

function PiggyNode:updateMax()
    local isShow = false
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if data and data:isUnlock() and data:isMax() then
        isShow = true
    end
    self.m_nodeMax:setVisible(isShow)
end

function PiggyNode:updateFree()
    local isShow = false
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if data and data:isUnlock() and data:isFree() then
        isShow = true
    end
    self.m_nodeFree:setVisible(isShow)
end

function PiggyNode:updateUnlock()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if data and data:isUnlock() then
        self.m_panelTouch1:setColor(cc.c3b(255, 255, 255))
        self.m_spLock:setVisible(false)
    else
        self.m_panelTouch1:setColor(cc.c3b(127, 115, 150))
        self.m_spLock:setVisible(true)
    end
end

function PiggyNode:initPiggyNoviceDiscount()
    self.m_pigNovice = util_createView("views.piggy.top.PiggyNoviceDiscountNode")
    self.m_nodeNoviceTip:addChild(self.m_pigNovice)
    self:updatePigNoviceDiscount()
end

function PiggyNode:updatePigNoviceDiscount()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    local isIn = false
    if data and data:isUnlock() and not data:isFree() and data:checkInNoviceDiscount() then
        isIn = true
    end
    self.m_pigNovice:setVisible(isIn == true)
end

function PiggyNode:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function PiggyNode:playAddCoins(_over)
    self:runCsbAction("addCoins", false, _over, 60)
end

function PiggyNode:playBetUp(_over)
    self:runCsbAction("Bet_Up", false, _over, 60)
end

function PiggyNode:playBetDown(_over)
    self:runCsbAction("Bet_Down", false, _over, 60)
end

function PiggyNode:playMax(_over)
    self:runCsbAction("max", false, _over, 60)
end

function PiggyNode:playLock()
    self:runCsbAction("lock", true, nil, 60)
end

function PiggyNode:playShow(_over)
    self:runCsbAction("start", false, function()
        self:updateUIStatus()
        if _over then
            _over()
        end
    end, 60)
end

function PiggyNode:playHide(_over)
    self:runCsbAction("over", false, function()
        if _over then
            _over()
        end
    end, 60)
end

-- 关卡内bet变化的时候 播放动画
function PiggyNode:changeBetValue(type)
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if not data then
        return
    end
    if not data:isUnlock() then
        return
    end
    if type == "add" then
        self:playBetUp()
        self:playAddBetParticle()
    elseif type == "sub" then
        self:playBetDown()
    elseif type == "max" then
        self:playBetUp()
        self:playMaxBetParticle()
    end
end

-- 播放bet增加时的粒子效果
function PiggyNode:playAddBetParticle()
    self.Particle_1:stopSystem()
    self.Particle_1:resetSystem()
end

function PiggyNode:playMaxBetParticle()
    self.Particle_2:stopSystem()
    self.Particle_2:resetSystem()
end

function PiggyNode:addCollectCoin(betCoin)
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if not data then
        return
    end
    if not data:isUnlock() then
        return
    end

    local UIStatus = self:getUIStatus()
    if UIStatus == UI_STATUS.IDLE then
        self.m_UIStatus = UIStatus
        self:playAddCoins(
            function()
                self:playIdle()
            end
        )
    elseif UIStatus == UI_STATUS.MAX then
        if UIStatus == self.m_UIStatus then
            return
        end
        self.m_UIStatus = UIStatus
        self:playMax()
    end
end

function PiggyNode:showPigBankLayer()
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "upPigBankIcon")
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_pig)
    end
    G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
        local dotEntryNode = gLobalViewManager:isLobbyView() and DotEntryType.Lobby or DotEntryType.Game
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, "touch_layer", DotUrlType.UrlName, true, DotEntrySite.UpView, dotEntryNode)
        end
    end)
end

function PiggyNode:clickTouchLayer()
    local data = G_GetMgr(G_REF.PiggyBank):getData()
    if data and data:isUnlock() then
        self:showPigBankLayer()
    else
        G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("Unlock")
    end
end

function PiggyNode:clickFunc(sender)
    local name = sender:getName()
    if name == "touch_layer" then
        self:clickTouchLayer()
    end
end

function PiggyNode:onEnter()
    PiggyNode.super.onEnter(self)

    -- local listener = cc.EventListenerKeyboard:create()
    -- listener:registerScriptHandler(
    --     function(code, event)
    --         if code == cc.KeyCode.KEY_F1 then
    --             G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("Max")
    --         elseif code == cc.KeyCode.KEY_F2 then
    --             G_GetMgr(G_REF.PiggyBank):getBubbleCtr():showTip("LevelUp")
    --         elseif code == cc.KeyCode.KEY_F3 then
    --             G_GetMgr(G_REF.PiggyBank):showFreeLayer(
    --                 function()
    --                     print("--- test pig free call back ---")
    --                 end
    --             )
    --         end
    --     end,
    --     cc.Handler.EVENT_KEYBOARD_RELEASED
    -- )
    -- cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, -1)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateUI()
        end,
        ViewEventType.PIGGY_DATA_UPDATE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateUI()
        end,
        ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:changeBetValue(params.type)
        end,
        ViewEventType.NOTIFY_LEVEL_CLICK_BET_CHANGE
    )

    -- 自动弹出tip 小猪满金币
    -- 自动弹出tip 小猪档位上升
end

function PiggyNode:onEnterFinish()
    PiggyNode.super.onEnterFinish(self)
    -- 创建成功后，要初始化气泡的位置
    G_GetMgr(G_REF.PiggyBank):getBubbleCtr():setBubblePosition(self:getTipWorldPos())
end

return PiggyNode
