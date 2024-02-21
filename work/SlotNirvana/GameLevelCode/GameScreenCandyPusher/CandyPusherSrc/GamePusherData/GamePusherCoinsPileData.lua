local GamePusherCoinsPileData = class("GamePusherCoinsPileData", util_require("CandyPusherSrc.GamePusherData.GamePusherBaseActionData"))


function GamePusherCoinsPileData:ctor(  )
    GamePusherCoinsPileData.super.ctor(self)
end

function GamePusherCoinsPileData:setEffectData( _coinPileNumlist)

    local coinPileNumlist = _coinPileNumlist 
    local totalNum = 0
    for i=1,#coinPileNumlist do
        totalNum= coinPileNumlist[i] + totalNum
    end
    self.m_tRunningData.ActionData.CoinsTotalNum = totalNum
end

function GamePusherCoinsPileData:getTotalNum()
    local addCount = self.m_tRunningData.ActionData.CoinsTotalNum
    return addCount
end




return GamePusherCoinsPileData