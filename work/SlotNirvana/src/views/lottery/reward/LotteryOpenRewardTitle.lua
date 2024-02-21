--[[
Author: your name
Date: 2021-11-19 16:32:21
LastEditTime: 2021-11-19 16:32:45
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardTitle.lua
--]]
local LotteryOpenRewardTitle = class("LotteryOpenRewardTitle", BaseView)

function LotteryOpenRewardTitle:initUI()
    LotteryOpenRewardTitle.super.initUI(self)
    
    local data = G_GetMgr(G_REF.Lottery):getData()
    self.m_coins = data:getGrandPrize()

    self:initView()
end

function LotteryOpenRewardTitle:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_title.csb"
end

function LotteryOpenRewardTitle:initView()
    -- 大奖池滚动金币
    local lbCoin = self:findChild("lb_coin_num")
    lbCoin:setString(util_formatCoins(self.m_coins, 20))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoin, 480)
    -- lbCoin
    -- G_GetMgr(G_REF.Lottery):registerCoinAddComponent(lbCoin, 490)
    --处理金币图标与金币居中显示
    local spCoin = self:findChild("sp_coin")
    util_alignCenter(
        {
            {node = spCoin},
            {node = lbCoin}
        }
    )

end

function LotteryOpenRewardTitle:playShowAct(_cb)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)

        if _cb then
            _cb()
        end
    end, 60)
end

return LotteryOpenRewardTitle