-- 排行榜金币条

local BaseRankCoinsControll = require("baseActivity.ActivityRank.BaseRankCoinsControll"):getInstance()

local BaseRankTitleUI = class("BaseRankTitleUI", util_require("base.BaseView"))

function BaseRankTitleUI:initUI(act_ref, csb_res)
    if csb_res then
        self:setCsbName(csb_res)
    end
    BaseRankTitleUI.super.initUI(self)

    self:runCsbAction("idle", true)
    -- 排行榜引用名
    self.act_ref = act_ref
end

function BaseRankTitleUI:initCsbNodes()
    self.node_coin = self:findChild("node_coin")
    self.sp_coins = self:findChild("sp_coins")
    self.lb_coins = self:findChild("lb_coins")
    self.sp_noRank = self:findChild("sp_noRank")
end

function BaseRankTitleUI:onEnter()
    BaseRankCoinsControll:regist(self.act_ref)

    self.schedule_timer =
        util_schedule(
        self,
        function()
            self:updateCoins()
        end,
        0.08
    )
    self:updateCoins()
end

function BaseRankTitleUI:onExit()
    BaseRankCoinsControll:unregist(self.act_ref)
end

-- 金币滚动
function BaseRankTitleUI:updateCoins()
    local coins = BaseRankCoinsControll:getCoinsByType(self.act_ref)
    if coins <= 0 then
        self.node_coin:setVisible(false)
        if self.sp_noRank then
            self.sp_noRank:setVisible(true)
        end

        return
    end

    self.node_coin:setVisible(true)
    if self.sp_noRank then
        self.sp_noRank:setVisible(false)
    end
    self.lb_coins:setString(util_formatCoins(coins or 0, 12))
    local posY1 = self.sp_coins:getPositionY()
    local posY2 = self.lb_coins:getPositionY()
    util_alignCenter(
        {
            {node = self.sp_coins},
            -- 这里要设置y值 因为工程里设置的y值 经过alggn方法以后 会被置0
            {node = self.lb_coins, alignX = 5, alignY = posY2 - posY1}
        }
    )
end

function BaseRankTitleUI:getRankData()
    return self.data
end

function BaseRankTitleUI:setRankData(data)
    if data then
        self.data = data
    end
end

function BaseRankTitleUI:setCsbName(csb_res)
    self.csb_res = csb_res
end

function BaseRankTitleUI:getCsbName()
    return self.csb_res
end

return BaseRankTitleUI
