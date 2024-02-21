--[[
Author: cxc
Date: 2021-04-26 20:30:00
LastEditTime: 2021-06-07 20:26:48
LastEditors: Please set LastEditors
Description: 本地推送 manager 将原来 PlatformManager 里的通知摘出来
1. 有奖励的通知会一直存在
2. 没有奖励的通知  切后台 注册， 进前台 清除  (为了避免 通知太多让玩家恶心， 完游戏时不弹无奖励的通知)
FilePath: /SlotNirvana/src/manager/System/LocalPushManager.lua
--]]
local LocalPushManager = class("LocalPushManager")
local LocalPushConfig = require("data.localPush.LocalPushConfig")
local URLImageManager = require("views.URLImageManager")

-----------------------和java对应的推送配置START
--android本地推送的key
local KEY_ID = "id"
local KEY_EVERY = "every"
local KEY_YEAR = "year"
local KEY_MONTH = "month"
local KEY_WEEK = "week"
local KEY_DAY = "day"
local KEY_HOUR = "hour"
local KEY_MINUTE = "minute"
local KEY_AT = "at"
local KEY_TITLE = "title"
local KEY_TEXT = "text"
local KEY_NOTIFYSMALLBGPATH = "notifysmallbgpath"
local KEY_NOTIFYBIGBGPATH = "notifybigbgpath"
local KEY_REWARD = "bReward"
--java 里写了俩默认的如果需要修改lua重新发起推送
local NOTIFY_ID_DAIYBONUS = 3
local NOTIFY_ID_HOURLYBONUS = 4
local NOTIFY_ID_GOLDVAULT = 5
local urlstr = "https://res.topultragame.com/LocalNotifyImage/"
-- local NOTIFY_ID_BONUS12 = 11~17
-- local NOTIFY_ID_BONUS21 = 21~27

-----------------------和java对应的推送配置END
-- Start-> Lobby -> Login
-- Start -> AutoLogin
-- Start -> Online
local LogTypeEnum = {
    START = "Start", -- 点击生成
    LOBBY = "Lobby", -- 未登录 进入 登陆界面
    LOGIN = "Login", -- 玩家 点击登陆
    AUTO = "AutoLogin", -- 玩家自动登陆
    ONLINE = "Online" -- 玩家登陆中 在线
}

LocalPushManager.m_instance = nil
function LocalPushManager:getInstance()
    if LocalPushManager.m_instance == nil then
        LocalPushManager.m_instance = LocalPushManager.new()
    end
    return LocalPushManager.m_instance
end

function LocalPushManager:ctor()
    self.m_clearIdList = {}
    self.m_download = {}
end

function LocalPushManager:gameInit()
    -- 启动游戏检查 报送 打点
    release_print("PushNotify-->gameInit")
    self:sendLocalPushLog()
    --清除本地通知_all
    --self:clearAllLocalPush()
end

function LocalPushManager:gotoGame()
    if MARKETSEL == AMAZON_MARKET then
        return
    end
    --添加本地推送
    self:clearAllLocalPush()
    self:getConfigLua()
    if #self.m_download > 0 then
        self:getUrlImage(self.m_download[1].path,self.m_download[1].url)
    end

    if util_isSupportVersion("1.7.9", "android") then
        -- 最新优化，只在登录时将推送数据写入Java内
        local pushList, offlinePushList = self:getLocalPushList_new()
        self:saveLocalPushData(pushList, offlinePushList)
    else
        local pushList = self:getLocalPushList(true)
        if #pushList <= 0 then
            -- pushList一直有数据，所以不会执行此步骤
            self:addLocalPushNotify()
        else
            self:callNativePushWithList(pushList)
        end
    end
end
-- 获取运营推送配置
function LocalPushManager:getConfigLua()
    self.localPushData = {}
    local file = cc.FileUtils:getInstance():fullPathForFilename("Dynamic/LocalPush.lua")
    local file1 = cc.FileUtils:getInstance():fullPathForFilename("Dynamic/LocalPush.luac")
    if not cc.FileUtils:getInstance():isFileExist(file) and not cc.FileUtils:getInstance():isFileExist(file1) then
        return
    end
    local lua_config = util_require("Dynamic.LocalPush")
    if lua_config and #lua_config > 0 then
        for i,v in ipairs(lua_config) do
            local a = {}
            a.Id = v.Id
            a.Type = tonumber(v.Type)
            a.Time = v.Time
            if a.Type == 1 then
                a.days = {}
                for utfChar in string.gmatch(a.Time, "[%z\1-\127\194-\244][\128-\191]*") do
                    local day = tonumber(utfChar) + 1
                    if day > 7 then
                        day = 1
                    end
                    table.insert(a.days, day)
                end
                a.Hour = tonumber(v.Hour)
            end
            a.onLine = v.onLine
            a.ShowType = v.ShowType
            if v.Reward == "1" then
                a.Reward = true
            else
                a.Reward = false
            end
            if gLobalLanguageChangeManager:getLanguageType() == "English" then
                a.title = v.EnT
                a.content = v.EnM
                a.smallbg = self:getLocalImageMd5(urlstr..v.EnS)
                a.smallbgurl = urlstr..v.EnS
                a.bigbg = self:getLocalImageMd5(urlstr..v.EnB)
                a.bigbgurl = urlstr..v.EnB
            else
                a.title = v.CnT
                a.content = v.CnM
                a.smallbg = self:getLocalImageMd5(urlstr..v.CnS)
                a.bigbg = self:getLocalImageMd5(urlstr..v.CnB)
                a.smallbgurl = urlstr..v.CnS
                a.bigbgurl = urlstr..v.CnB
            end
            if v.ShowType == "1" then
                self:addDownloadImage(a.smallbg,a.smallbgurl)
                self:addDownloadImage(a.bigbg,a.bigbgurl)
            end
           
            table.insert(self.localPushData,a)
        end
    end
    self:setOffLineImage()
end

