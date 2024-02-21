---
--zhpx
--2017年10月16日
--SendDataManager.lua
--
-- FIX IOS 139
local SendDataManager = class("SendDataManager")

local json = require "json"
-- 测试UDID,只在Mac上生效
local testUdid = ""

---- 游戏内用户运行时数据
GD.LOGIN_USER_DATA = "login_user_data" -- 登录用户数据

--ProductID
SendDataManager.PRODUCTID = "SlotNewCashLink"

SendDataManager.m_instance = nil

------ 定义 通通讯模块
SendDataManager.m_nwFb = nil
SendDataManager.m_nwIap = nil
SendDataManager.m_nwFeature = nil
SendDataManager.m_nwLogon = nil
SendDataManager.m_nwSlots = nil
SendDataManager.m_nwTour = nil
SendDataManager.m_nwCollect = nil

-------- 定义log
SendDataManager.m_logFeature = nil
SendDataManager.m_logIap = nil
SendDataManager.m_logSlots = nil
SendDataManager.m_logGameLoad = nil
SendDataManager.m_logScore = nil
--LogScore
SendDataManager.m_logPopup = nil
SendDataManager.m_logFbFun = nil
SendDataManager.m_gameCrazeFun = nil
SendDataManager.m_logNewPass = nil

local pcall_create = function(path)
    local ok, module = pcall(function()
        return require(path)
    end)

    if ok then
        return module:create()
    else
        return nil
    end
end

-- 构造函数
function SendDataManager:ctor()
    globalData.userRunData.userUdid = self:getDeviceUuid()
    gLobalBuglyControl:setId(globalData.userRunData.userUdid)
    -- if DEBUG == 2 then
    release_print("udid=" .. (globalData.userRunData.userUdid or " is nil"))
    -- end

    -- globalData.userRunData.isFbLogin = false

    self.m_nwFb = pcall_create("network.NetWorkFb")
    self.m_nwIap = pcall_create("network.NetWorkIap")
    self.m_nwFeature = pcall_create("network.NetWorkFeature")
    self.m_nwLogon = pcall_create("network.NetWorkLogon")
    self.m_nwSlots = pcall_create("network.NetWorkSlots")
    self.m_nwTour = pcall_create("network.NetWorkTournament")
    self.m_nwCollect = pcall_create("network.NetWorkCollect")

    self.m_logGuide = pcall_create("log.LogGuide")
    self.m_logFeature = pcall_create("log.LogFeature")
    self.m_logIap = pcall_create("log.LogIap")
    self.m_logSlots = pcall_create("log.LogSlots")
    self.m_logAds = pcall_create("log.LogAds")
    self.m_logAdvertisement = pcall_create("log.LogAdvertisement")
    self.m_logFindActivity = pcall_create("log.LogFindActivity")
    self.m_logQuestActivity = pcall_create("log.LogQuestActivity")
    self.m_logQuestNewActivity = pcall_create("log.LogQuestNewActivity")

    self.m_logQuestNewUserActivity = pcall_create("log.LogQuestNewUserActivity")

    self.m_logLevelDashActivity = pcall_create("log.LogLevelDashActivity")
    self.m_logSpinBonusActivity = pcall_create("log.LogSpinBonusActivity")

    self.m_logDinnerLandActivity = pcall_create("log.LogDinnerLandActivity")
    self.m_logDiningRoomActivity = pcall_create("log.LogDiningRoomActivity")
    self.m_logRedecorActivity = pcall_create("log.LogRedecorActivity")
    self.m_logPokerActivity = pcall_create("log.LogPokerActivity")

    self.m_logScore = pcall_create("log.LogScore")
    self.m_logPopup = pcall_create("log.LogPopup")

    self.m_logNewPass = pcall_create("log.LogNewPass")

    self.m_heartBeat = pcall_create("network.NetWorkHeartBeat")
    self.m_deluxe = pcall_create("log.LogDeluxe")

    self.m_logGameDL = pcall_create("log.LogGameDL") --弃用
    self.m_logGameLevelDL = pcall_create("log.LogGameLevelDL")

    self.m_logFbFun = pcall_create("log.LogFbFun")

    self.m_logGameLoad = pcall_create("log.LogGameLoad")

    --下载日志
    self.m_logDownload = pcall_create("log.LogDownload")

    self.m_gameCrazeFun = pcall_create("log.LogGameCraze")

    -- bingo 日志控制器
    self.m_logBingoActivity = pcall_create("log.LogBingoActivity")
    -- 餐厅 日志控制器
    self.m_logDinnerLandActivity = pcall_create("log.LogDinnerLandActivity")
    -- 大富翁 日志控制器
    self.m_richman = pcall_create("log.LogRichManActivity")
    -- 新版大富翁 日志控制器
    self.m_worldtrip = pcall_create("log.LogWorldTripActivity")
    -- blast 日志控制器
    self.m_blast = pcall_create("log.LogBlast")
    -- 推币机 日志控制器
    self.m_coinPusher = pcall_create("log.LogCoinPusher")
    -- 集字 日志控制器
    self.m_word = pcall_create("log.LogWord")
    -- 刮刮卡 日志控制器
    self.m_scratchCards = pcall_create("log.LogScratchCards")
    -- 新推币机 日志控制器
    self.m_newCoinPusher = pcall_create("log.LogNewCoinPusher")
    -- 埃及推币机 日志控制器
    self.m_egyptCoinPusher = pcall_create("log.LogEgyptCoinPusher")

    -- 大活动的日志控制器(整合了 餐厅 大富翁 blast 推币机 集字 等活动)
    -- self.m_activitysLogController = require("log.LogActivity"):create()
    -- 大厅底部按钮打点
    self.m_logBottomNode = pcall_create("log.LogBottomNode")
    -- 接水管打点
    self.m_logPipeConnectActivity = pcall_create("log.LogPipeConnectActivity")
    -- 新版大富翁打点
    self.m_logOutsideCaveActivity = pcall_create("log.LogOutsideCaveActivity")    

    -- 聚合挑战
    self.m_logHolidayChallengeActivity = pcall_create("log.LogHolidayChallengeActivity")
    --宠物系统打点
    self.m_logSidekicks = pcall_create("log.LogSidekicks")
    -- 新手期 弹窗打点
    self.m_logNovice = pcall_create("log.LogNovice")
    -- Miz
    self.m_logMinz = pcall_create("log.LogMinz")
    -- 重连次数
    self.m_reconnTime = 0
