--[[--
    manager类
--]]
-- 加载配置
require("GameModule.Friend.config.FriendConfig")

local FriendManager = class("FriendManager", BaseGameControl)

function FriendManager:ctor()
    FriendManager.super.ctor(self)
    self:setRefName(G_REF.Friend)
    self:setResInApp(true)
end

function FriendManager:parseData(_netData)
    if not _netData then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.Friend.model.FriendData"):create()
        _data:parseData(_netData)
        self:registerData(_data)
    else
        _data:parseData(_netData)
    end
    self:setSyncDataTime(self:getServerTime())
end

function FriendManager:getData()
    return globalData.friendData
end

function FriendManager:getServerTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

function FriendManager:setSyncDataTime(_curTime)
    self.m_syncDataTime = _curTime
end

function FriendManager:getSyncDataTime()
    return self.m_syncDataTime or 0
end

function FriendManager:setAdduid(_uid)
    self.add_uid = _uid
end

function FriendManager:getAdduid()
    return self.add_uid
end

function FriendManager:setAddStuts(_status)
    self.add_status = _status
end

function FriendManager:getAddStuts()
    return self.add_status or 0
end

function FriendManager:setDeleteuid(_uid)
    self.delete_uid = _uid
end

function FriendManager:getDeleteuid()
    return self.delete_uid
end

function FriendManager:getMaxCount()
    return self:getData():getMaxCount() or 0
end

-- 请求好友列表CD
function FriendManager:isInRequestAllFriendCD()
    local preTime = self:getSyncDataTime()
    local curTime = self:getServerTime()
    if preTime > 0 and curTime - preTime < FriendConfig.RequestAllFriendCD then
        return true
    end
    return false
end

-- 拉取最新的好友数据，先拉取sdk好友数据
function FriendManager:pGetAllFriendList(_callback, _isFriendIgnoreCD, _type)
    if device.platform == "mac" then
        self:getAllFriendList(_callback, _isFriendIgnoreCD, _type)
    else
        G_GetMgr(G_REF.FBFriend):pGetSDKFBFriendList(
            function()
                self:getAllFriendList(_callback, _isFriendIgnoreCD, _type)
            end,
            _isSDKIgnoreCD
        )
    end
end

-- 拉取最新的好友数据 _type只有刚打开好友界面的时候有
function FriendManager:getAllFriendList(_callback, _isIgnoreCD, _type)
    -- 判断cd
    if not _isIgnoreCD and self:isInRequestAllFriendCD() then
        if _callback then
            _callback()
        end
        return
    end
    local fbids = self:getFaceBookId()      
    local successFunc = function(_netData)
        if _callback then
            _callback()
        end
        gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.FRIEND_ALL_LIST, _type)
    end
    local fileFunc = function()
        if _fail then
            _fail()
        end
    end
    G_GetNetModel(NetType.Friend):requestAllFriendList(fbids, successFunc, fileFunc)
end

-- 拉取推荐列表
function FriendManager:getCommondList()
    local successFunc = function(_netData)
        self:getData():setCommondList(_netData.recommends)
        gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.COMMOND_LIST)
    end
    local fileFunc = function()
    end
    G_GetNetModel(NetType.Friend):requestCommondList(successFunc, fileFunc)
end

-- 搜索好友
function FriendManager:requestSerchList(content)
    local successFunc = function(_netData)
        self:getData():setSerchList(_netData)
        gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.ADD_SERCH_LIST)
    end
    local fileFunc = function()
    end
    G_GetNetModel(NetType.Friend):requestSerchList(content, successFunc, fileFunc)
end

-- 添加好友
function FriendManager:requestAddFriend(_type, _uid, _content, _source)
    local successFunc = function(_netData)
        if _type == "Apply" then
            self:setAddStuts(0)
            gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.ADD_SERCH_SUCCESS, _content)
        elseif _type == "Delete" then
            --筛选删除的好友
            self:updataHelpList(_uid)
            self:updataFriendList(_uid)
            gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.FRIEND_ALL_LIST)
        else
            self:pGetAllFriendList()
            local param = {type = _type, uid = _uid}
            gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.REQUEST_FRIEND, param)
        end
    end
    local fileFunc = function()
        self:setAddStuts(0)
    end
    local extraData = {}
    extraData.operateType = _type
    extraData.uid = _uid
    extraData.fbids = self:getFaceBookId()
    extraData.source = _source
    G_GetNetModel(NetType.Friend):requestAddFriend(extraData, successFunc, fileFunc)
end
--[[--
    position:
        SendCard: 处理好友请求卡
        Null: 邮箱送卡送钱
        Receive: 接受别人送卡 
]]
function FriendManager:requestSendCard(_position, _dealId, _mailType, _friendUdid, _cards, _success, _fail)
    local successFunc = function(_netData)
        local param = {}
        param.cardId = _dealId
        param.type = 2
        if _position ~= "Receive" then
            gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.CARD_SUCCESS, param)
        end
        if _success then
            _success(_netData)
        end
    end
    local fileFunc = function(errorCode)
        if _fail then
            _fail()
        end
    end
    local extraData = {}
    extraData.position = _position
    extraData.dealId = _dealId
    extraData.mailType = _mailType
    extraData.friendUdid = _friendUdid
    if _position == "Receive" then
        extraData.dealIds = _cards
    else
        extraData.cards = _cards
    end
    G_GetNetModel(NetType.Friend):requestSendCard(extraData, successFunc, fileFunc)
