---
-- 处理游戏内的所有功能消息
-- FIX IOS 139
local NetWorkFeature = class("NetWorkFeature", require "network.NetWorkBase")

function NetWorkFeature:ctor()
    -- 消息等待列表
    self.m_waitingAction = {}
end

---
--商城奖励
function NetWorkFeature:sendActionShopBonus(rewardCoins, bLevelUp, time, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.ShopGiftCollect)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum + rewardCoins)
    actionData.data.balanceGems = 0

    actionData.data.levelup = bLevelUp

    actionData.data.exp = globalData.userRunData.currLevelExper
    actionData.data.level = globalData.userRunData.levelNum
    actionData.data.version = self:getVersionNum()
    actionData.data.rewardGems = 0
    actionData.data.addExp = 0

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

function NetWorkFeature:sendQueryShopConfig()
    local udid = globalData.userRunData.userUdid
    local queryConfigReq = GameProto_pb.ShopConfigQueryRequest()
    queryConfigReq.udid = udid
    -- local bodyData = queryConfigReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_SHOP_CONFIG -- 拼接url 地址
    local pbResponse = BaseProto_pb.ShopConfig()

    -- 发送消息
    local success_call_fun = function(shopConfig)
        -- httpSender:release()
        -- local shopConfig = BaseProto_pb.ShopConfig()
        -- local responseStr = self:parseResponseData(responseTable)
        -- shopConfig:ParseFromString(responseStr)

        -- 更新shopConfig
        globalData.syncShopConfig(shopConfig)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        -- httpSender:release()
        printInfo("xcyy :shopconfig返回失败 failed")
    end

    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime

    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, queryConfigReq, pbResponse, success_call_fun, faild_call_fun)
end

function NetWorkFeature:sendQuerySaleConfig(func)
    release_print("----------------sendQuerySaleConfig send")
    local udid = globalData.userRunData.userUdid
    local queryConfigReq = GameProto_pb.SaleConfigQueryRequest()
    queryConfigReq.udid = udid
    -- local bodyData = queryConfigReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_SALE_CONFIG -- 拼接url 地址
    local pbResponse = BaseProto_pb.SaleConfig()
    -- 发送消息
    local success_call_fun = function(saleConfig)
        release_print("----------------sendQuerySaleConfig success_call_fun")
        -- httpSender:release()
        -- local saleConfig = BaseProto_pb.SaleConfig()
        -- local responseStr = self:parseResponseData(responseTable)
        -- saleConfig:ParseFromString(responseStr)
        --先检测是否已经有开启的促销
        local isOpenSale = globalData.saleRunData:checkBaicsSale()
        --更新促销数据
        globalData.syncSaleConfig(saleConfig)
        --如果已经是开启状态不触发新的促销逻辑
        if isOpenSale then
            release_print("----------------sendQuerySaleConfig isOpenSale0 = true")
            if func then
                func(false)
            end
        else
            --如果没有开启判断本次更新后是否开启
            isOpenSale = globalData.saleRunData:checkBaicsSale()
            if isOpenSale then
                release_print("----------------sendQuerySaleConfig isOpenSale1 = true")
            else
                release_print("----------------sendQuerySaleConfig isOpenSale2 = false")
            end
            if func then
                func(isOpenSale)
            end
        end
    end
    local faild_call_fun = function(errorCode, errorData)
        release_print("----------------sendQuerySaleConfig faild_call_fun")
        -- 根据errorCode 做处理
        -- httpSender:release()
        printInfo("xcyy :saleConfig failed")
        if func then
            func(false)
        end
    end

    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, queryConfigReq, pbResponse, success_call_fun, faild_call_fun)
end

function NetWorkFeature:sendQueryMission()
    local udid = globalData.userRunData.userUdid
    local queryConfigReq = GameProto_pb.MissionQueryRequest()
    queryConfigReq.udid = udid
    -- local bodyData = queryConfigReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_DAILY_MISSION -- 拼接url 地址
    local pbResponse = BaseProto_pb.MissionConfig()
    -- 发送消息
    local success_call_fun = function(missionConfig)
        -- httpSender:release()
        -- local missionConfig = BaseProto_pb.MissionConfig()
        -- local responseStr = self:parseResponseData(responseTable)
        -- missionConfig:ParseFromString(responseStr)

        -- 更新missionConfig
        if missionConfig then
            globalData.syncMission(missionConfig)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TASKS_UI_UPDATE)
    end
    local faild_call_fun = function(errorCode, errorData)
        -- 根据errorCode 做处理
        -- httpSender:release()
        printInfo("xcyy :missionConfig返回失败 failed")
    end

    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime

    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, queryConfigReq, pbResponse, success_call_fun, faild_call_fun)
end

function NetWorkFeature:sendQueryRepeatWinConfig()
    local udid = globalData.userRunData.userUdid
    local queryConfigReq = GameProto_pb.repeatWinRequest()
    queryConfigReq.udid = udid
    -- local bodyData = queryConfigReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_REPEATWIN_CONFIG -- 拼接url 地址
    local pbResponse = BaseProto_pb.RepeatWinConfig()
    -- 发送消息
    local success_call_fun = function(repeatWinConfig)
        -- httpSender:release()
        -- local repeatWinConfig = BaseProto_pb.RepeatWinConfig()
        -- local responseStr = self:parseResponseData(responseTable)
        -- repeatWinConfig:ParseFromString(responseStr)
        -- globalData.saleRunData:parseRepeatWinConfig(repeatWinConfig)
        globalData.commonActivityData:parsePromotionData(repeatWinConfig, ACTIVITY_REF.RepartWin)

        -- local GameProto_pb = require "protobuf.BaseProto_pb"
        -- local featuresData = GameProto_pb.FeaturesData()
        -- local responseStr = self:parseResponseData(responseTable)
        -- featuresData:ParseFromString(responseStr)
        -- globalData.syncActivityConfig(featuresData)
    end
    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        printInfo("xcyy :shopconfig返回失败 failed")
    end
    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, queryConfigReq, pbResponse, success_call_fun, faild_call_fun)
end

-- 发送用户额外数据
function NetWorkFeature:sendActionUserExtra(extraData, successCallback, failedCallback)
    if not extraData or type(extraData) ~= "table" then
        return
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    actionData.data.extra = cjson.encode(extraData)

    self:sendMessageData(actionData, successCallback, failedCallback)
end

--每日登录
function NetWorkFeature:sendActionLoginReward(signInfo)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local extraData = {}
    extraData[ExtraType.signInfo] = {}
    extraData[ExtraType.signInfo].mySignInfo = signInfo
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, self.sendLoginRewardSuccess, self.sendLoginRewardFailed)
end

function NetWorkFeature:sendLoginRewardSuccess(redultData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_DIALY_BONUS, {true})
end

function NetWorkFeature:sendLoginRewardFailed(errorCode, errorData)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_DIALY_BONUS, {false})
end

-- 绑定邮箱奖励
function NetWorkFeature:sendActionEmailReward(_callFun, _callFunFail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.NewUserGuide)
    local params = {}
    params.newUserGuideAwardId = "EmailReward"
    actionData.data.params = json.encode(params)

    local success_call_fun = function(responseTable)
        release_print("EmailReward success_call_fun")
        _callFun(responseTable)
    end
    local faild_call_fun = function(errorCode, errorData)
        release_print("EmailReward faild_call_fun errorCode =" .. (errorCode or "isnil"))
        _callFunFail(errorCode, errorData)
    end
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end

