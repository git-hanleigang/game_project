--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-12-27 10:53:18
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-12-27 10:53:48
FilePath: /SlotNirvana/src/data/clanData/ClanBaseInfoData.lua
Description: 公会基本数据
--]]
local ClanConfig = require "data.clanData.ClanConfig"
local ClanBaseInfoData = class("ClanBaseInfoData")

function ClanBaseInfoData:ctor()
    self.m_cid = "" --ID
    self.m_name = "" --名称
    self.m_logo = "1" --logo
    self.m_joinType = ClanConfig.joinLimitType.PUBLIC --类型(1,自由出入 2,需要申请)
    self.m_minVipLevel = 1 --公会准入最小VIP等级
    self.m_description = "" --描述
    self.m_countryArea = "" --工会所属国家地区
    self.m_tag = "" --工会标签
    self.m_division = 1 --排行榜 段位

    self.m_curMemCount = 0 -- 成员人数
    self.m_limitMemCount = 0 -- 成员人数上限
end

function ClanBaseInfoData:parseData(_data)
    if not _data then
        return
    end

    self.m_cid = _data.cid or "" --ID
    self.m_name = _data.name or "" --名称
    self.m_logo = _data.head or "1" --logo
    self.m_joinType = _data.type or ClanConfig.joinLimitType.PUBLIC --类型(1,自由出入 2,需要申请)
    self.m_minVipLevel = _data.minLevel or 1 --公会准入最小VIP等级
    self.m_description = _data.description or "" --描述
    self.m_countryArea = _data.countryArea or "" --工会所属国家地区
    self.m_tag = _data.tag or "" --工会标签
    self.m_division = math.max(1, tonumber(_data.division) or 1) --排行榜 段位
end

-- 设置 成员人数
function ClanBaseInfoData:setCurMemberCount(_count)
    self.m_curMemCount = _count or 0
end
function ClanBaseInfoData:getCurMemberCount()
    return self.m_curMemCount
end
-- 设置 成员人数上限
function ClanBaseInfoData:setLimitMemberCount(_count)
    self.m_limitMemCount = _count or 0
end
function ClanBaseInfoData:getLimitMemberCount()
    return self.m_limitMemCount
end

-- 获取公会id
function ClanBaseInfoData:getTeamCid()
    return self.m_cid
end
-- 获取公会名称
function ClanBaseInfoData:getTeamName()
    return self.m_name
end
-- 获取公会logo
function ClanBaseInfoData:getTeamLogo()
    return self.m_logo
end
function ClanBaseInfoData:setTeamLogo(_logo)
    self.m_logo = _logo
end
-- 获取公会加入类型
function ClanBaseInfoData:getTeamJoinType()
    return self.m_joinType
end
function ClanBaseInfoData:setTeamJoinType(_type)
    self.m_joinType = _type
end
-- 获取公会准入最小VIP等级
function ClanBaseInfoData:getTeamMinVipLevel()
    return self.m_minVipLevel
end
function ClanBaseInfoData:setTeamMinVipLevel(_vipLv)
    self.m_minVipLevel = _vipLv
end
-- 获取公会描述
function ClanBaseInfoData:getTeamDesc()
    return self.m_description
end
-- 获取公会所属国家地区
function ClanBaseInfoData:getTeamCountryArea()
    return self.m_countryArea
end
function ClanBaseInfoData:setTeamCountryArea(_area)
    self.m_countryArea = _area
end
-- 获取公会标签
function ClanBaseInfoData:getTeamTag()
    return self.m_tag
end
function ClanBaseInfoData:setTeamTag(_tag)
    self.m_tag = _tag
end
-- 获取公会排行榜 段位
function ClanBaseInfoData:getTeamDivision()
    return self.m_division
end
function ClanBaseInfoData:setTeamDivision(_division)
    if not _division then
        return
    end

    self.m_division = _division
end

return ClanBaseInfoData