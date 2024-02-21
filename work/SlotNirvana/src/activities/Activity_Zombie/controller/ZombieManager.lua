-- 行尸走肉 控制类
local ZombieNet = require("activities.Activity_Zombie.net.ZombieNet")
local ZombieManager = class("ZombieManager", BaseActivityControl)

function ZombieManager:ctor()
    ZombieManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Zombie)
    self.ZomBieConfig = util_require("activities.Activity_Zombie.config.ZomBieConfig")

    self.m_ZombieNet = ZombieNet:getInstance()
    self:registerObserver()
end

function ZombieManager:getConfig()
    local data = self:getRunningData()
    if not data then
        return
    end
    return self.ZomBieConfig
end

--获取分镜步数
function ZombieManager:getGuideStep()
    local step = globalData.ZomBieBordData or 0
    return step
end

--存储分镜
function ZombieManager:setGuideStep(_step)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.ZomBieBord] = _step
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    globalData.ZomBieBordData = _step
end

function ZombieManager:sendZombieInfo()
    local activityData = self:getRunningData()
    if not activityData then
        return
    end
    local active = activityData:getActiveTimes()
    if not active or active == "0" then
        self:sendInfoReq(99)
    end
end

function ZombieManager:getBuffLeftTime()
    local BuffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_ZOMBIECONNECT_DOUBLE) -- 宝箱
    return BuffTimeLeft
end

function ZombieManager:getZomPause()
    local data = self:getRunningData()
    if not data then
        return 0
    end
    local time = data:getPauseExTime()
    local leftTime = 0
    if time ~= 0 then
        leftTime = math.ceil((time - globalData.userRunData.p_serverTime)/1000)
    end
    return leftTime
end

--当前状态
-- 0 今天未激活状态,1 激活等待状态
function ZombieManager:getZomStaues()
    local data = self:getRunningData()
    if not data then
        return 0 
    end
    local active = data:getActiveTimes()
    if not active or active == "0" then
        return 0
    end
    return self.m_ZomStatus or 1
end

function ZombieManager:setZomStatus(_flag)
    self.m_ZomStatus = _flag
end

