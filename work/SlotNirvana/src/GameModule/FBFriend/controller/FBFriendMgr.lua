--[[--
    manager类
--]]
-- 加载配置
require("GameModule.FBFriend.config.FBFriendCfg")

local FBFriendMgr = class("FBFriendMgr", BaseGameControl)

function FBFriendMgr:ctor()
    FBFriendMgr.super.ctor(self)
    self:setRefName(G_REF.FBFriend)

    if FBFriendCfg.TEST_MODE == true then
        local testData = {
            {id = "131990378400545", name = "Kevin Cormac"},
            {id = "100387872519946", name = "李小帅"},
            {id = "155623057183388", name = "Zhang Yapeng"},
            {id = "112053358368087", name = "Yapeng Zhang"}
        }
        self:parseData({["data"] = testData})
    end
end

function FBFriendMgr:parseData(_netData)
    if not _netData then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.FBFriend.model.FBFriendData"):create()
        _data:parseData(_netData)
        self:registerData(_data)
    else
        _data:parseData(_netData)
    end
    self:setSyncDataTime(self:getServerTime())
end

function FBFriendMgr:getServerTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

function FBFriendMgr:setSyncDataTime(_curTime)
    self.m_syncDataTime = _curTime
end

function FBFriendMgr:getSyncDataTime()
    return self.m_syncDataTime or 0
end

-- 请求好友列表CD
function FBFriendMgr:isInCD()
    local preTime = self:getSyncDataTime()
    local curTime = self:getServerTime()
    if preTime > 0 and curTime - preTime < FBFriendCfg.RequestAllFBFriendCD then
        return true
    end
    return false
end

-- 拉取最新的好友数据
function FBFriendMgr:pGetSDKFBFriendList(_callback, _isIgnoreCD)
    local function callFunc()
        if _callback then
            _callback()
        end
    end
    if self:isLoginFB() == false then
        callFunc()
        return
    end
    if not _isIgnoreCD and self:isInCD() then
        callFunc()
        return
    end
    self:requestAllFBFriendList(callFunc)
end

-- 拉取好友列表
function FBFriendMgr:requestAllFBFriendList(_success, _fail)
    local function callback(data)
        release_print("dayin-------",data)
        local jsonData = util_cjsonDecode(data)
        if jsonData and jsonData.friendList ~= nil and jsonData.friendList.data ~= nil then
            if jsonData.flag then
                self:parseData(jsonData.friendList)
            end
        end
        if _success then
            _success()
        end
    end
    globalFaceBookManager:getFaceBookFriendList(callback)
end

function FBFriendMgr:isLoginFB()
    return gLobalSendDataManager:getIsFbLogin() == true
end

return FBFriendMgr
