--[[--
    title
]]
local LevelRecmdJackpotNode = util_require("views.lobby.LevelRecmdJackpotNode")
local LevelRecmdJillionJackpotNode = class("LevelRecmdJillionJackpotNode", LevelRecmdJackpotNode)

-- 重写
function LevelRecmdJillionJackpotNode:getCoins()
    return G_GetMgr(ACTIVITY_REF.CommonJackpot):getJackpotValue(CommonJackpotCfg.POOL_KEY.Lobby, true)
end

-- 重写
function LevelRecmdJillionJackpotNode:getJackpotFrame()
    return CommonJackpotCfg.JACKPOT_FRAME
end

-- 重写
function LevelRecmdJillionJackpotNode:adaptCoin()
    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.5},
            {node = self.m_lbCoin, scale = 0.35, alignX = 5, alignY = 2}
        }
    )
end

return LevelRecmdJillionJackpotNode