end

function SendDataManager:clearReconnTime()
    self.m_reconnTime = 0
end

function SendDataManager:reconnNetwork(reqFunc)
    self.m_reconnTime = self.m_reconnTime + 1
    if self.m_reconnTime >= 3 then
        self:clearReconnTime()
        if gLobalGameHeartBeatManager then
            gLobalGameHeartBeatManager:stopHeartBeat()
        end
        util_restartGame()
    else
        if reqFunc then
            reqFunc()
        else
            gLobalViewManager:addLoadingAnima()
            self:getNetWorkHeartBeat():sendHeartBeat(
                function(resultData)
                    gLobalViewManager:removeLoadingAnima()
                    self:clearReconnTime()
                end,
                function(errorCode, errorData)
                    gLobalViewManager:removeLoadingAnima()
                    local errorInfo = {
                        errorCode = tostring(errorCode),
                        errorMsg = "NetWorkHeartBeat:sendHeartBeat|" .. tostring(errorData)
                    }
                    gLobalViewManager:showReConnectNew(nil, nil, false, errorInfo)
                end
            )
        end
    end
end

function SendDataManager:getLogBottomNode()
    return self.m_logBottomNode
end

function SendDataManager:getLogGameLoad()
    return self.m_logGameLoad
end

function SendDataManager:getLogDownload()
    return self.m_logDownload
end

function SendDataManager:getLogGameDL()
    return self.m_logGameDL
end

function SendDataManager:getLogGameLevelDL()
    return self.m_logGameLevelDL
end

function SendDataManager:getLogGuide()
    return self.m_logGuide
end

function SendDataManager:getLogFeature()
    return self.m_logFeature
end
function SendDataManager:getLogIap()
    return self.m_logIap
end
function SendDataManager:getLogSlots()
    return self.m_logSlots
end

function SendDataManager:getLogAds()
    return self.m_logAds
end

function SendDataManager:getLogAdvertisement()
    return self.m_logAdvertisement
end

function SendDataManager:getLogFindActivity()
    return self.m_logFindActivity
end

function SendDataManager:getLogQuestActivity()
    return self.m_logQuestActivity
end
function SendDataManager:getLogQuestNewUserActivity()
    return self.m_logQuestNewUserActivity
end
--新版Quest 梦幻Quest
function SendDataManager:getLogQuestNewActivity()
    return self.m_logQuestNewActivity
end

function SendDataManager:getDiningRoomActivity()
    return self.m_logDiningRoomActivity
end

