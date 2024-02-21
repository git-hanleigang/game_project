-- Created by jfwang on 2019-05-06.
-- 游戏界面推送
local LuaList = require("common.LuaList")
local PopupItemConfig = require("data.popUp.PopupItemConfig")
local PushViewControl = class("PushViewControl")
PushViewControl.instance = nil
-- PushViewControl.pushNum = nil
local urlTypeEnum = {
    -- 推送
    Push = 1,
    -- 轮播图
    Slide = 2,
    -- 展示图
    Hall = 3
}

function PushViewControl:getInstance()
    if not PushViewControl.instance then
        PushViewControl.instance = PushViewControl:create()
        PushViewControl.instance:initData()
    end

    return PushViewControl.instance
end

--热更之后开启下载队列，直到队列为空
function PushViewControl:initData()
    self.pushNum = nil
    --读取配置-根据显示位置，格式化数据
    -- self.m_data = self:fmtConfigData()

    --记录时间戳，用于弹框时间间隔
    self.m_dataTime = {}

    --显示弹窗队列
    self.m_showQueue = LuaList.new()
    self.m_curData = nil

    -- 忽略队列
    self.m_ignoreArray = {}

    --注册通知
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            --弹窗逻辑暂停了
            if gLobalPopViewManager.m_isPause then
                return
            end
            self:nextPushView()
        end,
        ViewEventType.PUSH_VIEW_NEXT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:finishPushView()
        end,
        ViewEventType.PUSH_VIEW_FINISH
    )

    --大厅轮播图相应
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showActivityView(params, "Slide")
        end,
        ViewEventType.NOTIFY_CLICK_BROADCAST
    )

    --大厅展示图相应
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:showActivityView(params, "Hall")
        end,
        ViewEventType.NOTIFY_CLICK_BROADCAST_HALL
    )
    --hottoday
    gLobalNoticManager:addObserver(
        self,
        function(self, params, params1)
            self:showPushView(params, false)
        end,
        ViewEventType.NOTIFY_ONLY_OPEN_POPUP_VIEW
    )
    --没钱推送次数
    self.m_noSpinCoinsPushCount = gLobalDataManager:getNumberByField("NoSpinCoinsPushCount", 0)
    self.m_noSpinCoinsMinBetCount = gLobalDataManager:getNumberByField("NoSpinCoinsMinBetCount", 0)
end

function PushViewControl:purge()
    gLobalNoticManager:removeAllObservers(self)
    -- self.m_data = nil
    self.m_dataTime = nil
    self.m_showQueue = nil
    self.m_curData = nil
    self.pushNum = nil
end

