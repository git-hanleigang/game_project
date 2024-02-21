---
--xcyy
--2018年5月23日
--FarmBonus_WinCoinsView.lua

local FarmBonus_WinCoinsView = class("FarmBonus_WinCoinsView",util_require("base.BaseView"))
FarmBonus_WinCoinsView.coins = 0

function FarmBonus_WinCoinsView:initUI()

    self:createCsbNode("Farm_game_win.csb")

    self.coins = 0
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


function FarmBonus_WinCoinsView:onEnter()
 

end

function FarmBonus_WinCoinsView:showAdd()
    
end
function FarmBonus_WinCoinsView:onExit()
 
end

--默认按钮监听回调
function FarmBonus_WinCoinsView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FarmBonus_WinCoinsView