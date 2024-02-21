--[[
    卡牌基础信息
]]
local ShopItem = require "data.baseDatas.ShopItem"
local DragonChallengePassPageData = import(".DragonChallengePassPageData")
local DragonChallengePassData = class("DragonChallengePassData")

function DragonChallengePassData:ctor()
end

-- message DragonChallengePassResult {
--     optional int32 passSeq = 1; // pass的序号 标识
--     optional int64 curProgress = 2; // pass的当前进度
--     optional int64 totalProgress = 3;// pass的总进度
--     optional bool payUnlocked = 4; //是否付费
--     optional bool finished = 5;// 是否完成该pass
--     optional DragonChallengePassPayResult payValue = 6; // 单个pass的价格
--     optional DragonChallengePassPayResult packPayValue = 7;// 打包价格
--     repeated DragonChallengePassPointResult free = 8;// 免费节点数据
--     repeated DragonChallengePassPointResult pay = 9;//  付费的节点数据
--     optional int64 damage = 10;// 玩家对boss进行的累计伤害
--   }

function DragonChallengePassData:parseData(datas)
    self.m_tbPassData = {}
    if datas and #datas > 0 then
        for i, v in ipairs(datas) do
            if nil == self.m_tbPassData["" .. i] then
                local passData = DragonChallengePassPageData:create()
                passData:parseData(v)
                self.m_tbPassData["" .. passData:getPassSeq()] = passData
            else
                self.m_tbPassData["" .. passData:getPassSeq()]:parseData(v)
            end
        end
        gLobalNoticManager:postNotification("NOTIFY_DRAGON_PASS_DATA_UPDATE")
    end
end



-- 获得指定分页的PASS数据
function DragonChallengePassData:getPassPageData(idxPage)
    return self.m_tbPassData["" .. idxPage]
end

-- 获取指定分页的奖励数据
function DragonChallengePassData:getAllCanCollectReward(_page)
    local data = {}
    local coins = 0
    local items = {}
    local passData = self:getPassPageData(_page)
    for i, v in pairs(passData.p_freePoint) do
        if v.p_params <= passData.p_curProgress and not v.p_collected then
            coins = coins + (v.p_coins or 0)
            table.insertto(items, clone(v.p_items))
        end
    end
    if passData.p_payUnlocked then
        for i, v in pairs(passData.p_payPoint) do
            if v.p_params <= passData.p_curProgress and not v.p_collected then
                coins = coins + (v.p_coins or 0)
                table.insertto(items, clone(v.p_items))
            end
        end
    end

    data.p_coins = coins
    data.p_items = items

    return data
end

--[[
    @desc: 获取领奖数量
    --@idxPage: 分页索引，不指定索引则获取所有分页
    @return:
]]
function DragonChallengePassData:getRewardCount(idxPage)
    local count = 0

    local _rewardCount = function(_idx)
        local _count = 0
        -- 计算奖励数量
        local passData = self:getPassPageData(_idx)
        if not passData:getPassIsUnlocked() then
            return _count
        end
        for i, v in pairs(passData.p_freePoint) do
            if v.p_params <= passData.p_curProgress and not v.p_collected then
                _count = _count + 1
            end
        end

        if passData.p_payUnlocked then
            for i, v in pairs(passData.p_payPoint) do
                if v.p_params <= passData.p_curProgress and not v.p_collected then
                    _count = _count + 1
                end
            end
        end
        return _count
    end

    if not idxPage then
        -- 遍历所有分页的奖励数量
        for k,v in pairs(self.m_tbPassData) do
            count = count+_rewardCount(k)
        end
    elseif idxPage > 0 and idxPage <= self:getPageNum() then 
        -- 指定分页的奖励数量
        count = _rewardCount(idxPage)
    end

    return count
end


function DragonChallengePassData:getCurPassData()
    return self.p_passData[self.curPassIndex]
end

function DragonChallengePassData:isGetAllReward(_type)
    local type = _type or self.curPassIndex
    local passData = self.p_passData[type]
    local lastReward = passData.p_freePoint[#passData.p_freePoint]
    local flag = false
    if lastReward.p_params <= passData.p_curProgress then
        flag = true
    end

    return flag
end

function DragonChallengePassData:getPageNum()
    local res=0
    for k,v in pairs(self.m_tbPassData) do
        res=res+1
    end
    return res
end
--获取未付费的passs数据
function DragonChallengePassData:getUnpaidPass()
    local list = {}
    for k, v in pairs(self.m_tbPassData) do
        local isPay = v:getPayUnlocked()
        if not isPay then
            table.insert(list, v)
        end
    end
    return list
end

return DragonChallengePassData