function LocalPushManager:setOffLineImage()
    self.m_offlineImage = {}
    local imgOffLineConfig = LocalPushConfig:getConfig(LocalPushConfig.FilterType.IMG_OFFLINE)
    for i,v in ipairs(imgOffLineConfig) do
        local a = {}
        a.smallbg = self:getLocalImageMd5(urlstr..v[4])
        a.smallbgurl = urlstr..v[4]
        a.bigbg = self:getLocalImageMd5(urlstr..v[5])
        a.bigbgurl = urlstr..v[5]
        table.insert(self.m_offlineImage,a)
        self:addDownloadImage(a.smallbg,a.smallbgurl)
        self:addDownloadImage(a.bigbg,a.bigbgurl)
    end
    self.m_loginImage = {}
    local config = LocalPushConfig:getConfig(LocalPushConfig.FilterType.NEWUSER_LOGIN)
    for i,v in ipairs(config) do
        local a = {}
        a.smallbg = self:getLocalImageMd5(urlstr..v[4])
        a.smallbgurl = urlstr..v[4]
        a.bigbg = self:getLocalImageMd5(urlstr..v[5])
        a.bigbgurl = urlstr..v[5]
        table.insert(self.m_loginImage,a)
        self:addDownloadImage(a.smallbg,a.smallbgurl)
        self:addDownloadImage(a.bigbg,a.bigbgurl)
    end
end

function LocalPushManager:addDownloadImage(path,url)
    if not cc.FileUtils:getInstance():isFileExist(path) then
        local b = {}
        b.path = path
        b.url = url
        table.insert(self.m_download,b)
    end
end

--进入后台方法
function LocalPushManager:commonBackGround()
    if MARKETSEL == AMAZON_MARKET then
        return
    end
    --添加本地推送
    if util_isSupportVersion("1.7.9", "android") then
        self:registerLocalPushList()
    else
        local pushList = self:getLocalPushList()
        if #pushList <= 0 then
            -- 离线的 推送没有奖励
            self:addLocalPushNotifyWithOffLineIMG()
        else
            self:callNativePushWithList(pushList)
        end
    end
    --csc
    self:pushNotifyLoginReward()
end
--进入前台方法
function LocalPushManager:commonForeGround()
    if MARKETSEL == AMAZON_MARKET then
        return
    end
    -- 游戏检查 报送 打点
    self:sendLocalPushLog()

    -------------------------------------------------
    -- 清除 没有奖励的 通知
    if device.platform == "android" then
        self:clearLocalPushList()
    else
        self:clearNoRewardLocalPush()
    end
    -------------------------------------------------
end

--添加本地推送
function LocalPushManager:addLocalPushNotify()
    -- 不带图片的 原有 通知cxc2021-04-26 20:09:49不采用原来的 纯文本推送了
    -- self:addLocalPushNotifyWithText()

    -- 注册带图片的推送
    self:addLocalPushNotifyWithIMG()
end

-- 不带图片的 原有 通知
function LocalPushManager:addLocalPushNotifyWithText()
    -- 纯文本 推送
    local textConfig = LocalPushConfig:getConfig(LocalPushConfig.FilterType.TEXT)
    for i, config in ipairs(textConfig) do
        -- clear  有奖励不清除
        self:pushNotifyLocal(config[1], config[2], config[3], config[4], config[5], config[6], config[7], config[8], config[9], not config[9])
    end
end

-- 注册带图片的推送
-- params _bReward  注册 游戏中可推动的 配置 通知太多让玩家恶心_进入游戏注册可领奖的，切到后台都注册
function LocalPushManager:addLocalPushNotifyWithIMG()
    -- 固定时间 图片 推送
    local imgConfig = LocalPushConfig:getConfig(LocalPushConfig.FilterType.IMG)
    for i, config in ipairs(imgConfig) do
        self:pushNotifyLocal(config[1], config[2], config[3], config[4], config[5], config[6], config[7], config[8], config[9], not config[9])
    end
end

-- 玩家离线 图片 推送
function LocalPushManager:addLocalPushNotifyWithOffLineIMG()
    local imgOffLineConfig = LocalPushConfig:getConfig(LocalPushConfig.FilterType.IMG_OFFLINE)
    for i, info in ipairs(imgOffLineConfig) do
        -- 2021年05月10日12:03:58  新加需求。玩家 22点到 早9点不推送 离线通知
        local curHour = os.date("*t").hour
        local delayTime = info[6] or 0
        local pushHour = (curHour + math.floor(delayTime / 3600)) % 24
        if pushHour > 9 and pushHour < 22 then
            local sm,big = info[4],info[5]
            if self.m_offlineImage and self.m_offlineImage[i] then
                sm,big = self.m_offlineImage[i].smallbg,self.m_offlineImage[i].bigbg
                if device.platform == "ios" then
                    sm,big = self:getoffImage(sm, big)
                end
            end
            self:pushNotifyJson(info[1], info[2], info[3], sm, big, info[6], false, true)
        end
    end
end

function LocalPushManager:getDalyTime(time)
    local time_t = util_dataToTimeStamp(time)
    local da = os.date("%Y-%m-%d %H:%M:%S",os.time())
    local nowTime = util_dataToTimeStamp(da)
    return time_t - nowTime