--格式化配置数据
-- function PushViewControl:fmtConfigData()
--     local fmtData = {}
--     local content = globalData.GameConfig.popupConfigs
--     for i=1,#content do
--         local d = content[i]
--         if not fmtData[d:getPosType()] then
--             local temp = {}
--             temp[#temp+1] = d
--             fmtData[d:getPosType()] = temp
--         else
--             local temp = fmtData[d:getPosType()]
--             temp[#temp+1] = d
--         end
--     end

--     return fmtData
-- end

--结束后续推送
function PushViewControl:finishPushView()
    --清空没钱促销数据
    G_DelActivityDataByRef(ACTIVITY_REF.NoCoinSale)
    if G_GetMgr(G_REF.FirstCommonSale):isNoCoins() then
        G_GetMgr(G_REF.FirstCommonSale):deleteNoCoinsSaleData()
    end

    -- 做个处理 csc 2021年07月26日 后期需要优化弹窗队列
    if self.m_curData and self.m_curData:getPosType() == PushViewPosType.LoginToLobby then
        -- 当前弹窗队列中 登录触发点
        -- 如果是从 finish 阶段进入的，需要清除掉pushEndCallBack
        if self.m_pushEndCallBack then
            self.m_pushEndCallBack = nil
        end
    end

    self.m_showQueue:clear()
    self.m_curData = nil

    if self.m_pushEndCallBack then
        self.m_pushEndCallBack()
        self.m_pushEndCallBack = nil
    end
end

--开始推送窗口逻辑
function PushViewControl:nextPushView()
    if self.m_showQueue:empty() then
        self.m_curData = nil
        gLobalSendDataManager:getLogIap():clearPushCount()
        --检查有无需要恢复活动界面
        -- gLobalActivityManager:recoveryFindView(
        --     function()
        --清空没钱促销数据
        G_DelActivityDataByRef(ACTIVITY_REF.NoCoinSale)
        if G_GetMgr(G_REF.FirstCommonSale):isNoCoins() then
            G_GetMgr(G_REF.FirstCommonSale):deleteNoCoinsSaleData()
        end
        if self.m_pushEndCallBack then
            self.m_pushEndCallBack()
            self.m_pushEndCallBack = nil
        end
        --     end
        -- )

        return
    end

    self.m_curData = self.m_showQueue:pop()
    if self.m_curData ~= nil then
        self:showPushView(self.m_curData)
    end
end

function PushViewControl:pushDotHelper(node, posType)
    if not gLobalSendDataManager.getLogPopub then
        return
    end

    local urlType, pos, btnName = gLobalSendDataManager:getLogPopub():getClickUrl()
    if urlType and pos and btnName then
        gLobalSendDataManager:getLogPopub():addNodeDot(node, btnName, DotUrlType.UrlName, true, urlType, pos)
    else
        local pushType = gLobalSendDataManager:getLogPopub():exchangePopType(posType)
        local position = DotEntryType.Game
        if gLobalViewManager:isLobbyView() then
            position = DotEntryType.Lobby
        end
        if pushType then
            gLobalSendDataManager:getLogPopub():addNodeDot(node, "Push", DotUrlType.UrlName, true, pushType, position)
        end
    end
end

--显示推送窗口
function PushViewControl:showPushView(popItem, isPopup)
    if popItem:getPosType() == PushViewPosType.LoginToLobby then
        if not self.pushNum then
            self.pushNum = 0
        end
        self.pushNum = self.pushNum + 1
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType["Popup" .. self.pushNum])
        end
    end
    if isPopup == nil then -- false 时只执行单个弹窗弹出 nil true 时 都按true 处理
        isPopup = true
    end
    local isShow = false
    local viewType = tonumber(popItem:getPopType())
    if isPopup then
        gLobalSendDataManager:getLogIap():updatePushCount()
    end
    if viewType == PushViewType.VERSION_UPDATE_VIEW then
        -- 版本更新 newVersion
        local uiView = gLobalSysRewardManager:showView(popItem:getRefName())
        self:pushDotHelper(uiView, popItem:getPosType())
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        isShow = true
    elseif viewType == PushViewType.FB_LOGIN_VIEW then
        -- FB登陆奖励弹版 FBReward
        local uiView = gLobalSysRewardManager:showView(popItem:getRefName())
        self:pushDotHelper(uiView, popItem:getPosType())
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        isShow = true
    elseif viewType == PushViewType.ROUTINE_PROMOTION then
        self:addIapLogInfo(popItem:getPosType())
        -- 常规促销 BasicSaleLayer.lua
        local vPos = self:getPayPosition(popItem:getPosType())
        local uiView = nil
        local FirstSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
        local bCanShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
        local brokenSale = G_GetMgr(G_REF.BrokenSaleV2):isCanShowMainLayer()
        local isNoCoinsPos = popItem:getPosType() == PushViewPosType.NoCoinsToSpin
        local bcCanShowRoutineSale = G_GetMgr(G_REF.RoutineSale):canShowMainLayer()
        if bCanShowFirstSaleMulti then
            uiView = G_GetMgr(G_REF.FirstSaleMulti):showMainLayer({pos = vPos})
        elseif FirstSaleData then
            uiView = G_GetMgr(G_REF.FirstCommonSale):showMainLayer({pos = vPos}, FirstSaleData)
        elseif brokenSale and isNoCoinsPos then
            uiView = G_GetMgr(G_REF.BrokenSaleV2):showMainLayer()
        elseif bcCanShowRoutineSale then
            uiView = G_GetMgr(G_REF.RoutineSale):showMainLayer({pos = vPos})
        else
            -- local _saleData = G_GetActivityDataByRef(ACTIVITY_REF.BrokenSale)
            -- if _saleData and _saleData:isHasBrokenSale() then
            --     local luaName = "views.sale.BrokenSaleLayer"
            --     uiView = util_createView(luaName)
            --     gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
            -- else
            --     uiView = G_GetMgr(G_REF.SpecialSale):showMainLayer({pos = vPos})
            -- end
            uiView = G_GetMgr(G_REF.SpecialSale):showMainLayer({pos = vPos})
        end
        if uiView then
            self:pushDotHelper(uiView, popItem:getPosType())
            isShow = true
        else
            isShow = false
        end
    elseif viewType == PushViewType.NEW_LEVEL_RECOMMEND then
        -- 新关推荐弹版 LevelNewWindows.lua
        local csbName = "Lobby/" .. popItem.pathCsbName .. "NewWin.csb"
        if cc.FileUtils:getInstance():isFileExist(csbName) then
            local luaName = "views.lobby." .. popItem:getRefName()
            local uiView = util_createView(luaName, popItem.pathCsbName)
            self:pushDotHelper(uiView, popItem:getPosType())
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
            isShow = true
        end
    elseif viewType == PushViewType.ADVERT_VIEW then
        if not gLobalAdsControl:checkIsForbid(AdsRewardDialogType.Normal, popItem:getPosType()) then
            -- 广告弹版
            gLobalSendDataManager:getLogAdvertisement():setOpenSite(popItem:getPosType())
            gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
            gLobalAdsControl:playVideo(AdsRewardDialogType.Normal, popItem:getPosType())
            gLobalSendDataManager:getLogAds():createPaySessionId()
            gLobalSendDataManager:getLogAds():setOpenSite(popItem:getPosType())
            gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
            -- globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = popItem:getPosType()})
            isShow = true
        end
    elseif viewType == PushViewType.SHOP_GOLD_RECEIVE then
        -- 商城金币领取提示
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_VIEW_SHOW, PushViewTipsType.PushViewTipsType_ShopReward)
        isShow = true
    elseif viewType == PushViewType.CASHBONUS_REWARD_RECEIVE then
        -- cash bonus 金库奖励领取提示弹版
        -- 提示代码cashbonus 重构时候删除了先屏蔽
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_VIEW_SHOW, PushViewTipsType.PushViewTipsType_CashBonusReward)
        isShow = true
    elseif viewType == PushViewType.CASHBONUS_REWARD_COLLECT then
        -- cash bonus金库奖励收集方式提示弹版 不放到规则里面
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_VIEW_SHOW,PushViewTipsType.PushViewTipsType_CashBonusCollect)
    elseif viewType == PushViewType.PIGLET_VIEW then
        -- 小猪
        G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
            self:addIapLogInfo(popItem:getPosType())
            self:pushDotHelper(view, popItem:getPosType())
            isShow = true
        end)
    elseif viewType == PushViewType.SHOP_VIEW then
        --大厅=lobby、游戏关卡=gameName、登陆弹出购买=login、邮箱=Email邮箱
        --点击打开=tapOpen、自动打开=pushOpen、没钱触发_nocoinOpen
        --定义推动窗口位置类型
        self:addIapLogInfo(popItem:getPosType())
        -- 商城 ZQCoinStoreLayer.lua
        -- local luaName = "GameModule.Shop." .. popItem:getRefName()
        -- local view = util_createView(luaName, nil, false, true)
        local view = G_GetMgr(G_REF.Shop):showMainLayer()
        self:pushDotHelper(view, popItem:getPosType())
        isShow = true
    elseif viewType == PushViewType.NOSPINCOINS_BUY then
        --本地 没钱spin弹版
        local view = util_createView("views.noSpinCoins.NoSpinCoinsBuyLayer")
        self:pushDotHelper(view, popItem:getPosType())
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        isShow = true
    elseif viewType == PushViewType.NOSPINCOINS_GIFT then
        --本地 没钱spin礼物
        local view = util_createView("views.noSpinCoins.NoSpinCoinsGiftLayer")
        self:pushDotHelper(view, popItem:getPosType())
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        isShow = true
    elseif viewType == PushViewType.NOSPINCOINS_TRYPAY then
        --消费用户弹尝试消费
        if self:checkTryPayView() then
            --本地 没钱spin弹版
            local view = util_createView("views.TryPay.TryPayView")
            self:pushDotHelper(view, popItem:getPosType())
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            isShow = true
        end
    else
        -- 后续新弹窗功能，都走配置表
        --popItem.pathCsbName 指定使用csb
        --popItem:getRefName() 指ui文件名
        if gLobalSendDataManager.getLogPopub then
            local pushType = gLobalSendDataManager:getLogPopub():exchangePopType(popItem:getPosType())
            local urlType, pos, btnName = gLobalSendDataManager:getLogPopub():getClickUrl()
            if urlType and pos and btnName then
            else
                gLobalSendDataManager:getLogPopub():setClickUrl(DotEntrySite.LobbyCarousel, DotEntryType.Lobby, "Push")
            end
        end
        isShow = self:showActivityPushView(popItem, nil)
    end
    if isPopup then
        if not isShow then
            self:nextPushView()
        else
            gLobalSendDataManager:getLogIap():addPushCount(popItem:getPosType())
        end
    end