---
--领取邮件奖励
function NetWorkFeature:sendActionGetMailReward(rewardCoins, rewardGems, id, type, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.GetMailReward)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum + rewardCoins)
    actionData.data.balanceGems = 0

    actionData.data.version = self:getVersionNum()
    actionData.data.rewardCoins = rewardCoins
    actionData.data.rewardGems = rewardGems
    actionData.data.exp = globalData.userRunData.currLevelExper

    local extraData = {}
    extraData.id = id
    extraData.type = type
    actionData.data.extra = cjson.encode(extraData)

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

----------------------------------InBox相关接口------------------------------
--        GET_UNREAL_MAIL = "/v1.1/mail/get",  -- 获取未读邮件
--        READ_MAIL = "/v1.1/mail/confirm",   -- 读取邮件 Classic未用
--        GET_MAIL_REWARD = "/v1.1/mail/read",  -- 获取邮件奖励
-- 发送查询邮件
function NetWorkFeature:SendQueryMail(successCallBack, failCallBack)
    if IS_LAN_LOGIN then
        return
    end

    self:updatePlatFormType()
    local mailRequest = ExtendProto_pb.MailFetchRequestV11()
    mailRequest.udid = globalData.userRunData.userUdid
    mailRequest.game = PRODUCTID
    mailRequest.platform = self.PlatFormType
    mailRequest.clientVersion = tostring(util_getUpdateVersionCode())
    mailRequest.versionCode = tostring(self:getVersionNum())

    local url = DATA_SEND_URL .. RUI_INFO.GET_UNREAL_MAIL -- 拼接url 地址
    local pbResponse = ExtendProto_pb.MailFetchResponse()

    local success_call_fun = function(mailFetchResponse)
        printInfo("xcyy : mailFetchResponse %d", #mailFetchResponse.data)
        local mailData = {}
        if #mailFetchResponse.data > 0 then
            for i = 1, #mailFetchResponse.data do
                if mailFetchResponse.data[i].id ~= 0 and mailFetchResponse.data[i].id ~= "0" then
                    table.insert(mailData, mailFetchResponse.data[i])
                end
            end
        end
        successCallBack(mailData)
    end
    local faild_call_fun = function(errorCode, errorData)
        printInfo("xcyy :mail failed data %s %s ", errorCode, errorData)
        -- 根据errorCode 做处理
        --返回失败回调
        failCallBack()
    end
    self:sendNetMsg(url, mailRequest, pbResponse, success_call_fun, faild_call_fun)
end

---- 领取邮件
-- @param mailData table 邮件table
function NetWorkFeature:SendMailCollect(mailId, sunccessFun, failedFun)
    --检查网络
    local mailInfo = {}
    mailInfo["mailIds"] = mailId
    local actionData = self:getSendActionData(ActionType.GetMailReward)
    actionData.data.extra = cjson.encode(mailInfo)
    local success_call_fun = function(responseTable, resData)
        --解析邮件buff
        if resData:HasField("result") == true then
            local result = resData.result
            local buff = cjson.decode(result)
            globalData.syncBuffs(buff)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MULEXP_END)
        end
        if sunccessFun ~= nil then
            sunccessFun()
        end
    end
    local faild_call_fun = function(errorCode, errorData)
        if failedFun ~= nil then
            failedFun()
        end
    end
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end

function NetWorkFeature:sendWatchViodeMessage(messageData, successCallBack, failCallBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actType = ActionType.AdRewardCollect
    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()

    local actionData = self:getSendActionData(actType)

    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.exp = globalData.userRunData.currLevelExper
    actionData.data.level = globalData.userRunData.levelNum
    actionData.data.vipLevel = globalData.userRunData.vipLevel
    actionData.data.vipPoint = globalData.userRunData.vipPoints
    actionData.data.version = self:getVersionNum()
    local extraData = {}
    extraData.id = messageData.id
    extraData.position = messageData.position
    extraData.type = messageData.type
    extraData.firstPlay = messageData.firstPlay
    actionData.data.extra = cjson.encode(extraData)

    if DEBUG >= 2 then
        printInfo("========   显示messageData的数据   ========")
        printInfo(actionData.action)
        printInfo(actionData.game)
        printInfo(actionData.platform)
        printInfo(actionData.data.balanceCoinsNew)
        printInfo(actionData.data.exp)
        printInfo(actionData.data.level)
        printInfo("----------" .. actionData.data.version)
        printInfo("========   显示messageData的数据  END   ========")
    end
    if successCallBack ~= nil then
        self:sendMessageData(actionData, successCallBack, failCallBack)
    else
        self:sendMessageData(actionData, self.sendWatchViodeSuccess, self.sendWatchViodeFailed)
    end
end

function NetWorkFeature:sendWatchViodeSuccess(resultData)
    local result = resultData.result
    if DEBUG == 2 then
        release_print(result)
        print(result)
    end

    if resultData:HasField("simpleUser") == true then
        globalData.syncSimpleUserInfo(resultData.simpleUser)
    end

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BAR)

    gLobalViewManager:removeLoadingAnima()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_WATCH_VIDEO_REWARD, {true})
end

function NetWorkFeature:sendWatchViodeFailed(errorCode, errorData)
    gLobalViewManager:removeLoadingAnima()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COLLECT_WATCH_VIDEO_REWARD, {false})
end

--更新任务进度
--@parma
function NetWorkFeature:sendMissionCompleted(extraInfo, rewardCoin)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()

    local actionData = self:getSendActionData(ActionType.MissionCompleted)

    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum + rewardCoin)
    actionData.data.balanceGems = 0

    actionData.data.rewardCoins = get_integer_string(rewardCoin) --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石

    actionData.data.version = self:getVersionNum()

    local extraData = {}
    extraData[ExtraType.questData] = extraInfo
    actionData.data.extra = cjson.encode(extraData)

    local success_call_fun = function(responseTable)
        self:sendMissionCompletedSuccess(responseTable, rewardCoin)
    end
    local faild_call_fun = function(errorCode, errorData)
        self:sendMissionCompletedFailed(errorCode, errorData)
    end

    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end

---更新任务成功
function NetWorkFeature:sendMissionCompletedSuccess(redultData, addCoin)
    gLobalViewManager:removeLoadingAnima()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MISSION_COMPLETED, {true, addCoin})
end

--更细任务失败
function NetWorkFeature:sendMissionCompletedFailed(errorCode, errorData)
    gLobalViewManager:removeLoadingAnima()
    gLobalViewManager:showReConnect()
end

--保存新手任务
function NetWorkFeature:sendNewbieTaskUpdate(extraInfo)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.MissionUpdate)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local extraData = {}
    extraData[ExtraType.newbieTask] = extraInfo
    actionData.data.extra = cjson.encode(extraData)
    local success_call_fun = function(responseTable)
    end
    local faild_call_fun = function(errorCode, errorData)
    end
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end
--保存新手任务奖励
function NetWorkFeature:sendNewbieTaskReward(extraInfo, functionOk, functionFail)
    if not extraInfo then
        return
    end
    local extraData = {}
    extraData[ExtraType.newbieTask] = extraInfo
    local strExtraData = cjson.encode(extraData)
    if extraInfo.index and globalNewbieTaskManager.getRewardId then
        local rewardId = globalNewbieTaskManager:getRewardId(extraInfo.index)
        self:sendSystemReward(rewardId, strExtraData, functionOk, functionFail)
    end
end

