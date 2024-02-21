--
-- 每次发送消息时的log 结构体
-- Author:{author}
-- Date: 2019-05-16 17:36:26
--
local LogData = class("LogData")
LogData.device = nil -- 设备信息
LogData.app = nil -- app信息
LogData.user = nil -- user信息
LogData.event = nil -- event信息
LogData.p_data = nil -- 存储具体每个消息的信息

-------- 数据打点运行时数据
LogData.m_gameSessionId = nil -- 进入关卡时的唯一标识 ，session id
LogData.p_gameType = nil -- 关卡类型， normal activiy  recommend
--
GD.LOG_ENUM_TYPE = {
    --GameEnter 事件
    GameEnter_LevelCellNode = 1, --入口
    GameEnter_ChooseBetCell = 2, --bet选择界面
    GameEnter_ChooseBetLayer_Close = 3,
    --关闭bet选择界面
    GameEnter_LevelExit = 4,
    --退出关卡
    --Popup 事件
    --BigWin
    Popup_Trigger_BigWin = "BigWin",
    --MegaWin
    Popup_Trigger_MegaWin = "MegaWin",
    --EpicWin
    Popup_Trigger_EpicWin = "EpicWin",
    --EpicWin
    Popup_Trigger_Legendary = "Legendary",
    --fs
    Popup_Trigger_FreeSpin = "Freespin",
    --respin
    Popup_Trigger_ReSpin = "Respin",
    --bouns
    Popup_Trigger_Bonus = "Bouns",
    --BindFB 事件
    -- 登录
    BindFB_Login = "Login",
    --轮播条
    BindFB_Banner = "Banner",
    -- 下ui
    BindFB_BaseIcon = "BaseIcon",
    --上ui
    BindFB_TopIcon = "TopIcon",
    --设置
    BindFB_Settings = "Settings",
    --邮件
    BindFB_Inbox = "Inbox",
    --游戏内弹版
    BindFB_GamePop = "GamePop",
    --GameDownload 事件
    --loading下载
    GameDownload_loading = 1,
    --点击下载
    GameDownload_click = 2,
    --后台自动下载
    GameDownload_auto = 3,
    --CashBonus
    --打开界面
    CashBonus_OpenView = 1,
    --收集铜库
    CashBonus_CollectBronze = 2,
    --收集银库
    CashBonus_CollectSilver = 3,
    --收集金库
    CashBonus_CollectGold = 4,
    --Wheel
    --打开轮盘
    Wheel_Open = 5,
    --收集轮盘
    Wheel_Collect = 6,
    --DailyMission
    --打开每日任务
    DailyMission_view = "Open",
    -- DailyMission_task1 = 8,--领取第一个任务
    -- DailyMission_task2 = 9,--领取第一个任务
    -- DailyMission_task3 = 10,--领取第一个任务
    -- DailyMission_task4 = 11,--领取第一个任务
    -- DailyMission_collect1 = 12.1,--领取其他任务
    -- DailyMission_collect2 = 12.2,--领取其他任务

    --PaymentAction-operationType 操作类型
    --打开
    PaymentAction_open = "open",
    --关闭
    PaymentAction_close = "close",
    --跳转支付
    PaymentAction_skip = "skipPurchase",
    --支付返回
    PaymentAction_back = "backPurchase",
    --消耗返回
    PaymentAction_consume = "consumePurchase",
    PaymentAction_rebuy = "rebuyPurchase", -- 补单操作
    -- 订单进行中
    PaymentAction_purchasing = "purchasing",
    --PaymentAction-operationStatus 调起支付
    --调起支付成功
    PaymentAction_success = "sdkSuccess",
    --调起支付失败
    PaymentAction_failed = "sdkFailed",
    PaymentAction_buySuccess = "buySuccess", -- 正常购买成功
    PaymentAction_buyFaild = "buyFailed", -- 正常购买失败
    PaymentAction_reBuySuccess = "reBuySuccess", -- 补单购买成功
    PaymentAction_reBuyFailed = "reBuyFailed", -- 补单购买失败
    PaymentAction_reCheckPendingFailed = "reCheckPendingFailed",
    -- 消耗成功
    PaymentAction_consumeSuccess = "consumeSuccess",
    -- 消耗失败
    PaymentAction_consumeFailed = "consumeFailed",
    --PaymentAction-purchaseType 付费类型
    --促销
    PaymentAction_normalBuy = "normalBuy",
    --主题促销
    PaymentAction_themeBuy = "themeBuy",
    --多档促销
    PaymentAction_choiceBuy = "choiceBuy",
    --显示促销
    PaymentAction_sevenDay = "limitBuy",
    --小猪
    PaymentAction_pig = "pig",
    --每日轮盘
    PaymentAction_dayRoulette = "dayRoulette",
    --商店
    PaymentAction_storeyBuy = "storeyBuy",
    PaymentAction_boost = "boostMe", -- boost me
    --GameLoad
    --客户端启动到热更新
    GameLoad_enterApp = 0,
    --热更新到登陆loading
    GameLoad_enterUpdate = 1,
    --登陆loading到登陆界面
    GameLoad_enterLogin = 2,
    --登陆界面到大厅
    GameLoad_enterLobby = 3,
    --游戏界面到大厅
    GameLoad_backLobby = 4,
    --BET界面到游戏
    GameLoad_enterGame = 5,
    Invite = "Invite",
    -- 弹出代币二次确认弹版
    PaymentAction_buckConfirm_pop = "unlocktoken",
    -- 弹出代币二次确认弹版，选择用代币支付，点击yes
    PaymentAction_buckConfirm_buck = "choosetoken",
    -- 弹出代币二次确认弹版，点击关闭按钮，点击x
    PaymentAction_buckConfirm_close = "closetoken",
    -- 弹出代币二次确认弹版，取消代币支付，点击no
    PaymentAction_buckConfirm_cancel = "canceltoken",

    -- 弹出代币弹框后，选择了代币
    PaymentAction_buck_success = "tokenSuccess",
    -- 弹出代币弹框后，未选择代币
    PaymentAction_buck_cancel = "tokenCancel",
}

