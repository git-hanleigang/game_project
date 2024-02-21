--[[
    好友用户数据
]]
local FriendUserData = class("FriendUserData")

function FriendUserData:parseData(_netData)
    self.p_level = _netData.level
    self.p_name = _netData.name
    self.p_udid = _netData.udid
    self.p_vipLevel = _netData.vipLevel

    self.p_facebookId = _netData.facebookId
    self.p_facebookHead = _netData.head
    self.p_facebookHeadFrame = _netData.headFrame

    -- 加好友时间
    self.p_applyTime = _netData.applyTime
    -- 是否是fb好友
    self.p_isFBFriend = _netData.fb
    -- 是否是系统好友
    self.p_isSysFriend = _netData.systemFriend

    -- 亲密度
    self.p_curFriendliness = _netData.friendliness
    self.p_maxFriendliness = _netData.maxFriendliness
    self.p_friendlinessLevel = _netData.friendlinessLevel
end

function FriendUserData:getLevel()
    return self.p_level
end

function FriendUserData:getName()
    return self.p_name
end

function FriendUserData:getUDID()
    return self.p_udid
end

function FriendUserData:getFacebookId()
    return self.p_facebookId
end

function FriendUserData:getFacebookHead()
    return self.p_facebookHead
end

function FriendUserData:getApplyTime()
    return self.p_applyTime
end

function FriendUserData:isFBFriend()
    if self.p_isSysFriend == true then
        return false
    end
    return self.p_isFBFriend == true
end

function FriendUserData:isSysFriend()
    return self.p_isSysFriend == true
end

function FriendUserData:getCurFriendliness()
    return self.p_curFriendliness
end

function FriendUserData:getMaxFriendliness()
    return self.p_maxFriendliness
end

function FriendUserData:getFriendlinessLevel()
end

return FriendUserData