--保存首次进入关卡时间
function NetWorkFeature:sendCustTimeUpdate(extraInfo)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)

    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0

    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石

    actionData.data.version = self:getVersionNum()

    local extraData = {}
    extraData[ExtraType.custTime] = extraInfo
    actionData.data.extra = cjson.encode(extraData)
    local success_call_fun = function(responseTable)
        release_print("sendCustTimeUpdate success_call_fun")
    end
    local faild_call_fun = function(errorCode, errorData)
        -- release_print("sendCustTimeUpdate faild_call_fun errorCode ="..(errorCode or "isnil"))
    end
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end

--保存新手引导进度
function NetWorkFeature:sendNoviceGuideFinishListUpdate(extraInfo, success_callback, faild_callback)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)

    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0

    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石

    actionData.data.version = self:getVersionNum()

    local extraData = {}
    extraData[ExtraType.NoviceGuideFinishList] = extraInfo
    actionData.data.extra = cjson.encode(extraData)
    local success_call_fun = function(responseTable)
        if success_callback then
            success_callback()
        end
        release_print("sendNoviceGuideFinishListUpdate success_call_fun")
    end
    local faild_call_fun = function(errorCode, errorData)
        if faild_callback then
            faild_callback()
        end
        -- release_print("sendNoviceGuideFinishListUpdate faild_call_fun errorCode ="..(errorCode or "isnil"))
    end
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end

--保存关卡内测试数据
function NetWorkFeature:sendCustDebugUpdate(extraInfo)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)

    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0

    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石

    actionData.data.version = self:getVersionNum()

    local extraData = {}
    extraData[ExtraType.custDebugData] = extraInfo
    actionData.data.extra = cjson.encode(extraData)
    local success_call_fun = function(responseTable)
        release_print("sendCustDebugUpdate success_call_fun")
    end
    local faild_call_fun = function(errorCode, errorData)
        -- release_print("sendCustDebugUpdate faild_call_fun errorCode ="..(errorCode or "isnil"))
    end
    self:sendMessageData(actionData, success_call_fun, faild_call_fun)
end

-- 小猪银行booster活动  发送选择的buffType  buffID:buffID
function NetWorkFeature:sendPiggyBankBoosterChooseBuff(buffID, callFun)
    -- if gLobalSendDataManager:isLogin() == false then
    --     return
    -- end
    -- -- 开启等待 --
    -- gLobalViewManager:addLoadingAnima()
    -- local successCallFun = function(responseTable)
    --     if callFun ~= nil then
    --         callFun(responseTable)
    --     end
    --     gLobalViewManager:removeLoadingAnima()
    -- end
    -- local failedCallFun = function()
    --     gLobalViewManager:showReConnect()
    -- end
    -- local actionData = self:getSendActionData(ActionType.ChooseBooster)
    -- local extraData = {}
    -- extraData.booster = {buffId = buffID}
    -- actionData.data.extra = json.encode(extraData)
    -- self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--quest活动，获取关卡难度+奖励
function NetWorkFeature:sendActionQuestPhaseReward()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima(true)
    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.QuestPhaseReward)
    local params = {}
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        params["phase"] = questConfig:getPhaseIdx()
        actionData.data.params = json.encode(params)
    end

    self:sendMessageData(actionData, self.questPhaseRewardSuccessCallFun, failedCallFun)
end

--- 成功回调
function NetWorkFeature:questPhaseRewardSuccessCallFun(resultData)
    if resultData.result ~= nil then
        local rewardData = cjson.decode(resultData.result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_PHASEREWARD, rewardData)
    end
    gLobalViewManager:removeLoadingAnima()
end

--quest活动，选择难度
function NetWorkFeature:sendActionQuestSelectDifficulty(difficulty, func)
    if gLobalSendDataManager:isLogin() == false then
        if func then
            func(true)
        end
        return
    end

    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target, result)
        -- TODO:解析轮盘真实数据
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_DIFFICULTY)
        gLobalViewManager:removeLoadingAnima()
        if func then
            func(true)
        end

        -- 选择难度成功，重新请求排行版数据
        self:sendActionQuestRank()
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
        if func then
            func(false)
        end
    end

    local actionData = self:getSendActionData(ActionType.QuestChooseDifficulty)
    local params = {}
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        params["phase"] = questConfig:getPhaseIdx()
        params["difficulty"] = difficulty
        actionData.data.params = json.encode(params)
    end

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--quest活动，切换下一个关卡
function NetWorkFeature:sendActionQuestUseItemSkipStage()
    if gLobalSendDataManager:isLogin() == false then
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_SkIP_STAGE_BY_ITEM, false)
        return
    end

    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_SkIP_STAGE_BY_ITEM, true)
    end

    local failedCallFun = function(target, code, desc)
        if DEBUG == 2 then
            local view =
                gLobalViewManager:showDialog(
                "Dialog/MaintainLayer.csb",
                function()
                    gLobalViewManager:showReConnect()
                end
            )
            view:updateContentTipUI("lb_text", "code = " .. code .. "    " .. "desc = " .. desc)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_SkIP_STAGE_BY_ITEM, false)
    end

    local actionData = self:getSendActionData(ActionType.QuestCostSkipItem)
    actionData.data.params = json.encode({})
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--quest活动，切换下一个关卡
function NetWorkFeature:sendActionQuestNextStage(msg_type)
    if gLobalSendDataManager:isLogin() == false then
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE, false)
        return
    end

    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target,resultData)
        if resultData.result ~= nil and resultData.result ~= "" then
            local wheelResulData = cjson.decode(resultData.result)
            local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getData()
            if quest_data then
                quest_data:setWheelResultData(wheelResulData)
            end
        end
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE, true)
    end

    local failedCallFun = function(target, code, desc)
        if DEBUG == 2 then
            local view =
                gLobalViewManager:showDialog(
                "Dialog/MaintainLayer.csb",
                function()
                    gLobalViewManager:showReConnect()
                end
            )
            view:updateContentTipUI("lb_text", "code = " .. code .. "    " .. "desc = " .. desc)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE, false)
    end

    local actionData = self:getSendActionData(ActionType.QuestNextStage)
    local quest_data = G_GetMgr(ACTIVITY_REF.Quest):getData()
    if quest_data ~= nil then
        local params = {}
        params["phase"] = quest_data:getPhaseIdx()
        params["stage"] = quest_data:getStageIdx()
        if msg_type then
            params["type"] = msg_type
        end
        actionData.data.params = json.encode(params)

        quest_data:recordLastBoxData()
    end
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--quest活动，切换下一个关卡
function NetWorkFeature:sendActionQuestNewUserNextStage()
    if gLobalSendDataManager:isLogin() == false then
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE, false)

        return
    end
    gLobalViewManager:addLoadingAnimaDelay()
    local successCallFun = function()
        -- 跳转到下一个关卡
        local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getData()
        if questConfig and questConfig:isNewUserQuest() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE, true)
        end
        gLobalViewManager:removeLoadingAnima()
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE, false)
    end

    local actionData = self:getSendActionData(ActionType.NewUserQuestNextStage)
    local params = {}
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        params["phase"] = questConfig:getPhaseIdx()
        params["stage"] = questConfig:getStageIdx()
        actionData.data.params = json.encode(params)
        questConfig.m_lastBoxData = questConfig:getPhaseReward()
        questConfig.m_lastBoxJackpot = questConfig.p_questJackpot
    end

    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--quest活动，获取排行榜信息
function NetWorkFeature:sendActionQuestRank()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- gLobalViewManager:addLoadingAnima()
    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.QuestRank)
    local params = {}
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        params["phase"] = questConfig:getPhaseIdx()
    else
        params["phase"] = -1
    end
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, self.questRankSuccessCallFun, failedCallFun)
end