end
-- 获取本地推送数据列表
function LocalPushManager:getLocalPushList(_bReward)
    local pushList = {}
    if not self.localPushData then
        return pushList
    end 
    local clearList = {}
    if #self.localPushData > 0 then
        for i,v in ipairs(self.localPushData) do
            if v.Type == 1 then
                for j=1, #v.days do
                    if device.platform == "ios" then
                        local localImageDir = nil
                        local tmpImage = nil
                        local cp = false
                        if v.ShowType == "1" then
                            localImageDir = v.bigbg
                            tmpImage = string.gsub( localImageDir , ".png", "Ios.png" )
                            cp = self:copyfile(localImageDir,tmpImage)
                        end
                        
                        if cp and cc.FileUtils:getInstance():isFileExist(tmpImage) then
                            local data = self:parseLocalFixDatePushData(v.Id,v.title,v.content,tmpImage,tmpImage,v.days[j],v.Hour,0,v.Reward,not v.Reward,"1")
                            table.insert(pushList, data)
                        else
                            local data = self:parseLocalFixDatePushData(v.Id,v.title,v.content,"","",v.days[j],v.Hour,0,v.Reward,not v.Reward,"1")
                            table.insert(pushList, data)
                        end
                    else
                        if v.ShowType == "1" then
                            local data = self:parseLocalFixDatePushData(v.Id,v.title,v.content,v.smallbg,v.bigbg,v.days[j],v.Hour,0,v.Reward,not v.Reward,"1")
                            table.insert(pushList, data)
                        else
                            local data = self:parseLocalFixDatePushData(v.Id,v.title,v.content,"","",v.days[j],v.Hour,0,v.Reward,not v.Reward,"1")
                            table.insert(pushList, data)
                        end
                        
                    end
                end
            else
                local dayTime = self:getDalyTime(v.Time)
                if dayTime > 0 then
                    if device.platform == "ios" then
                        local localImageDir = v.bigbg
                        local tmpImage = string.gsub( localImageDir , ".png", "Ios.png" )
                        local cp = self:copyfile(localImageDir,tmpImage)
                        if cp and cc.FileUtils:getInstance():isFileExist(tmpImage) then
                            --self:pushNotifyJson(v.Id,v.title,v.content,tmpImage,tmpImage,dayTime,false,false,true)
                            local data = self:parseLocalNoFixDatePushData(v.Id,v.title,v.content,tmpImage,tmpImage,dayTime,false,false,true)
                            table.insert(pushList,data)
                        else
                            local data = self:parseLocalNoFixDatePushData(v.Id,v.title,v.content,"","",dayTime,false,false,true)
                            table.insert(pushList,data)
                        end
                    else
                        local data = self:parseLocalNoFixDatePushData(v.Id,v.title,v.content,v.smallbg,v.bigbg,dayTime,false,false,true)
                        table.insert(pushList,data)
                    end
                else
                    table.insert(clearList,v.Id)
                    --self:clearLocalPushWithId(v.Id)
                end
            end
        end
    end
    if clearList and #clearList > 0 then
        self:clearLocalPushByIdList(clearList)
        clearList = {}
    end
    if _bReward then
        return pushList
    end

    local imgOffLineConfig = LocalPushConfig:getConfig(LocalPushConfig.FilterType.IMG_OFFLINE)
    for i, info in ipairs(imgOffLineConfig) do
        -- 2021年05月10日12:03:58  新加需求。玩家 22点到 早9点不推送 离线通知
        local curHour = os.date("*t").hour
        local delayTime = info[6] or 0
        local pushHour = (curHour + math.floor(delayTime / 3600)) % 24
        if pushHour > 9 and pushHour < 22 then
            local sm,big = self.m_offlineImage[i].smallbg,self.m_offlineImage[i].bigbg
            if device.platform == "ios" then
                sm,big = self:getoffImage(sm, big)
            end
            local data = self:parseLocalNoFixDatePushData(info[1], info[2], info[3], sm, big, info[6], false, true,"0")
            table.insert(pushList, data)
        end
    end

    return pushList
end

function LocalPushManager:getoffImage(_small,_big)
    local sm = _small
    local big = _big
    if device.platform == "ios" then
        local localImageDir = _big
        local tmpImage = string.gsub( localImageDir , ".png", "Ios.png" )
        local cp = self:copyfile(localImageDir,tmpImage)
        if cp and cc.FileUtils:getInstance():isFileExist(tmpImage) then
            sm = tmpImage
            big = tmpImage
        else
            sm = ""
            big = ""
        end
    end
    return sm,big
end

-- 清除 不带奖励的 通知
function LocalPushManager:clearNoRewardLocalPush()
    self:clearLocalPushByIdList(self.m_clearIdList)
    self.m_clearIdList = {}
end

-- CashBonus推送
function LocalPushManager:pushNotifyGoldenVault(delayTime)
    local config = LocalPushConfig:getConfig(LocalPushConfig.FilterType.CASH_BONUS)
    self:pushNotifyJson(NOTIFY_ID_GOLDVAULT, config[1], config[2], nil, nil, delayTime, false)
end

-- DailyBonus推送
function LocalPushManager:pushNotifyCashbonus()
    local delayTime = 86400
    local config = LocalPushConfig:getConfig(LocalPushConfig.FilterType.DAILY_BONUS)
    self:pushNotifyJson(NOTIFY_ID_DAIYBONUS, config[1], config[2], nil, nil, delayTime, true)
end

--[[
    @desc: 提醒登录上线
    author:符合 abtest 第三期的 用户分组 type1 类型推送
    time:2021-08-27 11:43:51
]]
function LocalPushManager:pushNotifyRemindLogin()
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        -- 1.优先判断玩家是否满足注册时间 < 限定天数
        local disDay = math.floor((globalData.userRunData.p_serverTime - globalData.userRunData.createTime) / 1000) / ONE_DAY_TIME_STAMP
        if disDay >= globalData.constantData.NOVICE_PUSH_ADAPT_DAYS then
            return
        end
        -- 2.判断触发次数是否已经超出
        local remidLoginTimes = gLobalDataManager:getNumberByField("pushNotifyRemindLoginTimes", 0)
        if remidLoginTimes >= globalData.constantData.NOVICE_PUSH_TYPE_1_TIMES then
            return
        end
        -- 3.判断两次登录间隔是否超过 24h,记录一次触发次数
        local currLoginStamp = math.floor(globalData.userRunData.loginUserData.timestamp / 1000)
        local lastLoginStamp = gLobalDataManager:getNumberByField("pushNotifyLastLoginStamp", 0)
        if lastLoginStamp == 0 then -- 没有存过值的话,使用服务器时间
            lastLoginStamp = math.floor(globalData.userRunData.p_serverTime / 1000)
        end
        gLobalDataManager:setNumberByField("pushNotifyLastLoginStamp", currLoginStamp)
        if (currLoginStamp - lastLoginStamp) >= ONE_DAY_TIME_STAMP then
            remidLoginTimes = remidLoginTimes + 1
            gLobalDataManager:setNumberByField("pushNotifyRemindLoginTimes", remidLoginTimes)
        end
        -- 4.判断触发次数 添加后是否还能继续推送
        if remidLoginTimes < globalData.constantData.NOVICE_PUSH_TYPE_1_TIMES then
            -- 继续推送
            local config = LocalPushConfig:getConfig(LocalPushConfig.FilterType.NEWUSER_LOGIN)
            local info = config[1]
            local sm,big = info[4],info[5]
            if self.m_loginImage and self.m_loginImage[1] then
                sm,big = self.m_loginImage[1].smallbg,self.m_loginImage[1].bigbg
                if device.platform == "ios" then
                    sm,big = self:getoffImage(sm, big)
                end
            end
            self:pushNotifyJson(info[1], info[2], info[3], sm, big, ONE_DAY_TIME_STAMP, false, false)
        end
    end
end

