--版本更新
local NoSpinCoinsBuyLayer = class("NoSpinCoinsBuyLayer", util_require("base.BaseView"))
function NoSpinCoinsBuyLayer:initUI()
    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    self:createCsbNode("NoSpinCoinsUI/NoSpinCoinsBuyLayer.csb", isAutoScale)
    self:initView()
    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
            end
        )
    else
        self:runCsbAction("show")
    end
end

function NoSpinCoinsBuyLayer:initView()
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", "nocoinNoPayPush")
    local goodsInfo = {}
    goodsInfo.goodsTheme = "NoSpinCoinsBuyLayer"
    local purchaseInfo = {}
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, "openTheme", nil, self)
end

function NoSpinCoinsBuyLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_buy" then
        sender:setTouchEnabled(false)
        -- 有首充弹首充，没首充弹小猪
        local view = self:showSale()
        if not view then
            self:showPig()
        end
    elseif name == "btn_close" then
        -- 有首充弹首充，没首充弹小猪
        local view = self:showSale()
        if not view then
            self:showPig()
        end
    end
end

function NoSpinCoinsBuyLayer:showSale()
    gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, "NoSpinCoinsBuyLayer")
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    local uiView = nil
    local FirstSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
    if FirstSaleData then
        uiView = G_GetMgr(G_REF.FirstCommonSale):showMainLayer({pos = "Store"})
    end
    if gLobalSendDataManager.getLogPopub then
        gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "btn_buy", DotUrlType.UrlName, false)
    end
    self:closeUI()
    return uiView
end

function NoSpinCoinsBuyLayer:showPig()
    gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, "NoSpinCoinsBuyLayer")
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_close", DotUrlType.UrlName, false)
        end
    end)    
    self:closeUI()

    if not globalData.slotRunData.machineData then
        return
    end
    --调小bet值
    local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()
    if machineCurBetList and machineCurBetList[1] then
        local betSelectId = machineCurBetList[1].p_betId
        for i = #machineCurBetList, 1, -1 do
            local betData = machineCurBetList[i]
            if betData.p_totalBetValue <= globalData.userRunData.coinNum then
                betSelectId = betData.p_betId
                break
            end
        end
        globalData.slotRunData.iLastBetIdx = betSelectId
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    end
end

function NoSpinCoinsBuyLayer:onKeyBack()
    -- 有首充弹首充，没首充弹小猪
    local view = self:showSale()
    if not view then
        self:showPig()
    end
end

function NoSpinCoinsBuyLayer:closeUI(isLog)
    if self.isClose then
        return
    end
    self.isClose = true

    local root = self:findChild("root")
    if root then
        self:commonHide(
            root,
            function()
                self:removeFromParent()
            end
        )
    else
        self:runCsbAction(
            "over",
            false,
            function()
                self:removeFromParent()
            end,
            60
        )
    end
end

return NoSpinCoinsBuyLayer
