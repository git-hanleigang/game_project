--[[
    成长基金控制
    author:{author}
    time:2023-03-10 15:53:37
]]
-- 加载配置类
util_require("GameModule.GrowthFund.config.GrowthFundConfig")

local GrowthFundCtrl = class("GrowthFundCtrl", BaseGameControl)

function GrowthFundCtrl:ctor()
    GrowthFundCtrl.super.ctor(self)

    self.m_bNew = false
    self:setRefName(G_REF.GrowthFund)
end

function GrowthFundCtrl:parseData(data, _bNew)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        local luaPath = "GameModule.GrowthFund.model.GrowthFundData"
        if _bNew then
            luaPath = "GameModule.GrowthFund.modelNew.GrowthFundDataNew"
        end
        self:setDataModule(luaPath)
        self.m_bNew = _bNew
    end

    GrowthFundCtrl.super.parseData(self, data)
end

function GrowthFundCtrl:registerData(data)
    GrowthFundCtrl.super.registerData(self, data)

    self:updateTotalNum()
end

-- 检查是否是 新版
function GrowthFundCtrl:checkIsNew()
    return self.m_bNew
end

function GrowthFundCtrl:isUnlock(_phaseIdx)
    local data = self:getData()
    if not data then
        return false
    end

    return data:isUnlock(_phaseIdx)
end

-- 奖励状态
function GrowthFundCtrl:getLevelStatus(idx, typeIdx, _phaseIdx)
    local data = self:getData()
    if not data then
        return false
    end

    return data:getLevelStatus(idx, typeIdx, _phaseIdx)
end

function GrowthFundCtrl:updateTotalNum()
    local data = self:getData()
    if data then
        data:updateTotalNum()
    end
end

-- 显示主界面
function GrowthFundCtrl:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local luaPath = "GrowthFund/GrowthFundMainLayer"
    if self.m_bNew then
        luaPath = "GrowthFund/view_new/GrowthFundMainLayerNew"
    end
    local layer = util_createFindView(luaPath)
    self:showLayer(layer, ViewZorder.ZORDER_UI)
    return layer
end

-- 是否出发自动弹出主界面
function GrowthFundCtrl:isTriggerAutoPopMainLayer()
    local data = self:getRunningData()
    if not data then
        return false
    end

    -- 判断是否解锁了一个新的
    if not data:isUnlockNewReward() then
        return false
    end

    if not self.m_bNew then
        -- 待领取>3且未解锁
        if not data:isUnlock() and data:getCanCollectCountByType(GrowthFundConfig.Type.Pay) >= 3 then
            return true
        end
    else
        return  true
    end

    return false
end

-- 显示付费权益
function GrowthFundCtrl:showBenefitLayer()
    local data = self:getData()
    if not data then
        return nil
    end

    G_GetMgr(G_REF.PBInfo):showPBInfoLayer({p_price = data:getPrice()})
end

function GrowthFundCtrl:showRewardLayer(result)
    if not result then
        return
    end

    local layer = self:getLayerByName("GrowthFundRewardLayer")
    if layer ~= nil then
        return layer
    end

    local rewardCoins = 0 -- todo
    if result and result.coins ~= nil then
        rewardCoins = tonumber(result.coins)
    end

    if rewardCoins > 0 then
        layer = util_createView("GrowthFund.GrowthFundRewardLayer", rewardCoins)
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end

    return layer
end

function GrowthFundCtrl:isCanShowEntry()
    if not self:isCanShowLayer() then
        return false
    end

    if not GrowthFundCtrl.super.isCanShowEntry(self) then
        return false
    end

    return true
end

function GrowthFundCtrl:createEntryNode()
    if not self:isCanShowEntry() then
        return
    end

    local view = util_createView(self:getEntryModule())
    return view
end

function GrowthFundCtrl:getEntryModule()
    return "GrowthFund.GrowthFundEntryNode"
end

-- 购买解锁付费
function GrowthFundCtrl:buyUnlock()
    local data = self:getData()
    if not data then
        return
    end

    -- 解锁商品信息
    local goodsInfo = data:getGoodsInfo()
    if not goodsInfo then
        return
    end

    self:sendIapLog(goodsInfo)
    local buyType = BUY_TYPE.GROWTH_FUND_UNLOCK
    local phaseIdx, localId
    if self.m_bNew then
        buyType = BUY_TYPE.GROWTH_FUND_UNLOCK_V3
        phaseIdx = data:getCurPhaseIdx() - 1
        localId = string.format("%s_%s", buyType, phaseIdx)
    end
    gLobalSaleManager:purchaseActivityGoods(localId, phaseIdx,
        buyType,
        goodsInfo.keyId,
        goodsInfo.price,
        0,
        0,
        function()
            self:buySuccess()
        end,
        function()
            self:buyFailed()
        end
    )
end

-- 解锁付费打点
function GrowthFundCtrl:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}

    goodsInfo.goodsTheme = "GrowthFundSale"
    goodsInfo.goodsId = _goodsInfo.keyId
    goodsInfo.goodsPrice = _goodsInfo.price
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0

    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "GrowthFundSale"
    purchaseInfo.purchaseStatus = "GrowthFundSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
end

function GrowthFundCtrl:buySuccess()
    self:updateTotalNum()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GROWTH_FUND_UNLOCK_UPDATE, {success = true})
    gLobalViewManager:checkBuyTipList()
end

function GrowthFundCtrl:buyFailed()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GROWTH_FUND_UNLOCK_UPDATE, {success = false})
end

--[[
    @desc: 领取奖励 
    --@_index:0 一键领取
]]
function GrowthFundCtrl:collectReward(_index, _rewardType, _suc, _fail)
    local data = self:getData()
    if not data then
        return
    end

    local successFunc = function(_result)
        if _suc then
            _suc()
        end

        self:updateTotalNum()

        local _callback = function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GROWTH_FUND_COLLECT, {index = _index, rewardType = _rewardType, isSuc = true})
        end

        local layer = self:showRewardLayer(_result)
        if layer then
            layer:setOverFunc(_callback)
        else
            _callback()
        end
    end

    local failFunc = function()
        if _fail then
            _fail()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GROWTH_FUND_COLLECT, {index = _index, rewardType = _rewardType, isSuc = false})
    end
    local position = _index - 1 -- 服务器从0开始
    G_GetNetModel(NetType.GrowthFund):collectReward(position, _rewardType, successFunc, failFunc)
end

return GrowthFundCtrl
