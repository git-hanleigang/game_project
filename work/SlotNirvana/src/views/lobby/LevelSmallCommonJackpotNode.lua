--[[--
    公共Jackopt在小关卡的标题
]]
local LevelSmallCommonJackpotNode = class("LevelSmallCommonJackpotNode", BaseView)

function LevelSmallCommonJackpotNode:initUI()
    LevelSmallCommonJackpotNode.super.initUI(self)
    self:initView()
end

function LevelSmallCommonJackpotNode:getCsbName()
    return "newIcons/LevelRecmd2023/Jackpot/Jackpot_short.csb"
end

function LevelSmallCommonJackpotNode:initCsbNodes()
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_shuzi")
end

function LevelSmallCommonJackpotNode:initView()
    self.m_handle = nil
    -- self:initJackpot()
    self:runCsbAction("idle",true)
end

function LevelSmallCommonJackpotNode:startHandle()
    if self.m_handle then
        return
    end

    self:initJackpot()
end

function LevelSmallCommonJackpotNode:stopHandle()
    if self.m_handle then
        self:stopAction(self.m_handle)
        self.m_handle = nil
    end
end

function LevelSmallCommonJackpotNode:initJackpot()
    self.m_handle =
        schedule(
        self,
        function()
            local coins = G_GetMgr(ACTIVITY_REF.CommonJackpot):getJackpotValue(CommonJackpotCfg.POOL_KEY.Lobby, true)
            if coins and coins > 0 then
                self.m_lbCoin:setString(util_getFromatMoneyStr(coins))
                util_alignCenter(
                    {
                        {node = self.m_lbCoin, scale = 0.23, anchor = cc.p(0.5, 0.5), alignX = 0, alignY = 0}
                    },
                    nil,
                    200
                )
            end
        end,
        0.08
    )
end

return LevelSmallCommonJackpotNode
