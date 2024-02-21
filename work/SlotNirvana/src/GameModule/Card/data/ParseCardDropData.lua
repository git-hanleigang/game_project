--[[
    掉落原始数据
]]
-- message CardDropInfo {
--     optional string type = 1; //类型, 1:卡片，2:普通卡包，3:link卡包
--     repeated Card cards = 2; //所有卡数据
--     optional int32 currentLinkCard = 3; //现在link收集进度,有新增加显示数量，没有新增加显示0
--     optional int32 totalLinkCard = 4; //总的link收集进度
--     optional int32 wildCard = 5; //wild卡数量
--     optional CardCollectReward albumReward = 6; //赛季卡册集齐奖励
--     repeated CardCollectReward clanReward = 7; //赛季卡组章节集齐奖励
--     optional string source = 8; //来源
--     optional CardCollectNado collectNado = 9;//收集nado卡奖励nado游戏进度
--     optional int32 nadoGames = 10;//nadoGame次数
--     optional int32 nextRound = 11;//下一轮 大于0有效
--   }

local ParseCardData = require("GameModule.Card.data.ParseCardData")
local ParseCollectNado = require("GameModule.Card.data.ParseCollectNado")
local ParseCardCollectRewardData = require("GameModule.Card.data.ParseCardCollectRewardData")
local ParseCardDropData = class("ParseCardDropData")
function ParseCardDropData:parseData(_netData)
    self.type = _netData.type

    self.cards = {}
    if _netData.cards and #_netData.cards > 0 then
        for i = 1, #_netData.cards do
            local cardData = ParseCardData:create()
            cardData:parseData(_netData.cards[i])
            table.insert(self.cards, cardData)

            -- 同一个掉落卡包肯定是同一个轮次的，如果有多余的卡会转换成金币或者商城积分
            self.m_round = (cardData.round or 0) + 1

            if not self.m_dropAlbumId then
                self.m_dropAlbumId = cardData:getAlbumId()
            end
        end
    end

    self.currentLinkCard = _netData.currentLinkCard --现在link收集进度,有新增加显示数量，没有新增加显示0
    self.totalLinkCard = _netData.totalLinkCard --总的link收集进度
    self.wildCard = _netData.wildCard --wild卡数量

    if _netData.albumReward and _netData.albumReward.id and _netData.albumReward.id ~= "" then
        self.albumReward = ParseCardCollectRewardData:create()
        self.albumReward:parseData(_netData.albumReward)
    end

    self.clanReward = {}
    if _netData.clanReward and #_netData.clanReward > 0 then
        for i = 1, #_netData.clanReward do
            local pcrData = ParseCardCollectRewardData:create()
            pcrData:parseData(_netData.clanReward[i])
            table.insert(self.clanReward, pcrData)
        end
    end

    -- 总结为：集齐章节类型相同的章节给的大奖？服务器张铜不支持
    -- 新增magic四个章节都完成的大奖
    self.albumMagicReward = nil
    if _netData.albumMagicReward and _netData.albumMagicReward.id and _netData.albumMagicReward.id ~= "" then
        self.albumMagicReward = ParseCardCollectRewardData:create()
        self.albumMagicReward:parseData(_netData.albumMagicReward)
    end

    self.source = _netData.source --掉落来源

    self.collectNado = nil
    if _netData.collectNado and _netData.collectNado.currentCards ~= nil then
        local cnData = ParseCollectNado:create()
        cnData:parseData(_netData.collectNado)
        self.collectNado = cnData
    end

    self.nadoGames = _netData.nadoGames
    self.nextRound = _netData.nextRound -- 解锁的轮次，没有解锁没有数据
    -- self.round = _netData.round -- 当前次掉落属于哪一轮次
end

function ParseCardDropData:getCollectNado()
    return self.collectNado
end

-- 开启了下一轮的轮次，默认0不开启
function ParseCardDropData:getNextRound()
    return self.nextRound
end

-- 理论上存在nil的可能性，如果卡包数据有问题的话
-- 掉落的wild卡，返回nil
function ParseCardDropData:getRound()
    local round = nil
    if self.m_round ~= nil then
        round = self.m_round
    else
        local albumInfo = CardSysRuntimeMgr:getCardAlbumInfo()
        if albumInfo then
            round = (albumInfo:getRound() or 0) + 1
        end
    end
    return round
end

function ParseCardDropData:getDropAlbumId()
    return self.m_dropAlbumId
end

-- 融合两个掉落数据
function ParseCardDropData:mergeData(_netData)
    if not self.m_isMerge then
        self.mergedTypes = {}
        self.mergedTypes[self.type] = 1
    end

    if not self.mergedTypes[_netData.type] then
        self.mergedTypes[_netData.type] = 0
    end
    self.mergedTypes[_netData.type] = self.mergedTypes[_netData.type] + 1

    if self:isObsidianDropType(_netData.type) then
        self.type = CardSysConfigs.CardDropType.mergeObsidian
    else
        self.type = CardSysConfigs.CardDropType.merge
    end
    if _netData.cards and #_netData.cards > 0 then
        for i = 1, #_netData.cards do
            local cardData = ParseCardData:create()
            cardData:parseData(_netData.cards[i])
            table.insert(self.cards, cardData)
        end
    end

    self.currentLinkCard = self.currentLinkCard + _netData.currentLinkCard --现在link收集进度,有新增加显示数量，没有新增加显示0
    self.totalLinkCard = math.max(self.totalLinkCard, _netData.totalLinkCard) --总的link收集进度
    self.wildCard = math.max(self.wildCard, _netData.wildCard) --wild卡数量

    if _netData.albumReward and _netData.albumReward.id and _netData.albumReward.id ~= "" then
        self.albumReward = ParseCardCollectRewardData:create()
        self.albumReward:parseData(_netData.albumReward)
    end

    if _netData.clanReward and #_netData.clanReward > 0 then
        for i = 1, #_netData.clanReward do
            local isHasSameClan = false
            for j = 1, #self.clanReward do
                local netDataPhaseChips = _netData.clanReward[i].clanCardNum or _netData.clanReward[i].phaseChips
                if tonumber(self.clanReward[j]:getClanId()) == tonumber(_netData.clanReward[i].id) 
                and tonumber(self.clanReward[j]:getPhaseChips()) == tonumber(netDataPhaseChips) then
                    isHasSameClan = true
                    break
                end
            end
            if not isHasSameClan then
                local pcrData = ParseCardCollectRewardData:create()
                pcrData:parseData(_netData.clanReward[i])
                table.insert(self.clanReward, pcrData)
            end
        end
    end

    if _netData.collectNado and _netData.collectNado.currentCards ~= nil and _netData.collectNado.currentCards > 0 then
        if not self.collectNado then
            local cnData = ParseCollectNado:create()
            cnData:parseData(_netData.collectNado)
            self.collectNado = cnData
        else
            self.collectNado:mergeData(_netData.collectNado)
        end
    end

    self.nadoGames = math.max(self.nadoGames, _netData.nadoGames)

    self.nextRound = math.max(self.nextRound, _netData.nextRound)

    self.m_isMerge = true
end

function ParseCardDropData:isObsidianDropType(_dropType)
    if _dropType == CardSysConfigs.CardDropType.obsidian_gold then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.obsidian_copper then
        return true
    end
    if _dropType == CardSysConfigs.CardDropType.obsidian_purple then
        return true
    end
    return false
end


return ParseCardDropData
