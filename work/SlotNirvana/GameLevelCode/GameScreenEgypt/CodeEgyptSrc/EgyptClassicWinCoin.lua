---
--xcyy
--2018年5月23日
--EgyptClassicWinCoin.lua

local EgyptClassicWinCoin = class("EgyptClassicWinCoin",util_require("base.BaseView"))

EgyptClassicWinCoin.m_lb_winCoin = nil
function EgyptClassicWinCoin:initUI()

    self:createCsbNode("Egypt_Classical_kuang.csb")

    self.m_lb_winCoin = self:findChild("m_lb_coin")
    self.m_lb_winCoin:setString("0")
    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
end

function EgyptClassicWinCoin:updateWinCoin(startValue, coins)
    self.m_lb_winCoin:setString(util_formatCoins(coins, 30))
    self:updateLabelSize({label=self.m_lb_winCoin, sx = 1, sy = 1}, 368)
    self.m_lb_winCoin:setString("0")
    local addValue = (coins - startValue) / 120
    util_jumpNum(self.m_lb_winCoin,startValue, coins, addValue, 1 / 60, {30}, nil, nil, function()
        self:updateLabelSize({label=self.m_lb_winCoin,sx=1,sy=1},368)
    end)
end

function EgyptClassicWinCoin:onEnter()
 
end

function EgyptClassicWinCoin:showAdd()
    
end
function EgyptClassicWinCoin:onExit()
 
end

--默认按钮监听回调
function EgyptClassicWinCoin:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return EgyptClassicWinCoin