--获取是有丧失阶段或者无丧尸阶段
function ZombieManager:getZomStage()
    local data = self:getRunningData()
    if not data then
        return 0
    end
    local type = 0
    local jieduan = self:getJieDuan()
    local times = data:getAttackTimes()
    local localtime = globalData.userRunData.p_serverTime
    local pausetime = data:getPauseExTime()
    if not pausetime then
        pausetime = 0
    elseif pausetime > 0 then
        pausetime = pausetime - localtime
    end
    local leftTime = 0
    if jieduan == 1 then
        type = 1
        leftTime = times[1] - localtime - pausetime
    elseif jieduan ~= 0 then
        local middletime = ((tonumber(times[jieduan]) - pausetime) + (tonumber(times[jieduan-1]) - pausetime))/2
        if localtime > middletime then
            type = 1
            leftTime = tonumber(times[jieduan]) - localtime - pausetime
        else
            type = 2
            leftTime = tonumber(times[#times]) - localtime - pausetime
        end
    end
    if leftTime ~= 0 then
        leftTime = math.floor(leftTime/1000)
    end
    return type ,leftTime     --1有丧失，2无丧尸
end

function ZombieManager:getJieDuan()
    local jieduan = 0
    local data = self:getRunningData()
    if not data then
        return jieduan
    end
    local localtime = globalData.userRunData.p_serverTime
    local times = data:getAttackTimes()
    local pausetime = data:getPauseExTime()
    if not pausetime then
        pausetime = 0
    elseif pausetime > 0 then
        pausetime = pausetime - localtime
    end
    for i,v in ipairs(times) do
        local tmp = tonumber(v) - pausetime
        if localtime < tmp then
            jieduan = i
            break
        end
        local moretiem = times[i+1] - pausetime
        if moretiem and localtime > tmp and localtime < tonumber(moretiem) then
            jieduan = i + 1
            break
        end
        if localtime > (tonumber(times[#times]) - pausetime) then
            jieduan = #times
            break
        end
    end
    return jieduan
end

function ZombieManager:getNeedArm(_flag)
    local data = self:getRunningData()
    if not data then
        return 0 
    end
    local arms = data:getNeedArms()
    local jieduan = self:getJieDuan()
    if _flag then
        local localtime = globalData.userRunData.p_serverTime
        local times = data:getAttackTimes()
        local pausetime = data:getPauseExTime()
        if not pausetime then
            pausetime = 0
        elseif pausetime > 0 then
            pausetime = pausetime - localtime
        end
        if localtime > (tonumber(times[#times]) - pausetime) then
            jieduan = #times
        else
            jieduan = jieduan - 1
        end
    end
    if jieduan == 0 then
        return 0
    end
    return arms[jieduan]
end

--损失的奖励
function ZombieManager:getLoseReward()
    local data = self:getRunningData()
    local jieduan = self:getJieDuan()
    if not data or jieduan <= 1 then
        return {}
    end
    local reward1 = data:getCurrentReward() --当前阶段的奖励
    local reward2 = data:getLoseReward() --上一阶段的奖励
    local lose = {}
    for i,v in ipairs(reward2) do
        local hold = 0
        for k=1,#reward1 do
            if v.p_id == reward1[k].p_id then
                hold = 1
            end
        end
        if hold == 0 then
            table.insert(lose,v)
        end
    end
    return lose
end

function ZombieManager:getLoseCoins()
    local data = self:getRunningData()
    if not data then
        return 0 
    end
    return data:getLoseCoins()
end

--是否结束 0 结束了 1 没有任何奖励了，直接进入结算,2 袭击结束，但是可以领奖励 3 袭击还没结束
function ZombieManager:getOnlinState()
    local status = self:getZomStaues()
    if status == 0 then
        return 0
    end
    local data = self:getRunningData()
    local times = data:getAttackTimes()
    local fileNums = data:getFileNums()
    if fileNums == #times then
        return 1
    end
    local result = data:getDefendResult()
    if #result == #times then
        return 2
    end
    return 3
end

--多少武器抵挡了多少波
function ZombieManager:getArracks()
    local data = self:getRunningData()
    local result = data:getDefendResult()
    local num = globalData.ZomBieLineData
    if not num then
        num = 0
    end
    local cishu = #result - num
    if cishu <= 0 then
        return 0,0
    end
    local attacks = data:getNeedArms()
    local loseack = 0
    if num == 0 then
        num = 1
    end
    local di_nums = 0
    local cover_num = 0
    for i=num,#result do
        local aks = attacks[i]
        local ru = result[i]
        if aks and ru.success then
            if ru.useProtectiveCover then
                cover_num = cover_num + 1
            else
                loseack = loseack + tonumber(aks)
            end
            di_nums = di_nums + 1
        end 
    end
    return di_nums,loseack,cover_num
end

--剩余多少时间领奖
function ZombieManager:getLeftAccTime()
    local data = self:getRunningData()
    if not data then
        return 0
    end
    local localtime = globalData.userRunData.p_serverTime   
    local times = data:getAttackTimes()
    local leftTime = 0
    local pausetime = data:getPauseExTime()
    if not pausetime then
        pausetime = 0
    elseif pausetime > 0 then
        pausetime = pausetime - localtime
    end
    if times and #times > 0 then
        leftTime = tonumber(times[#times]) - localtime - pausetime
        if leftTime ~= 0 then
            leftTime = math.floor(leftTime/1000)
        end
    end
    return leftTime
end

function ZombieManager:getLeftComming()
    local data = self:getRunningData()
    if not data then
        return 0
    end
    local jieduan = self:getJieDuan()
    local localtime = globalData.userRunData.p_serverTime
    local times = data:getAttackTimes()
    local time = times[jieduan]
    local leftTime = 0
    local pausetime = data:getPauseExTime()
    if not pausetime then
        pausetime = 0
    elseif pausetime > 0 then
        pausetime = pausetime - localtime
    end
    if time then
        leftTime = tonumber(time) - localtime - pausetime
        if leftTime ~= 0 then
            leftTime = math.floor(leftTime/1000)
        end
    end
    return leftTime
end

--后台弹板
function ZombieManager:checkZombieLogin(_flag)
    local status = self:getOnlinState()
    local view = nil
    if status == 1 then
        self:showAttackResultLayer()
        --self:sendRewardReq(999)
    elseif status == 2 then
        view = self:showOnLineLayer(_flag)
    elseif status == 3 then
        local attacks,nums = self:getArracks()
        if attacks ~= 0 then
            view = self:showOnLineLayer(_flag)
        end
    end
    return view
end

--离线
function ZombieManager:saveOnlinStatus(_flag)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.ZomBieLine] = _flag
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
    globalData.ZomBieLineData = _flag
end

function ZombieManager:setOnlineStep()
    local data = self:getRunningData()
    if not data then
        return 0
    end
    local attacks = data:getDefendResult()
    self:saveOnlinStatus(#attacks)
end

function ZombieManager:checkZombieReward()
    local data = self:getRunningData()
    if not data then
        return
    end
    local result = data:getDefendResult()
    local attacks = data:getAttackTimes()
    if #result == #attacks then
        local resultNum = data:getFileNums()
        if resultNum == #attacks then
            self:sendRewardReq(111)
        else
            self:showRewardLayer()
        end
    end
end

--获取活动最新数据
function ZombieManager:sendInfoReq(_type)
    local successFunc = function(_netData)
        if not self:getRunningData() then
            return
        end
        if _type then
            if _type == 99 then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SERVER_TIME_ZERO)
            elseif _type == 1 then
                self:setOnlineStep()
            elseif _type == 100 then
                --切后台回来
                self:updateComHouTai()
            end
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_SEND_SUCCESS,_type)
    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendInfoReq(successFunc,fileFunc)
end

--领奖
function ZombieManager:sendRewardReq(_flag)
    local successFunc = function(_netData)
        local gameData = self:getRunningData()
        if not gameData then
            return
        end
        self:saveOnlinStatus(0)
        if globalData.ZomBieBordData and globalData.ZomBieBordData == 6 then
            self:setGuideStep(5)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_REWARD_SUCCESS)
        if _flag then
            if _flag == 999 or _flag == 111 then
                local attack = gameData:getArms()
                local price = gameData:getArmsCoins()
                if price and price ~= "" and tonumber(price) > 0 then
                    self:showRcyCoinsLayer()
                end
                if _flag == 111 and gLobalViewManager:getCurSceneType() == 3 then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_GAME_OVER)
                end
            end
        end
        self:setSpinData(false)

    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendRewardReq(successFunc,fileFunc)
end
--领取回收金币
function ZombieManager:sendRcyCoinsReq()
    local successFunc = function(_netData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_CRY_COINS)
    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendRcyCoinsReq(successFunc,fileFunc)
end

--取消回收
function ZombieManager:sendCancelRecoverReq()
    local successFunc = function(_netData)
        if not self:getRunningData() then
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_RECOVER_CALCLE)
    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendCancelRecoverReq(successFunc,fileFunc)
end

--取消回收
function ZombieManager:sendBuySaleReq()
    local successFunc = function(_netData)
        if not self:getRunningData() then
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BUFF_REFRESH, {name = ACTIVITY_REF.Zombie})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_BUY_SUCCESS)
    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendBuySaleReq(successFunc,fileFunc)
end
--购买暂停时间
function ZombieManager:sendBuyTimeReq(_index)
    local successFunc = function(_netData)
        if not self:getRunningData() then
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_SALETIME_SUCCESS)
    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendBuyTimeReq(_index,successFunc,fileFunc)
end
--取消暂停
function ZombieManager:sendCoverTimeReq()
    local successFunc = function(_netData)
        if not self:getRunningData() then
            return
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_SALETIME_CANCLE)
    end
    local fileFunc = function()
        print("fileFunc")
    end
    self.m_ZombieNet:sendCoverTimeReq(successFunc,fileFunc)
end


--购买
function ZombieManager:buyGoods(_data)
    local data = self:getRunningData()
    if not data then
        return
    end
    local saleData = {key = _data.key,keyId = _data.keyId, price = _data.price}
    self:sendIapLog(saleData,"zombie1",1)
    gLobalSaleManager:purchaseActivityGoods(
        data.p_id,
        "ZomBie",
        BUY_TYPE.ZOMBIE_RECOVER_SALE,
        saleData.keyId,
        saleData.price,
        0,
        0,
        function()
            self:buySuccess()
        end,
        function()
        end
    )
end

function ZombieManager:buyArmsGoods(_data,_type)
    local data = self:getRunningData()
    if not data then
        return
    end
    local saleData = {key = _data.p_key,keyId = _data.p_keyId, price = _data.p_price}
    self:sendIapLog(saleData,_type,1)

    gLobalSaleManager:purchaseActivityGoods(
        data.p_id,
        _type,
        BUY_TYPE.ZOMBIE_ARMS_SALE,
        saleData.keyId,
        saleData.price,
        0,
        0,
        function()
            self:buySuccess(1,_type)
        end,
        function()
        end
    )
end

function ZombieManager:buySuccess(_flag,_type)
    if _flag then
        gLobalViewManager:checkBuyTipList(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_SALE_SUCCESS,_type)
        end)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_RECOVER_SALE)
    end