function SendDataManager:getLevelDashActivity()
    return self.m_logLevelDashActivity
end

function SendDataManager:getSpinBonusActivity()
    return self.m_logSpinBonusActivity
end

function SendDataManager:getRedecorActivity()
    return self.m_logRedecorActivity
end

function SendDataManager:getPokerActivity()
    return self.m_logPokerActivity
end

function SendDataManager:getPipeConnectActivity()
    return self.m_logPipeConnectActivity
end

function SendDataManager:getOutsideCaveActivity()
    return self.m_logOutsideCaveActivity
end

function SendDataManager:getSidekicks()
    return self.m_logSidekicks
end

function SendDataManager:getHolidayChallengeActivity()
    return self.m_logHolidayChallengeActivity
end

-- 新手期 弹窗打点
function SendDataManager:getLogNovice()
    return self.m_logNovice
end

function SendDataManager:getNetWorkFB()
    return self.m_nwFb
end
function SendDataManager:getNetWorkIap()
    return self.m_nwIap
end
function SendDataManager:getNetWorkFeature()
    return self.m_nwFeature
end
function SendDataManager:getNetWorkLogon()
    return self.m_nwLogon
end
function SendDataManager:getNetWorkSlots()
    return self.m_nwSlots
end
function SendDataManager:getNetWorkTour()
    return self.m_nwTour
end
function SendDataManager:getNetWorkCollect()
    return self.m_nwCollect
end
function SendDataManager:getNetWorkHeartBeat()
    return self.m_heartBeat
end

function SendDataManager:getNetWorkDeluxe()
    return self.m_deluxe
end

function SendDataManager:getLogScore()
    return self.m_logScore
end

function SendDataManager:getLogNewPass()
    return self.m_logNewPass
end

function SendDataManager:getLogPopub()
    return self.m_logPopup
end

function SendDataManager:getLogFbFun()
    return self.m_logFbFun
end

function SendDataManager:getLogGameCraze()
    return self.m_gameCrazeFun
end

-- 获取bingo日志控制器
function SendDataManager:getBingoActivity()
    return self.m_logBingoActivity
end

-- 获取餐厅日志控制器
function SendDataManager:getDinnerLandActivity()
    return self.m_logDinnerLandActivity
end

-- 获取大富翁日志控制器
function SendDataManager:getRichManActivity()
    return self.m_richman
end

-- 获取新版大富翁日志控制器
function SendDataManager:getWorldTripActivity()
    return self.m_worldtrip
end

-- 获取blast日志控制器
function SendDataManager:getBlastActivity()
    return self.m_blast
end

-- 获取CoinPusher日志控制器
function SendDataManager:getCoinPusherActivity()
    return self.m_coinPusher
end

-- 获取集字日志控制器
function SendDataManager:getWordActivity()
    return self.m_word
end

-- 获取刮刮卡日志控制器
function SendDataManager:getScratchActivity()
    return self.m_scratchCards
end

-- 获取NewCoinPusher日志控制器
function SendDataManager:getNewCoinPusherActivity()
    return self.m_newCoinPusher
end

-- 获取EgyptCoinPusher日志控制器
function SendDataManager:getEgyptCoinPusherActivity()
    return self.m_egyptCoinPusher
end


-- 获取农场引导日志控制器
function SendDataManager:getFarmActivity()
    self.m_farm = self.m_farm or require("log.LogFarm"):create()
    return self.m_farm
end

-- Minz日志控制器
function SendDataManager:getMinzActivity()
    return self.m_logMinz
end

-- 活动日志控制器
-- function SendDataManager:getActivityLogManager()
--     return self.m_activitysLogController
-- end

-- 活动日志控制器
function SendDataManager:getActivityLogManager(_type)
    if _type then
        if _type == ACTIVITY_REF.Word then
            return self:getWordActivity()
        elseif _type == ACTIVITY_REF.Blast then
            return self:getBlastActivity()
        elseif _type == ACTIVITY_REF.DinnerLand then
            return self:getDinnerLandActivity()
        end
    end
end

--拼接udid
function SendDataManager:getDeviceUuid()
    -- -------------
    if isMac() and testUdid ~= "" then
        return testUdid
    end
    -- 修复 ios 版本
    self:checkKeychainUuid()
    -- 新游戏包里 有token 绑定 进行token绑定服务器 会吧 之前账号的uuid返回回来，
    -- 客户端进行存储下次登录直接用缓存的uuid,  请缓存就 重新绑定！！！
    local cacheUuid = gLobalDataManager:getStringByField("UserNewUuid", "")
    if #cacheUuid > 0 then
        return cacheUuid
    end
    ---------------
    -- - ！！！！！ 如果有需要要修改账号 千万记得不要提交GIT xx
    local uuid = xcyy.GameBridgeLua:getDeviceUuid() .. ":" .. self.PRODUCTID
    self:saveDeviceUuid(uuid)
    return uuid
