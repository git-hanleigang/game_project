--[[--
    游戏公告 控制类
]]
local NetWorkBase = util_require("network.NetWorkBase")
local AnnouncementData = util_require("data.announcement.AnnouncementData")
local AnnouncementManager = class("AnnouncementManager", NetWorkBase)

function AnnouncementManager:ctor()
    AnnouncementManager.super.ctor(self)
end

function AnnouncementManager:getInstance()
    if not self._instance then
        self._instance = AnnouncementManager:create()
        self._instance:initBaseData()
    end
    return self._instance
end

function AnnouncementManager:initBaseData()
    self.m_announcementData = nil
    self:registerObserver()

    self.m_annCd = {}

    self.m_annCd = cjson.decode(gLobalDataManager:getStringByField("annCd", "{}"))
end

-- function AnnouncementManager:setAnnouncementData(_netData)
--     self.m_announcementData = _netData
-- end

function AnnouncementManager:parseData(data)
    local _annData = AnnouncementData:create()
    _annData:parseData(data)
    self.m_announcementData = _annData
end

function AnnouncementManager:getAnnouncementData()
    -- return self.m_announcementData
    return self.m_curAnnInfo
end

-- 是否CD中
function AnnouncementManager:isCd(info)
    local id = info:getId()
    local ts = self.m_annCd["" .. id] or 0
    local serverTs = math.floor(globalData.userRunData.p_serverTime / 1000)
    if ts > serverTs then
        return true
    else
        return false
    end
end

-- 添加Cd时间
function AnnouncementManager:addCd(info)
    if info:getCd() <= 0 then
        return
    end

    local id = info:getId()

    local serverTs = math.floor(globalData.userRunData.p_serverTime / 1000)
    self.m_annCd["" .. id] = serverTs + info:getCd()

    local strCD = cjson.encode(self.m_annCd)
    gLobalDataManager:setStringByField("annCd", strCD)
end

function AnnouncementManager:isOpenLv(info)
    local _curLv = (globalData.userRunData.levelNum or 0)
    local _lowerLv = info:getLowerLv()
    local _upperLv = info:getUpperLv()
    if _curLv < _lowerLv then
        return false
    end

    if _curLv > _upperLv then
        return false
    end

    return true
end

function AnnouncementManager:checkPlate(info)
    local plate = info:getPlate()
    if plate == "all" then
        return true
    end

    return (plate == device.platform)
end

function AnnouncementManager:registerObserver()
    -- -- TODO:在PopViewConfig中使用此弹框，有可能出现异步问题
    -- -- 服务器返回成功消息
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, data)
    --         -- 监听一次登陆就移除
    --         gLobalNoticManager:removeObserver(self, HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS)
    --         -- 发送游戏公告请求并解析数据
    --         self:sendAnnouncementLogin()
    --     end,
    --     HTTP_MESSAGE_TYPES.HTTP_TYPE_LOGIN_SUCCESS
    -- )
end

function AnnouncementManager:sendMessageData(body, successCallBack, failedCallBack)
    if gLobalSendDataManager:isLogin() then
        AnnouncementManager.super.sendMessageData(self, body, successCallBack, failedCallBack)
    end
end

--[[
    @desc: 实时强制公告
    time:2021-08-24 15:55:51
    @return:
]]
function AnnouncementManager:requestAnnouncement(callback)
    -- local callFunc = function()
    --     if callback then
    --         callback()
    --     end
    -- end

    self.m_isURLResponsed = false
    self:sendAnnoucementUrl(
        function()
            -- if self:checkAnnouncement(1) then
            --     self:showAnnouncementUI()
            -- else
            --     callFunc()
            -- end
            if self.m_isURLResponsed == true then
                return
            end
            self.m_isURLResponsed = true
            gLobalNoticManager:postNotification("GL_EVENT_ANNOUNCEMENT_SUCCESS")
        end,
        function()
            -- callFunc()
            if self.m_isURLResponsed == true then
                return
            end
            self.m_isURLResponsed = true
            gLobalNoticManager:postNotification("GL_EVENT_ANNOUNCEMENT_FAILD")
        end
    )

    -- 请求超过3秒后没有返回结果，继续逻辑
    local node = cc.Node:create()
    gLobalViewManager:getViewLayer():addChild(node)
    util_performWithDelay(
        node,
        function()
            if self.m_isURLResponsed == true then
                node:removeFromParent()
                node = nil
                return
            end
            self.m_isURLResponsed = true
            -- callFunc()
            gLobalNoticManager:postNotification("GL_EVENT_ANNOUNCEMENT_FAILD")
            node:removeFromParent()
            node = nil
        end,
        3
    )