--[[
    @desc: 提示登录领奖
    author:符合 abtest 第三期的 用户分组 type2 类型推送
    time:2021-08-27 16:12:58
]]
function LocalPushManager:pushNotifyLoginReward()
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    if gLobalDataManager:getBoolByField("pushNotifyLoginRewardStatus") then
        gLobalDataManager:setBoolByField("pushNotifyLoginRewardStatus", false)
    end

    if globalData.constantData and globalData.GameConfig:checkUseNewNoviceFeatures() then
        release_print("----csc pushNotifyLoginReward 当前是 第三期 A组用户 进入 推送2")
        -- 1.优先判断玩家是否满足注册时间 < 限定天数
        local disDay = math.floor((globalData.userRunData.p_serverTime - globalData.userRunData.createTime) / 1000) / ONE_DAY_TIME_STAMP
        if disDay >= globalData.constantData.NOVICE_PUSH_ADAPT_DAYS then
            return
        end
        release_print("----csc pushNotifyLoginReward 当前玩家注册 < 7 天")
        -- 2.判断玩家当前所在等级区间
        local iLevelIndex = self:getPushType2LevelIndex()
        if iLevelIndex == nil then
            return
        end

        -- 3.判断触发次数是否已经超出
        if globalData.constantData.NOVICE_PUSH_TYPE_2_TIMES == nil or #globalData.constantData.NOVICE_PUSH_TYPE_2_TIMES == 0 then
            return
        end
        local type2pushTimes = gLobalDataManager:getNumberByField("pushNotifyLoginRewardTimes" .. iLevelIndex, 0)
        local pushType2Times = globalData.constantData.NOVICE_PUSH_TYPE_2_TIMES[iLevelIndex]
        if pushType2Times and type2pushTimes >= tonumber(pushType2Times) then
            return
        end
        release_print("----csc pushNotifyLoginReward 当前玩家推送 < " .. pushType2Times .. " 次")

        -- 4.判断当前持金是否 < 推送配置的最低持金
        if globalData.constantData.NOVICE_PUSH_TYPE_2_COINS == nil or #globalData.constantData.NOVICE_PUSH_TYPE_2_COINS == 0 then
            return
        end
        local pushCoinsLimit = globalData.constantData.NOVICE_PUSH_TYPE_2_COINS[iLevelIndex]
        if pushCoinsLimit then
            if globalData.userRunData.coinNum > toLongNumber(pushCoinsLimit) then
                return
            end
            release_print("----csc pushNotifyLoginReward 当前玩家持金 <= " .. tonumber(pushCoinsLimit))
        end

        --每次推送1h
        local config = LocalPushConfig:getConfig(LocalPushConfig.FilterType.NEWUSER_LOGIN)
        local info = config[2]
        local sm,big = info[4],info[5]
        if self.m_loginImage and self.m_loginImage[2] then
            sm,big = self.m_loginImage[2].smallbg,self.m_loginImage[2].bigbg
            if device.platform == "ios" then
                sm,big = self:getoffImage(sm, big)
            end
        end
        self:pushNotifyJson(info[1], info[2], info[3], sm, big, globalData.constantData.NOVICE_PUSH_TYPE_2_NOSPIN_TIME, false, true)
        release_print("----csc pushNotifyLoginReward 发送 1h 后的推送type2 ")
        --根据当前剩余的推送次数 累计推送 1h + 24*n 的推送 为了是让一直不登录的玩家能够收到 n次的提示
        for i = 1, tonumber(pushType2Times) - type2pushTimes do
            local delayTime = ONE_DAY_TIME_STAMP * i + globalData.constantData.NOVICE_PUSH_TYPE_2_NOSPIN_TIME
            self:pushNotifyJson(info[1] + i, info[2], info[3], info[4], info[5], delayTime, false, true)
            release_print("----csc pushNotifyLoginReward 发送 " .. delayTime / 3600 .. "h后的推送type2 ")
        end

        -- 记录一下当前推送了type2
        release_print("----csc pushNotifyLoginReward 记录当前推送了 type2")
        gLobalDataManager:setBoolByField("pushNotifyLoginRewardStatus", true)
    end
end

--[[
    @desc: 每次登陆之后要检测一下当前是否推送过 tpye2
]]
function LocalPushManager:checkPushNotifyLoginRewardStatus()
    if gLobalDataManager:getBoolByField("pushNotifyLoginRewardStatus") then
        -- 如果当前推送过type 2 需要加一次推送次数
        gLobalDataManager:setBoolByField("pushNotifyLoginRewardStatus", false)
        local iLevelIndex = self:getPushType2LevelIndex()
        if iLevelIndex == nil then
            return
        end
        local type2pushTimes = gLobalDataManager:getNumberByField("pushNotifyLoginRewardTimes" .. iLevelIndex, 0)
        type2pushTimes = type2pushTimes + 1
        gLobalDataManager:setNumberByField("pushNotifyLoginRewardTimes" .. iLevelIndex, type2pushTimes)
    end
end

--[[
    @desc: 针对新手期 abtest 第三期 type2推送的判断决定等级区间
]]
function LocalPushManager:getPushType2LevelIndex()
    if globalData.constantData.NOVICE_PUSH_TYPE_2_LEVEL_RANGE == nil or #globalData.constantData.NOVICE_PUSH_TYPE_2_LEVEL_RANGE == 0 then
        return nil
    end
    local iLevelIndex = nil
    for i = 1, #globalData.constantData.NOVICE_PUSH_TYPE_2_LEVEL_RANGE do
        local levelList = globalData.constantData.NOVICE_PUSH_TYPE_2_LEVEL_RANGE[i]
        local levelL = tonumber(levelList[1])
        local levelR = tonumber(levelList[2])
        if globalData.userRunData.levelNum >= levelL and globalData.userRunData.levelNum <= levelR then
            iLevelIndex = i
            release_print("----csc pushNotifyLoginReward 当前玩家等级 符合区间 [" .. levelL .. "," .. levelR .. "] .. index = " .. iLevelIndex)
            break
        end
    end
    return iLevelIndex
end
-------------------------------------------推送相关 START-------------------------------------------

--跳转到设置推送界面部分特殊机型不会跳转
function LocalPushManager:openNotifyEnabled()
    self:sendPlatformMsg(globalPlatformManager.OPEN_NOTIFY_ENABLED)
end

--判断是否开启了推送功能
function LocalPushManager:isNotifyEnabled()
    -- local msg = globalPlatformManager:getPlatformInfo(globalPlatformManager.INFO_IS_NOTIFY)
    -- if msg and msg == "open" then
    --     release_print("isNotifyEnabled open true")
    --     return true
    -- end
    -- if msg then
    --     release_print("--------------isNotifyEnabled=" .. msg)
    -- end
    -- release_print("isNotifyEnabled open false")
    -- return false

    local isEnable = globalDeviceInfoManager:isNotifyEnabled()
    release_print("--------------isNotifyEnabled=" .. tostring(isEnable))
    return isEnable