end

--显示活动推送view
function PushViewControl:showActivityPushView(popItem, callback)
    self:addIapLogInfo(popItem:getPosType())

    if popItem then
        local refName = popItem:getRefName()
        local uiView = nil
        local refMgr = G_GetMgr(refName)
        if refMgr then
            local popInfo = {
                -- refName = themeName,
                activityId = popItem:getPopUpId(),
                clickFlag = popItem.clickFlag,
                pos = popItem.pos,
                popupType = ACT_LAYER_POPUP_TYPE.AUTO,
                csbPath = popItem.pathCsbName
            }
            uiView = refMgr:showPopLayer(popInfo, callback)
            if uiView then
                if uiView.setPushView then
                    uiView:setPushView(true)
                end
                -- 处理CD
                globalData.popCdData:addPopCd(popItem:getPopUpId(), popItem:getCdSecs())
                globalData.popCdData:addPopCd(popItem:getRefName(), popItem:getCdSecs())
                return true
            end
        else
            local _activiy = G_GetActivityDataByRef(refName)
            if not _activiy or not _activiy:isCanShowPopView() then
                return false
            end

            local themeName = _activiy:getThemeName()
            local luaFileName = _activiy:getPopModule()
            if luaFileName == "" then
                return false
            end
            uiView = util_createView(luaFileName, {refName = themeName, activityId = popItem:getPopUpId(), clickFlag = popItem.clickFlag, popupType = ACT_LAYER_POPUP_TYPE.AUTO})
            if uiView ~= nil then
                -- 处理CD
                globalData.popCdData:addPopCd(popItem:getPopUpId(), popItem:getCdSecs())
                globalData.popCdData:addPopCd(popItem:getRefName(), popItem:getCdSecs())

                uiView:setOverFunc(
                    function()
                        if callback ~= nil then
                            callback()
                        end
                    end
                )

                if uiView.setPushView then
                    uiView:setPushView(true)
                end
                gLobalViewManager:showUI(uiView, gLobalActivityManager:getUIZorder(refName))
                return true
            end
        end

        if uiView then
            -- 打点
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(refName .. "_Popup", false)
            end
            if gLobalSendDataManager.getLogPopub then
                local urlType, pos, btnName = gLobalSendDataManager:getLogPopub():getClickUrl()
                if urlType and pos and btnName then
                    gLobalSendDataManager:getLogPopub():addNodeDot(uiView, btnName, DotUrlType.UrlName, true, urlType, pos)
                end
            end
        else
            dump(data, "弹板信息")
            printInfo("------>    弹板配置错误 ")
        end
    end
    return false
end

