--[[--
    title
]]
local LevelRecmdJackpotNode = util_require("views.lobby.LevelRecmdJackpotNode")
local LevelRecmdFlamingoJackpotNode = class("LevelRecmdFlamingoJackpotNode", LevelRecmdJackpotNode)

function LevelRecmdFlamingoJackpotNode:getCoins()
    return G_GetMgr(ACTIVITY_REF.FlamingoJackpot):getJackpotValue(FlamingoJackpotCfg.JackpotType.Super)
end

function LevelRecmdFlamingoJackpotNode:getJackpotFrame()
    return FlamingoJackpotCfg.JACKPOT_FRAME
end

function LevelRecmdFlamingoJackpotNode:adaptCoin()
    util_alignCenter(
        {
            {node = self.m_spCoin, scale = 0.5},
            {node = self.m_lbCoin, scale = 0.35, alignX = 5, alignY = 2}
        }
    )
end

return LevelRecmdFlamingoJackpotNode
