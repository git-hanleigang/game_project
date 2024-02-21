--[[
    -- TODO: 数据获取
]]
local StatueRunData = class("StatueRunData", BaseSingleton)
function StatueRunData:ctor()
    StatueRunData.super.ctor(self)
end

-- 获取神像的章节的数据
function StatueRunData:getStatueClanListData(_statueType)
    local statueClans = {}
    local _, _, _, statueClanData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    local flag1 = 0
    local flag2 = 0
    local clanTypes = ", clanTpye = "
    for i = 1, #statueClanData do
        clanTypes = clanTypes .. statueClanData[i].type .. ","
        if _statueType == 1 and statueClanData[i].type == CardSysConfigs.CardClanType.statue_left then
            table.insert(statueClans, statueClanData[i])
            flag1 = flag1 + 1
        end
        if _statueType == 2 and statueClanData[i].type == CardSysConfigs.CardClanType.statue_right then
            table.insert(statueClans, statueClanData[i])
            flag2 = flag2 + 1
        end
    end
    release_print("!!! StatueRewardNode m_clanData --- flag " .. #statueClanData .. "," .. flag1 .. "," .. flag2 .. clanTypes)
    local sortFunc = function(a, b)
        local aid = a and tonumber(a.clanId)
        local bid = b and tonumber(b.clanId)
        return aid <= bid
    end
    table.sort(statueClans, sortFunc)

    return statueClans
end

-- 当前神像所处的等级
function StatueRunData:getCurrentStatueClan(_statueType)
    local getRewardNum = 0
    local statueClans = self:getStatueClanListData(_statueType)
    for i = #statueClans, 1, -1 do
        if statueClans[i].getReward == true then
            getRewardNum = getRewardNum + 1
        end
    end

    local curIndex = math.min(#statueClans, getRewardNum + 1)
    release_print("!!! StatueRewardNode m_clanData --- " .. getRewardNum .. "," .. curIndex)
    return getRewardNum, statueClans[curIndex]
end

function StatueRunData:getBuffInfo(_clanRewards)
    local buffs = {}
    if _clanRewards and #_clanRewards > 0 then
        for i = 1, #_clanRewards do
            if _clanRewards[i].p_type == "Buff" then
                table.insert(buffs, clone(_clanRewards[i]))
            end
        end
    end
    return buffs
end

function StatueRunData:getCountdown()
    return 0 -- globalData.userRunData.p_serverTime + 3000000
end

return StatueRunData
