--[[
]]
util_require("GameModule.PiggyBank.config.PiggyBankCfg")
local PiggyBubbleCtrl = util_require("GameModule.PiggyBank.controller.PiggyBubbleCtrl")
local PiggyBankMgr = class("PiggyBankMgr", BaseGameControl)

function PiggyBankMgr:ctor()
    PiggyBankMgr.super.ctor(self)
    self:setRefName(G_REF.PiggyBank)

    self.m_pigBubbleCtrl = PiggyBubbleCtrl:create()
end

function PiggyBankMgr:getBubbleCtr()
    return self.m_pigBubbleCtrl
end

-- 获取主题名，绑定小猪挑战的主题
-- TODO:待优化
function PiggyBankMgr:getThemeName()
    local pigChallengeMgr = G_GetMgr(ACTIVITY_REF.PiggyChallenge)
    if pigChallengeMgr and pigChallengeMgr:isRunning() then
        return pigChallengeMgr:getThemeName()
    end
    return pigChallengeMgr.THEMES.COMMON
end

-- 数据解析和数据注册
function PiggyBankMgr:parseData(_netData)
    if not _netData then
        return
    end

    local data = self:getData()
    if not data then
        data = require("GameModule.PiggyBank.model.PiggyBankData"):create()
        data:parseData(_netData)
        self:registerData(data)
    else
        data:parseData(_netData)
    end
end

-- 所有正在开启的小猪折扣活动
function PiggyBankMgr:getDiscountRate(_isIgnoreNovice)
    local discountRate = 0
    local pigBoostData = G_GetMgr(ACTIVITY_REF.PigBooster):getRunningData()
    local pigRandomCardData = G_GetMgr(ACTIVITY_REF.PigRandomCard):getRunningData()
    local pigCoinsData = G_GetMgr(ACTIVITY_REF.PigCoins):getRunningData()
    local clanSaleData = G_GetMgr(ACTIVITY_REF.PigClanSale):getRunningData() -- 公会小猪折扣
    local pigGoldData = G_GetMgr(ACTIVITY_REF.PigGoldCard):getRunningData()

    if pigBoostData then
        if pigBoostData:beingOnPiggyBoostSale() then
            discountRate = pigBoostData.p_discount
        end
    elseif pigRandomCardData then
        discountRate = pigRandomCardData:getPiggyRandomCardSaleParam(true)
    elseif pigGoldData then
        if pigGoldData:getPiggyGoldFlag() then
            discountRate = pigGoldData:getDisCount()
        end
    elseif pigCoinsData then
        discountRate = pigCoinsData:getPiggyCommonSaleParam(true)
    elseif clanSaleData and clanSaleData:isRunning() then
        discountRate = clanSaleData:getDiscount(true)
    end

    -- 新手首购折扣 等级提升 会与活动 折扣叠加
    if not _isIgnoreNovice then
        local noviceFirstBuyDiscount = self:getNoviceFirstBuyDisCount()
        discountRate = discountRate + noviceFirstBuyDiscount
    end

    return discountRate
end

-- 新手首购 折扣
function PiggyBankMgr:getNoviceFirstBuyDisCount()
    local discountRate = 0

    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    local isInNoviceDiscount = piggyBankData and piggyBankData:checkInNoviceDiscount()
    if isInNoviceDiscount then
        discountRate = piggyBankData:getNoviceFirstDiscount() or 0
    end

    return discountRate
end

-- 所有正在使用的优惠券
function PiggyBankMgr:getCouponRate()
    local couponRate = 0
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    couponRate = couponRate + (piggyBankData and piggyBankData:getTicketDiscount() or 0)
    return couponRate
end

--[[--
    对金币有更改的情况：
        折扣活动[不同的活动同时开启时折扣要叠加]
        优惠券[同一时间只有一个优惠券能使用]
]]
function PiggyBankMgr:getPiggySaleRate(_isIgnoreNovice)
    local saleRate = 0
    saleRate = saleRate + self:getDiscountRate(_isIgnoreNovice)
    saleRate = saleRate + self:getCouponRate()
    return saleRate
end

