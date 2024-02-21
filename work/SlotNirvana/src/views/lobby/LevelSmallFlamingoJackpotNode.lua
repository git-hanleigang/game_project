--[[--
    公共Jackopt在小关卡的标题
]]
local LevelSmallFlamingoJackpotNode = class("LevelSmallFlamingoJackpotNode", BaseView)

function LevelSmallFlamingoJackpotNode:initUI()
    LevelSmallFlamingoJackpotNode.super.initUI(self)
    self:initView()
end

function LevelSmallFlamingoJackpotNode:getCsbName()
    return "newIcons/LevelRecmd2023/Jackpot/Flamingo_Jackpotshort.csb"
end

function LevelSmallFlamingoJackpotNode:initCsbNodes()
    -- self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_shuzi")
end

function LevelSmallFlamingoJackpotNode:initView()
    self.m_handle = nil
    -- self:initJackpot()
    self:runCsbAction("idle", true, nil, 60)
end

function LevelSmallFlamingoJackpotNode:startHandle()
    if self.m_handle then
        return
    end

    self:initJackpot()
end

function LevelSmallFlamingoJackpotNode:stopHandle()
    if self.m_handle then
        self:stopAction(self.m_handle)
        self.m_handle = nil
    end
end

function LevelSmallFlamingoJackpotNode:initJackpot()
    self.m_handle =
        schedule(
        self,
        function()
            local coins = G_GetMgr(ACTIVITY_REF.FlamingoJackpot):getJackpotValue(FlamingoJackpotCfg.JackpotType.Super)
            if coins and coins > 0 then
                self.m_lbCoin:setString(util_getFromatMoneyStr(coins))
                self:updateLabelSize({label = self.m_lbCoin, sx = 1, sy = 1}, 150)
            end
        end,
        FlamingoJackpotCfg.JACKPOT_FRAME
    )
end

return LevelSmallFlamingoJackpotNode
