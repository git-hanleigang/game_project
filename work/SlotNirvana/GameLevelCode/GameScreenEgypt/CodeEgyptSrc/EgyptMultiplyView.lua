---
--xcyy
--2018年5月23日
--EgyptMultiplyView.lua

local EgyptMultiplyView = class("EgyptMultiplyView",util_require("base.BaseView"))

EgyptMultiplyView.m_lb_coin = nil
EgyptMultiplyView.m_currMultip = nil
local MULTIPLY_ARRAY = {2, 4, 8, 10}


function EgyptMultiplyView:initUI()

    self:createCsbNode("Egypt_MultiplyView.csb")

    self.m_lb_coin = self:findChild("m_lb_coin")

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
    self.m_icon2x = util_spineCreate("Egypt_FastLuck_2x", true, true)
    self:findChild("Spine_Egypt_FastLuck_2x"):addChild(self.m_icon2x)

    self.m_icon4x = util_spineCreate("Egypt_FastLuck_4x", true, true)
    self:findChild("Spine_Egypt_FastLuck_4x"):addChild(self.m_icon4x)

    self.m_icon8x = util_spineCreate("Egypt_FastLuck_8x", true, true)
    self:findChild("Spine_Egypt_FastLuck_8x"):addChild(self.m_icon8x)

    self.m_icon10x = util_spineCreate("Egypt_FastLuck_10x", true, true)
    self:findChild("Spine_Egypt_FastLuck_10x"):addChild(self.m_icon10x)
end

function EgyptMultiplyView:showStart(multip, coins, func)
    for i = 1, #MULTIPLY_ARRAY, 1 do
        self:findChild("Spine_Egypt_FastLuck_"..MULTIPLY_ARRAY[i].."x"):setVisible(false)
    end
    self:findChild("Spine_Egypt_FastLuck_"..multip.."x"):setVisible(true)
    self.m_currMultip = self["m_icon"..multip.."x"]
    self.m_lb_coin:setString("0")
    performWithDelay(self, function()
        self:updateWinCoin(coins)
    end, 1.5)
    util_spinePlay(self.m_currMultip, "Egypt_MultiplyView_open")
    self:runCsbAction("open", false, function()
        
        self:showIdle(func)
    end) -- 播放时间线
end

function EgyptMultiplyView:updateWinCoin(coins)
    self:updateLabelSize({label=self.m_lb_coin, sx = 1, sy = 1}, 600)
    local addValue = coins / 120
    util_jumpNum(self.m_lb_coin, 0, coins, addValue, 1 / 60, {30}, nil, nil, function()
        self:updateLabelSize({label=self.m_lb_coin,sx=1,sy=1},600)
    end)
end

function EgyptMultiplyView:showIdle(func)
    util_spinePlay(self.m_currMultip, "Egypt_MultiplyView_idle")
    self:runCsbAction("idle", false, function()
        self:showOver(func)
    end)
end

function EgyptMultiplyView:showOver(func)
    util_spinePlay(self.m_currMultip, "Egypt_MultiplyView_over")
    self:runCsbAction("over", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function EgyptMultiplyView:onEnter()
    
end

function EgyptMultiplyView:showAdd()
    
end

function EgyptMultiplyView:onExit()
 
end

--默认按钮监听回调
function EgyptMultiplyView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return EgyptMultiplyView