function PiggyBankMgr:addCloseCallFunc(_func)
    if not self.m_closeCallFuncList then
        self.m_closeCallFuncList = {}
    end
    table.insert(self.m_closeCallFuncList, _func)
end

function PiggyBankMgr:enterPigSys(_func)
    if _func ~= nil and type(_func) == "function" then
        self:addCloseCallFunc(_func)
    end
end

function PiggyBankMgr:exitPigSys()
    if self.m_closeCallFuncList and #self.m_closeCallFuncList > 0 then
        for i = 1, #self.m_closeCallFuncList do
            self.m_closeCallFuncList[i]()
            self.m_closeCallFuncList[i] = nil
        end
    end
    self:triggerDropFuncNext()
end

-- 显示主界面
function PiggyBankMgr:showMainLayer(_params, _enterSuccessCall, _closeCallFunc)
    if gLobalViewManager:getViewByName("PiggyBankLayer") ~= nil then
        return nil
    end
    if G_GetMgr(ACTIVITY_REF.TrioPiggy):isTrioPiggyEffective() then
        G_GetMgr(ACTIVITY_REF.TrioPiggy):requestTrioPigInfo(
            function()
                local view = G_GetMgr(ACTIVITY_REF.TrioPiggy):showMainLayer(_params)
                if view then
                    view:setName("PiggyBankLayer")
                    if _enterSuccessCall then
                        _enterSuccessCall(view)
                    end
                    self:enterPigSys(_closeCallFunc)
                end
            end,
            function()
            end
        )
    else
        local view = self:showBasePigMainLayer(_params)
        if view then
            view:setName("PiggyBankLayer")
            if _enterSuccessCall then
                _enterSuccessCall(view)
            end
            self:enterPigSys(_closeCallFunc)
        end
    end
    -- local createBasePiggy = function()
    --     if gLobalViewManager:getViewByName("PiggyBankLayer") ~= nil then
    --         return nil
    --     end
    --     local view = util_createView("views.piggy.main.PiggyBankLayer", _params)
    --     if view then
    --         self:enterPigSys(_closeCallFunc)
    --         view:setName("PiggyBankLayer")
    --         gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    --     end
    --     return view
    -- end
    -- local view = nil
    -- local trioPiggyMgr = G_GetMgr(ACTIVITY_REF.TrioPiggy)
    -- if trioPiggyMgr then
    --     local data = trioPiggyMgr:getRunningData()
    --     if data then
    --         view = trioPiggyMgr:showMainLayer()
    --     end
    -- end
    -- if view then
    --     self:enterPigSys(_closeCallFunc)
    -- else
    --     view = createBasePiggy()
    -- end
    -- return view
    -- -- if gLobalViewManager:getViewByName("PiggyBankLayer") ~= nil then
    -- --     return nil
    -- -- end
    -- -- self:enterPigSys(_closeCallFunc)
    -- -- local view = util_createView("views.piggy.main.PiggyBankLayer", _params)
    -- -- if view then
    -- --     view:setName("PiggyBankLayer")
    -- --     gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    -- -- end
    -- -- return view
end

function PiggyBankMgr:showBasePigMainLayer(_params)
    local view = util_createView("views.piggy.main.PiggyBankLayer", _params)
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function PiggyBankMgr:showTrioPigMainLayer(_params)


    return view
end

