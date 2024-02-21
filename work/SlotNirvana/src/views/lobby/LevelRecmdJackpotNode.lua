--[[--
    title
]]
local LevelRecmdJackpotNode = class("LevelRecmdJackpotNode", BaseView)

function LevelRecmdJackpotNode:getCsbName()
    return self.m_csbName
end

function LevelRecmdJackpotNode:initDatas(_csbName, _info)
    self.m_csbName = _csbName
    self.m_info = _info
end

function LevelRecmdJackpotNode:initCsbNodes()
    self.m_lbCoin = self:findChild("lb_shuzi")
    self.m_spCoin = self:findChild("sp_coin")
end

function LevelRecmdJackpotNode:initUI()
    LevelRecmdJackpotNode.super.initUI(self)
    self:initView()
end

function LevelRecmdJackpotNode:initView()
    self:initJackpot()
    self:runCsbAction("idle", true)
end

function LevelRecmdJackpotNode:initJackpot()
    schedule(
        self,
        function()
            local coins = self:getCoins()
            if coins and coins > 0 then
                self.m_lbCoin:setString(util_getFromatMoneyStr(coins))
                self:adaptCoin()
            end
        end,
        self:getJackpotFrame()
    )
end

-- 金币
function LevelRecmdJackpotNode:getCoins()
end

-- 刷新频率
function LevelRecmdJackpotNode:getJackpotFrame()
    return 0.08 -- 默认
end

-- 适配金币和数字
function LevelRecmdJackpotNode:adaptCoin()
end

return LevelRecmdJackpotNode