--[[
    sdk fb好友用户信息
]]
local FBFriendInfoData = class("FBFriendInfoData")

function FBFriendInfoData:parseData(_netData)
    self.p_id = _netData.id
    self.p_name = _netData.name
    release_print("!!! Facebook id = " .. self.p_id .. ", name = " .. self.p_name)
end

function FBFriendInfoData:getFacebookId()
    return self.p_id
end

function FBFriendInfoData:getFacebookName()
    return self.p_name
end

return FBFriendInfoData
