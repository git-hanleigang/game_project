--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-07 10:46:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-07 10:46:20
FilePath: /SlotNirvana/src/activities/Activity_Leagues/model/LeagueTrophyData.lua
Description: 巅峰竞技场奖杯数据 登录显示 个人信息页里展示
--]]
local TrophyInfoData = class("TrophyInfoData")
function TrophyInfoData:ctor(_info)
    self.m_type = _info.type  --奖杯类型
    self.m_number = _info.number  --奖杯数量
end
function TrophyInfoData:getType()
    return self.m_type
end
function TrophyInfoData:getNumber()
    return self.m_number or 0
end

local LeagueTrophyData = class("LeagueTrophyData")
function LeagueTrophyData:ctor()
    self.m_list = {}
end

function LeagueTrophyData:parseData(_list)
    if not _list then
        return
    end

    self.m_list = {}
    for i=1, #_list do
        local data = TrophyInfoData:create(_list[i])
        table.insert(self.m_list, data)
    end
end

-- 获取奖杯 新系
function LeagueTrophyData:getTrophyList()
    return self.m_list
end

return LeagueTrophyData