-- 结算界面
function PiggyBankMgr:showRewardLayer()
    if gLobalViewManager:getViewByName("PiggyBankRewardLayer") ~= nil then
        return
    end
    local view = util_createView("views.piggy.reward.PiggyBankRewardLayer")
    if view then
        view:setName("PiggyBankRewardLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示规则界面
function PiggyBankMgr:showInfoLayer()
    if gLobalViewManager:getViewByName("PiggyBankInfoLayer") ~= nil then
        return
    end
    local view = util_createView("views.piggy.info.PiggyBankInfoLayer")
    if view then
        view:setName("PiggyBankInfoLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 检查掉落的奖励数据中是否有免费小猪道具
function PiggyBankMgr:checkFreePig(_itemDatas)
    if _itemDatas and #_itemDatas > 0 then
        for i = 1, #_itemDatas do
            local itemData = _itemDatas[i]
            if itemData.p_icon == PiggyBankCfg.FREE_ICON then
                return true
            end
        end
    end
    return false
end

-- 免费界面
function PiggyBankMgr:showFreeLayer(_closeFunc)
    if gLobalViewManager:getViewByName("PiggyFreeLayer") ~= nil then
        return
    end
    local view = util_createView("views.piggy.pop.PiggyFreeLayer", _closeFunc)
    if view then
        view:setName("PiggyFreeLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--[[--
    上UI挂的小猪控件节点
]]
function PiggyBankMgr:createTopPigNode()
    return util_createView("views.piggy.top.PiggyNode")
end

--[[--
    上UI弹出的小猪气泡
]]
function PiggyBankMgr:createPiggyTip(_luaName, _luaPath, _ZOrder, _pos)
    if gLobalViewManager:getViewByName(_luaName) ~= nil then
        return
    end
    local view = util_createView(_luaPath)
    if view then
        view:setName(_luaName)
        gLobalViewManager:getViewLayer():addChild(view, _ZOrder)
        if _pos then
            view:setPosition(cc.p(_pos.x, _pos.y))
        end
    end
    return view
end

-- 领完奖励后续弹框队列list
function PiggyBankMgr:initRewardDropList()
    local list = {}
    list[#list + 1] = handler(self, self.triggerDropTip)
    list[#list + 1] = handler(self, self.triggerShowPigRandomCard)
    list[#list + 1] = handler(self, self.triggerDropCards)
    list[#list + 1] = handler(self, self.triggerChipPiggyDropCards)
    list[#list + 1] = handler(self, self.triggerBooster)
    list[#list + 1] = handler(self, self.triggerLuckyStamp)
    list[#list + 1] = handler(self, self.triggerShowPigChallenge)
    -- list[#list + 1] = handler(self, self.triggerFirstCommonSale)
    list[#list + 1] = handler(self, self.triggerShowGoodWheel)
    list[#list + 1] = handler(self, self.exitPigSys)
    self.m_dropFuncList = list
end

function PiggyBankMgr:initMainCloseList()
    local list = {}
    list[#list + 1] = handler(self, self.triggerShowPigChallenge)
    list[#list + 1] = handler(self, self.triggerFirstCommonSale)
    list[#list + 1] = handler(self, self.exitPigSys)
    self.m_dropFuncList = list
end

function PiggyBankMgr:doMainCloseFunc()
    self.m_triggerInder = 0
    self:initMainCloseList()
    self:triggerDropFuncNext()
end

-- 结算界面关闭后续的弹板队列(_type:默认不传为金币小猪 "coin", "chip", "gem", "trio"三合一)
function PiggyBankMgr:doRewardDropFunc(_type)
    self.m_triggerInder = 0
    self.m_buyType = _type
    self:initRewardDropList()
    self:triggerDropFuncNext()
end

-- 检测 list 调用方法
function PiggyBankMgr:triggerDropFuncNext()
    self.m_triggerInder = (self.m_triggerInder or 0) + 1
    if self.m_triggerInder > #self.m_dropFuncList then
        self.m_triggerInder = 0
        self.m_buyType = nil
        return
    end
    local func = self.m_dropFuncList[self.m_triggerInder]
    if func then
        func()
    end
end

function PiggyBankMgr:triggerDropTip()
    --掉卡之前的提示
    gLobalViewManager:checkAfterBuyTipList(
        function()
            self:triggerDropFuncNext()
        end
    )
end

function PiggyBankMgr:triggerDropCards()
    -- 有卡片掉落 --
    if CardSysManager:needDropCards("Purchase") == true then
        CardSysManager:doDropCards(
            "Purchase",
            handler(
                self,
                function()
                    self:triggerDropFuncNext()
                end
            )
        )
    elseif CardSysManager:needDropCards("Pig Free Rewards") == true then
        CardSysManager:doDropCards(
            "Pig Free Rewards",
            handler(
                self,
                function()
                    self:triggerDropFuncNext()
                end
            )
        )
    else
        self:triggerDropFuncNext()
    end
end

function PiggyBankMgr:triggerChipPiggyDropCards()
    if CardSysManager:needDropCards("Pig Chip") == true then
        CardSysManager:doDropCards(
            "Pig Chip",
            handler(
                self,
                function()
                    self:triggerDropFuncNext()
                end
            )
        )
    else
        self:triggerDropFuncNext()
    end
end

function PiggyBankMgr:triggerBooster()
    if self.m_buyType and (self.m_buyType == "chip" or self.m_buyType == "gem") then
        self:triggerDropFuncNext()
        return
    end
    -- 购买成功后 需要处理促销活动数据 --
    local pigBoost = G_GetMgr(ACTIVITY_REF.PigBooster):getRunningData()
    if pigBoost and pigBoost:beingOnPiggyBoostSale() then
        -- 处于boost活动 并未选择buff 状态 --
        -- 通知saleConfig处理buff选择显示 --
        local view = G_GetMgr(ACTIVITY_REF.PigBooster):showPiggyBoosterChooseView(
            function()
                self:triggerDropFuncNext()
            end
        )
        if not view then
            self:triggerDropFuncNext()
        end
    else
        self:triggerDropFuncNext()
    end
end

function PiggyBankMgr:triggerLuckyStamp()
    gLobalViewManager:checkBuyTipList(
        function()
            self:triggerDropFuncNext()
        end
    )
end

-- 小猪累充 (new弹板顺序 充值完-> boost -> luckstamp -> 小猪挑战)
function PiggyBankMgr:triggerShowPigChallenge()
    if self.m_buyType and (self.m_buyType == "chip" or self.m_buyType == "gem") then
        self:triggerDropFuncNext()
        return
    end
    local bOpenLoad = gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.PiggyChallenge)
    if bOpenLoad then
        local actData = G_GetActivityDataByRef(ACTIVITY_REF.PiggyChallenge)
        if actData then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BROADCAST_HALL, {id = actData:getActivityID(), d = actData, clickFlag = true})
            actData:setCloseCallBack(
                function()
                    self:triggerDropFuncNext()
                end
            )
        end
    else
        self:triggerDropFuncNext()
    end
end

function PiggyBankMgr:triggerFirstCommonSale()
    local FirstSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
    if FirstSaleData then
        local params = {}
        params.pos = "pigBank"
        params.callback = function()
            self:triggerDropFuncNext()
        end
        G_GetMgr(G_REF.FirstCommonSale):checkShowMianLayer(params)
    else
        self:triggerDropFuncNext()
    end
end

function PiggyBankMgr:triggerShowGoodWheel()
    local data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    if data and data:checkIsReconnectPop() then
        local view = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):showMainLayer(
            function()
                self:triggerDropFuncNext()
            end
        )
        if not view then
            self:triggerDropFuncNext()
        end
    else
        self:triggerDropFuncNext()
    end
end

-- 显示小猪送卡界面
function PiggyBankMgr:triggerShowPigRandomCard()
    if self.m_buyType and (self.m_buyType == "chip" or self.m_buyType == "gem") then
        self:triggerDropFuncNext()
        return
    end
    local PigCardData = G_GetMgr(ACTIVITY_REF.PigRandomCard):getRunningData()
    if PigCardData then
        local function callFunc()
            self:triggerDropFuncNext()
        end
        local view = G_GetMgr(ACTIVITY_REF.PigRandomCard):showMainLayer({isPlayComplete = true},callFunc)
        if not view then
            self:triggerDropFuncNext()
        end
    else
        self:triggerDropFuncNext()
    end
end

function PiggyBankMgr:buyFree()
    local successFunc = function(_result)
        gLobalNoticManager:postNotification(ViewEventType.PIGGY_BANK_BUY_FREE, {isSuc = true})
    end
    local failFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.PIGGY_BANK_BUY_FREE, {isSuc = false})
        gLobalViewManager:showReConnect()
    end
    local data = self:getData()
    if not data then
        return
    end
    G_GetNetModel(NetType.PiggyBank):buyFree(successFunc, failFunc)
end

return PiggyBankMgr