end

-- 登陆前请求公告数据
function AnnouncementManager:sendAnnoucementUrl(_successFunc, _failFunc)
    self.sendHttpRequest(
        "https://cashtornado-slots.com/notice.json",
        "GET",
        30,
        function(responseData)
            if responseData ~= nil then
                if type(responseData) == "string" then
                    if responseData ~= "null" then
                        local rData = util_cjsonDecode(responseData)
                        if rData ~= nil then
                            -- 解析数据
                            -- local aData = AnnouncementData:create()
                            -- aData:parseData(rData)
                            -- self:setAnnouncementData(aData)
                            self:parseData(rData)
                            -- 成功回调
                            if _successFunc then
                                _successFunc()
                            end
                            return
                        else
                            -- util_sendToSplunkMsg("NoitceError", tostring(responseData) .. ", " .. tostring(errorStr))
                            release_print("---------- sendHttpRequest success, but rData is nil")
                        end
                    else
                        release_print("---------- sendHttpRequest success, but responseData type is null ----------")
                    end
                else
                    release_print("---------- sendHttpRequest success, but responseData type is not string ----------")
                end
            else
                release_print("---------- sendHttpRequest success, but responseData is nil ----------")
            end
            if _failFunc then
                _failFunc()
            end
        end,
        function(responseCode, responseData)
            release_print("---------- sendHttpRequest failure, responseCode ----------" .. tostring(responseCode or "responseCode is nil") .. ", " .. tostring(responseData or "responseData is nil"))
            if _failFunc then
                _failFunc()
            end
        end
    )
end

-- 登陆后请求公告数据
function AnnouncementManager:sendAnnouncementLogin(_doNext)
    local success = function(target, resultData)
        if resultData ~= nil then
            if resultData.result ~= nil and resultData.result ~= "null" and resultData.result ~= "" then
                local rData = cjson.decode(resultData.result)
                if rData.error ~= nil then
                    release_print("---------- MandatoryAnnouncement success, but resultData.result.error is ----------" .. rData.error)
                else
                    -- 解析数据
                    -- local aData = AnnouncementData:create()
                    -- aData:parseData(rData)
                    -- self:setAnnouncementData(aData)
                    self:parseData(rData)
                end
            else
                release_print("---------- MandatoryAnnouncement success, but resultData.result is null ----------")
            end
        else
            release_print("---------- MandatoryAnnouncement success, but resultData is nil ----------")
        end
        if _doNext then
            _doNext()
        end
    end

    local fail = function(target, errorCode, errorData)
        release_print("---------- MandatoryAnnouncement fail errorCode, errorData ----------" .. tostring(errorCode) .. ", " .. tostring(errorData))
        if _doNext then
            _doNext()
        end
    end

    local actionData = self:getSendActionData(ActionType.MandatoryAnnouncement)
    local params = {}
    actionData.data.params = json.encode(params)
    self:sendMessageData(actionData, success, fail)
end

function AnnouncementManager:checkAnnouncement(_pos)
    self.m_curAnnInfo = nil
    if not self.m_announcementData then
        return false
    end

    local datas = self.m_announcementData:getAnnDatas(_pos)

    for i = 1, #datas do
        local data = datas[i]

        if data and self:isOpenLv(data) and self:checkPlate(data) and (not self:isCd(data)) and (data:getDesc() ~= "") then
            self.m_curAnnInfo = data
            break
        end
    end

    if self.m_curAnnInfo then
        return true
    else
        return false
    end
end

function AnnouncementManager:showAnnouncementUI(_closeCall)
    local ui = util_createView("views.Announcement.AnnouncementUI", _closeCall)
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    self:addCd(self.m_curAnnInfo)
    self.m_curAnnInfo = nil
end

return AnnouncementManager
