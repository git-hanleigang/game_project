--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 16:50:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 16:51:00
FilePath: /SlotNirvana/src/data/clanData/ClanRushMemberData.lua
Description: 公会rush 各玩家的贡献数据
--]]
local ClanRushMemberData = class("ClanRushMemberData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ClanRushMemberData:ctor(_coins, _itemList)
    self.m_name = "" --成员名称
    self.m_head = 0 --图像
    self.m_uid = "" --用户id
    self.m_udid = "" --用户udid
    self.m_frameId = "" --用户头像框
    self.m_facebookId = "" --facebook ID
    self.m_level = 0 --等级
    self.m_progress = 0-- 贡献进度
    self.m_rank = 1 -- 玩家贡献排名
    self.m_coins = _coins or 0 -- 预计奖励金币
    self.m_rewardList = _itemList or {}
end

function ClanRushMemberData:parseData(_data)
    if not _data then
        return
    end

    self.m_name = _data.name or "" --成员名称
    self.m_head = _data.head or 0 --图像
    self.m_uid = _data.uid --用户id
    self.m_udid = _data.udid --用户udid
    self.m_frameId = _data.frame --用户头像框
    self.m_facebookId = _data.facebookId --facebook ID
    self.m_level = _data.level or 1 --等级
    self.m_progress = tonumber(_data.progress) or 0 -- 贡献进度
    self.m_rank = _data.order or 1 -- 玩家贡献排名
    self.m_bMe = self.m_udid == globalData.userRunData.userUdid
end

function ClanRushMemberData:checkIsBMe()
    return self.m_bMe
end

-- 玩家贡献排名
function ClanRushMemberData:getRank()
    return self.m_rank
end

--成员名称
function ClanRushMemberData:getName()
    if self.m_bMe then
        self.m_name = globalData.userRunData.nickName
    end
    return self.m_name
end
--图像
function ClanRushMemberData:getHead()
    if self.m_bMe then
        self.m_head = globalData.userRunData.HeadName
    end
    return self.m_head
end
--用户id
function ClanRushMemberData:getUid()
    return self.m_uid
end
--用户udid
function ClanRushMemberData:getUdid()
    return self.m_udid
end
--用户头像框
function ClanRushMemberData:getFrameId()
    if self.m_bMe then
        self.m_frameId = globalData.userRunData.avatarFrameId
    end
    return self.m_frameId
end
--facebook ID
function ClanRushMemberData:getFacebookId()
    return self.m_facebookId
end
--等级
function ClanRushMemberData:getLevel()
    return self.m_level
end
--贡献进度
function ClanRushMemberData:getProgress()
    return self.m_progress
end
-- 获取玩家预计奖励
function ClanRushMemberData:getRewardCoins()
    return self.m_progress>0 and self.m_coins or 0
end
function ClanRushMemberData:getRewardList()
    return self.m_progress>0 and self.m_rewardList or {}
end

return ClanRushMemberData