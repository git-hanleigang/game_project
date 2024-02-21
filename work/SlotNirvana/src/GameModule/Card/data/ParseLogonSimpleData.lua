--[[
    只有登陆时才返回此数据
    在游戏过程中不会进行数据的刷新
]]
local ParseYearData = require("GameModule.Card.data.ParseYearData")
local ParseCollectNado = require("GameModule.Card.data.ParseCollectNado")
local ParseLogonSimpleData = class("ParseLogonSimpleData")
function ParseLogonSimpleData:ctor()
end

-- message CardsSimpleInfo {
--     optional string currentAlbumId = 1; //当前赛季的卡册Id
--     repeated CardYearInfo cardYears = 2; //年度卡册信息
--     optional int32 totalLinkCard = 3; //总的link收集进度
--     optional int64 nadoGames = 4; //link游戏总次数
--     optional CardCollectNado collectNado = 5;//收集nado卡奖励nado游戏进度
--   }
function ParseLogonSimpleData:parseData(_netData)
    self.p_currentAlbumId = _netData.currentAlbumId
    
    self.p_cardYears = {}
    for i = 1, #_netData.cardYears do
        local yearsdata = ParseYearData:create()
        yearsdata:parseData(_netData.cardYears[i])
        table.insert(self.p_cardYears, yearsdata)
    end

    self.p_totalLinkCard = _netData.totalLinkCard
    self.p_nadoGames = tonumber(_netData.nadoGames)

    self.p_collectNado = nil
    if _netData.collectNado and _netData.collectNado.currentCards ~= nil then
        local cnData = ParseCollectNado:create()
        cnData:parseData(_netData.collectNado)
        self.p_collectNado = cnData
    end

    -- self:setClanCollects()
    print("---ParseLogonSimpleData---")
end

function ParseLogonSimpleData:getCurrentAlbumId()
    return self.p_currentAlbumId
end

function ParseLogonSimpleData:getCardYears()
    return self.p_cardYears
end

function ParseLogonSimpleData:getTotalLinkCard()
    return self.p_totalLinkCard
end

function ParseLogonSimpleData:getNadoGames()
    return self.p_nadoGames or 0
end

function ParseLogonSimpleData:getCollectNado()
    return self.p_collectNado
end

-- function ParseLogonSimpleData:setClanCollects()
--     if self.p_cardYears and #self.p_cardYears > 0 then
--         for i=1,#self.p_cardYears do
--             local yearData = self.p_cardYears[i]
--             local albumDatas = yearData:getAlbumDatas()
--             if albumDatas and #albumDatas > 0 then
--                 for j=1,#albumDatas do
--                     local albumData = albumDatas[j]
--                     local clanDatas = albumData:getCardClans()
--                     if clanDatas and #clanDatas > 0 then
--                         for k=1,#clanDatas do
--                             local clanData = clanDatas[k]
--                             -- 客户端缓存数据
--                             if CardSysRuntimeMgr:isNormalClan(clanData.type) then
--                                 print("setClanCollects clanId=", clanData:getClanId())
--                                 CardSysRuntimeMgr:setClanCollects(clanData:getClanId(), clanData:getCur(), clanData:getMax(), albumData.round)
--                             end
--                         end
--                     end
                    
--                 end
--             end
--         end
--     end    
-- end

return ParseLogonSimpleData