--轮播图&展示图 打开对应的促销弹版
function PushViewControl:showActivityView(params, _pos)
    if params == nil then
        return
    end

    local activityId = params.id
    local data = params.d
    local clickFlag = params.clickFlag
    if activityId == nil or data == nil then
        return
    end

    local refName = data:getRefName()
    local vType = data.p_activityType
    if not vType then
        gLobalBuglyControl:luaException("activityId = " .. tostring(activityId) .. "_", debug.traceback())
        return
    end
    if vType > ACTIVITY_TYPE.COMMON then
        --判断促销是否结束
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(vType, refName)
        if retV then
            local csbName = nil
            if popupView ~= nil and popupView ~= "" then
                csbName = popupView
            elseif data.p_popupImage ~= nil and data.p_popupImage ~= "" then
                csbName = data.p_popupImage
            end
            --弹窗中没配置，根据活动配置，弹出界面
            local popupData = PopupItemConfig:create()
            local viewData = {popupId = activityId, resourcePath = csbName, activityName = refName, type = data.p_id}
            popupData:parseData(viewData)
            popupData.clickFlag = clickFlag
            popupData.pos = _pos
            self:showActivityPushView(popupData, nil)
        end
    end
end

--是否满足逻辑需求
function PushViewControl:isSatisfyOpen(data)
    --配置表是否开启
    if not data then
        return false
    end
    --配置表内，配置了未开启
    if tonumber(data:isOpen()) ~= 1 then
        return false
    end

    -- 是否在忽略队列
    if self:isIgnorePop(data:getPosType(), data:getRefName()) then
        return false
    end

    --等级不满足
    if not self:isSatisfyLevel(data) then
        return false
    end

    --时间间隔不满足
    if not self:isSatisfyTime(data) then
        return false
    end

    --登录增加了新的检测
    if data:getPosType() == PushViewPosType.LoginToLobby then
        local controlData = PopUpManager:getPopupControlData(data)
        if not controlData then
            return false
        end
        if controlData.p_loginShow == 0 then
            return false
        end
    end

    --根据弹版类型，判断游戏逻辑是否满足弹版
    local ret = false
    local viewType = tonumber(data.type)
    local refName = data.luaName
    
    if refName and refName ~= "" then
        local mgr = G_GetMgr(refName)
        if mgr and (not mgr:isCanShowPop()) then
            -- 没有达到显示弹窗条件
            return false
        end
    end

    if viewType == PushViewType.VERSION_UPDATE_VIEW then
        -- 版本更新 "newVersion"
        ret = gLobalSysRewardManager:isOpenReward(data.luaName)
    elseif viewType == PushViewType.FB_LOGIN_VIEW then
        -- FB登陆奖励弹版 "FBReward"
        local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
        if FBSignRewardManager then
            ret = FBSignRewardManager:getInstance():isOpenReward()
        end
    elseif viewType == PushViewType.ROUTINE_PROMOTION then
        --没钱不走这个逻辑
        if data:getPosType() == PushViewPosType.NoCoinsToSpin then
            ret = true
        else
            -- 常规促销
            -- local retV,popupView = globalData.saleRunData:isNeedPushView(ACTIVITY_TYPE.COMMON,data.id)
            local retV = globalData.saleRunData:checkBaicsSale()
            local popupView = nil
            if retV then
                --登录需要检测折扣
                if data:getPosType() == PushViewPosType.LoginToLobby and globalData.saleRunData:isOpenNormalSale() then
                    ret = true
                else
                    ret = true
                end
            end
        end
    elseif viewType >= PushViewType.THEME_PROMOTION_BEGIN and viewType <= PushViewType.THEME_PROMOTION_END then
        -- 主题促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.THEME, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.MULTIPLE_PROMOTION_BEGIN and viewType <= PushViewType.MULTIPLE_PROMOTION_END then
        -- 多档促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.CHOICE, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.ACTIVITY_PROMOTION_BEGIN and viewType <= PushViewType.ACTIVITY_PROMOTION_END then
        -- 活动促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.SEVENDAY, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.BINGO_PROMOTION_BEGIN and viewType <= PushViewType.BINGO_PROMOTION_END then
        -- bingo促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.BINGO, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.DINNERLAND_PROMOTION_BEGIN and viewType <= PushViewType.DINNERLAND_PROMOTION_END then
        -- 餐厅促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.DINNERLAND, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.COINPUSHER_PROMOTION_BEGIN and viewType <= PushViewType.COINPUSHER_PROMOTION_END then
        -- 推币机促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.COINPUSHER, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.RICHMAIN_PROMOTION_BEGIN and viewType <= PushViewType.RICHMAIN_PROMOTION_END then
        -- bingo促销
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.RICHMAIN, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType >= PushViewType.KEEPRECHARGE_PROMOTION_BEGIN and viewType <= PushViewType.KEEPRECHARGE_PROMOTION_END then
        --连续充值
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.KEEPRECHARGE, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType == PushViewType.ACTIVITY_VIEW then
        -- 活动弹版
        ret = globalData.commonActivityData:IsOpenActivity(data.luaName)
        if ret then
            local activityData = G_GetActivityDataByRef(data.luaName)
            local refName = activityData:getRefName()
            local themeName = activityData:getThemeName()
            if data:getPosType() == PushViewPosType.LevelToLobby or data:getPosType() == PushViewPosType.LoginToLobby or data:getPosType() == PushViewPosType.CloseStore then
                if string.find(refName, "Activity_SaleTicket") then
                    local saleTicketData = G_GetMgr(ACTIVITY_REF.SaleTicket):getRunningData()
                    if saleTicketData and saleTicketData.isRunning and saleTicketData:isRunning() then
                        if saleTicketData:getRefName() ~= data.luaName then
                            ret = false
                        end
                    else
                        ret = false
                    end
                end
            end
        end
    elseif viewType == PushViewType.BLAST_PROMOTION then
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.BLAST, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType == PushViewType.ADVERT_VIEW then
        -- 广告弹版
        ret = globalData.adsRunData:isPlayRewardForPos(data:getPosType(), nil, true)
    elseif viewType == PushViewType.NEW_LEVEL_RECOMMEND then
        -- 新关推荐弹版
        local levelName = globalData.GameConfig:getRecommendLevelName()
        if levelName then
            data.pathCsbName = levelName
            ret = true
        end
    elseif viewType == PushViewType.SHOP_GOLD_RECEIVE then
        -- 商城金币领取提示
    elseif viewType == PushViewType.CASHBONUS_REWARD_RECEIVE then
        -- cash bonus 金库奖励领取提示弹版
        ret = G_GetMgr(G_REF.CashBonus):willMegaCollect()
    elseif viewType == PushViewType.CASHBONUS_REWARD_COLLECT then
        -- cash bonus金库奖励收集方式提示弹版
        ret = G_GetMgr(G_REF.CashBonus):willGoldCollect()
    elseif viewType == PushViewType.PIGLET_VIEW then
        -- 小猪
        if globalData.userRunData.levelNum >= globalData.constantData.OPENLEVEL_PIGBANK then
            --如果是没钱推送
            if data:getPosType() and data:getPosType() == PushViewPosType.NoCoinsToSpin then
                local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
                if piggyBankData then
                    local price = tonumber(piggyBankData.p_price)
                    local valuePrice = tonumber(piggyBankData.p_valuePrice)
                    --显示的金币价格 大于等于实际购买的价格的2倍以上才弹出
                    if price and valuePrice and valuePrice >= price * 2 then
                        ret = true
                    end
                end
            else
                ret = true
            end
        end
    elseif viewType == PushViewType.MEMORYFLYING_PROMOTION then
        local retV, popupView = globalData.saleRunData:isNeedPushViewByRef(ACTIVITY_TYPE.MEMORY_FLYING, refName)
        if retV then
            ret = true
            if popupView ~= nil and popupView ~= "" then
                data.pathCsbName = popupView
            end
        end
    elseif viewType == PushViewType.SHOP_VIEW then
        -- 商城
        ret = true
    elseif viewType == PushViewType.NOSPINCOINS_BUY then
        --本地 没钱spin弹版
        ret = true
    elseif viewType == PushViewType.NOSPINCOINS_GIFT then
        --本地 没钱spin礼物
        ret = true
    elseif viewType == PushViewType.NOSPINCOINS_TRYPAY then
        --本地 没钱spin礼物，尝试性付费
        if not globalData.constantData or not globalData.constantData.TEST_PAY_LEVEL or globalData.userRunData.levelNum < globalData.constantData.TEST_PAY_LEVEL then --等级不足
            ret = false
        elseif not globalData.saleRunData:getAttemptData() then 
            --已经购买过
            ret = false
        else
            ret = true
        end
    end

    return ret