end

function SendDataManager:saveDeviceUuid(_uuid)
    if device.platform == "mac" then
        -- mac端不保存
        return
    end

    if not _uuid or #_uuid <= 0 then
        return
    end
    gLobalDataManager:setStringByField("UserNewUuid", _uuid, true)
end

-- 获取本地缓存的Udid (fbUdid, deviceUdid, appleID)
-- function SendDataManager:getCacheUdid()
--     local _fbUdid = gLobalDataManager:getStringByField(FB_USERID, "")
--     if _fbUdid ~= "" then
--         return _fbUdid
--     end
--     local appleUserID = gLobalDataManager:getStringByField("luaappleuserid", "")
--     if appleUserID ~= "" then
--         local _appleId = gLobalDataManager:getStringByField(APPLE_ID, "")
--         if _appleId ~= "" then
--             return _appleId
--         end
--     end

--     return self:getDeviceUuid()
-- end
---
--获得 设备id
function SendDataManager:getDeviceId()
    return tostring(xcyy.GameBridgeLua:getDeviceId())
end
---
--获得google 广告ID
function SendDataManager:getGoogleAdvertisingID()
    return tostring(xcyy.GameBridgeLua:getGoogleAdvertisingID())
end

function SendDataManager:getInstance()
    if SendDataManager.m_instance == nil then
        SendDataManager.m_instance = SendDataManager.new()
    end
    return SendDataManager.m_instance
end

function SendDataManager:getIsFbLogin()
    -- return globalData.isFbLogin
    return globalData.userRunData.isFbLogin
end

--联网弹窗 true 弹（未联网） false 不谈（联网）
function SendDataManager:showNetworkDialog()
    globalNoviceGuideManager:clearGuide()
    gLobalViewManager:showReConnectNew()
    -- function()
    --     self:checkShowNetworkDialog()
    -- end
end

function SendDataManager:checkShowNetworkDialog()
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        self:showNetworkDialog()
        return true
    end
    return false
end

function SendDataManager:isLogin()
    if globalData.userRunData.loginUserData == nil then
        printInfo("尚未登录。。。")
        return false
    end
    return true
end

-- 设置界面是否显示 tokenUI 用来迁移数据(50级以上不 进行数据迁移)
function SendDataManager:checkIsShowTokenUI()
    if device.platform == "android" then
        return false
    end

    local levelNum = globalData.userRunData.levelNum or 1
    local closeLv = globalData.constantData.USERDATA_TRANSFER_LEVEL or 0
    if levelNum >= closeLv then
        return false
    end

    -- 现在的逻辑 fb 和 apple 登录的不用显示 游客登录都显示
    local loginType = self:getLogGameLoad():getLoginType() or "GUEST"
    return loginType == "GUEST"
end

--[[
    @desc: 修复ios切换主账号带来的keychain值变化丢失数据问题
    author:csc
    time:2021-10-03
    修复 ios 1.6.3上
]]
function SendDataManager:checkKeychainUuid()
    if device.platform == "ios" and DEBUG == 0 then
        if util_isSupportVersion("1.6.3") then
            -- 获取 userdefult 中的存值
            local cacheUuid = gLobalDataManager:getStringByField("UserNewUuid", "")
            if #cacheUuid > 0 then
                -- 获取 keychain 中的值
                local keychianUuid = globalPlatformManager:getKeyChainValueForKey("udidservice")
                local newCacheUuid = string.split(cacheUuid, ":" .. self.PRODUCTID)[1] -- 裁剪掉 之前拼上去的 :SlotNewCashLink
                if keychianUuid == nil or #keychianUuid <= 0 or keychianUuid ~= newCacheUuid then -- 证明当前没有从 keychain 中存过值 或者值不相等，都认为缓冲文件中的为正确的值
                    if string.find(cacheUuid, ":" .. self.PRODUCTID) then --
                        local newKeyChainUuid = newCacheUuid
                        globalPlatformManager:saveKeyChainValueForKey("udidservice", newKeyChainUuid) -- 把当前cache 值存入 keychain
                    end
                end
            end
        end
    end
end

return SendDataManager
