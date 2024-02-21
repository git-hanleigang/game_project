
--[[
    神秘宝箱系统
]]
local BoxSystemGroupData = class("BoxSystemGroupData")

function BoxSystemGroupData:ctor()
    self.p_groupName = ""
    self.p_num = 0
    self.p_activityName = ""
    self.p_icon = ""
end

--[[
    message PassMysteryBoxGroup {
        optional string groupName = 1; //分组
        optional int32 num = 2;//宝箱数量
    }
]]
function BoxSystemGroupData:parseData(data)
    self.p_groupName = tostring(data.groupName or "")
    self.p_num = tonumber(data.num or 0)
    local splitArr = string.split(self.p_groupName, "|")
    if splitArr and #splitArr > 1 then
        self.p_activityName = splitArr[1]
        self.p_icon = splitArr[2]
    end
end

-- 规则："活动名|宝箱道具icon名|活动结束时间戳（毫秒）" 例如 "Pass|Box_Christmas|1703131979000"
function BoxSystemGroupData:getGroupName()
    return self.p_groupName
end

function BoxSystemGroupData:getNum()
    return self.p_num
end

function BoxSystemGroupData:getActivityName()
    return self.p_activityName
end

function BoxSystemGroupData:getIcon()
    return self.p_icon
end

return BoxSystemGroupData