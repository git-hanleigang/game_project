--[[
    --新版每日任务pass主界面 购买等级商城界面
    csc 2021-06-21
]]
local BaseLayer = util_require("base.BaseLayer")
local DailyMissionPassBuyLevelLayer = class("DailyMissionPassBuyLevelLayer", BaseLayer)

function DailyMissionPassBuyLevelLayer:initCsbNodes()
    -- 左边
    self.m_nodeLeft = self:findChild("node_1")
    self.m_labLeftLevel = self:findChild("lb_left_level")
    self.m_labLeftPrice = self:findChild("lb_left_price")

    self.m_labLeftLevelFnt1 = self:findChild("fnt_1") -- 追加的level 文本
    self.m_labLeftLevelFnt2 = self:findChild("fnt_1_0") -- 追加的level 文本
    -- 右边
    self.m_nodeRight = self:findChild("node_2")
    self.m_labRightLevel = self:findChild("lb_right_level")
    self.m_labRightPrice = self:findChild("lb_right_price")

    self.m_labRightLevelFnt1 = self:findChild("fnt_2") -- 追加的level 文本
    self.m_labRightLevelFnt2 = self:findChild("fnt_2_1") -- 追加的level 文本
    -- 中间
    self.m_nodeCenter = self:findChild("node_3")

    -- benifit 界面
    self.m_nodeBp1 = self:findChild("NodeBp_1")
    -- benifit 界面
    self.m_nodeBp2 = self:findChild("NodeBp_2")
end

function DailyMissionPassBuyLevelLayer:ctor()
    DailyMissionPassBuyLevelLayer.super.ctor(self)
    -- 设置横屏csb

    self:setLandscapeCsbName(DAILYPASS_RES_PATH.DailyMissionPass_LevelStoreLayer)
    self:setPortraitCsbName(DAILYPASS_RES_PATH.DailyMissionPass_LevelStoreLayer_Vertical)
end

function DailyMissionPassBuyLevelLayer:initView()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        self.m_goodInfo = actData:getBuyLvGoodsInfo()
        -- 坐标
        local leftData = self.m_goodInfo[1]
        if leftData then
            local goodInfo = leftData:getGoodsInfo()
            self.m_labLeftLevel:setString(leftData:getBuyLevel())
            self.m_labLeftPrice:setString("$" .. goodInfo.price)

            if leftData:getBuyLevel() == 1 then -- 只有1级可以买的时候 不能显示LEVELS
                self.m_labLeftLevelFnt2:setString("LEVEL")
            end
            -- 计算追加字体坐标
            local newPosXLeft = self.m_labLeftLevel:getPositionX() - self.m_labLeftLevel:getContentSize().width / 2 - 8
            local newPosXRight = self.m_labLeftLevel:getContentSize().width / 2 + self.m_labLeftLevel:getPositionX() + 8
            self.m_labLeftLevelFnt1:setPositionX(newPosXLeft)
            self.m_labLeftLevelFnt2:setPositionX(newPosXRight)

            if actData:getLevel() + leftData:getBuyLevel() >= actData:getMaxLevel() then
                self.m_nodeRight:setVisible(false)
                self.m_nodeLeft:setPosition(cc.p(self.m_nodeCenter:getPosition()))
                self.m_nodeBp1:setPositionX(self.m_nodeCenter:getPositionX())
                self.m_nodeBp2:setVisible(false)
            end
            -- 添加 bp 节点
            -- gLobalBattlePassManager:initBPNode(self.m_nodeBp1, self.m_pbNode1, goodInfo.price, goodInfo.vipPoints)
        end

        local rightData = self.m_goodInfo[2]
        if rightData then
            local goodInfo = rightData:getGoodsInfo()
            self.m_labRightLevel:setString(rightData:getBuyLevel())
            self.m_labRightPrice:setString("$" .. goodInfo.price)

            -- 计算追加字体坐标
            local newPosXLeft = self.m_labRightLevel:getPositionX() - self.m_labRightLevel:getContentSize().width / 2 - 8
            local newPosXRight = self.m_labRightLevel:getContentSize().width / 2 + self.m_labRightLevel:getPositionX() + 8
            self.m_labRightLevelFnt1:setPositionX(newPosXLeft)
            self.m_labRightLevelFnt2:setPositionX(newPosXRight)

            -- 添加 bp 节点
            -- gLobalBattlePassManager:initBPNode(self.m_nodeBp2, self.m_pbNode2, goodInfo.price, goodInfo.vipPoints)
        end
    end

    self:startButtonAnimation("btn_left", "sweep")
    self:startButtonAnimation("btn_right", "sweep")

    self:updateBtnBuck()