--- 成功回调
function NetWorkFeature:questRankSuccessCallFun(resultData)
    if resultData.result ~= nil then
        local rankData = cjson.decode(resultData.result)
        -- 此处临时修改，消息结构优化时应该把整个successCallFun由上层传入
        local questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
        if questData then
            questData:parseQuestRankConfig(rankData)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Quest})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_RANK, rankData)
    end
    gLobalViewManager:removeLoadingAnima()
end

--请求更新活动数据
function NetWorkFeature:sendActivityConfig(callback, isLoadingAnima)
    local udid = globalData.userRunData.userUdid
    local queryConfigReq = GameProto_pb.SaleConfigQueryRequest()
    queryConfigReq.udid = udid

    -- local bodyData = queryConfigReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_ACTIVITY_CONFIG -- 拼接url 地址
    local pbResponse = BaseProto_pb.FeaturesData()

    if isLoadingAnima == nil then
        isLoadingAnima = true
    end

    -- 发送消息
    if isLoadingAnima then
        gLobalViewManager:addLoadingAnima()
    end
    local success_call_fun = function(featuresData)
        -- httpSender:release()
        -- local featuresData = BaseProto_pb.FeaturesData()
        -- local responseStr = self:parseResponseData(responseTable)
        -- featuresData:ParseFromString(responseStr)

        globalData.syncActivityConfig(featuresData)
        gLobalNoticManager:postNotification(ViewEventType.UPDATE_ACTIVITY_CONFIG_FINISH)

        gLobalViewManager:removeLoadingAnima()
        if callback then
            callback(true)
        end
    end

    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        if callback then
            callback(false)
        end
        -- gLobalViewManager:showReConnect()
    end

    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, queryConfigReq, pbResponse, success_call_fun, faild_call_fun)
end

--请求更新活动数据
function NetWorkFeature:sendRefreshDrawTask()
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.UPDATE_ACTIVITY_CONFIG_FINISH)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_GAMEBOTTOM_BUFF)
    end
    local failedCallFun = function(errorCode, errorData)
        -- gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.DrawRefreshTask)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--保存firebase token
function NetWorkFeature:sendSaveFirebaseToken()
    local firebaseToken = globalFireBaseManager:getFireBaseToken()
    if not firebaseToken or firebaseToken == "" then
        return
    end
    if DEBUG == 2 then
        release_print("firebaseToken = " .. firebaseToken)
    end
    local udid = globalData.userRunData.userUdid
    local firebaseTokenRequest = GameProto_pb.FirebaseTokeRequest()
    firebaseTokenRequest.udid = udid
    firebaseTokenRequest.token = firebaseToken
    -- local bodyData = firebaseTokenRequest:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.FIREBASE_TOKEN_SAVE -- 拼接url 地址
    -- 发送消息
    local success_call_fun = function(responseTable)
        -- httpSender:release()
    end

    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
    end
    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, firebaseTokenRequest, nil, success_call_fun, faild_call_fun)
end

--没钱促销请求
function NetWorkFeature:sendNoCoinsSale(succFunc, failFunc)
    -- local isATest = globalData.GameConfig:checkABtestGroupA("NoCoinsSaleV2")
    -- --是否请求新的破产促销
    -- local isRequestNewSale = false
    -- local mgr = G_GetMgr(ACTIVITY_REF.BrokenSale)
    -- if not mgr:isInColdCD() and isATest and not isTestB then
    --     isRequestNewSale = true
    -- end

    local udid = globalData.userRunData.userUdid
    local commonQueryRequest = GameProto_pb.CommonQueryRequest()
    commonQueryRequest.udid = udid
    -- local bodyData = commonQueryRequest:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. (isRequestNewSale and RUI_INFO.NOCOINS2_SALE_CONFIG or RUI_INFO.NOCOINS_SALE_CONFIG) -- 拼接url 地址
    local pbResponse = BaseProto_pb.SaleItemConfig()
    -- 发送消息
    local success_call_fun = function(pbResponse)
        -- httpSender:release()
        -- if isRequestNewSale then
        --     if responseTable == "" then
        --         httpSender:release()
        --         self:sendNoCoinsSale(func,true)
        --         return
        --     end
        --     local bankruptcySaleResponse = GameProto_pb.BankruptcySaleResponse()
        --     local responseStr = self:parseResponseData(responseTable)
        --     bankruptcySaleResponse:ParseFromString(responseStr)
        --     globalData.commonActivityData:syncNoCoinsConfigV2(bankruptcySaleResponse)
        -- else
        -- local pbResponse = BaseProto_pb.SaleItemConfig()
        -- local responseStr = self:parseResponseData(responseTable)
        -- pbResponse:ParseFromString(responseStr)
        globalData.commonActivityData:syncNoCoinsConfig(pbResponse)
        -- end

        if succFunc then
            succFunc()
        end
    end

    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        if failFunc then
            failFunc()
        end
    end
    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, commonQueryRequest, pbResponse, success_call_fun, faild_call_fun)
end

--破产促销请求
function NetWorkFeature:sendBankruptSale(succFunc, failFunc)
    local udid = globalData.userRunData.userUdid
    local commonQueryRequest = GameProto_pb.CommonQueryRequest()
    commonQueryRequest.udid = udid
    local bodyData = commonQueryRequest:SerializeToString()
    local httpSender = xcyy.HttpSender:createSender()
    -- 拼接url 地址
    local url = DATA_SEND_URL .. RUI_INFO.NOCOINS2_SALE_CONFIG
    -- 发送消息
    local success_call_fun = function(responseTable)
        httpSender:release()

        local bankruptcySaleResponse = GameProto_pb.BankruptcySaleResponse()
        local responseStr = self:parseResponseData(responseTable)
        bankruptcySaleResponse:ParseFromString(responseStr)
        globalData.commonActivityData:syncNoCoinsConfigV2(bankruptcySaleResponse)

        if succFunc then
            succFunc()
        end
    end

    local faild_call_fun = function(errorCode, errorData)
        httpSender:release()
        if failFunc then
            failFunc()
        end
    end
    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
end

--每日登录
function NetWorkFeature:sendRateUsData(rateUsData)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function(responseTable)
    end
    local failedCallFun = function()
    end
    local actionData = self:getSendActionData(ActionType.SyncUserExtra)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local extraData = {}
    extraData[ExtraType.rateUsData] = rateUsData
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--spin没钱赠送
function NetWorkFeature:sendNoSpinCoinsGift(game, rewardCoins, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.NoCoinsAward, game)
    local params = {clientCoins = rewardCoins}
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--推送
function NetWorkFeature:sendNotifyReward(code, type, succFunc, failFunc)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function(self, resData)
        if resData:HasField("result") == true then
            local result = resData.result
            -- "{"coins":300000,"result":"SUCCESS","totalCoins":750000,"vipMultiple":"2.5"}"
            local rewardData = cjson.decode(result)
            if rewardData then
                if rewardData.result == "SUCCESS" then
                    if succFunc then
                        succFunc(rewardData)
                    end
                else
                    if failFunc then
                        failFunc(rewardData.result)
                    end
                end
                return
            end
        end
        if failFunc then
            failFunc()
        end
    end

    local failedCallFun = function(self, code)
        if failFunc then
            failFunc(code)
        end
    end

    local actionData = self:getSendActionData(ActionType.PushGiftCollect)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local paramsData = {}
    paramsData.code = code
    paramsData.type = type
    actionData.data.params = cjson.encode(paramsData)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