end

-- 客户端打点
function ZombieManager:sendIapLog(_goodsInfo,name,status)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "Zombie"
        goodsInfo.goodsId = _goodsInfo.key
        goodsInfo.goodsPrice = _goodsInfo.price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = name
        purchaseInfo.purchaseStatus = status

        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function ZombieManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return
    end
end
--分镜界面
function ZombieManager:showBordyLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieBordyUI") == nil then
        view = util_createView("ZomBieCode/ZomBieBordyUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--有无丧尸弹板
function ZombieManager:showBieInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieInfoUI") == nil then
        view = util_createView("ZomBieCode/ZomBieInfoUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--预警弹板
function ZombieManager:showComingLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieComingUI") == nil then
        view = util_createView("ZomBieCode/ZomBieComingUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--规则界面
function ZombieManager:showRuleLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieRuleUI") == nil then
        view = util_createView("ZomBieCode/ZomBieRuleUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--战斗界面
function ZombieManager:showAttackLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieArrtckUI") == nil then
        view = util_createView("ZomBieCode/ZomBieArrtckUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--战斗结果
function ZombieManager:showAttackResultLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieArrtckResultUI") == nil then
        view = util_createView("ZomBieCode/ZomBieArrtckResultUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--结算分镜
function ZombieManager:showAccountLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieAccountUI") == nil then
        view = util_createView("ZomBieCode/ZomBieAccountUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--领奖弹板
function ZombieManager:showRewardLayer(_flag)
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieRewardUI") == nil then
        view = util_createView("ZomBieCode/ZomBieRewardUI",_flag)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--武器回收动画弹板
function ZombieManager:showRecycleLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieRecycleUI") == nil then
        view = util_createView("ZomBieCode/ZomBieRecycleUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--武器回收弹板
function ZombieManager:showRcyArrackLayer(_flag)
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieRcyArrackUI") == nil then
        view = util_createView("ZomBieCode/ZomBieRcyArrackUI",_flag)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

function ZombieManager:showRcyCoinsLayer(_flag)
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieRcyCoinsUI") == nil then
        view = util_createView("ZomBieCode/ZomBieRcyCoinsUI",_flag)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--武器二次确认弹板
function ZombieManager:showSecondaryLayer(_flag)
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieSecondaryUI") == nil then
        view = util_createView("ZomBieCode/ZomBieSecondaryUI",_flag)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--再次上线弹板
function ZombieManager:showOnLineLayer(_flag)
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieOnLineUI") == nil then
        view = util_createView("ZomBieCode/ZomBieOnLineUI",_flag)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--再次上线弹板
function ZombieManager:showBuffLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("ZomBieCode/ZomBiePromotion")
    if view ~= nil then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end
--前置动画
function ZombieManager:showActionLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieActionUI") == nil then
        local view = util_createView("ZomBieCode/ZomBieActionUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

--补给占
function ZombieManager:showDepotLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieDepotUI") == nil then
        local view = util_createView("ZomBieCode/ZomBieDepotUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

function ZombieManager:showPauseShopLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBiePauseShopUI") == nil then
        local view = util_createView("ZomBieCode/ZomBiePauseShopUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

function ZombieManager:showCanclePauseLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomBieCoverTimeUI") == nil then
        local view = util_createView("ZomBieCode/ZomBieCoverTimeUI")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

function ZombieManager:showBuySuccessLayer(_flag,_item)
    if not self:isCanShowLayer() then
        return
    end
    local view = nil
    if gLobalViewManager:getViewByExtendData("ZomDepotSuccessUI") == nil then
        local view = util_createView("ZomBieCode/ZomDepotSuccessUI",_flag,_item)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI-1)
        end
    end
    return view
end

-- 左边条
function ZombieManager:getEntryModule()
    if self:isCanShowLayer() then
        return "ZomBieCode.Activity_ZombieEntryNode"
    end
    return ""
end

function ZombieManager:getYuJing()
    local data = self:getRunningData()
    if not data or #data:getDefendResult() == #data:getAttackTimes() then
        self:stopComing()
        return 0
    end
    local localtime = math.ceil(globalData.userRunData.p_serverTime/1000)
    local attacks = data:getAttackTimes()
    local status = 0
    local jieduan = self:getJieDuan()
    local big,small
    if jieduan == 1 then
       big = attacks[jieduan]
       small = 0
    else
        big = attacks[jieduan]
        small = attacks[jieduan-1]
    end
    if small and big then
        local middletime = math.floor((tonumber(big) + tonumber(small))/2000)
        local di_time = math.floor(tonumber(big)/1000)
        if localtime == middletime and jieduan ~= 1 then
            status = 1
        elseif localtime == di_time then
            self.m_bigTime = localtime + 2
        end
        if self.m_bigTime and localtime == self.m_bigTime then
            status = 2
            self.m_bigTime = 0
        end
        if localtime == di_time - 298 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_GAME_ACTION,1)
        elseif localtime == di_time - 180 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_GAME_ACTION,2)
        end
    elseif self.m_bigTime and self.m_bigTime ~= 0 then
        if self.m_bigTime and localtime == self.m_bigTime then
            status = 2
            self.m_bigTime = 0
        end
    end
    return status
end

--监听预警弹窗
function ZombieManager:updateComing()
    local data = self:getRunningData()
    if not data or #data:getDefendResult() == #data:getAttackTimes() then
        return
    end
    self:stopComing()
    self.checkComing = scheduler.scheduleGlobal(
        function()
            local pause = self:getZomPause()
            if pause > 0 then
                return
            end
            local status = self:getYuJing()
            if status == 1 then
                --丧尸预警
                if self:getSpinData() then
                    self.m_spinStatus = 1
                else
                    self:showComingLayer()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_COMING_SUCCESS)
                end
            elseif status == 2 then
                --丧尸来袭
                if self:getSpinData() then
                    self.m_spinStatus = 2
                else
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_TRACK)
                    self:showActionLayer()
                end
            end
        end,
        1
    )
end

function ZombieManager:stopComing()
    if self.checkComing ~= nil then
        scheduler.unscheduleGlobal(self.checkComing)
        self.checkComing = nil
    end
end

function ZombieManager:checkFirstComing()
    local data = self:getRunningData()
    if not data or #data:getAttackTimes() == 0 then
        return
    end
    local localtime = globalData.userRunData.p_serverTime
    local firstTime = data:getAttackTimes()[1]
    if localtime < tonumber(firstTime) then
        self:showComingLayer()
        self:updateComing()
    end
end

function ZombieManager:setSpinData(_flag)
    self.m_spin = _flag
end

function ZombieManager:getSpinData()
    return self.m_spin
end

function ZombieManager:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params[1] == true then
                -- spine 成功了数据
                local spinData = params[2]
                if spinData and spinData.result and spinData.result.selfData and table.nums(spinData.result.selfData) > 0 then
                    self:setSpinData(true)
                end
                if not spinData or not spinData.extend or not spinData.extend.zombie then
                    return
                end
                self:sendZombieInfo()
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

     gLobalNoticManager:addObserver(
        self,
        function(self, params) -- 更新赢钱动画
            if not params then
                return
            end
            self:checkView()
        end,
        "BET_ENABLE"
    )

     gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:checkView()
        end,
        ViewEventType.NOTIFY_ZOMBIE_FUN_OVER
    )
end

function ZombieManager:checkView()
    local st = self:getZomStaues()
    if st == 0 then
        self:setSpinData(false)
        return
    end
    if self:getSpinData() then
        if self.m_spinStatus and self.m_spinStatus == 1 then
            self:showComingLayer()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_COMING_SUCCESS)
        elseif self.m_spinStatus and self.m_spinStatus == 2 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_TRACK)
            self:showActionLayer()
        end
        self.m_spinStatus = 0
    end
    self:setSpinData(false)
end

--后台切回来，同步数据
function ZombieManager:commonForeGround()
    local data = self:getRunningData()
    if not data then
        return
    end
    self:sendInfoReq(100)
end

function ZombieManager:updateComHouTai()
    local data = self:getRunningData()
    local status = self:getZomStaues()
    if status == 0 then
        self:checkZombieLogin()
        return
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_HOUTAI)
    if gLobalViewManager:getCurSceneType() == 3 then
        local attacks = data:getAttackTimes()
        local localtime = math.ceil(globalData.userRunData.p_serverTime/1000)
        local jieduan = self:getJieDuan()
        local big,small
        if jieduan == 1 then
           big = attacks[jieduan]
           small = 0
        else
            big = attacks[jieduan]
            small = attacks[jieduan-1]
        end
        if big and small then
            local di_time = math.floor(tonumber(big)/1000)
            if localtime < (di_time - 298) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_GAME_ACTION,4)
            end
        end
        local stage = self:getZomStage()
        if stage == 1 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_COMING_SUCCESS)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ZOMBIE_GAME_ACTION,5)
        end
    end
end


return ZombieManager