end

function DailyMissionPassBuyLevelLayer:updateBtnBuck()
    local buyType = BUY_TYPE.TRIPLEXPASS_LEVELSTORE
    if gLobalDailyTaskManager:isWillUseNovicePass() then
        buyType = BUY_TYPE.TRIPLEXPASS_LEVELSTORE_NOVICE
    end
    self:setBtnBuckVisible(self:findChild("btn_left"), buyType)
    self:setBtnBuckVisible(self:findChild("btn_right"), buyType)
end

function DailyMissionPassBuyLevelLayer:clickFunc(_sender)
    local name = _sender:getName()
    
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_left" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods(1)
    elseif name == "btn_right" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:buyGoods(2)
    elseif name == "btn_bp1" then
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if actData then
            local leftData = self.m_goodInfo[1]
            if leftData then
                local goodInfo = leftData:getGoodsInfo()
                local saleData = {p_price = goodInfo.price, p_vipPoint = goodInfo.vipPoints}
                G_GetMgr(G_REF.PBInfo):showPBInfoLayer(saleData)
            end
        end
    elseif name == "btn_bp2" then
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if actData then
            local rightData = self.m_goodInfo[2]
            if rightData then
                local goodInfo = rightData:getGoodsInfo()
                local saleData = {p_price = goodInfo.price, p_vipPoint = goodInfo.vipPoints}
                G_GetMgr(G_REF.PBInfo):showPBInfoLayer(saleData)
            end
        end
    end
end

-- 购买等级
function DailyMissionPassBuyLevelLayer:buyGoods(_index)
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if not actData then
        return
    end
    if self.m_purchasing then
        return
    end
    self.m_purchasing = true

    local goodsItem = self.m_goodInfo[_index]
    if not goodsItem then
        return 
    end
    
    local goodsInfo = goodsItem:getGoodsInfo()

    self:sendIapLog(goodsInfo, _index)

    local buyType = BUY_TYPE.TRIPLEXPASS_LEVELSTORE
    if gLobalDailyTaskManager:isWillUseNovicePass() then
        buyType = BUY_TYPE.TRIPLEXPASS_LEVELSTORE_NOVICE
    end

    gLobalSaleManager:purchaseActivityGoods(
        actData:getActivityID(),
        _index,
        buyType,
        goodsInfo.key,
        goodsInfo.price,
        0,
        0,
        function()
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess()
            else
            end
        end,
        function()
            self.m_purchasing = false
            if self.buyFailed ~= nil then
                self:buyFailed()
            else
            end
        end
    )
end

function DailyMissionPassBuyLevelLayer:buySuccess()
    gLobalSendDataManager:getLogIap():setLastEntryType()
    gLobalBattlePassManager:removeInfoPbNode(self.m_pbNode1)
    gLobalBattlePassManager:removeInfoPbNode(self.m_pbNode2)

    local closeFunc = function()
        if not tolua.isnull(self) then
            self:closeUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_BUY_LEVELSTORE, {success = true})
            end
        )
        end
    end
    gLobalViewManager:checkBuyTipList(closeFunc)
end

function DailyMissionPassBuyLevelLayer:buyFailed()
end

-- 客户端打点
function DailyMissionPassBuyLevelLayer:sendIapLog(_goodsInfo, _index)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "GloryPassLevel"
        goodsInfo.goodsId = _goodsInfo.key
        goodsInfo.goodsPrice = _goodsInfo.price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = "GloryPassLevel" .. _index
        local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
        if not actData then
            return
        end
        purchaseInfo.purchaseStatus = actData:getLevel()
        gLobalSendDataManager:getLogIap():setEntryType("GloryPass")
        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function DailyMissionPassBuyLevelLayer:onEnter()
    DailyMissionPassBuyLevelLayer.super.onEnter(self)

    -- 促销到期
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params.name == ACTIVITY_REF.NewPass then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_DAILY_TASK_UI_CLOSE
    )
    -- csc 特殊补单逻辑,执行购买成功的动画
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self.m_purchasing = false
            if self.buySuccess ~= nil then
                self:buySuccess()
            end
        end,
        IapEventType.IAP_RetrySuccess
    )
    
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self.m_purchasing = false
        end,
        ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    )
end

function DailyMissionPassBuyLevelLayer:closeUI(...)
    if self:isShowing() or self:isHiding() then
        return
    end
    DailyMissionPassBuyLevelLayer.super.closeUI(self, ...)
end

return DailyMissionPassBuyLevelLayer
