local PiggyNodeFull = class("PiggyNodeFull", BaseView)

function PiggyNodeFull:initUI(max)
    if self:util_IsFileExist() then
        self:createCsbNode(self:getCsbName())
        local touchLayer = self:findChild("touch_layer")
        self:addClick(touchLayer)
        self:initPigBankData()
    end
end

function PiggyNodeFull:getCsbName()
    return "GameNode/PiggyFull.csb"
end

function PiggyNodeFull:initPigBankData()
    -- local piggyConfig = globalPiggyBankManager:getForLevelPiggyConfig()
    -- local piggyMul = globalPiggyBankManager:getPiggyMul()
    -- self.maxCoin = piggyConfig.MAX_COIN
    -- if piggyMul then
    --     self.maxCoin = self.maxCoin * piggyMul.MAX_PERCENT
    -- end

    -- if globalData.iapRunData.piggyBankCoin >= self.maxCoin then
    --     self:setVisible(true)
    -- else
    --     self:setVisible(false)
    -- end
    self.m_piggy_msg = self:findChild("piggy_msg")
    self.m_piggy_msg:setVisible(false)
    self.m_piggy_lock = self:findChild("suotou_1")
    local levelNum = globalData.userRunData.levelNum or 1
    local unlock = globalData.constantData.OPENLEVEL_PIGBANK or 6
    if levelNum < unlock then
        self:runCsbAction("lock", false)
        self:findChild("touch_layer1"):setBright(false)
        self.m_piggy_lock:setVisible(true)
    else
        self.m_piggy_lock:setVisible(false)
        self:findChild("touch_layer1"):setBright(true)
        self:playIdle()
    end
end
function PiggyNodeFull:playIdle()
    self:runCsbAction("act_2", true)
end

function PiggyNodeFull:addCollectCoin(betCoin)
    if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_PIGBANK then
        return
    end
    local piggyConfig = globalPiggyBankManager:getForLevelPiggyConfig()
    local piggyMul = globalPiggyBankManager:getPiggyMul()
    self.maxCoin = piggyConfig.MAX_COIN
    if piggyMul then
        self.maxCoin = self.maxCoin * piggyMul.MAX_PERCENT
    end

    --存储已经为最大值
    if globalData.iapRunData.piggyBankCoin == self.maxCoin then
        self:setVisible(true)
        return
    else
        self:setVisible(false)
    end
end

function PiggyNodeFull:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch_layer" then
        if globalData.userRunData.levelNum < globalData.constantData.OPENLEVEL_PIGBANK then
            self.m_piggy_msg:setVisible(true)
            gLobalViewManager:addAutoCloseTips(
                self.m_piggy_msg,
                function()
                    self.m_piggy_msg:setVisible(false)
                end
            )
        else
            G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
                gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "pigBank")
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(view, name, DotUrlType.UrlName, true, DotEntrySite.GamePushPig, DotEntryType.Game)
                end
            end)            
        end
    end
end

function PiggyNodeFull:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initPigBankData()
        end,
        ViewEventType.NOTIFY_UPDATE_PIGBANK_DATA
    )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:initPigBankData()
        end,
        ViewEventType.NOTIFY_PIGBANK_TISHI
    )
end

return PiggyNodeFull
