local CoinPusherSlotData = class("CoinPusherSlotData", util_require("CandyPusherSrc.GamePusherData.GamePusherBaseActionData"))


function CoinPusherSlotData:initSlotsRunData( )
    local reel = self:getPlaySlotsDataReels()
    if  reel and #reel > 0  then
        -- 保持数据的一致性，只随机一次
        return
    end
    
    -- 三列一行的小轮盘 数据
    self.m_tRunningData.ActionData.Reel = {}
    self.m_tRunningData.ActionData.EndType = nil
    local endType = self:getSlotsEndType()
    local coinPileEndNum =  self:getSlotsCoinPileEndNum()
    self.m_tRunningData.ActionData.EndType = endType
    self.m_tRunningData.ActionData.coinPileNumlist = {0,0,0}
    if endType == self.m_pConfig.slotsSymbolType.CoinPile then
        -- 因为是一行三列；小金币堆信号个数只有可能是有三种情况 3，2，1
        local indexPos = {1,2,3}
        local rodIndex = math.random(1,#indexPos)

        if coinPileEndNum == 2 then
            self.m_tRunningData.ActionData.Reel[rodIndex] = self:getSlotsCoinPileBlankShowType()
            table.remove( indexPos, rodIndex )

            for i=1,#indexPos do
                self.m_tRunningData.ActionData.Reel[indexPos[i]] = endType
                self.m_tRunningData.ActionData.coinPileNumlist[indexPos[i]] = self:getSlotsCoinPileLabShowNum( )
            end
        elseif coinPileEndNum == 1 then
            self.m_tRunningData.ActionData.Reel[rodIndex] = endType 
            self.m_tRunningData.ActionData.coinPileNumlist[rodIndex] = self:getSlotsCoinPileLabShowNum( )
            table.remove( indexPos, rodIndex )

            local showType = self:getSlotsCoinPileBlankShowType()
            for i=1,#indexPos do
                self.m_tRunningData.ActionData.Reel[indexPos[i]] = showType
            end
        else
            for i=1,3 do
                table.insert( self.m_tRunningData.ActionData.Reel, endType )
                self.m_tRunningData.ActionData.coinPileNumlist[indexPos[i]] = self:getSlotsCoinPileLabShowNum()
            end
        end
    else
        for i=1,3 do
            table.insert( self.m_tRunningData.ActionData.Reel, endType )
        end
    end


    local collectItemsNumData = self.m_pGamePusherMgr:getInitItemList( )
    local runningData = self.m_pGamePusherMgr:loadRunningData(  )
    local pushersData = runningData.playingData or {} 
    if pushersData and table_length(pushersData) ~= 0 then
        if pushersData.collectItemsNum  then
            collectItemsNumData = pushersData.collectItemsNum
        end
    end

    if collectItemsNumData[tostring(endType)] then
        collectItemsNumData[tostring(endType)] = collectItemsNumData[tostring(endType)] + 1
    end

    local data = {}
    data.collectItemsNum = collectItemsNumData 
    self.m_pGamePusherMgr:updatePlayingData( data )

end

function CoinPusherSlotData:getPlaySlotsDataReels( )
    return self.m_tRunningData.ActionData.Reel
end

function CoinPusherSlotData:getCoinPileNumlistData( )
    return self.m_tRunningData.ActionData.coinPileNumlist
end

function CoinPusherSlotData:getSlotsEndType( )

    -- 从 itemsWeight 取得 最终玩法类型
    -- 每次游戏只有可能出一种jackpot  : 107信号！！！：当出过jackpot玩法时，jackpot概率不删除依旧站位，只是再随机到不算钱
    local playingData = self.m_pGamePusherMgr:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local itemsWeight = netInitData.itemsWeight or {}
    local pusherMaxUseNum = playingData.pusherMaxUseNum or 0


    local slotType = nil
    local totalWeight = 0
    local typeList = {}
    for k,v in pairs(itemsWeight) do
        totalWeight = v + totalWeight
        table.insert(typeList,{slotType = k,indexWeight = totalWeight})
    end
    local rodIndex = math.random(1,totalWeight)
    for i=1,#typeList do
        local indexWeight = typeList[i].indexWeight
        slotType = tonumber(typeList[i].slotType)
        if rodIndex <= indexWeight  then
            if  self.m_pGamePusherMgr:checkJackPotSymbolType(slotType )  then
                local jpTriggerd = netInitData.jpTriggerd
                if jpTriggerd and jpTriggerd == 1 then
                    -- 之前触发过就不在触发
                    slotType = self:getSlotsEndType( )
                    return slotType
                else
                    -- jackPot 需要取服务器给的最终信号值
                    slotType = self:getSlotsJPEndType( )
                    -- 随机后标记本地数据已出发过
                    self.m_pGamePusherMgr:updateNetInitData({jpTriggerd = 1} )
                end
            elseif slotType == self.m_pConfig.slotsSymbolType.Wall then
                local upWallsLT = self.m_pGamePusherMgr:getBuffUpWallsLT()
                if (upWallsLT and upWallsLT > 0) or pusherMaxUseNum < self.m_pConfig.DelWallLeftNum then
                    -- 如果当前有墙的道具或者剩余测试小于10，那么随机出的墙不生效，重新再随机一次
                    slotType = self:getSlotsEndType( )
                    return slotType
                end
            end
            return slotType
        end
    end

    
end
--"字符串，每次spin只能出一个jackpot，指定这次jackpot类型",
function CoinPusherSlotData:getSlotsJPEndType( )
    local playingData = self.m_pGamePusherMgr:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local jackpotSignal = tonumber(netInitData.jackpotSignal)  
    return jackpotSignal
end

-- 个数：权重 "随机到金币堆玩法时，随机1-3个，不满三个时，在coinBlankItems随机一个图标，金币堆一个时这个图标成对显示",
function CoinPusherSlotData:getSlotsCoinPileEndNum( )
    
    local playingData = self.m_pGamePusherMgr:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local coinPileNumWeight = netInitData.coinPileNumWeight or {}

    local totalWeight = 0
    local typeList = {}
    for k,v in pairs(coinPileNumWeight) do
        totalWeight = v + totalWeight
        table.insert(typeList,{slotType = k,indexWeight = totalWeight})
    end
    local rodIndex = math.random(1,totalWeight)
    for i=1,#typeList do
        local indexWeight = typeList[i].indexWeight
        local CoinPileNum = tonumber(typeList[i].slotType)
        if rodIndex <= indexWeight  then
            return CoinPileNum
        end
    end

end
-- 个数：权重 "键值对格式，每个金币堆图标显示金币个数",每一个 106信号显示的个数都从这里面随机
function CoinPusherSlotData:getSlotsCoinPileLabShowNum( )
    
    local playingData = self.m_pGamePusherMgr:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local coinPileWeight = netInitData.coinPileWeight or {}

    local totalWeight = 0
    local typeList = {}
    for k,v in pairs(coinPileWeight) do
        totalWeight = v + totalWeight
        table.insert(typeList,{slotType = k,indexWeight = totalWeight})
    end
    local rodIndex = math.random(1,totalWeight)
    for i=1,#typeList do
        local indexWeight = typeList[i].indexWeight
        local CoinPileLabShowNum = tonumber(typeList[i].slotType)
        if rodIndex <= indexWeight  then
            return CoinPileLabShowNum
        end
    end

end

--"金币堆不足三个时，需要显示的slot显示的图标",随机抽取
function CoinPusherSlotData:getSlotsCoinPileBlankShowType( )
    
    local playingData = self.m_pGamePusherMgr:getPusherUseData( ) or {}
    local netInitData = playingData.netInitData or {}
    local coinBlankItems = netInitData.coinBlankItems or {}

    local showType = self.m_pConfig.slotsSymbolType.Wall
    local totalWeight = 0
    local typeList = {}
    for k,v in pairs(coinBlankItems) do
        totalWeight = v + totalWeight
        table.insert(typeList,{blankType = k,indexWeight = totalWeight})
    end
    local rodIndex = math.random(1,totalWeight)
    for i=1,#typeList do
        local indexWeight = typeList[i].indexWeight
        showType = tonumber(typeList[i].blankType)
        if rodIndex <= indexWeight  then
            return showType
        end
    end

end



return CoinPusherSlotData