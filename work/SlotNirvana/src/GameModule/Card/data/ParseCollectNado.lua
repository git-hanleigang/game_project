--[[--
]]
-- message CardCollectNado {
--     repeated int32 cards = 1; //目标卡数
--     repeated int32 games = 2; //赠送游戏数
--     optional int32 currentCards = 3; //目前卡数
--   }
local ParseCollectNado = class("ParseCollectNado")
function ParseCollectNado:ctor()
end

function ParseCollectNado:parseData(_netData)
    self.cards = {}
    if _netData.cards and #_netData.cards > 0 then
        for i = 1, #_netData.cards do
            self.cards[i] = _netData.cards[i]
        end
    end

    self.games = {}
    if _netData.games and #_netData.games > 0 then
        for i = 1, #_netData.games do
            self.games[i] = _netData.games[i]
        end
    end

    self.currentCards = _netData.currentCards
end

function ParseCollectNado:getCurrentCards()
    return self.currentCards
end

function ParseCollectNado:getCardsIndexBetweenNum(_srcNum, _tarNum)
    local idxs = {}
    if self.cards and #self.cards > 0 and _srcNum <= _tarNum and _tarNum <= self.cards[#self.cards] then
        for i=1,#self.cards do
            if _srcNum < self.cards[i] and self.cards[i] <= _tarNum then
                table.insert(idxs, i)
            end
        end
    end
    return idxs
end

function ParseCollectNado:getGamesByIndex(_index)
    if self.games and #self.games > 0 and _index <= #self.games then
        return self.games[_index]
    end
    return 0
end

function ParseCollectNado:mergeData(_netData)
    if _netData and _netData.currentCards and _netData.currentCards > 0 then
        self.currentCards = math.max(self.currentCards, _netData.currentCards)
    end

    if not (self.cards and #self.cards > 0) then
        self.cards = {}
        if _netData.cards and #_netData.cards > 0 then
            for i = 1, #_netData.cards do
                self.cards[i] = _netData.cards[i]
            end
        end
    end

    if not (self.games and #self.games > 0) then
        self.games = {}
        if _netData.games and #_netData.games > 0 then
            for i = 1, #_netData.games do
                self.games[i] = _netData.games[i]
            end
        end
    end
end

return ParseCollectNado
