---
--xcyy
--2018年5月23日
--WallballCollectEffect.lua

local WallballCollectEffect = class("WallballCollectEffect",util_require("base.BaseView"))


function WallballCollectEffect:initUI(data)

    self:createCsbNode("Wallball_shoujitiao_"..data..".csb")

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

function WallballCollectEffect:collectAnim()
    self:runCsbAction("shouji1", false, function()
        self:runCsbAction("idle1", true)
    end)
end

function WallballCollectEffect:onEnter()

end

function WallballCollectEffect:onExit()
 
end

--默认按钮监听回调
function WallballCollectEffect:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return WallballCollectEffect