function NetWorkFeature:sendActionLevelDashPlay()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local failedCallFun = function(_a, _b, _c)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    gLobalViewManager:addLoadingAnima()
    local actionData = self:getSendActionData(ActionType.LevelDashPlay)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, self.levelDashPlaySuccessCallFun, failedCallFun)
end

function NetWorkFeature:levelDashPlaySuccessCallFun(resultData)
    if resultData.result ~= nil then
        local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
        if levelDashData and levelDashData:getIsExist() == true then
            levelDashData:initPokerData(resultData.result)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_DASH_POKER_START)
        end
    end
    gLobalViewManager:removeLoadingAnima()
end

function NetWorkFeature:sendActionLevelDashCollect(type)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local failedCallFun = function(_a, _b, _c)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end
    gLobalViewManager:addLoadingAnima()
    local actionData = self:getSendActionData(ActionType.LevelDashCollectCoins)
    local params = {}
    params.levelDashType = type
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, self.levelDashCollectSuccessCallFun, failedCallFun)
end

function NetWorkFeature:levelDashCollectSuccessCallFun(resultData)
    if resultData.result ~= nil then
        local levelDashData = G_GetActivityDataByRef(ACTIVITY_REF.LevelDash)
        levelDashData:initPokerData(resultData.result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_DASH_CONNECT)
    end
    gLobalViewManager:removeLoadingAnima()
end

function NetWorkFeature:sendLuckyStampCollectCoins(callBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local function successCallFun(self, resData)
        if resData:HasField("simpleUser") == true then
            globalData.syncSimpleUserInfo(resData.simpleUser)
        end
        -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,globalData.userRunData.coinNum)

        if resData:HasField("result") == true then
            local result = cjson.decode(resData.result)
            if result then
                if result.luckyStampConfig then
                    globalData.syncLuckyStampData(result.luckyStampConfig)
                end
                if callBack then
                    callBack(true)
                end
            else
                if callBack then
                    callBack(false)
                end
            end
        else
            if callBack then
                callBack(false)
            end
        end
    end

    local function failedCallFun(self, code)
        if callBack ~= nil then
            callBack(false)
        end
    end

    local actionData = self:getSendActionData(ActionType.LuckyStampCollectCoins, "")
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- quest活动：轮盘点击spin
function NetWorkFeature:sendActionQuestWheelSpin(success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()

        if success then
            success(resData)
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.QuestWheelCollect)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- quest活动：排行榜消耗星星领取
function NetWorkFeature:sendActionQuestRankStarCollect(index, callBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(true, resData)
        end
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(false)
        end
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.QuestRankPointsRewardCollect)
    local params = {}
    params.index = index
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end
--spinbonus 收集
function NetWorkFeature:sendSpinBonusCollect(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.SpinBonusCollect, "SpinBonusCollect")
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local params = {}
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--获得系统奖励 rewardId奖励id
function NetWorkFeature:sendSystemReward(rewardId, strExtraData, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionType = ActionType.NewUserGuide
    local params = {}
    if rewardId == "NewUserProtectReward" then
        actionType = ActionType.NewUserProtectReward
    else
        params.newUserGuideAwardId = rewardId
    end
    local actionData = self:getSendActionData(actionType)
    actionData.data.params = json.encode(params)
    if strExtraData then
        actionData.data.extra = strExtraData
    end
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--开启debug打印
function NetWorkFeature:sendOpenDebugCode(code, funcSuccess, funcFaild)
    local udid = globalData.userRunData.userUdid
    local spinDebugReq = GameProto_pb.SpinDebugRequest()
    spinDebugReq.udid = udid
    spinDebugReq.op = code
    -- local bodyData = spinDebugReq:SerializeToString()
    -- local httpSender = xcyy.HttpSender:createSender()
    local url = DATA_SEND_URL .. RUI_INFO.DEBUG_CODE_REQUEST -- 拼接url 地址
    local pbResponse = BaseProto_pb.Response()
    -- 发送消息
    local success_call_fun = function(responseData)
        -- local responseData = BaseProto_pb.Response()
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseData:ParseFromString(responseStr)
        if responseData:HasField("code") == true then
            local successCode = responseData.code
            if successCode == 1 then
                if funcSuccess then
                    funcSuccess()
                end
            else
                if funcFaild then
                    funcFaild()
                end
            end
        end
        -- httpSender:release()
    end
    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        if funcFaild then
            funcFaild()
        end
    end
    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, spinDebugReq, pbResponse, success_call_fun, faild_call_fun)
end

-- 评分系统发送数据给服务器 type 0 是请求金币数 1 是评价完之后加金币 3 仅仅评论 不加任何
function NetWorkFeature:sendActionUserComment(textStr, type, version, score, callBack)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    -- gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target, resData)
        -- gLobalViewManager:removeLoadingAnima()
        local coins = 0
        if resData:HasField("result") then
            local result = cjson.decode(resData.result)
            coins = result.coins
        end
        if callBack then
            callBack(true, coins)
        end
    end
    local failedCallFun = function()
        -- gLobalViewManager:removeLoadingAnima()
        if callBack then
            callBack(false)
        end
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.UserComment)
    local params = {}
    params.comment = textStr
    params.type = type
    params.version = version
    params.score = score
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 第二条任务线pick小游戏
function NetWorkFeature:sendPickRequest(status, rewardId, success, fail, isLoadingDelay)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    if self.m_waitingAction["" .. ActionType.LuckyChallengePickBoxPlay] then
        return
    end
    self.m_waitingAction["" .. ActionType.LuckyChallengePickBoxPlay] = true

    if not isLoadingDelay then
        gLobalViewManager:addLoadingAnima()
    end

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        -- resData
        local result = util_cjsonDecode(resData.result)
        if result then
            globalData.syncLuckyChallengeData(result)
        else
            release_print("cjson----------" .. resData.result)
        end
        if success then
            success(resData)
        end

        self.m_waitingAction["" .. ActionType.LuckyChallengePickBoxPlay] = false
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end

        self.m_waitingAction["" .. ActionType.LuckyChallengePickBoxPlay] = false
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengePickBoxPlay)
    local extra = {}
    extra = {type = status, rewardId = rewardId}
    actionData.data.extra = json.encode(extra)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 第二条任务线dice小游戏
function NetWorkFeature:sendDiceRequest(status, rewardId, success, fail, isLoadingDelay)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    if not isLoadingDelay then
        gLobalViewManager:addLoadingAnima()
    end

    if self.m_waitingAction["" .. ActionType.LuckyChallengeDicePlay] then
        return
    end
    self.m_waitingAction["" .. ActionType.LuckyChallengeDicePlay] = true

    local successCallFun = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        -- resData
        local result = util_cjsonDecode(resData.result)
        if result then
            globalData.syncLuckyChallengeData(result)
        end
        if success then
            success(resData)
        end
        self.m_waitingAction["" .. ActionType.LuckyChallengeDicePlay] = false
    end
    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        if fail then
            fail()
        end
        self.m_waitingAction["" .. ActionType.LuckyChallengeDicePlay] = false
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.LuckyChallengeDicePlay)
    local extra = {}
    extra = {type = status, rewardId = rewardId}
    actionData.data.extra = json.encode(extra)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