end
-- 添加好友列表 _type只有刚打开好友界面的时候有
function FriendManager:requestAddFriendList(_type)
    local successFunc = function(_netData)
        local num = 0
        if self:getData() and _netData.requests then
            num = #_netData.requests
            self:setLobbyBottomNum(num)
            self:getData():setRequestList(_netData.requests)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRIEND_TIP, num)
        local param = {}
        param.type = _type
        param.num = num
        gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.REQUEST_FRIEND_LIST, param)
    end
    local fileFunc = function(errorCode, errorData)
    end
    if not _type then
        gLobalViewManager:addLoadingAnima()
    end
    G_GetNetModel(NetType.Friend):requestAddFriendList(successFunc, fileFunc)
end

-- 要卡和送卡列表
function FriendManager:requestFriendCardList()
    local successFunc = function(_netData)
        if self:getData() then
            self:getData():setCardList(_netData)
        end
        gLobalNoticManager:postNotification(FriendConfig.EVENT_NAME.CARD_FRIEND)
    end
    local fileFunc = function(errorCode, errorData)
    end
    G_GetNetModel(NetType.Friend):requestFriendCardList(successFunc, fileFunc)
end

-- 向好友要卡
function FriendManager:requestApplyFriendCard(cardId)
    local successFunc = function(_netData)
        if _netData and _netData.askChipCD then
            if CardSysRuntimeMgr then
                CardSysRuntimeMgr:setAskCD(tonumber(_netData.askChipCD))
                gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_COUNTDOWN_UPDATE)
            end
        end
    end
    local fileFunc = function(errorCode, errorData)
    end
    G_GetNetModel(NetType.Friend):requestApplyFriendCard(cardId, successFunc, fileFunc)
end

--搜索
function FriendManager:stringMatch(_friendDatas, _input)
    -- 条件筛选：输入搜索
    if _input and _input ~= "" then
        local indexTemp = {}
        local matchingIndexs = {}
        for i = 1, #_friendDatas do
            local oriData = _friendDatas[i]
            local startIndex, overIndex = string.find(string.lower(oriData.p_name), string.lower(_input), nil, true)
            if startIndex ~= nil then
                indexTemp[#indexTemp + 1] = {matchingType = 1, startIndex = startIndex, data = oriData}
                matchingIndexs[#matchingIndexs + 1] = i
            end
        end

        if string.find(_input, " ") then
            for i = 1, #_friendDatas do
                local isMatching = false
                for j = 1, #matchingIndexs do
                    if i == matchingIndexs[j] then
                        isMatching = true
                    end
                end
                if not isMatching then
                    local oriData = _friendDatas[i]
                    local startIndex, overIndex = string.find(string.lower(string.gsub(oriData.p_name, " ", "")), string.lower(string.gsub(content, " ", "")), nil, true)
                    if startIndex ~= nil then
                        indexTemp[#indexTemp + 1] = {matchingType = 2, startIndex = startIndex, data = oriData}
                    end
                end
            end
        end

        local temp = {}
        if #indexTemp > 0 then
            table.sort(
                indexTemp,
                function(a, b)
                    if a.matchingType == b.matchingType then
                        if a.startIndex == b.startIndex then
                            if a.data.p_name == b.data.p_name then
                                return a.data.p_udid == b.data.p_udid
                            else
                                return a.data.p_name <= b.data.p_name
                            end
                        else
                            return a.startIndex <= b.startIndex
                        end
                    else
                        return a.matchingType < b.matchingType
                    end
                end
            )

            for i = 1, #indexTemp do
                temp[#temp + 1] = indexTemp[i].data
            end
        end
        return temp
    else
        return _friendDatas
    end
end

function FriendManager:getIsMyFriend(_uuid)
    local list = self:getAllFriend()
    local isf = false
    if list and #list > 0 then
        for i,v in ipairs(list) do
            if v.p_udid == _uuid and v.p_isSysFriend then
                isf = true
                break
            end
        end
    end
    return isf
end

function FriendManager:getLobbyBottomNum()
    return self.red_num or 0
end

function FriendManager:setLobbyBottomNum(_rednum)
    self.red_num = _rednum
end

function FriendManager:getAllFriend()
    return self:getData():getFriendAllList()
end

function FriendManager:updataHelpList(_uid)
    local list = self:getData():getAllCardList()
    if list and #list > 0 then
        for i,v in ipairs(list) do
            if _uid == v.udid then
                table.remove(list,i)
                break
            end
        end
    end
end

function FriendManager:updataFriendList(_uid)
    local list = self:getData():getFriendAllList()
    if list and #list > 0 then
        for i,v in ipairs(list) do
            if _uid == v.p_udid then
                if v.p_isSysFriend then
                    local count = self:getData():getCourentCount() - 1
                    self:getData():setCourentCount(count)
                end
                table.remove(list,i)
                break
            end
        end
    end
end

function FriendManager:getFaceBookId()
    local FBFriendData = G_GetMgr(G_REF.FBFriend):getData()
    local fbids = {}
    if FBFriendData then
        fbids = FBFriendData:getFBFriendFBIds()
        if fbids == nil then
            fbids = {}
        end
    end 
    return fbids
end

function FriendManager:getThemeName(refName)
    return "Friend"
end

function FriendManager:showMainLayer(param)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("views.FirendCode.FirendMainLayer", param)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function FriendManager:showAddLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("views.FirendCode.FirendAddLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function FriendManager:showRequstLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("views.FirendCode.FirendRequestLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function FriendManager:showRulesLayer()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("views.FirendCode.FirendRuleLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function FriendManager:showErrorLayer(_callback)
    local view =
        util_createView(
        "views.dialogs.DialogLayer",
        "Dialog/Friend.csb",
        function()
            if _callback then
                _callback()
            end
        end,
        nil,
        false,
        {
            {buttomName = "btn_ok", labelString = "I SEE"}
        }
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

return FriendManager
