local LuckyStampTipViewNew = class("LuckyStampTipViewNew", BaseView)

function LuckyStampTipViewNew:initDatas(_callback, _isPermanent, _isLuckySpin)
    self.m_callback = _callback
    self.m_isPermanent = _isPermanent
    self.m_isLuckySpin = _isLuckySpin

    self.m_process = self:getProcess()
end

function LuckyStampTipViewNew:getCsbName()
    return LuckyStampCfg.csbPath .. "tipUI/LuckyStamp_tishi_new.csb"
end

function LuckyStampTipViewNew:initCsbNodes()
    self.m_lb_time = self:findChild("lb_time")
    self.m_lb_coins = self:findChild("lb_prizeCount")

    self.m_qipao1 = self:findChild("qipao1")
    self.m_qipao2 = self:findChild("qipao2")

    local panel2 = self:findChild("Panel_2")
    if panel2 then
        self:addClick(panel2)
    end
    local btn_i = self:findChild("btn_i")
    self:addClick(btn_i)

    self.m_nodeStamps = {}
    for i = 1, 4 do
        local nodeStamp = self:findChild("node_stamp" .. i)
        table.insert(self.m_nodeStamps, nodeStamp)
    end
end

function LuckyStampTipViewNew:initUI()
    LuckyStampTipViewNew.super.initUI(self)
    self:initView()
end

function LuckyStampTipViewNew:initView()
    self:initStamps()
    self:updateView()
    self:playEnterAction()
end

function LuckyStampTipViewNew:updateView()
    self.m_process = self:getProcess()
    self:updateStamps()
    self:updateBubble()
end

function LuckyStampTipViewNew:initStamps()
    self.m_stamps = {}
    for i = 1, #self.m_nodeStamps do
        local nodeStamp = self.m_nodeStamps[i]
        local stamp = util_createView(LuckyStampCfg.luaPath .. "MiniGame.mainUI.LSGameStampSlot", i)
        nodeStamp:addChild(stamp)
        table.insert(self.m_stamps, stamp)
    end
end

function LuckyStampTipViewNew:updateStamps()
    for i = 1, #self.m_stamps do
        self.m_stamps[i]:setVisible(i <= self.m_process)
        if i <= self.m_process then
            self.m_stamps[i]:updateStamp()
        end
    end
end

function LuckyStampTipViewNew:updateBubble()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        return
    end

    if self.m_process == 0 then
        self.m_qipao1:setVisible(true)
        self.m_qipao2:setVisible(false)
    else
        self.m_qipao1:setVisible(false)
        self.m_qipao2:setVisible(true)
        local processIdx = data:getProcessIndex()
        local processData = data:getProcessDataByIndex(processIdx)
        if processData then
            self.m_lb_coins:setString("YOUR LUCKY PRIZE: " .. util_formatCoins(tonumber(processData:getTopCoins() or 0), 11))
        end
        local str = util_daysdemaining(data:getExpireAt() / 1000)
        self.m_lb_time:setString(str)
    end
end

function LuckyStampTipViewNew:playShow(_over)
    self:runCsbAction("show", false, _over, 30)
end

function LuckyStampTipViewNew:playIdle()
    self:runCsbAction("idle1", true, nil, 30)
end

function LuckyStampTipViewNew:playOver(_over)
    self:runCsbAction("over", false, _over, 30)
end

function LuckyStampTipViewNew:playOnlyOne(_over)
    self:runCsbAction("actionframe", false, _over, 30)
end

function LuckyStampTipViewNew:playTipShow(_over)
    self:runCsbAction("show2", false, _over, 30)
end

function LuckyStampTipViewNew:playTipIdle()
    self:runCsbAction("idle2", true, nil, 30)
end

function LuckyStampTipViewNew:playTipOver(_over)
    self:runCsbAction("over2", false, _over, 30)
end

function LuckyStampTipViewNew:playEnterAction()
    -- 展开动画
    self:playShow(
        function()
            if not tolua.isnull(self) then
                if self.m_process == 3 then
                    self:playOnlyOne(
                        function()
                            if not tolua.isnull(self) then
                                self:autoClose()
                            end
                        end
                    )
                else
                    self:autoClose()
                end
            end
        end
    )
end

function LuckyStampTipViewNew:onEnter()
    LuckyStampTipViewNew.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, activityId)
            self.m_click = true
            self.m_isShow2 = true
            self:playTipShow(
                function()
                    self.m_click = false
                end
            )
        end,
        ViewEventType.NOTIFY_GUIDE_LUCKYSTAMP
    )

    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:updateView()
        end,
        ViewEventType.NOTIFY_UPDATA_LUCKYSTAMP
    )
end

function LuckyStampTipViewNew:clickFunc(sender)
    local name = sender:getName()
    if self.m_click then
        return
    end
    self.m_click = true
    if name == "btn_i" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOPINFO_CLOSE)
        if self.m_isShow2 then
            self.m_isShow2 = false
            self:playTipOver(
                function()
                    if not tolua.isnull(self) then
                        self:autoClose()
                    end
                end
            )
        else
            self.m_isShow2 = true
            self:playTipShow()
        end
    elseif name == "Panel_2" then
        if self.m_isShow2 then
            self.m_isShow2 = false
            self:playTipOver(
                function()
                    if not tolua.isnull(self) then
                        self:autoClose()
                    end
                end
            )
        end
    end
    performWithDelay(
        self,
        function()
            self.m_click = false
        end,
        1
    )
end

function LuckyStampTipViewNew:autoClose()
    if not self.m_isPermanent then
        performWithDelay(
            self,
            function()
                if not self.m_isShow2 and not tolua.isnull(self) then
                    self:closeUI()
                end
            end,
            3
        )
    end
end

function LuckyStampTipViewNew:closeUI()
    self:setVisible(false)
    if self.m_callback then
        self.m_callback()
    end
    self:removeFromParent()
end

function LuckyStampTipViewNew:getProcess()
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local processIdx = data:getProcessIndex()
        if processIdx == 0 then
            return 0
        else
            local processData = data:getProcessDataByIndex(processIdx)
            if processData then
                local stampIndex = processData:getIndex()
                return stampIndex
            end
        end
    end
    return 0
end

function LuckyStampTipViewNew:getContentSize()
    local size = self:findChild("Panel_1"):getContentSize()
    return size
end

return LuckyStampTipViewNew