end

--[[
@description: 本地推送（循环推送）_ 某个日期推送
@param  id: 通知id
@param  title: 通知title
@param  text: 通知 内容
@param  smallBgPath: 通知 小的预览图
@param  bigBgPath: 通知 大的预览图
@param  day: 通知 时间 天
@param  hour: 通知 时间 小时
@param  minutes: 通知 时间 分钟
@param  bReward: 通知 该通知是否要请求奖励
@param  bClear: 切到后台是不是要清除(通知太多，避免通知信息大爆炸)
@return {*}
--]]
function LocalPushManager:pushNotifyLocal(id, title, text, smallBgPath, bigBgPath, day, hour, minutes, bReward, bClear)
    local info = {}
    info[KEY_ID] = id
    info[KEY_TITLE] = title
    info[KEY_TEXT] = text
    info[KEY_DAY] = day
    info[KEY_HOUR] = hour
    info[KEY_MINUTE] = minutes
    info[KEY_AT] = 0
    info[KEY_REWARD] = bReward
    if smallBgPath ~= nil then
        info[KEY_NOTIFYSMALLBGPATH] = smallBgPath
    end
    if bigBgPath ~= nil then
        info[KEY_NOTIFYBIGBGPATH] = bigBgPath
    end
    --按照周还是按照天循环
    if day > 0 then
        info[KEY_EVERY] = KEY_WEEK
    else
        info[KEY_EVERY] = KEY_DAY
    end

    if bClear then
        table.insert(self.m_clearIdList, id)
    end

    local weekMillisTime = 604800000
    local dayMillisTime = 86400000
    local tData = os.date("*t")
    tData.hour = hour
    tData.min = minutes
    tData.sec = 0
    tData.isdst = false
    local targetTime = os.time(tData)
    --计算时间差
    local delayTime = (targetTime - os.time()) * 1000
    if day == tData.wday then
        if targetTime <= os.time() then
            --本日已过设定到下周
            delayTime = delayTime + weekMillisTime
        end
    else
        --如果不是今天加入天数差值
        delayTime = delayTime + (day - tData.wday) * dayMillisTime
        if day < tData.wday then
            --本周已过设定到下周
            delayTime = delayTime + weekMillisTime
        end
    end
    info[KEY_AT] = os.time() * 1000 + delayTime
    local jsonStr1 = json.encode(info)
    if device.platform == "android" then
        local jsonStr = json.encode(info)
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "toPush", {jsonStr})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
        local timez = os.time(tData) + (day - tData.wday) * 86400
        info[KEY_AT] = tostring(timez)
        -- if util_isSupportVersion("1.7.9") then
            info[KEY_AT] = tostring(timez*1000)
        -- end
        local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "toLocalPush", info)
        if not ok then
            return nil
        else
            return ret
        end
    end
end

-- 注册固定日期的 推送 list (暂时没有使用)
function LocalPushManager:pushLocalFixDateConfigList(_fixDateList)
    _fixDateList = _fixDateList or {}

    if #_fixDateList <= 0 then
        return
    end

    local pushDataList = {}
    for i, pushConfig in ipairs(_fixDateList) do
        -- id:通知id, title: 通知title, text: 通知 内容, smallBgPath: 通知 小的预览图, bigBgPath: 通知 大的预览图, day: 通知 时间 天, hour: 通知 时间 小时, minutes: 通知 时间 分钟, bReward: 通知 该通知是否要请求奖励, bClear: 切到后台是不是要清除(通知太多，避免通知信息大爆炸)
        local pushData =
            self:parseLocalPushData(pushConfig[1], pushConfig[2], pushConfig[3], pushConfig[4], pushConfig[5], pushConfig[6], pushConfig[7], pushConfig[8], pushConfig[9], not pushConfig[9])
        table.insert(pushDataList, pushData)
    end
    self:callNativePushWithList(pushDataList)
end

-- 解析单个的固定日期的push 数据
function LocalPushManager:parseLocalFixDatePushData(id, title, text, smallBgPath, bigBgPath, day, hour, minutes, bReward, bClear,bline)
    local info = {}
    info[KEY_ID] = id
    info[KEY_TITLE] = title
    info[KEY_TEXT] = text
    info[KEY_DAY] = day
    info[KEY_HOUR] = hour
    info[KEY_MINUTE] = minutes
    info[KEY_AT] = 0
    info[KEY_REWARD] = bReward
    if smallBgPath ~= nil then
        info[KEY_NOTIFYSMALLBGPATH] = smallBgPath
    end
    if bigBgPath ~= nil then
        info[KEY_NOTIFYBIGBGPATH] = bigBgPath
    end
    --按照周还是按照天循环
    if day > 0 then
        info[KEY_EVERY] = KEY_WEEK
    else
        info[KEY_EVERY] = KEY_DAY
    end

    if bClear then
        table.insert(self.m_clearIdList, id)
    end

    local weekMillisTime = 604800000
    local dayMillisTime = 86400000
    local tData = os.date("*t")
    tData.hour = hour
    tData.min = minutes
    tData.sec = 0
    tData.isdst = false
    local targetTime = os.time(tData)
    if targetTime == nil then
        local errorMsg = "Error hour"
        if hour ~= nil then
            errorMsg = errorMsg..hour
        end
        if minutes ~= nil then
            errorMsg = errorMsg.."minutes "..minutes
        end
        if tData and tData.year then
            errorMsg = errorMsg.."tData year "..tData.year
        end
        util_sendToSplunkMsg("LocalPushError", errorMsg)
        targetTime = os.time() + 1679891100
    end
    --计算时间差
    local delayTime = (targetTime - os.time()) * 1000
    if day == tData.wday then
        if targetTime <= os.time() then
            --本日已过设定到下周
            delayTime = delayTime + weekMillisTime
        end
    else
        --如果不是今天加入天数差值
        delayTime = delayTime + (day - tData.wday) * dayMillisTime
        if day < tData.wday then
            --本周已过设定到下周
            delayTime = delayTime + weekMillisTime
        end
    end
    info[KEY_AT] = os.time() * 1000 + delayTime
    info["line"] = bline
    return info
end

--[[
@description: lua推送_延迟多长时间后推送
@param  id: 通知id
@param  title: 通知title
@param  body: 通知 内容
@param  smallBgPath: 通知 小的预览图
@param  bigBgPath: 通知 大的预览图
@param  delayTime: 通知 间隔时间 
@param  loop: 通知 是否循环
@param  bClear: 切到后台是不是要清除(通知太多，避免通知信息大爆炸)
--]]
function LocalPushManager:pushNotifyJson(id, title, body, smallBgPath, bigBgPath, delayTime, loop, bClear,bReward)
    local info = {}
    info[KEY_ID] = id
    info[KEY_TITLE] = title
    info[KEY_TEXT] = body
    info[KEY_AT] = os.time() * 1000 + delayTime * 1000
    if smallBgPath ~= nil then
        info[KEY_NOTIFYSMALLBGPATH] = smallBgPath
    end
    if bigBgPath ~= nil then
        info[KEY_NOTIFYBIGBGPATH] = bigBgPath
    end
    if loop then
        info[KEY_EVERY] = KEY_DAY
    end
    if bReward then
        info[KEY_REWARD] = bReward
    end
    if bClear then
        table.insert(self.m_clearIdList, id)
    end
    local jsonStr = json.encode(info)
    jsonStr = string.gsub(jsonStr, "\\'", "'")
    release_print(string.format("error push params: %s", jsonStr))
    if device.platform == "android" then
        local jsonStr = json.encode(info)

        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "toPush", {jsonStr})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
        info[KEY_AT] = tostring(info[KEY_AT])
        -- if util_isSupportVersion("1.7.9") then
            local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "toLocalPush", info)
            if not ok then
                local jsonStr = json.encode(info)
                jsonStr = string.gsub(jsonStr, "\\'", "'")
                release_print(string.format("error push params: %s", jsonStr))
                return nil
            else
                return ret
            end
        -- else
        --     local jsonStr = json.encode(info)
        --     jsonStr = string.gsub(jsonStr, "\\'", "'") -- encode 会将' 变为\' 导致oc解析jsonStr解析不了
        --     local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "toPush", {msg = jsonStr})
        --     if not ok then
        --         return nil
        --     else
        --         return ret
        --     end
        -- end
    end
end

-- 注册非固定日期的 推送 list （暂时未使用）
function LocalPushManager:pushLocalNoFixDateConfigList(_noFixDateList)
    _noFixDateList = _noFixDateList or {}

    if #_noFixDateList <= 0 then
        return
    end

    local pushDataList = {}
    for i, pushConfig in ipairs(_noFixDateList) do
        -- id: 通知id, title: 通知title, body: 通知 内容, smallBgPath: 通知 小的预览图, bigBgPath: 通知 大的预览图, delayTime: 通知 间隔时间 , loop: 通知 是否循环, bClear: 切到后台是不是要清除(通知太多，避免通知信息大爆炸)
        local pushData = self:parseLocalNoFixDatePushData(pushConfig[1], pushConfig[2], pushConfig[3], pushConfig[4], pushConfig[5], pushConfig[6], pushConfig[7], not pushConfig[8])
        table.insert(pushDataList, pushData)
    end

    self:callNativePushWithList(pushDataList)
end

-- 解析单个的非固定日期的push 数据 间隔多少秒 推送
function LocalPushManager:parseLocalNoFixDatePushData(id, title, body, smallBgPath, bigBgPath, delayTime, loop, bClear,bline)
    local info = {}
    info[KEY_ID] = id
    info[KEY_TITLE] = title
    info[KEY_TEXT] = body
    info[KEY_AT] = os.time() * 1000 + delayTime * 1000
    if smallBgPath ~= nil then
        info[KEY_NOTIFYSMALLBGPATH] = smallBgPath
    end
    if bigBgPath ~= nil then
        info[KEY_NOTIFYBIGBGPATH] = bigBgPath
    end
    if loop then
        info[KEY_EVERY] = KEY_DAY
    end
    if bClear then
        table.insert(self.m_clearIdList, id)
    end
    info["line"] = bline
    info["delayTime"] = delayTime
    return info
end

--注册 通知 list
function LocalPushManager:callNativePushWithList(_pushDataList)
    if not _pushDataList or #_pushDataList <= 0 then
        return
    end

    local jsonStr = json.encode(_pushDataList)
    jsonStr = string.gsub(jsonStr, "\\'", "'") -- encode 会将' 变为\'
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "toLocalPushWithList", {jsonStr})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "toLocalPushWithList", {pushDataList = jsonStr})
        if not ok then
            -- local str = "ret = "..ret.."  jsonStr = "..jsonStr
            -- util_sendToSplunkMsg("LocalPush",str)
            return nil
        else
            return ret
        end
    end
end

-- 清除本地通知_通过id
function LocalPushManager:clearLocalPushWithId(_id)
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "clearLocalPushById", {tostring(_id)})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "clearLocalPushById", {id = tostring(_id)})
        if not ok then
            return nil
        else
            return ret
        end
    end
end

function LocalPushManager:clearLocalPushByIdList(_idList)
    if not _idList or not next(_idList) then
        return
    end

    local jsonStr = json.encode(_idList)

    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "clearLocalPushByIdList", {jsonStr})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "clearLocalPushByIdList", {ids = jsonStr})
        if not ok then
            return nil
        else
            return ret
        end
    end
end

-- 清除本地通知_all
function LocalPushManager:clearAllLocalPush()
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "clearAllLocalPush", {})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("XcyyAlarm", "clearAllLocalPush", {})
        if not ok then
            return nil
        else
            return ret
        end
    end
end
--检测是否存在奖励推送数据 如果存在尝试弹出
function LocalPushManager:readNotifyRewardData(callBack)
    self.isSendServer = false
    local serverGiftData = gLobalDataManager:getStringByField("checkPushServerGift", "",true)
    local localGiftData = gLobalDataManager:getStringByField("checkPushLocalGift", "",true)
    local localiosPushData = gLobalDataManager:getStringByField("clickLocalPushInfoID", "",true)
    release_print("PushNotify--> read serverGiftData:" .. tostring(serverGiftData))
    local keyCode = ""
    local keyType = ""
    local pushId = -1
    local isPushData = nil
    local bImg = false
    local bLocal = false
    if localGiftData ~= "" then
        isPushData = true
        local notifyData = cjson.decode(localGiftData)
        if notifyData and notifyData.at then
            --奖励id 范围
            pushId = notifyData.id
            if notifyData.bReward then
                keyCode = "DP_C_" .. notifyData.id
                keyType = "DailyPushC"
            end

            bImg = notifyData.notifysmallbgpath and notifyData.notifybigbgpath
        end
        bLocal = true
    elseif localiosPushData ~= "" then
        isPushData = true
        keyCode = "DP_C_" .. localiosPushData
        keyType = "DailyPushC"
        bLocal = true
    elseif serverGiftData ~= "" then
        isPushData = true
        local info = util_string_split(serverGiftData, ";")
        if info then
            pushId = 10000
            keyCode = info[1]
            if #info >= 2 then
                keyType = info[2]
            else
                keyType = "remoteRewardCode"
            end
        end
    end

    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local isCheck = self:checkShowNotifyReward(keyCode, keyType, callBack)
    if not isCheck then
        -- 奖励验证失败，清理推送数据
        gLobalDataManager:setStringByField("checkPushLocalGift", "")
        gLobalDataManager:setStringByField("checkPushServerGift", "")
        gLobalDataManager:setStringByField("clickLocalPushInfoID", "")
    end
end

--清除保存数据
function LocalPushManager:clearNotifyReward()
    gLobalDataManager:setStringByField("checkPushServerGift", "")
    gLobalDataManager:setStringByField("checkPushLocalGift", "")
    gLobalDataManager:setStringByField("clickLocalPushInfoID", "")
end

--尝试弹出奖励界面callBack结束回调
function LocalPushManager:checkShowNotifyReward(keyCode, keyType, callBack)
    if keyCode == "" or keyType == "" then
        if callBack then
            callBack()
        end
        return false
    end
    self:sendNotifyReward(keyCode, keyType, callBack)
    return true
end

--检测是否有推送奖励
function LocalPushManager:sendNotifyReward(keyCode, keyType, callBack)
    if self.isSendServer then
        release_print("PushNotify-->has sendServer")
        return
    end
    local _logMsg = string.format("PushNotify-->sendNotifyReward keyCode:%s, keyType:%s", tostring(keyCode), tostring(keyType))
    release_print(_logMsg)
    --发送奖励
    self.isSendServer = true
    local errCodeList = {"PUSH_CODE_NOT_EXIST", "PUSH_CODE_EXPIRED", "PUSH_CODE_USED"}
    gLobalSendDataManager:getNetWorkFeature():sendNotifyReward(
        keyCode,
        keyType,
        function(rewardData)
            self.isSendServer = false
            release_print("PushNotify-->sendNotifyReward isReward = success")
            self:clearNotifyReward()

            local notifyRewardUI = util_createView("views.NotifyReward.NotifyRewardUI", rewardData, callBack)
            gLobalViewManager:showUI(notifyRewardUI)
        end,
        function(errCode)
            self.isSendServer = false
            release_print("PushNotify-->sendNotifyReward errorCode = " .. tostring(errCode))
            if table_indexof(errCodeList, tostring(errCode)) then
                self:clearNotifyReward()
            else
                util_sendToSplunkMsg("LocalPush", "sendNotifyReward return error code:" .. tostring(errCode))
            end
            if callBack then
                callBack()
            end
        end
    )
end

-- 点击推送 给后台 报送 打点
function LocalPushManager:sendLocalPushLog()
    local serverGiftData = gLobalDataManager:getStringByField("checkPushServerGift", "", true)
    release_print("PushNotify--> log serverGiftData:" .. tostring(serverGiftData))
    local localGiftData = gLobalDataManager:getStringByField("checkPushLocalGift", "", true)
    release_print("PushNotify--> log localGiftData:" .. tostring(localGiftData))
    local localiosPushData = gLobalDataManager:getStringByField("clickLocalPushInfoID", "", true)
    release_print("PushNotify--> log localiosPushData:" .. tostring(localiosPushData))
    local keyCode = ""
    local keyType = ""
    local pushId = -1
    -- 推送进入游戏的打点标记
    local isPushData = nil
    local bImg = false
    local bLocal = false
    if localGiftData ~= "" then
        isPushData = true
        local notifyData = cjson.decode(localGiftData)
        if notifyData and notifyData.at then
            --奖励id 范围
            pushId = notifyData.id
            if notifyData.bReward then
                keyCode = "DP_C_" .. notifyData.id
                keyType = "DailyPushC"
            end

            bImg = notifyData.notifysmallbgpath and notifyData.notifybigbgpath
        end
        bLocal = true
    elseif localiosPushData ~= "" then
        pushId = localiosPushData
        isPushData = true
        keyCode = "DP_C_" .. localiosPushData
        keyType = "DailyPushC"
        bLocal = true
    elseif serverGiftData ~= "" then
        isPushData = true
        local info = util_string_split(serverGiftData, ";")
        if info and #info >= 2 then
            pushId = 10000
            keyCode = info[1]
            keyType = info[2]
        end
    end

    if DEBUG > 0 then
        local logMsg = string.format("PushNotify-->pushId:%s,code:%s,type:%s,bImg:%s,bLocal:%s", tostring(pushId), tostring(keyCode), tostring(keyType), tostring(bImg), tostring(bLocal))
        release_print(logMsg)
    end

    if isPushData then
        if gLobalSendDataManager:getLogGameLoad().setStartPush then
            gLobalSendDataManager:getLogGameLoad():setStartPush(true)
        end
        -- 发送推送打点信息
        if gLobalSendDataManager:getLogFeature().sendNotifyLog then
            local logData = self:parseLocalPushLogData(LogTypeEnum.START, pushId, keyCode, bImg, bLocal)
            if gLobalSendDataManager:isLogin() then
                logData = self:parseLocalPushLogData(LogTypeEnum.ONLINE)
            end
            gLobalSendDataManager:getLogFeature():sendNotifyLog(logData)
            gLobalDataManager:setStringByField("clickLocalPushInfo", "")
        end
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.PushGameOpen)
        end
    end
end

-- 点击推送的全局回调
GD.nativeCallLuaFuncLocalPushLog = function()
    if globalLocalPushManager then
        release_print("PushNotify-->nativeCallLuaFuncLocalPushLog")
        globalLocalPushManager:sendLocalPushLog()
    end
end

-- 报送 数据封装
function LocalPushManager:parseLocalPushLogData(_actionType, _pushId, _rewardCode, _bImg, _bLocal)
    if _actionType == LogTypeEnum.START then
        local messageData = {
            actionType = _actionType,
            pushId = _pushId,
            rewardCode = _rewardCode,
            pushSite = _bLocal and "Local" or "Remote",
            pushStatus = _bImg and 1 or 0,
            status = _rewardCode == "" and 0 or 1
        }
        self.m_logData = messageData
        return self.m_logData
    end
    if not self.m_logData then
        return
    end

    self.m_logData.actionType = _actionType

    if _actionType == LogTypeEnum.LOBBY then
    elseif _actionType == LogTypeEnum.LOGIN or _actionType == LogTypeEnum.AUTO or _actionType == LogTypeEnum.ONLINE then
        local messageData = clone(self.m_logData)
        self.m_logData = nil
        return messageData
    end

    return self.m_logData
end

-- 发送 报送 登录界面 需要 手动登录
function LocalPushManager:sendLocalPushLogWaitLogonReq()
    if not self.m_logData then
        return
    end

    local loginStatus = gLobalSendDataManager:getLogGameLoad():getLoginStatus()
    if loginStatus == "Auto" then
        return
    end

    local logData = self:parseLocalPushLogData(LogTypeEnum.LOBBY)
    gLobalSendDataManager:getLogFeature():sendNotifyLog(logData)
end

-- 发送 报送 自动登录 还是 手动登录成功
function LocalPushManager:sendLocalPushLogLogonReq()
    if not self.m_logData then
        return
    end

    local loginStatus = gLobalSendDataManager:getLogGameLoad():getLoginStatus()
    local logType = LogTypeEnum.LOGIN
    if loginStatus == "Auto" then
        logType = LogTypeEnum.AUTO
    end

    local logData = self:parseLocalPushLogData(logType)
    gLobalSendDataManager:getLogFeature():sendNotifyLog(logData)
end

-- 发送 报送 在线状态
function LocalPushManager:sendLocalPushLogOnlineReq()
    if not gLobalSendDataManager:isLogin() then
        return
    end

    if not self.m_logData then
        return
    end

    local logData = self:parseLocalPushLogData(LogTypeEnum.ONLINE)
    gLobalSendDataManager:getLogFeature():sendNotifyLog(logData)
end

--[[
    @desc: 登录成功之后需要的事情
    time:2021-08-27 17:14:33
]]
function LocalPushManager:logonSuccessDoSomething()
    -- 原先的检测登录状态
    self:sendLocalPushLogLogonReq()
    -- 新手期推送相关的登录检测
    self:pushNotifyRemindLogin()
    self:checkPushNotifyLoginRewardStatus()
    globalFireBaseManager:setFireBaseCnvMeasEmail(globalData.userRunData.mail)
    -- ...
end
-------------------------------------------推送相关 END-------------------------------------------
--推送下载图片
function LocalPushManager:getLocalImageMd5( sUrl )
    assert( sUrl," !! sUrl is nil !! " )
    local tempMd5   = xcyy.UrlImage:getInstance():getMd5( sUrl )
    -- type --
    local type = ".png"
    local tmpPath   = device.writablePath.."pub/head" .. "/" .. tempMd5 .. type
    local fileName  = cc.FileUtils:getInstance():fullPathForFilename( tmpPath )
    return fileName
end

--请求网络数据
function LocalPushManager:getUrlImage(path,url)
    local iamgeUrl = url
    local function HttpRequestCompleted(statusCode, status)
        if statusCode == 200 then
            table.remove(self.m_download,1)
            if #self.m_download > 0 then
                self:getUrlImage(self.m_download[1].path,self.m_download[1].url)
            end
        end
    end
    URLImageManager.getInstance():pushDownloadInfo(iamgeUrl,nil,HttpRequestCompleted)
end
--拷贝文件
function LocalPushManager:copyfile( oldPath , newPath )
    if cc.FileUtils:getInstance():isFileExist(newPath) then
        return true
    end
    local oldFile,errorString = io.open(oldPath,"rb")
    if oldFile == nil then
        return false , errorString
    end
    local data = oldFile:read("*a")
    oldFile:close()
    local newFile = io.open(newPath,"wb")
    if newFile == nil then
        return false
    end
    newFile:write(data)
    newFile:close()
    return true
end

----------------  最新优化  -------------------
function LocalPushManager:getLocalPushList_new()
    local pushList = {}
    if self.localPushData and #self.localPushData > 0 then
        for i,v in ipairs(self.localPushData) do
            if v.Type == 1 then
                for j = 1, #v.days do
                    if v.ShowType == "1" then
                        local data = self:parseLocalFixDatePushData(v.Id,v.title,v.content,v.smallbg,v.bigbg,v.days[j],v.Hour,0,v.Reward,not v.Reward,"1")
                        table.insert(pushList, data)
                    else
                        local data = self:parseLocalFixDatePushData(v.Id,v.title,v.content,nil,nil,v.days[j],v.Hour,0,v.Reward,not v.Reward,"1")
                        table.insert(pushList, data)
                    end
                end
            else
                local dayTime = self:getDalyTime(v.Time)
                if dayTime > 0 then
                    local data = self:parseLocalNoFixDatePushData(v.Id,v.title,v.content,v.smallbg,v.bigbg,dayTime,false,false,true)
                    table.insert(pushList,data)
                end
            end
        end
    end
    -- 离线推送列表
    local offlinePushList = {}
    local imgOffLineConfig = LocalPushConfig:getConfig(LocalPushConfig.FilterType.IMG_OFFLINE)
    for i, info in ipairs(imgOffLineConfig) do
        local sm,big = self.m_offlineImage[i].smallbg,self.m_offlineImage[i].bigbg
        if device.platform == "ios" then
            sm,big = self:getoffImage(sm, big)
        end
        local data = self:parseLocalNoFixDatePushData(info[1], info[2], info[3], sm, big, info[6], false, true,"1")
        table.insert(offlinePushList, data)
    end

    return pushList, offlinePushList
end

-- 保存本地推送数据到设备
function LocalPushManager:saveLocalPushData(_pushList, _localPushList)
    local pushList = _pushList or {}
    local localPushList = _localPushList or {}

    local jsonPushList = json.encode(_pushList)
    local jsonLocalPushList = json.encode(_localPushList)
    local jsonClearList = json.encode(self.m_clearIdList)
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "saveLocalPushData", {jsonPushList, jsonLocalPushList, jsonClearList})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
    end
end

-- 注册本地推送列表
function LocalPushManager:registerLocalPushList()
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "registerLocalPushList", {})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
    end
end

-- 清理本地推送列表
function LocalPushManager:clearLocalPushList()
    if device.platform == "android" then
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/Alarm/XcyyAlarm"
        local ok, ret = luaj.callStaticMethod(className, "clearLocalPushList", {})
        if not ok then
            return nil
        else
            return ret
        end
    elseif device.platform == "ios" then
    end
end

return LocalPushManager
