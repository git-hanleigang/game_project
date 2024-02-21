--[[--
    好友数据
--]]
local FriendUserData = require("GameModule.Friend.model.FriendUserData")
local FriendData = class("FriendData")

function FriendData:ctor()
end

function FriendData:parseData(_netData)
    self.p_sysFriendMax = _netData.max
    self.p_sysFriendCount = _netData.counts

    self.p_friendUserList = {}
    if _netData.friends and #_netData.friends > 0 then
        self:praseAllFriend(_netData.friends)
    end
    if _netData.fbFriends and #_netData.fbFriends > 0 then
        self:praseAllFriend(_netData.fbFriends)
    end
    self.m_friendIdList = {}
end

function FriendData:praseAllFriend(_list)
    for i = 1, #_list do
        local userData = FriendUserData:create()
        userData:parseData(_list[i])
        table.insert(self.p_friendUserList, userData)
    end
end

--所有好友
function FriendData:getFriendAllList()
    return self.p_friendUserList or {}
end
--上线
function FriendData:getMaxCount()
    return self.p_sysFriendMax or 100
end
--当前有的好友
function FriendData:getCourentCount()
    return self.p_sysFriendCount or 0
end

--设置当前有的好友数量
function FriendData:setCourentCount(_count)
    self.p_sysFriendCount = _count
end

--推荐列表
function FriendData:setCommondList(_data)
    self.m_commondList = _data
end

function FriendData:getCommondList()
    return self.m_commondList or {}
end
--搜索列表
function FriendData:setSerchList(_data)
    self.m_addSerchList = _data
end

function FriendData:getSerchList()
    return self.m_addSerchList or {}
end
--好友请求列表
function FriendData:setRequestList(_data)
    self.m_addRequestList = _data
end

function FriendData:getRequestList()
    return self.m_addRequestList or {}
end
--要卡和送卡列表
function FriendData:setCardList(_data)
    self.m_friendcardList = _data.requestCardInfos
    self.m_mycard = _data.selfCardInfos
    self.m_allcardList = {}
    self.m_receiveList = {}
    if _data.selfCardInfos and #_data.selfCardInfos > 0 then
        for i,v in ipairs(_data.selfCardInfos) do
            v.tab = 1
            v.source = 0
            table.insert(self.m_allcardList,v)
            if v.status and v.status == "received" then
                v.source = 1
                table.insert(self.m_receiveList,v.id)
            end
        end
    end
    table.sort( self.m_allcardList, function(a,b)
            return a.source > b.source
    end )
    if _data.requestCardInfos and #_data.requestCardInfos > 0 then
        table.sort( _data.requestCardInfos, function(a,b)
            return a.expireAt > b.expireAt
        end )
        for i,v in ipairs(_data.requestCardInfos) do
            v.tab = 0
            table.insert(self.m_allcardList,v)
        end
    end
end

--别人给我要卡
function FriendData:getCardList()
    return self.m_friendcardList or {}
end
--我给别人要卡
function FriendData:getMyCardList()
    return self.m_mycard or {}
end

--已经接受到的卡列表
function FriendData:getReveCardList()
    return self.m_receiveList or {}
end

function FriendData:setReveCardList()
    self.m_receiveList = {}
end

function FriendData:getAllCardList()
    return self.m_allcardList or {}
end

function FriendData:setAllCardList(_list)
    self.m_allcardList = _list
end

function FriendData:getMacyList()
    self.m_macyList = {}
    if self.p_friendUserList and #self.p_friendUserList > 0 then 
        self.m_macyList = clone(self.p_friendUserList)
        for i,v in ipairs(self.m_macyList) do
            local first_z = string.sub(v.p_name,1,1)
            v.fr = string.upper(first_z)
        end
        table.sort( self.m_macyList, handler(self, self.sortFunc) )
    end
    return self.m_macyList
end
-- 亲密度>等级>名称首字母>UID
function FriendData:sortFunc(a,b)
    if a.p_friendlinessLevel == b.p_friendlinessLevel then
        if a.p_curFriendliness == b.p_curFriendliness then
            if a.p_level == b.p_level then
                return a.fr > b.fr
            else
                return a.p_level > b.p_level
            end
        else
            return a.p_curFriendliness > b.p_curFriendliness
        end
    else
        return a.p_friendlinessLevel > b.p_friendlinessLevel
    end
end

return FriendData