function LogData:ctor()
    self:initLogData()
end

function LogData:createNearestGameSessionId(gameModule)
    if not gameModule then
        gameModule = "errorLevel"
    end
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    self.m_nearestGameSessionId = tostring(globalData.userRunData.loginUserData.displayUid) .. "_" .. gameModule .. randomTag
end
function LogData:getNearestGameSessionId()
    return self.m_nearestGameSessionId
end
function LogData:createGameSessionId(gameModule)
    if not gameModule then
        gameModule = "errorLevel"
    end
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    self.m_gameSessionId = tostring(globalData.userRunData.loginUserData.displayUid) .. "_" .. gameModule .. randomTag
end
function LogData:getGameSessionId()
    return self.m_gameSessionId
end

--[[
    @desc: 初始化log 数据， 只有device 和 app是需要初始化的，其他的 user 和 event 、data 都是每次发送熊希时检测变更
    time:2019-05-16 17:41:40
    @return:
]]
function LogData:initLogData()
    self.device = {
        ip = globalPlatformManager:getIp(),
        imei = globalPlatformManager:getImei(),
        deviceId = globalPlatformManager:getDeviceId(),
        platform = device.platform,
        osVersion = globalPlatformManager:getSystemVersion(),
        dn = globalPlatformManager.getPhoneName ~= nil and globalPlatformManager:getPhoneName() or "unknown",
        dv = globalPlatformManager:getOsSystemVersion(),
        dm = xcyy.GameBridgeLua:getDeviceMemory(),
        st = globalDeviceInfoManager:getIsEmulator() and 1 or 0,
        tz = globalDeviceInfoManager:getDeviceTimeZone(),
        lg = globalDeviceInfoManager:getDeviceLanguage(),
        vpn = globalDeviceInfoManager:getDeviceUseVPN() and 1 or 0,
        ns = "false"
    }

    self.device.ldm = tostring(globalPlatformManager:getMemoryUnused())
    local pixelMode = cc.Texture2D:getDefaultAlphaPixelFormat()
    if pixelMode == cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444 then
        self.device.md = "RGB_A4444"
    else
        self.device.md = "RGB_A8888"
    end

    if globalDeviceInfoManager.isNotifyEnabled then
        local _notify = globalDeviceInfoManager:isNotifyEnabled()
        self.device.ns = tostring(_notify)
        -- release_print("NotifyStatus:" .. tostring(_notify))
    end

    --亚马逊平台
    if MARKETSEL == AMAZON_MARKET then
        self.device.platform = AMAZON_MARKET
    end

    self.app = {
        appVersion = util_getAppVersionCode(),
        resVersion = util_getUpdateVersionCode(false)
    }
    self.user = {
        udid = "",
        uid = "",
        coins = "",
        level = "",
        exp = "",
        vipLevel = "",
        vipPoints = "",
        createTime = "",
        loginType = "",
        abTest = "",
        category = "",
        gems = ""
    }
    self.event = {
        action = "", -- 发生事件名字
        time = "", -- 发生时间
        timestamp = "", -- 发生时间时间戳  毫秒
        token = "" -- 登录的token
    }