end

--是否满足等级需求
function PushViewControl:isSatisfyLevel(data)
    local curLevel = globalData.userRunData.levelNum
    if data and curLevel >= tonumber(data.leftLevel) and (tonumber(data.rightLevel) == -1 or curLevel < tonumber(data.rightLevel)) then
        return true
    end

    return false
end

--是否满足时间需求
function PushViewControl:isSatisfyTime(data)
    local popUpId = nil
    local refName = ""
    if data.getPopUpId and type(data.getPopUpId) == "function" then
        popUpId = data:getPopUpId()
        refName = data:getRefName()
    else
        popUpId = data.id
    end

    -- 判断CD
    local isCD_id = globalData.popCdData:isCoolDown(popUpId)
    local isCD_ref = true
    if refName ~= "" then
        isCD_ref = globalData.popCdData:isCoolDown(refName)
    end
    local isCD = (isCD_id and isCD_ref)
    if not isCD then
        return false
    end

    if tonumber(data.time) == -1 then
        return true
    end

    --获取当前时间
    local curTime = tonumber(globalData.userRunData.p_serverTime) / 1000
    -- local curTime = util_get_time()
    local time = self.m_dataTime[data.id]
    if time then
        local endTime = time + tonumber(data.time) * 60
        if endTime < curTime then
            self.m_dataTime[data.id] = curTime
            return true
        end
    else
        self.m_dataTime[data.id] = curTime
        return true
    end

    return false
end

-- 是否忽略弹板
function PushViewControl:isIgnorePop(posType, refName)
    if not posType or posType == "" then
        return false
    end
    if not refName or refName == "" then
        return false
    end

    local _array = self.m_ignoreArray[posType]
    if not _array or not _array[refName] then
        return false
    else
        return true
    end
end

-- 添加忽略
function PushViewControl:addIgnorePop(posType, refName)
    if not posType or posType == "" then
        return
    end
    if not refName or refName == "" then
        return
    end

    local _array = self.m_ignoreArray[posType]
    if not _array then
        self.m_ignoreArray[posType] = {}
    end

    self.m_ignoreArray[posType][refName] = true
end

-- 移除忽略
function PushViewControl:removeIgnorePop(posType, refName)
    if not posType or posType == "" then
        return
    end
    if not refName or refName == "" then
        return
    end

    if self:isIgnorePop(posType, refName) then
        self.m_ignoreArray[posType][refName] = false
    end
end

