--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-13 15:48:39
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-13 15:48:53
FilePath: /SlotNirvana/src/data/clanData/ClanRedGiftCollectDeailData.lua
Description: 红包领取信息
--]]
local UserInfo = class("UserInfo")
function UserInfo:ctor()
    self.m_name = "" --成员名称
    self.m_dollars = 0 -- 领取的美刀价值
    self.m_coins = 0 --领取的金币
    self.m_head = 0 --图像
    self.m_udid = "" --用户udid
    self.m_frameId = "" --用户头像框
    self.m_facebookId = "" --facebook ID
end
function UserInfo:parseData(_data)
    self.m_name = _data.name or "" --成员名称
    self.m_dollars = tonumber(_data.dollars) or 0  -- 领取的美刀价值
    self.m_coins = tonumber(_data.coins) or 0  --领取的金币
    self.m_head = _data.head or 0--图像
    self.m_udid = _data.udid or "" --用户udid
    self.m_frameId = _data.frame --用户头像框
    self.m_facebookId = _data.facebookId --facebook ID
end
--成员名称
function UserInfo:getName()
    return self.m_name
end
--领取的美刀价值
function UserInfo:getDollars()
    return self.m_dollars
end
--领取的金币
function UserInfo:getCoins()
    return self.m_coins
end
--图像
function UserInfo:getHead()
    return self.m_head
end
--用户udid
function UserInfo:getUdid()
    return self.m_udid
end
--用户头像框
function UserInfo:getFrameId()
    return self.m_frameId
end
--facebook ID
function UserInfo:getFacebookId()
    return self.m_facebookId
end


local ClanRedGiftCollectDeailData = class("ClanRedGiftCollectDeailData")

function ClanRedGiftCollectDeailData:ctor()
    self.m_dollars = 0 --领取美刀
    self.m_coins = 0 --领取金币
    self.m_collectUserList = {} --领取用户列表
    self.m_remainCount = 0 --剩余个数
    self.m_totalCount = 0 --总个数
    self.m_redPackageOwner = UserInfo:create() --发红包人
end

function ClanRedGiftCollectDeailData:parseData(_data, _msgType)
    if not _data then
        return
    end
    
    self.m_dollars = tonumber(_data.dollars) or 0 --self领取美刀
    self.m_coins = tonumber(_data.coins) or 0 --self领取金币
    self.m_collectUserList = {} --领取用户列表
    self:parseMemberList(_data.collectUsers or {})
    self.m_remainCount = _data.remainCount or 0 --剩余个数
    self.m_totalCount = _data.totalCount or 0 --总个数
    self.m_redPackageOwner:parseData(_data.redPackageOwner) --发红包人
    self.m_totalDollars = tonumber(_data.totalDollars) or 0 -- 消息总美刀

    self.m_msgType = _msgType -- 消息类型 ALL  ASSIGN
end

--领取用户列表
function ClanRedGiftCollectDeailData:parseMemberList(_list)
    for i=1, #_list do
        local userInfoData = UserInfo:create()
        userInfoData:parseData(_list[i])

        table.insert(self.m_collectUserList, userInfoData)
    end

    table.sort(self.m_collectUserList, function(_a, _b)
        return _a:getDollars() > _b:getDollars()
    end)
end

--领取的美刀价值
function ClanRedGiftCollectDeailData:getDollars()
    return self.m_dollars
end
-- 消息总美刀
function ClanRedGiftCollectDeailData:getTotalDollars()
    return self.m_totalDollars
end
--领取的金币
function ClanRedGiftCollectDeailData:getCoins()
    return self.m_coins
end
--领取用户列表
function ClanRedGiftCollectDeailData:getCollectUserList()
    return self.m_collectUserList
end
--已领取个数
function ClanRedGiftCollectDeailData:getHadColCount()
    return #self.m_collectUserList
end
--剩余个数
function ClanRedGiftCollectDeailData:getRemainCount()
    return self.m_remainCount
end
--总个数
function ClanRedGiftCollectDeailData:getTotalCount()
    return self.m_totalCount
end
--发红包人的名字
function ClanRedGiftCollectDeailData:getRedPackageOwner()
    return self.m_redPackageOwner
end
--获取消息类型
function ClanRedGiftCollectDeailData:getMsgType()
    return self.m_msgType
end

return ClanRedGiftCollectDeailData