function NetWorkFeature:sendActionLCTaskInfo(callback)
    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.LuckyChallenge):getRunningData()
    if not luckyChallengeData then
        if callback then
            callback()
        end
        return
    end

    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- gLobalViewManager:addLoadingAnima()
    local successCallFun = function(target, resData)
        local result = nil
        if resData:HasField("result") == true then
            result = util_cjsonDecode(resData.result)
        end
        -- gLobalViewManager:removeLoadingAnima()
        if globalData.syncLuckyChallengeData then
            globalData.syncLuckyChallengeData(result)
        end
        if callback then
            callback(true)
        end
    end

    local failedCallFun = function()
        -- gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        if callback then
            callback(false)
        end
    end
    local actionData = self:getSendActionData(ActionType.LuckyChallengeTaskInfo)
    local extraData = {}
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

function NetWorkFeature:sendActionRichManPlay(isMonster, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData
    if isMonster then
        actionData = self:getSendActionData(ActionType.RichMonsterPlay)
    else
        actionData = self:getSendActionData(ActionType.RichPlay)
    end
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 大富翁 消耗钻石购买锁定打狼额外奖励消息
function NetWorkFeature:sendActionRichManTimeFreeze(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.RichUseGems)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- blast活动 翻牌
function NetWorkFeature:sendActionBlastPick(idx, successCallFun, failedCallFun, _flag)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local type = ActionType.BlastPickBox
    if _flag then
        type = ActionType.NewUserBlastPickBox
    end
    local actionData = self:getSendActionData(type)

    local params = {index = idx}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-----------------------------------------------------------------------------------------------------
-- FB好友页签 请求邮件列表 FriendGiftMails
function NetWorkFeature:FBInbox_requestFBMailList(success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    if self.m_waitingAction["" .. ActionType.FriendGiftMails] then
        return
    end
    self.m_waitingAction["" .. ActionType.FriendGiftMails] = true

    local successFunc = function(target, resData)
        local result = nil
        if resData:HasField("result") == true then
            result = cjson.decode(resData.result)
        end
        if success then
            success(result)
        end

        self.m_waitingAction["" .. ActionType.FriendGiftMails] = false
    end
    local failFunc = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
        if fail then
            fail()
        end

        self.m_waitingAction["" .. ActionType.FriendGiftMails] = false
    end
    local actionData = self:getSendActionData(ActionType.FriendGiftMails)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failFunc)
end

-- FB好友页签 收集邮件 一键领取 FriendCollectGiftMail
function NetWorkFeature:FBInbox_collectFBMail(extraData, success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local successFunc = function(target, resData)
        if success then
            success(resData)
        end
    end
    local failFunc = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
        if fail then
            fail()
        end
    end
    local actionData = self:getSendActionData(ActionType.FriendCollectGiftMail)
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, successFunc, failFunc)
end

-- -- FB发送页签 发送邮件 FriendSendGiftMail
-- -- extra: "{"mailType":"COIN","facebookId":"fan2"}"
-- function NetWorkFeature:FBInbox_sendFBMail(extraData, success, fail)
--     if gLobalSendDataManager:isLogin() == false then
--         return
--     end
--     gLobalViewManager:addLoadingAnima()
--     local successFunc = function(target, resData)
--         gLobalViewManager:removeLoadingAnima()
--         local result = nil
--         if resData:HasField("result") == true then
--             result = cjson.decode(resData.result)
--         end
--         if success then
--             success(result)
--         end
--     end
--     local failFunc = function(errorCode, errorData)
--         gLobalViewManager:removeLoadingAnima()
--         gLobalViewManager:showReConnect()
--         if fail then
--             fail()
--         end
--     end
--     local actionData = self:getSendActionData(ActionType.FriendSendGiftMail)
--     actionData.data.extra = cjson.encode(extraData)
--     self:sendMessageData(actionData, successFunc, failFunc)
-- end

-- FB发送页签 请求集卡数据 FriendGiftCards
function NetWorkFeature:FBInbox_requestFBCardList(success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            result = cjson.decode(resData.result)
        end
        if success then
            success(result)
        end
    end
    local failFunc = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        if fail then
            fail()
        end
    end
    local actionData = self:getSendActionData(ActionType.FriendGiftCards)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failFunc)
end

-- -- FB获取好友数据 FriendInfo
-- -- extra: "{"facebookIds":["fan2", "aaa"]}"
-- function NetWorkFeature:FBInbox_requestFBFriendInfo(extraData, success, fail)
--     if gLobalSendDataManager:isLogin() == false then
--         return
--     end
--     gLobalViewManager:addLoadingAnima()
--     local successFunc = function(target, resData)
--         gLobalViewManager:removeLoadingAnima()
--         local result = nil
--         if resData:HasField("result") == true then
--             result = cjson.decode(resData.result)
--         end
--         if success then
--             success(result)
--         end
--     end
--     local failFunc = function(errorCode, errorData)
--         gLobalViewManager:removeLoadingAnima()
--         gLobalViewManager:showReConnect()
--         if fail then
--             fail()
--         end
--     end
--     local actionData = self:getSendActionData(ActionType.FriendInfo)
--     actionData.data.extra = cjson.encode(extraData)
--     self:sendMessageData(actionData, successFunc, failFunc)
-- end
-----------------------------------------------------------------------------------------------------

--每日登录
function NetWorkFeature:sendActionChallengeGuide(guideIndex)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function(target, resData)
    end

    local failedCallFun = function()
    end

    local actionData = self:getSendActionData(ActionType.SyncUserExtra)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local extraData = {}
    extraData[ExtraType.LuckyChallengeGuide] = guideIndex
    actionData.data.extra = cjson.encode(extraData)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

function NetWorkFeature:sendActionUserBack(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.UserBackRewardCollect)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    -- local params = {}
    -- actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--玩家修改邮箱 名字头像消息
function NetWorkFeature:sendNameEmailHead(_nickName, _mail, _extra, _sendOption, _success_call_fun, _faild_call_fun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    -- local httpSender = xcyy.HttpSender:createSender()
    local pbResponse = UserProto_pb.EditUserInfoResponse()

    -- 发送消息
    local success_call_fun = function(resData)
        -- httpSender:release()
        -- local resData = UserProto_pb.EditUserInfoResponse()
        -- local responseStr = self:parseResponseData(responseTable)
        -- resData:ParseFromString(responseStr)
        if resData:HasField("user") == true then
            -- globalData.syncSimpleUserInfo(resData.user)
            globalData.userRunData.mail = resData.user.mail
            globalData.userRunData.nickName = resData.user.nickName

            local extraData = resData.user.extra
            local content = {}
            if extraData ~= nil and extraData ~= "" then
                content = cjson.decode(extraData)
            end
            --用户上次换名的时间戳
            if content[ExtraType.LastUpdateNickNameTime] ~= nil then
                globalData.userRunData.lastUpdateNickNameTime = math.floor(content[ExtraType.LastUpdateNickNameTime] * 0.001)
            end

            -- 用户头像
            if content[ExtraType.HeadName] ~= nil then
                globalData.userRunData.HeadName = content[ExtraType.HeadName]

                -- 保存下用户选择的非fb头像 以便fb登出后恢复之前的头像
                if tonumber(globalData.userRunData.HeadName) ~= 0 then
                    gLobalDataManager:setStringByField("PreUserHeadName", globalData.userRunData.HeadName)
                end
            end
            -- 用户头像框
            if content[ExtraType.avatarFrameId] ~= nil then
                globalData.userRunData.avatarFrameId = content[ExtraType.avatarFrameId]
                G_GetMgr(G_REF.AvatarFrame):changeSelfAvatarFrameID()
            end
        end
        if _success_call_fun then
            _success_call_fun(resData.user)
        end
        printInfo("xcyy :sendNameEmailHead success")
    end
    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        if _faild_call_fun then
            _faild_call_fun(errorCode, errorData)
        end
        printInfo("xcyy :sendNameEmailHead failed")
    end

    local requestData = UserProto_pb.EditUserInfo()
    requestData.nickName = _nickName
    requestData.mail = _mail
    local _sendOp = 0
    if _sendOption then
        _sendOp = 1
    end

    requestData.sendOption = _sendOp
    if next(_extra) then
        local params = {}
        params["HeadName"] = _extra["headName"]
        params["Frame"] = _extra["avatarFrameId"]
        requestData.extra = cjson.encode(params)
    end

    -- local bodyData = requestData:SerializeToString()
    local url = DATA_SEND_URL .. RUI_INFO.SAVE_NICKNAME
    -- local offset = self:getOffsetValue()
    -- local token = globalData.userRunData.loginUserData.token
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, requestData, pbResponse, success_call_fun, faild_call_fun)
end

function NetWorkFeature:sendActionWeekTreatCollect(collectDay, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.WeekTreatCollect)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local params = {}
    params.collectDay = collectDay
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--LuckyChipsDraw领取任务奖励
function NetWorkFeature:sendActionLCDCollectTask(func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if func then
            func()
        end
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.DrawCollectReward)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--LuckyChipsDraw刷新奖池
function NetWorkFeature:sendActionLCDRefresh(func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if func then
            func()
        end
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.DrawRefreshReward)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--LuckyChipsDraw抽奖
function NetWorkFeature:sendActionLCDPress(func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local httpSender = xcyy.HttpSender:createSender()

    local successFunc = function(target, resData)
        httpSender:release()
        gLobalViewManager:removeLoadingAnima()
        local result = nil
        if resData:HasField("result") == true then
            result = cjson.decode(resData.result)
        end
        if func then
            func(result)
        end
    end
    local failedCallFun = function(errorCode, errorData)
        httpSender:release()
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.DrawPlay)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 获取玩家背包信息
function NetWorkFeature:sendUserBagInfoReq(_success_call_fun, _faild_call_fun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    -- local httpSender = xcyy.HttpSender:createSender()
    local pbResponse = UserProto_pb.UserPackage()

    -- 发送消息
    local success_call_fun = function(userPackageData)
        -- httpSender:release()
        -- local userPackageData = UserProto_pb.UserPackage()
        -- local responseStr = self:parseResponseData(responseTable)
        -- userPackageData:ParseFromString(responseStr)

        _success_call_fun(userPackageData.items)

        printInfo("xcyy :sendUserBagInfoReq success")
    end
    local faild_call_fun = function(errorCode, errorData)
        -- httpSender:release()
        _faild_call_fun(errorCode, errorData)

        printInfo("xcyy :sendUserBagInfoReq failed")
    end

    local requestData = UserProto_pb.QueryRequest()
    local token = globalData.userRunData.loginUserData.token
    requestData.token = token

    -- local bodyData = requestData:SerializeToString()
    local url = DATA_SEND_URL .. RUI_INFO.USER_BAG_INFO
    -- local offset = self:getOffsetValue()
    -- local serverTime = globalData.userRunData.p_serverTime
    -- httpSender:sendMessage(bodyData, offset, token, url, serverTime, success_call_fun, faild_call_fun)
    self:sendNetMsg(url, requestData, pbResponse, success_call_fun, faild_call_fun)
end

--使用折扣券
function NetWorkFeature:sendUseTicket(ticketId, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.UseTicket)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local params = {}
    params.ticketId = ticketId
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--激活free spin 免费次数奖励
function NetWorkFeature:sendFreeGameActive(ticketId, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.FreeGameActivate)
    actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
    actionData.data.balanceGems = 0
    actionData.data.rewardCoins = 0 --奖励金币
    actionData.data.rewardGems = 0 --奖励钻石
    actionData.data.version = self:getVersionNum()
    local params = {}
    params.order = ticketId
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--小猪挑战领取奖励
function NetWorkFeature:sendPigChallengeCollectReq(successCallFun, failedCallFun)
    -- 不需要传档位，服务器器领取全部达到要求但未领取的
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local actionData = self:getSendActionData(ActionType.PigChallengeCollect)
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 圣诞树挑战接口
function NetWorkFeature:sendChristmasMagicTourReq(_actionType, _params, _successCallFun, _failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    if not _actionType then
        if _failedCallFun then
            _failedCallFun()
        end
        return
    end
    local actionData = self:getSendActionData(_actionType)
    actionData.data.params = json.encode(_params)
    local success = function(target, resultData)
        if _successCallFun then
            _successCallFun(resultData)
        end
    end
    local fail = function(errorCode, errorData)
        if _failedCallFun then
            _failedCallFun(errorCode, errorData)
        end
    end

    self:sendMessageData(actionData, success, fail)
end

--连续充值免费奖励
function NetWorkFeature:sendKeepRechagerFreeGift(index, success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(target, resData)
        end
    end
    local failedCallFun = function(target, errorCode, errorData)
        if fail then
            fail(errorCode, errorData)
        end
        gLobalViewManager:showReConnect()
    end
    local keepChargeCfg = G_GetMgr(ACTIVITY_REF.KRechargeSale):getRunningData()
    local actType = ActionType.FreeContinuousSales
    if keepChargeCfg and keepChargeCfg:isNovice() then
        actType = ActionType.NewUserFreeContinuousSales
    end
    local actionData = self:getSendActionData(actType)
    local params = {}
    params.saleIndex = index
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 常规促销 小游戏
function NetWorkFeature:sendSaleMiniGamesCollectReq(successCallFun, failedCallFun)
    -- 不需要传档位，服务器器领取全部达到要求但未领取的
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local actionData = self:getSendActionData(ActionType.SpecialSaleMiniGame)
    actionData.data.params = json.encode({})
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

--房间刷新数据
function NetWorkFeature:refreshRoomData(gameName, success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    -- gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        -- gLobalViewManager:removeLoadingAnima()
        if success then
            success(target, resData)
        end
    end
    local failedCallFun = function(target, errorCode, errorData)
        if fail then
            fail(errorCode, errorData)
        end
        --抛出刷新房间数据失败消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_ROOM_ERROR, {errorCode = errorCode, errorData = errorData})
    end

    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end
    local actionData = self:getSendActionData(ActionType.TeamMissionData, gameName)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--LottoParty刷新数据
function NetWorkFeature:sendTeamMissionData(gameName, success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    -- gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        -- gLobalViewManager:removeLoadingAnima()
        if success then
            success(target, resData)
        end
    end
    local failedCallFun = function(target, errorCode, errorData)
        if fail then
            fail(errorCode, errorData)
        end
        gLobalViewManager:showReConnect()
    end

    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end
    local actionData = self:getSendActionData(ActionType.TeamMissionData, gameName)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--LottoParty领取奖励
function NetWorkFeature:sendTeamMissionReward(gameName, index, success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            if globalData.slotRunData.gameModuleName ~= nil then
                local _strResult = resData.result
                if not _strResult or _strResult == "" then
                    _strResult = "{}"
                end
                local _resultJson = cjson.decode(_strResult)
                local _extendData = _resultJson.extend
                if _extendData then
                    gLobalSendDataManager:getNetWorkSlots():parseLeagueExtendData(_extendData)
                    gLobalSendDataManager:getNetWorkSlots():parseSlotTrialExtendData(_extendData)
                end
            end

            success(target, resData)
        end
    end
    local failedCallFun = function(target, errorCode, errorData)
        if fail then
            fail(errorCode, errorData)
        end
        gLobalViewManager:showReConnect()
    end
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end
    local actionData = self:getSendActionData(ActionType.TeamMissionReward, gameName)
    local params = {
        spinSessionId = gL_logData:getGameSessionId()
    }
    params.position = index
    actionData.data.params = json.encode(params)
    actionData.data.betCoins = globalData.slotRunData:getCurTotalBet()
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--LottoParty切换房间
function NetWorkFeature:sendTeamMissionReset(gameName, success, fail)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if success then
            success(target, resData)
        end
    end
    local failedCallFun = function(target, errorCode, errorData)
        if fail then
            fail(errorCode, errorData)
        end
        gLobalViewManager:showReConnect()
    end
    if globalData.slotRunData.isDeluexeClub == true then
        gameName = gameName .. "_H"
    end
    local actionData = self:getSendActionData(ActionType.TeamMissionReset, gameName)
    local params = {
        spinSessionId = gL_logData:getGameSessionId()
    }
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

--LuckyChipsDraw领取任务奖励
function NetWorkFeature:sendActionDailyTaskSkipTask(func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if func then
            func(resData)
        end
    end
    local failedCallFun = function(errorCode, errorData)
        gLobalViewManager:showReConnect()
    end
    local actionData = self:getSendActionData(ActionType.DailyTaskSkipTask)
    actionData.data.extra = cjson.encode({})
    self:sendMessageData(actionData, successFunc, failedCallFun)
end

function NetWorkFeature:sendActionQuestSkipTask(taskId, func)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima()

    local successFunc = function(target, resData)
        gLobalViewManager:removeLoadingAnima()
        if func then
            func(resData)
        end
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.QuestGemsSkipTask)
    local extraData = {}
    extraData.taskId = taskId
    actionData.data.extra = cjson.encode(extraData)

    self:sendMessageData(actionData, successFunc, failedCallFun)
end

-- 领取BattlePass奖励
function NetWorkFeature:sendActionBattlePassSkipLevel(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    gLobalViewManager:addLoadingAnima()
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if successCallFun then
            successCallFun(target, resultData)
        end
    end
    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if failedCallFun then
            failedCallFun(errorCode, errorData)
        end
    end

    local actionData = self:getSendActionData(ActionType.BattlePassGemsSkipLevel)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success, fail)
end

-- 首充降档
function NetWorkFeature:sendFirstSaleDownPrice()
    gLobalViewManager:addLoadingAnima(false, 1)
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()

        local saleData = cjson.decode(resultData.result)

        local firstCommomSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
        local noCoinsData = G_GetActivityDataByRef(ACTIVITY_REF.NoCoinSale)

        if noCoinsData then
            noCoinsData:parseData(saleData)
            noCoinsData.p_type = 2
        end

        if firstCommomSaleData and firstCommomSaleData:isRunning() then
            firstCommomSaleData:parseData(saleData)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FIRST_SALE_DOWNMARKET_SUCCESS, {data = resultData})
    end
    local fail = function(errorCode, errorData)
        -- gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    local actionData = self:getSendActionData(ActionType.FirstSaleDownPrice)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success, fail)
end

-- 6个箱子
function NetWorkFeature:sendMemoryFlyingReward(idx, _bNovice)
    gLobalViewManager:addLoadingAnima(false, 1)
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEMORY_FLYING_COLLECT, {isSuccess = true, idx = idx})
    end
    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEMORY_FLYING_COLLECT, {isSuccess = false, idx = idx})
    end

    local actionType = ActionType.MemoryFlyingReward
    if _bNovice then
        actionType = ActionType.NewUserMemoryFlyingReward
    end
    local actionData = self:getSendActionData(actionType)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success, fail)
end

-- 首充降档
function NetWorkFeature:sendFBGiftReward_200k()
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData and resultData.code and resultData.code == 1 then
            local result = cjson.decode(resultData.result)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MEMORY_FBFANS_REWARD, result)
        end
    end

    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local actionData = self:getSendActionData(ActionType.FacebookAttentionData)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success, fail)
