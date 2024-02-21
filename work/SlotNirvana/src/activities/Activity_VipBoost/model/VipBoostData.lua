--[[
    
    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local VipBoostData = class("VipBoostData", BaseActivityData)

function VipBoostData:ctor()
    VipBoostData.super.ctor(self)
    self.p_extraVipLevel = 0
end

function VipBoostData:parseData(data)
    VipBoostData.super.parseData(self, data)
    self.p_expire = data.expire
    self.p_activityId = data.activityId
    self.p_expireAt = tonumber(data.expireAt)
    self.p_extraVipLevel = data.extraVipLevel
    self.p_multiple = 2
    self.p_type = data.type -- activity & vipItem csc 2021年11月18日 添加新字段表明当前活动是否在体验
    self.p_newUserIgnore = nil -- csc 2021年11月18日 添加新字段表明当前活动是否在体验
    self:checkIgnoreType()
    util_nextFrameFunc(
        function()
            self:checkUpdateVipBoostMul()
        end
    )
end
--是否开放boost
function VipBoostData:isOpenBoost()
    local vipLevel = globalData.userRunData.vipLevel or 1
    if self:getLeftTime() > 0 and self.p_extraVipLevel > 0 and vipLevel <= VipConfig.MAX_LEVEL then
        return true
    end
    return false
end

--登录获取全部数据后刷新活动
function VipBoostData:checkUpdateVipBoostMul()
    if self:getLeftTime() > 0 then
        local newVipLevel = globalData.userRunData.vipLevel + self.p_extraVipLevel
        local nextData = nil
        local vipData = G_GetMgr(G_REF.Vip):getData()
        if vipData then
            nextData = vipData:getVipLevelInfo(newVipLevel) --获取下一个等级的VIP数据
        end
        --没有数据VIP顶级不开活动
        if not nextData then
            self.p_expire = 0
            self.p_extraVipLevel = 0
        else
            local newPoint = tonumber(nextData.vipPointActivity)
            if newPoint then
                self.p_multiple = newPoint - nextData.vipPoint
            end
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIP_BOOST_UPDATE_DATA)
end

--额外的vip等级
function VipBoostData:getBoostVipLevel()
    if self:getLeftTime() > 0 then
        return self.p_extraVipLevel
    end
    return 0
end

--额外的vip等级 icon使用
function VipBoostData:getBoostVipLevelIcon()
    local vipLevel = globalData.userRunData.vipLevel or 1
    if self:getLeftTime() > 0 and vipLevel < VipConfig.MAX_LEVEL then
        return self.p_extraVipLevel
    end
    return 0
end

function VipBoostData:checkCompleteCondition()
    local vipLevel = globalData.userRunData.vipLevel or 1
    if vipLevel > VipConfig.MAX_LEVEL then
        return true
    end
    return false
end

function VipBoostData:checkIgnoreType()
    if self.p_type == "activity" then
        self.p_newUserIgnore = false
    elseif self.p_type == "vipItem" then
        self.p_newUserIgnore = true
    elseif self.p_type == "vipExperienceItem" then
        self.p_newUserIgnore = true
    end
end

function VipBoostData:isIgnoreLevel()
    local isIgnore = VipBoostData.super.isIgnoreLevel(self)
    if self.p_newUserIgnore then
        isIgnore = true
    end
    return isIgnore
end

function VipBoostData:isRunning()
    if not VipBoostData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end

    return true
end

function VipBoostData:isExperienceItemType()
    return self.p_type == "vipExperienceItem"
end

function VipBoostData:getBoost()
    local oldVipLevel = globalData.userRunData.vipLevel
    local data = G_GetMgr(G_REF.Vip):getData()
    local curData = data:getVipLevelInfo(oldVipLevel+ self:getBoostVipLevel())
    local preData = data:getVipLevelInfo(oldVipLevel) --获取下一个等级的VIP数据
    if preData and curData then
        local curBoost = curData.coinPackages
        local preBoost = preData.coinPackages
        local val = (curBoost - preBoost) / preBoost
        val = tonumber(string.format("%0.2f", val))
        return val
    end
    return 0
end

return VipBoostData
