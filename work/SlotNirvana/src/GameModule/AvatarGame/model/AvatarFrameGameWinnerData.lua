--[[
--]]
local AvatarFrameGameWinnerData = class("AvatarFrameGameWinnerData")

-- message AvatarFrameGameWinner {
--     optional string name = 1;//成员名称
--     optional string head = 2;//图像
--     optional string udid = 3;//udid
--     optional string facebookId = 4;//facebook ID
--     optional string frame = 5; //头像框
--   }
function AvatarFrameGameWinnerData:ctor()
    self.m_name = ""
    self.m_head = ""
    self.m_udid = ""
    self.m_facebookId = ""
    self.m_frame = ""
end

function AvatarFrameGameWinnerData:parseData(_data)
    if not _data then
        return
    end

    self.m_name = _data.name
    self.m_head = _data.head
    self.m_udid = _data.udid
    self.m_facebookId = _data.facebookId
    self.m_frame = _data.frame
end

function AvatarFrameGameWinnerData:getName()
    return self.m_name
end

function AvatarFrameGameWinnerData:getHead()
    return self.m_head
end

function AvatarFrameGameWinnerData:getFacebookId()
    return self.m_facebookId
end

function AvatarFrameGameWinnerData:getUdid()
    return self.m_udid
end

function AvatarFrameGameWinnerData:getFrame()
    return self.m_frame
end

return AvatarFrameGameWinnerData