end

-------------------------------------------  bingo比赛相关  -------------------------------------------
-- bingo比赛 报名比赛
function NetWorkFeature:sendActionBingoRushEnter(idx, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushEnterRoom)
    local params = {betIndex = idx}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 退出比赛
function NetWorkFeature:sendActionBingoRushQuit(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushQuitRoom)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 状态查询
function NetWorkFeature:sendActionBingoRushStatus(status, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushStatus)
    local params = {}
    params.status = status
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 前两轮spin
function NetWorkFeature:sendActionBingoRushSpin(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushSpin)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 领取奖励
function NetWorkFeature:sendActionBingoRushReward(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushCollect)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 排行榜pass 任务 领取
function NetWorkFeature:sendActionBingoRushPassCollect(_idx, _payType, successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushPassCollect)
    local params = {}
    params.index = _idx -- 领取奖励的位置 0 - n  全部领取 -1
    params.type = _payType -- 是否付费 免费奖励0， 付费奖励1 全部领取2
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 获取排行榜数据
function NetWorkFeature:sendActionBingoRushRank(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushRank)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- bingo比赛 退出bingo轮次
function NetWorkFeature:sendActionBingoRushLost(successCallFun, failedCallFun)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = self:getSendActionData(ActionType.BingoRushContinueResult)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

