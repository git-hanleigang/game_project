--[[
    货币数据
    author:{author}
    time:2022-05-24 10:53:53
]]
local CurrencyData = class("CurrencyData")

function CurrencyData:ctor()
    self.m_coins = toLongNumber(0)
    self.m_gems = 0
    self.m_bucks = 0 -- 所有操作必须支持string类型、代币有小数点
end

function CurrencyData:setCoins(coins, _bFly)
    self.m_coins:setNum(coins or 0)

    if _bFly and globalNoviceGuideManager:isNoobUsera() and not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then --新用户
        --新手金币指引没完成 减去第一步引导 宝箱给的奖励
        local guideBoxCoins = math.max(globalData.constantData.NOVICE_SERVER_INIT_COINS - FIRST_LOBBY_COINS, 0)
        self.m_coins = self.m_coins + guideBoxCoins
    end
end

function CurrencyData:getCoins()
    local coins = self.m_coins
    if globalNoviceGuideManager:isNoobUsera() and not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then --新用户
        --新手金币指引没完成 减去第一步引导 宝箱给的奖励
        local guideBoxCoins = math.max(globalData.constantData.NOVICE_SERVER_INIT_COINS - FIRST_LOBBY_COINS, 0)
        coins = coins - guideBoxCoins
    end

    return LongNumber.max(coins, 0)
end

function CurrencyData:setGems(gems)
    self.m_gems = gems or 0
end

function CurrencyData:getGems()
    return self.m_gems
end

function CurrencyData:setBucks(bucks)
    self.m_bucks = bucks or 0
end

function CurrencyData:getBucks()
    return self.m_bucks
end

return CurrencyData
