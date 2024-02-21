---
--xcyy
--2018年5月23日
--AliceJackpotMore.lua

local AliceJackpotMore = class("AliceJackpotMore",util_require("base.BaseView"))


function AliceJackpotMore:initUI(data)

    self:createCsbNode("Alice/BonusMapOver.csb")

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
    self:findChild("m_lb_num"):setString(util_formatCoins(data,50))

    self:runCsbAction("start", false, function()
        self.m_clickFlag = true
        self:runCsbAction("idle", true)
    end)
end


function AliceJackpotMore:onEnter()
 

end

function AliceJackpotMore:showAdd()
    
end
function AliceJackpotMore:onExit()
 
end

function AliceJackpotMore:setRemoveCallBack(func)
    self.m_callFunc = func
end

--默认按钮监听回调
function AliceJackpotMore:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFlag ~= true then
        return
    end
    self.m_clickFlag = false
    self:runCsbAction("over", false, function()
        if self.m_callFunc ~= nil then
            self.m_callFunc()
        end
        self:removeFromParent()
    end)
end


return AliceJackpotMore