-- 每日刷新
function NetWorkFeature:sendDailyRefresh(func)
    local success = function(target, resultData)
        if resultData and resultData.code and resultData.code == 1 then
            local result = cjson.decode(resultData.result)
            if func and result then
                func(result)
            end
        end
    end
    local actionData = self:getSendActionData(ActionType.DailyRefresh)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success)
end

function NetWorkFeature:sendQuestGemsBuy(onSuccess, onFaild)
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData and resultData.code and resultData.code == 1 then
            local result = nil
            if resultData.config and resultData.config.sales and resultData.config.sales.quest then
                result = resultData.config.sales.quest
                local sale_data = G_GetMgr(ACTIVITY_REF.QuestSale):getRunningData()
                if sale_data and result then
                    sale_data:parseData(result)
                end
            end

            if onSuccess then
                onSuccess()
            end
        end
    end

    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if onFaild then
            onFaild()
        end
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local actionData = self:getSendActionData(ActionType.QuestSaleGems)
    local params = {}
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, success, fail)
end

function NetWorkFeature:sendBingoRushNoCoin(onSuccess, onFaild)
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        if resultData and resultData.code and resultData.code == 1 then
            local result = json.decode(resultData.result)
            local act_data = G_GetMgr(ACTIVITY_REF.BingoRush):getRunningData()
            local sale_data = act_data:getSaleNoCoinData()
            sale_data:parseData(result)
            if onSuccess then
                onSuccess()
            end
        end
    end

    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        if onFaild then
            onFaild()
        end
    end

    gLobalViewManager:addLoadingAnima(false, 1)

    local actionData = self:getSendActionData(ActionType.BingoRushNoCoinSaleData)
    local params = {}
    actionData.data.params = cjson.encode(params)
    self:sendMessageData(actionData, success, fail)
end

-- 返回大厅时刷新活动数据
function NetWorkFeature:refreshActivityData()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local successCallFun = function (target, resultData)
        
    end

    local failedCallFun = function ()
        
    end

    local actionData = self:getSendActionData(ActionType.ActivityInfoRefresh)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, successCallFun, failedCallFun)
end

return NetWorkFeature
