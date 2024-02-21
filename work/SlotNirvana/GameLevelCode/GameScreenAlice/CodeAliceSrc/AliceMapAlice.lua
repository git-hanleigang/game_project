---
--xcyy
--2018年5月23日
--AliceMapAlice.lua

local AliceMapAlice = class("AliceMapAlice",util_require("base.BaseView"))


function AliceMapAlice:initUI()

    self:createCsbNode("Alice_Map_pointer.csb")

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


function AliceMapAlice:onEnter()

    

end

function AliceMapAlice:moveAnimation()
    self:runCsbAction("move", false, function()
        self:showIdle()
    end)
end

function AliceMapAlice:showIdle()
    self:runCsbAction("idle", true)
end

function AliceMapAlice:showAppear()
    self:runCsbAction("start", false, function()
        self:showIdle()
    end)
end

function AliceMapAlice:onExit()
 
end

--默认按钮监听回调
function AliceMapAlice:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceMapAlice