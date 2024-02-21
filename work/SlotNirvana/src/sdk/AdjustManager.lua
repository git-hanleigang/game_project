--[[
	Adjust 管理类
]]
local AdjustManager = class("AdjustManager")

AdjustManager.m_instance = nil

GD.AdjustNPEventType = {
    spend_firstly = "spend_firstly",
    click_GoldenVault = "click_GoldenVault",
    spin = "spin",
    login = "login",
    click_shop = "click_shop",
    click_SilverVault = "click_SilverVault"
}

--Adjust key 必须写到这里
local AdjustTypeAndroid = {
    appInit = "kv3pbv",
    login = "8c8fox",
    --升级打点
    Level_9 = "m827zs",
    Level_19 = "bvs2iw",
    Level_29 = "uim24g",
    Level_39 = "a9qd6h",
    Level_49 = "a2fwrd",
    Level_59 = "juiwj5",
    Level_69 = "2b2lz5",
    Level_79 = "7uhwn2",
    Level_89 = "vfgijw",
    Level_99 = "ootcib",
    Level_109 = "6owosh",
    Level_119 = "2mvtpf",
    Level_129 = "os0gdz",
    Level_139 = "4gh3w5",
    Level_149 = "2qfzli",
    --登录打点
    Login_2 = "w2rza0",
    Login_3 = "er484r",
    Login_4 = "bifigs",
    Login_5 = "l74jdd",
    Login_6 = "lr5xgf",
    Login_7 = "z4pqr5",
    showalladstime = "swhiln",
    --这个在java广告加过lua没有打点
    realshowads = "bzi6tm"
}

--iOS Adjust key 必须写到这里
local AdjustTypeiOS = {
    appInit = "qdcnrn",
    login = "9qbotf",
    -- "237zwi", 内购

    --升级打点
    Level_9 = "tg57f4",
    Level_19 = "etn0fe",
    Level_29 = "4n590r",
    Level_39 = "h2u5cu",
    Level_49 = "qckyfq",
    Level_59 = "4ahplv",
    Level_69 = "sy0bbk",
    Level_79 = "tljj0d",
    Level_89 = "a4blml",
    Level_99 = "uyqar8",
    Level_109 = "cj6ci6",
    Level_119 = "uryhs7",
    Level_129 = "fpoo1z",
    Level_139 = "w3pus0",
    Level_149 = "7k5r5r",
    Level_159 = "vwn7v7",
    Level_169 = "p0ytrf",
    Level_179 = "ou7lld",
    Level_189 = "80jenp",
    Level_199 = "445yyv",
    --登录打点
    Login_2 = "w2rza0",
    Login_3 = "er484r",
    Login_4 = "bifigs",
    Login_5 = "l74jdd",
    Login_6 = "lr5xgf",
    Login_7 = "z4pqr5",
    showalladstime = "knagln",
    --这个在java广告加过lua没有打点
    click_buy = "8w841c",
    --1. 点击购买
    buy_more1_99 = "z7gscb",
    --4. 当次购买金额大于等于1.99
    buy_more2_99 = "p8he9d",
    --4. 当次购买金额大于等于2.99
    buy_more4_99 = "enir0q"
    --4. 当次购买金额大于等于4.99
}

if device.platform == "ios" then
    GD.AdjustType = AdjustTypeiOS
else
    GD.AdjustType = AdjustTypeAndroid
end

GD.onAdjustAttributionChanged = function(strAttrib)
    release_print("Adjust Attrib Change:" .. tostring(strAttrib))
    -- 发送splunk打点
    local jsonAttrib = {}
    if isAndroid() then
        jsonAttrib = cjson.decode(strAttrib)
    elseif isIOS() then
        strAttrib = strAttrib or "{}"
        -- release_print("onAdjustAttributionChanged1 = " .. strAttrib)
        jsonAttrib = loadstring(string.format("return %s", strAttrib))()
        -- release_print("onAdjustAttributionChanged2 = " .. cjson.encode(jsonAttrib))
    end
    if jsonAttrib then
        gLobalSendDataManager:getLogGameLoad():sendAdjustAttribLog(jsonAttrib)
    end
end

local dirtyTs = 180

function AdjustManager:ctor()
    self.m_idfa = ""
    self.m_idfa_ts = os.time()
    
    self.m_adid = ""
    self.m_adid_ts = os.time()
end

function AdjustManager:getInstance()
    if AdjustManager.m_instance == nil then
        AdjustManager.m_instance = AdjustManager.new()
    end
    return AdjustManager.m_instance
end

--新手期间
function AdjustManager:checkTriggerNPAdjustLog(msg)
    if not globalData.userRunData:isNewUser() then
        return
    end
    local dealTimes = function(key)
        local times = gLobalDataManager:getNumberByField(key, 0)
        times = times + 1
        gLobalDataManager:setNumberByField(key, times)
        return times
    end
    local key = "AdjustNPEvent_" .. msg
    if msg == AdjustNPEventType.spend_firstly then
        if not globalData.hasPurchase then
            globalAdjustManager:sendAdjustEventId("yu1v3r")
        end
    elseif msg == AdjustNPEventType.click_GoldenVault then
        local times = dealTimes(key)
        if times == 2 then
            globalAdjustManager:sendAdjustEventId("4dkws4")
        elseif times == 3 then
            globalAdjustManager:sendAdjustEventId("2ynbt8")
        end
    elseif msg == AdjustNPEventType.spin then
        local times = dealTimes(key)
        if times == 500 then
            globalAdjustManager:sendAdjustEventId("7dta0d")
        elseif times == 1000 then
            globalAdjustManager:sendAdjustEventId("ah67dm")
        elseif times == 1500 then
            globalAdjustManager:sendAdjustEventId("4fr28j")
        end
    elseif msg == AdjustNPEventType.login then
        local times = dealTimes(key)
        if times == 3 then
            globalAdjustManager:sendAdjustEventId("audgp4")
        elseif times == 4 then
            globalAdjustManager:sendAdjustEventId("yxb6nm")
        elseif times == 5 then
            globalAdjustManager:sendAdjustEventId("oss3hn")
        end
    elseif msg == AdjustNPEventType.click_shop then
        local times = dealTimes(key)
        if times == 2 then
            globalAdjustManager:sendAdjustEventId("xblbr4")
        elseif times == 3 then
            globalAdjustManager:sendAdjustEventId("3jepln")
            --这个点firebase也需要单独统计一下和adjust保持一致
            globalFireBaseManager:sendBaseFirebaseLog("click_shop_3")
        elseif times == 4 then
            globalAdjustManager:sendAdjustEventId("c5bhdg")
        end
    elseif msg == AdjustNPEventType.click_SilverVault then
        local times = dealTimes(key)
        if times == 3 then
            globalAdjustManager:sendAdjustEventId("ac6cvd")
        elseif times == 4 then
            globalAdjustManager:sendAdjustEventId("fxdtcs")
        elseif times == 5 then
            globalAdjustManager:sendAdjustEventId("2vdyt1")
        end
    end
end

--Adjust 升级打点
function AdjustManager:sendAdjustLevelUpLog(curLevel)
    if not curLevel then
        return
    end
    -- --循环打点
    -- for level=lastLevel+1,curLevel do
    --     local key = "Level_"..level
    --     self:sendAdjustKey(key)
    -- end

    --没有跳级直接判断
    local key = "Level_" .. curLevel
    self:sendAdjustKey(key)
end
--Adjust 登录
function AdjustManager:sendAdjustLoginLog(num)
    if not num then
        return
    end
    local key = "Login_" .. num
    self:sendAdjustKey(key)
end
--Adjust统计最终发送
function AdjustManager:sendAdjustKey(key)
    if DEBUG == 2 then
        release_print("Adjust key = " .. key)
    end
    if not AdjustType[key] then
        if DEBUG == 2 then
            release_print("not Adjust key !!!")
        end
        return
    end

    local eventID = AdjustType[key]
    local extraData = {}
    extraData.deviceId = gLobalSendDataManager:getDeviceUuid()
    if gLobalSendDataManager:isLogin() == true then
        extraData.udid = globalData.userRunData.userUdid
    end

    local data = cjson.encode(extraData)
    gLobalAdsControl:adjustEventTrack(eventID, data) -- 用于用户分级
end
--Adjust统计最终发送
function AdjustManager:sendAdjustEventId(eventId)
    if DEBUG == 2 then
        release_print("eventId = " .. eventId)
    end

    local udid = gLobalSendDataManager:getDeviceUuid()
    local extraData = {}
    extraData.udid = udid
    local data = cjson.encode(extraData)
    gLobalAdsControl:adjustEventTrack(eventId, data) -- 用于用户分级
end

function AdjustManager:getAdjustIDFA()
    local _curTs = os.time()
    if device.platform == "ios" then
        -- local idfa = gLobalDataManager:getStringByField("adjust_idfa", "", true)
        if (self.m_idfa == nil or self.m_idfa == "") or (_curTs - self.m_idfa_ts) > dirtyTs then
            local ok, ret = luaCallOCStaticMethod("AppController", "getAdjustIDFA", nil)
            if not ok then
                -- idfa = ""
            else
                if ret ~= nil and ret ~= "0" then
                    self.m_idfa = ret
                    self.m_idfa_ts = _curTs
                    release_print("adjust_idfa:" .. self.m_idfa)
                    -- gLobalDataManager:setStringByField("adjust_idfa", ret)
                else
                    -- idfa = ""
                end
            end
        end
        return self.m_idfa
    else
        return ""
    end
end

function AdjustManager:getAdjustID()
    local _curTs = os.time()
    if device.platform == "ios" then
        -- local idid = gLobalDataManager:getStringByField("adjust_id", "", true)
        if (self.m_adid == nil or self.m_adid == "") or (_curTs - self.m_adid_ts) > dirtyTs then
            local ok, ret = luaCallOCStaticMethod("AppController", "getAdjustID", nil)
            if not ok then
                -- idid = ""
            else
                if ret ~= nil and ret ~= "0" then
                    self.m_adid = ret
                    self.m_adid_ts = _curTs
                    release_print("adjust_id:" .. self.m_adid)
                    -- gLobalDataManager:setStringByField("adjust_id", ret)
                else
                    -- self.m_adid = ""
                end
            end
        end
        return self.m_adid
    elseif device.platform == "android" then
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        if (self.m_adid == nil or self.m_adid == "") or (_curTs - self.m_adid_ts) > dirtyTs then
            local ok, ret = luaj.callStaticMethod(className, "getAdjustID", {}, sig)
            if not ok then
                -- return ""
            else
                -- return ret
                self.m_adid = ret
                self.m_adid_ts = _curTs
            end
        end
        return self.m_adid
    else
        return ""
    end
end

-- 获取归因属性json字符串
function AdjustManager:getAdjustAttJsonStr()
    if util_isSupportVersion("1.9.2", "ios") then
        local ok, ret = luaCallOCStaticMethod("AppController", "getAdjustAttrib", nil)
        if ok then
            ret = ret or {}
            return cjson.encode(ret)
        end
        return ""
    elseif util_isSupportVersion("1.8.5", "android") then
        local sig = "()Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "getAdjustAttrib", {}, sig)
        if not ok then
            return ""
        else
            return tostring(ret)
        end
    else
        return ""
    end
end

return AdjustManager
