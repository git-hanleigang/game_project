--[[
]]
local LSGameTopReward = class("LSGameTopReward", BaseView)

function LSGameTopReward:initDatas()
    self.m_showCoinNum = self:getTopCoins(true)
end

function LSGameTopReward:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_reward.csb"
end

function LSGameTopReward:initCsbNodes()
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
end

function LSGameTopReward:initUI()
    LSGameTopReward.super.initUI(self)
    self:initCoin()
    self:runCsbAction("idle", true, nil, 60)
end

function LSGameTopReward:initCoin()
    self.m_lbCoin:setString(util_formatCoins(self.m_showCoinNum, 13))
    -- util_alignCenter(
    --     {
    --         --{node = self.m_spCoin, scale = 0.75},
    --         {node = self.m_lbCoin, scale = 0.58, alignX = 10}
    --     }
    -- )
end

function LSGameTopReward:stopSche()
    if self.m_upSche then
        self:stopAction(self.m_upSche)
        self.m_upSche = nil
    end
end

function LSGameTopReward:upCoin(_over)
    self:stopSche()
    local costTime = 1 -- 秒
    local finalCoins = self:getTopCoins()
    local changeNum = math.floor((finalCoins - self.m_showCoinNum) / 30)
    self.m_upSche =
        util_schedule(
        self,
        function()
            self.m_showCoinNum = self.m_showCoinNum + changeNum
            if self.m_showCoinNum >= finalCoins then
                self.m_showCoinNum = finalCoins
                self:initCoin()
                self:stopSche()
                return
            else
                self:initCoin()
            end
        end,
        1 / 30
    )

    return costTime
end

function LSGameTopReward:onEnter()
    LSGameTopReward.super.onEnter(self)
end

function LSGameTopReward:onExit()
    LSGameTopReward.super.onExit(self)
    self:stopSche()
end

-- 获取当前戳的最大奖励
function LSGameTopReward:getTopCoins(_isInit)
    if LuckyStampCfg.TEST_MODE == true then
        return 30000000000
    end
    -- 获取戳的数据
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local stampData = data:getCurProcessData(_isInit)
        if stampData then
            return stampData:getTopCoins() or 0
        end
    end
    return 0
end

return LSGameTopReward