--获取满足条件的弹窗
function PushViewControl:getNeedShowData(posType)
    local needData = {}
    if not posType then
        return {}
    end

    if not globalData.hasPurchase and posType == PushViewPosType.NoCoinsToSpin then
        -- 非付费用户没钱走特殊逻辑
        local tempData = self:getNoSpinCoinsShowData(posType)
        if tempData then
            --没钱购买存在特殊逻辑
            -- return tempData
            needData = tempData
        end
    else
        --付费用户走正常配置
        local data = self:getDataForType(posType)
        for key, value in pairs(data) do
            if self:isSatisfyOpen(value) and self:isNotHaveThisActByRefName(needData, value:getRefName()) then
                needData[#needData + 1] = value
            end
        end
    end

    return needData
end

--根据类型获取弹窗数据
function PushViewControl:getDataForType(posType)
    return PopUpManager:getPopUpInfosByPos(posType)
end

--没钱弹窗逻辑不走后台
function PushViewControl:getNoSpinCoinsShowData(posType)
    local needData = {}

    --新手期只弹商店和常规促销
    if globalData.userRunData.levelNum <= globalData.constantData.NEW_USER_GUIDE_LEVEL then
        --如果没有开启常规促销 检测商店
        local data = self:getDataForType(PushViewPosType.NoCoinsToSpin)
        for key, value in pairs(data) do
            --检测商店
            if value:getPopType() == PushViewType.SHOP_VIEW then
                if self:isSatisfyOpen(value) then
                    if #needData == 1 then
                        --常规促销先放进去了
                        needData[2] = needData[1]
                        needData[1] = value
                    else
                        needData[1] = value
                    end
                end
            end

            --检测常规促销
            if value:getPopType() == PushViewType.ROUTINE_PROMOTION then
                if self:isSatisfyOpen(value) then
                    needData[#needData + 1] = value
                end
            end
        end

        return needData
    end

    -- self.m_noSpinCoinsPushCount = self.m_noSpinCoinsPushCount + 1
    -- gLobalDataManager:setNumberByField("NoSpinCoinsPushCount", self.m_noSpinCoinsPushCount)

    --添加前三次的常规促销逻辑
    -- if self.m_noSpinCoinsPushCount <= 3 then
        --尝试性付费
        local temp = self:getViewByTypeAndInType(PushViewPosType.NoCoinsToSpin, PushViewType.NOSPINCOINS_TRYPAY)
        if temp then
            needData[#needData + 1] = temp
        end
        local saleData = self:getNoSpinCoinsData(1)
        if saleData then
            needData[#needData + 1] = saleData
        end
    -- end
    --前三次走常规促销
    if #needData >= 1 then
        return needData
    end

    if globalData.slotRunData.machineData == nil then
        return nil
    end

    --检测bet索引
    local betIndex = -1
    local machineCurBetList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i = 1, #machineCurBetList do
        local betData = machineCurBetList[i]
        if betData.p_betId == globalData.slotRunData.iLastBetIdx then
            betIndex = i
            break
        end
    end
    --bet索引有误
    if betIndex == -1 then
        return nil
    end
    --test
    -- self:setNoSpinCoinsMinBetCount(0)

    if betIndex == 1 then
        --尝试性付费
        local temp = self:getViewByTypeAndInType(PushViewPosType.NoCoinsToSpin, PushViewType.NOSPINCOINS_TRYPAY)
        if temp then
            needData[#needData + 1] = temp
        end
        --弹购买
        -- local saleData = self:getNoSpinCoinsData(2)
        -- if saleData then
        --     needData[#needData + 1] = saleData
        -- end

        local freeCoins = self:getNoCoinsFree()
        if freeCoins then
            needData[#needData + 1] = freeCoins
        end
    else
        if self.m_noSpinCoinsMinBetCount > 0 then
            --尝试性付费
            local temp = self:getViewByTypeAndInType(PushViewPosType.NoCoinsToSpin, PushViewType.NOSPINCOINS_TRYPAY)
            if temp then
                needData[#needData + 1] = temp
            end
            --弹破冰促销
            local saleData = self:getNoSpinCoinsData(1)
            if saleData then
                needData[#needData + 1] = saleData
                self:setNoSpinCoinsMinBetCount(1)
            end
            local freeCoins = self:getNoCoinsFree()
            if freeCoins then
                needData[#needData + 1] = freeCoins
            end
        else
            --尝试性付费
            local temp = self:getViewByTypeAndInType(PushViewPosType.NoCoinsToSpin, PushViewType.NOSPINCOINS_TRYPAY)
            if temp then
                needData[#needData + 1] = temp
            end
            --弹购买
            -- local saleData = self:getNoSpinCoinsData(2)
            -- if saleData then
            --     needData[#needData + 1] = saleData
            -- end
            local freeCoins = self:getNoCoinsFree()
            if freeCoins then
                needData[#needData + 1] = freeCoins
            end
        end
    end
    --没有加检测到弹窗走付费流程
    if #needData > 0 then
        return needData
    else
        return nil
    end
end

function PushViewControl:checkTryPayView()
    if not globalData.constantData or not globalData.constantData.TEST_PAY_LEVEL or globalData.userRunData.levelNum < globalData.constantData.TEST_PAY_LEVEL then --等级不足
        return false
    end
    if not globalData.saleRunData:getAttemptData() then --已经购买过
        return false
    end
    local showState = gLobalDataManager:getNumberByField("TryPay_NOMoney_Show", 0)
    if showState == 0 then
        gLobalDataManager:setNumberByField("TryPay_NOMoney_Show", 1)
    else
        if globalData.saleRunData:isOnceBuyAttemps() then -- 首次膨胀之后付过费 不弹
            return false
        end
    end
    return true
end

--最小bet是否弹出过破冰促销
function PushViewControl:setNoSpinCoinsMinBetCount(count)
    if self.m_noSpinCoinsMinBetCount == count then
        return
    end
    self.m_noSpinCoinsMinBetCount = count
    gLobalDataManager:setNumberByField("NoSpinCoinsMinBetCount", self.m_noSpinCoinsPushCount)
end

function PushViewControl:getViewByTypeAndInType(posType, inType)
    local datas = PopUpManager:getPopUpInfoByPosAndType(posType, inType)

    for index = 1, #datas do
        local data = datas[index]
        if self:isSatisfyOpen(data) then
            return data
        end
    end

    return nil
end

--1.破冰促销 2.购买金币 3.赠送金币
function PushViewControl:getNoSpinCoinsData(type)
    --1.破冰促销
    if type == 1 then
        --检测常规促销
        local data = self:getDataForType(PushViewPosType.NoCoinsToSpin)
        for key, value in pairs(data) do
            if value:getPopType() == PushViewType.ROUTINE_PROMOTION then
                if self:isSatisfyOpen(value) then
                    return value
                end
            end
        end

        --如果没有开启常规促销 检测商店
        local data = self:getDataForType(PushViewPosType.NoCoinsToSpin)
        for key, value in pairs(data) do
            if value:getPopType() == PushViewType.SHOP_VIEW then
                if self:isSatisfyOpen(value) then
                    return value
                end
            end
        end
    end
    --2.购买金币
    if type == 2 then
        local data = PopupItemConfig:create()
        data.desc = "购买金币"
        data.leftLevel = 1
        data.rightLevel = -1
        data.time = -1
        data.type = PushViewType.NOSPINCOINS_BUY
        data.pos = PushViewPosType.NoCoinsToSpin
        data.zOrder = math.abs(PushViewType.NOSPINCOINS_BUY)
        data.zOrder1 = math.abs(PushViewType.NOSPINCOINS_BUY)
        return data
    end
    --3.赠送金币
    if type == 3 then
        local data = PopupItemConfig:create()
        data.desc = "赠送金币"
        data.leftLevel = 1
        data.rightLevel = -1
        data.time = -1
        data.type = PushViewType.NOSPINCOINS_GIFT
        data.pos = PushViewPosType.NoCoinsToSpin
        data.zOrder = math.abs(PushViewType.NOSPINCOINS_GIFT)
        data.zOrder1 = math.abs(PushViewType.NOSPINCOINS_GIFT)
        return data
    end
end

--显示弹框
function PushViewControl:showView(posType)
    --原来弹窗队列还在执行，就继续
    local queueCount = self.m_showQueue:getListCount()
    if queueCount > 0 then
        self:nextPushView()
        return
    end

    if posType == PushViewPosType.NoCoinsToSpin then
        gLobalViewManager:addLoadingAnima(true)
        gLobalSaleManager:requestNoCoinsSale(
            function(isOk)
                gLobalViewManager:removeLoadingAnima()
                if gLobalViewManager:isLobbyView() then
                    return
                end
                local data = self:getNeedShowData(posType)
                self:showViewLogic(data, posType)
            end
        )
    else
        local data = self:getNeedShowData(posType)
        self:showViewLogic(data, posType)
    end
end

function PushViewControl:showViewLogic(data, posType)
    if data == nil or #data <= 0 then
        self:nextPushView()
        return
    end

    data = PopUpManager:sortPopUpData(data, posType)

    --最多显示几个弹窗
    local maxCount = self:getShowViewCount(posType)

    --将需要显示的弹窗加入队列
    for i = 1, #data do
        if i <= maxCount then
            self.m_showQueue:push(data[i])
        end
    end
    self:nextPushView()
end

--获取最大弹版数量
function PushViewControl:getShowViewCount(posType)
    if posType and posType == PushViewPosType.NoCoinsToSpin then
        --没钱逻辑不走配置   why？？？？
        return 5
    end
    return globalData.constantData:getPushViewMaxCount(posType)
end

--获取付费位置
function PushViewControl:getPayPosition(posType)
    local ret = "Store"
    if posType == PushViewPosType.LoginToLobby then
        ret = "Login"
    end

    return ret
end

--添加支付打点
function PushViewControl:addIapLogInfo(posType, logData)
    if posType == nil then
        return
    end
    local entryOpen = "PushOpen"
    local entryName = nil
    if posType == PushViewPosType.LoginToLobby then
        entryName = "loginLobbyPush"
    elseif posType == PushViewPosType.LevelToLobby then
        entryName = "leaveGamePush"
    elseif posType == PushViewPosType.CloseStore then
        entryName = "closeStorePush"
    elseif posType == PushViewPosType.NoCoinsToSpin then
        entryName = "nocoinPush"
    end
    --优先读取传递过来的log
    if logData then
        if logData.entryOpen then
            entryOpen = logData.entryOpen
        end
        if logData.entryName then
            entryName = logData.entryName
        end
    end
    gLobalSendDataManager:getLogIap():setEnterOpen(entryOpen, entryName)
end

--设置弹窗队列结束回调
function PushViewControl:setEndCallBack(func)
    self.m_pushEndCallBack = func
end

--弹窗是否在执行队列
function PushViewControl:isPushingView()
    if self.m_curData then
        return true
    else
        return false
    end
end

--升级是否是首次触发
function PushViewControl:checkToDayFristLevelQuest()
    local isShow = false
    if G_GetMgr(ACTIVITY_REF.Quest):isNormalQuestGame() then
        return isShow
    end

    -- local unLockLevel = globalData.constantData.OPENLEVEL_NEWQUEST or 40
    -- local curLevel = globalData.userRunData.levelNum
    -- --级别不够
    -- if curLevel < unLockLevel then
    --     return isShow
    -- end

    -- -- --非升级大弹版不弹
    -- -- if curLevel%5~=0 then
    -- --     return
    -- -- end

    local lastToDayTimeStr = gLobalDataManager:getStringByField("ToDayLevelUpTime", "")
    local toDayTime = util_getymd_format()
    if lastToDayTimeStr == toDayTime then
        isShow = false
    else
        isShow = true
        gLobalDataManager:setStringByField("ToDayLevelUpTime", toDayTime)
    end
    return isShow
end

function PushViewControl:showLevelQuestView(overFunc)
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig then
        local data = PopUpManager:getPushViewDataByActivityId(questConfig.p_activityId)
        local themeName = questConfig:getThemeName()
        if data and themeName and themeName ~= "" then
            gLobalSendDataManager:getLogQuestActivity():sendQuestEntrySite("gameLevelUpPush")
            local luaFileName = "Activity/" .. themeName
            local uiView = util_createFindView(luaFileName, {name = data.pathCsbName, activityId = data.id, clickFlag = data.clickFlag})
            if uiView ~= nil then
                local enterType = globalData.slotRunData.machineData.p_levelName or "questLobby"
                gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
                uiView:setOverFunc(overFunc)
            else
                overFunc()
            end
        else
            overFunc()
        end
    else
        self:showLevelFantasyQuestView(overFunc)
    end
end

-- 新版Quest 梦幻Quest
function PushViewControl:showLevelFantasyQuestView(overFunc)
    local questActivity = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if questActivity then
        local data = PopUpManager:getPushViewDataByActivityId(questActivity.p_activityId)
        local themeName = questActivity:getThemeName()
        if data and themeName and themeName ~= "" then
            
            gLobalSendDataManager:getLogQuestNewActivity():sendQuestEntrySite("gameLevelUpPush")
            local luaFileName = "Activity/" .. themeName
            local uiView = util_createFindView(luaFileName, {name = data.pathCsbName, activityId = data.id, clickFlag = data.clickFlag})
            if uiView ~= nil then
                gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
                uiView:setOverFunc(overFunc)
            else
                overFunc()
            end
        else
            overFunc()
        end
    else
        overFunc()
    end
end



--大富翁
--升级是否是首次触发
function PushViewControl:checkToDayFristLevelRichMan()
    local isShow = false
    local unLockLevel = 20
    local curLevel = globalData.userRunData.levelNum
    --级别不够
    if curLevel < unLockLevel then
        return isShow
    end

    local richManFristIsLevelUp20 = gLobalDataManager:getBoolByField("RichManFristIsLevelUp20", false)
    if richManFristIsLevelUp20 then
        isShow = false
    else
        isShow = true
        gLobalDataManager:setBoolByField("RichManFristIsLevelUp20", true)
    end
    return isShow
end

-- 活动到达等级解锁
function PushViewControl:isActivityUnlock(activity_type)
    if not activity_type then
        return false
    end
    local activityData = G_GetActivityDataByRef(activity_type)
    if activityData and activityData:isRunning() then
        if globalData.userRunData.levelNum >= activityData.p_openLevel then
            -- 存储等级弹窗 适配多个活动 做成拼接字符串 例如 BlastFristIsLevelUp20
            local log_name = activity_type .. "FristIsLevelUp" .. activityData.p_openLevel
            local bl_unlock = gLobalDataManager:getBoolByField(log_name, false)
            if not bl_unlock then
                gLobalDataManager:setBoolByField(log_name, true)
                return true
            end
        end
    end
    return false
end

-- battlepass 是否首次弹出
function PushViewControl:checkToDayFristLevelBattlePass()
    local isShow = false
    local unLockLevel = globalData.constantData.BATTLEPASS_OPEN_LEVEL or 25
    local curLevel = globalData.userRunData.levelNum
    --级别不够
    if curLevel < unLockLevel then
        return isShow
    end

    local BattlePassFristIsLevelUp20 = gLobalDataManager:getBoolByField("BattlePassFristIsLevelUp20", false)
    if BattlePassFristIsLevelUp20 then
        isShow = false
    else
        isShow = true
        gLobalDataManager:setBoolByField("BattlePassFristIsLevelUp20", true)
    end
    return isShow
end

-- 有没有相同 引用名的 弹板
function PushViewControl:isNotHaveThisActByRefName(_filterTb, _refName)
    if not _filterTb or not _refName or #_refName <= 0 then
        return true
    end

    for key, value in pairs(_filterTb) do
        if value:getRefName() == _refName then
            return false
        end
    end

    return true
end

--[[
    @desc: 新手期ABTEST 第三版 A组用户检测是否能给免费金币
]]
function PushViewControl:getNoCoinsFree()
    if not globalData.GameConfig:checkUseNewNoviceFeatures() then
        return nil
    end
    --1. <= 等级限制
    if globalData.userRunData.levelNum > globalData.constantData.NOVICE_NOCOINS_OPEN_LEVEL then
        return nil
    end
    --高倍场不送钱
    if globalData.slotRunData.isDeluexeClub then
        return nil
    end

    local freeCoins = self:getNoSpinCoinsData(3)

    return freeCoins
end

return PushViewControl