end

--转化成json格式
function LogData:getJsonData()
    local tableData = {device = self.device, app = self.app, user = self.user, event = self.event, data = self.p_data}
    local jsonData = cjson.encode(tableData)
    return jsonData
end

function LogData:syncUserData(coinNum, level, exp, vipLevel, vipPoints, gemNum)
    self.user.udid = globalData.userRunData.userUdid
    self.user.createTime = globalData.userRunData.createTime
    self.user.uid = globalData.userRunData.uid
    if globalData.userRunData.isFbLogin == true then
        self.user.loginType = "facebook"
    else
        self.user.loginType = "game"
    end
    if coinNum == nil then
        coinNum = globalData.userRunData.coinNum
    end
    if level == nil then
        level = globalData.userRunData.levelNum
    end
    if exp == nil then
        exp = globalData.userRunData.currLevelExper
    end

    --升到下一级需要的经验
    local mlv = nil
    if gLobalSendDataManager:isLogin() == true and globalData.userRunData.getPassLevelNeedExperienceVal then
        mlv = globalData.userRunData:getPassLevelNeedExperienceVal()
    end
    if vipLevel == nil then
        vipLevel = globalData.userRunData.vipLevel
    end
    if vipPoints == nil then
        vipPoints = globalData.userRunData.vipPoints
    end
    if gemNum == nil then
        gemNum = globalData.userRunData.gemNum
    end

    if type(coinNum) == "number" then
        self.user.coins = string.format("%.f", coinNum)
    else
        self.user.coins = tostring(coinNum)
    end
    self.user.level = level
    self.user.exp = exp
    self.user.mlv = mlv
    self.user.vipLevel = vipLevel
    self.user.vipPoints = vipPoints
    self.user.category = globalData.userRunData.p_categoryNum
    self.user.rcId = globalData.userRunData.rcId
    self.user.gems = gemNum

    --获取网络状态
    if globalDeviceInfoManager and globalDeviceInfoManager.getNetWorkType and self.device then
        self.device.net = globalDeviceInfoManager:getNetWorkType()
    end
end
--[[
    @desc: 设置事件信息
    time:2019-05-16 20:09:23
    @return:
]]
function LogData:syncEventData(action)
    self.event.action = action
    self.event.timestamp = xcyy.SlotsUtil:getMilliSeconds()
    self.event.time = util_chaneTimeFormat(os.time())
    -- self.event.time = xcyy.SlotsUtil:getMilliSeconds()
    -- 如果取不到服务器时间， 那么使用本地时间
    -- if globalData.userRunData.p_serverTime == nil then
    --       self.event.timestamp = xcyy.SlotsUtil:getMilliSeconds()
    -- else
    --       self.event.timestamp = globalData.userRunData.p_serverTime
    -- end
    if globalData.userRunData.loginUserData then
        self.event.token = globalData.userRunData.loginUserData.token
    end
end

--[[
    @desc: 一个消息发送成功后， 清空掉当前log的 data
    time:2019-05-16 20:00:32
    @return:
]]
function LogData:clearMessageData()
    self.p_data = nil
end

return LogData
