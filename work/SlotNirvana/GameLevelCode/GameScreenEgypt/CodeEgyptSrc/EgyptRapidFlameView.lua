---
--xcyy
--2018年5月23日
--EgyptRapidFlameView.lua

local EgyptRapidFlameView = class("EgyptRapidFlameView",util_require("base.BaseView"))

EgyptRapidFlameView.m_lb_coin = nil
EgyptRapidFlameView.m_lb_num = nil
function EgyptRapidFlameView:initUI()

    self:createCsbNode("Egypt/EgyptRapidFlameView.csb")

    self.m_lb_coin = self:findChild("m_lb_coin")
    self.m_lb_num = self:findChild("m_lb_num")

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
    
    self.m_icon = util_spineCreate("Socre_Egypt_rapid1", true, true)
    self:findChild("Spine_Socre_Egypt_rapid1"):addChild(self.m_icon)

end

function EgyptRapidFlameView:showStart(num, coins, func)
    self.m_lb_num:setString(num)
    self.m_lb_coin:setString("0")
    performWithDelay(self, function()
        self:updateWinCoin(coins)
    end, 0.8)
    util_spinePlay(self.m_icon, "EgyptRapidFlameView_open")
    self:runCsbAction("open", false, function()
        self:showIdle(func)
    end)
end

function EgyptRapidFlameView:updateWinCoin(coins)
    self:updateLabelSize({label=self.m_lb_coin, sx = 1, sy = 1}, 600)
    local addValue = coins / 120
    util_jumpNum(self.m_lb_coin, 0, coins, addValue, 1 / 60, {30}, nil, nil, function()
        self:updateLabelSize({label=self.m_lb_coin,sx=1,sy=1},600)
    end)
end

function EgyptRapidFlameView:showIdle(func)
    util_spinePlay(self.m_icon, "EgyptRapidFlameView_idle")
    self:runCsbAction("idle", false, function()
        self:showOver(func)
    end)
end

function EgyptRapidFlameView:showOver(func)
    util_spinePlay(self.m_icon, "EgyptRapidFlameView_over")
    self:runCsbAction("over", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function EgyptRapidFlameView:onEnter()
 

end

function EgyptRapidFlameView:showAdd()
    
end
function EgyptRapidFlameView:onExit()
 
end

--默认按钮监听回调
function EgyptRapidFlameView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return EgyptRapidFlameView