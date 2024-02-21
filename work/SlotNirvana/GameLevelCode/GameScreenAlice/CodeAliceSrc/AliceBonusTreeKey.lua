---
--xcyy
--2018年5月23日
--AliceBonusTreeKey.lua

local AliceBonusTreeKey = class("AliceBonusTreeKey",util_require("base.BaseView"))


function AliceBonusTreeKey:initUI(data)

    self:createCsbNode("Alice_Bonuscup_key.csb")

    self:runCsbAction("idleframe1") -- 播放时间线
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
    util_setCascadeOpacityEnabledRescursion(self,true)
end


function AliceBonusTreeKey:onEnter()
 

end

function AliceBonusTreeKey:showAdd()
    
end

function AliceBonusTreeKey:onExit()
 
end

function AliceBonusTreeKey:showCollect()
    self:runCsbAction("idleframe2")
end

function AliceBonusTreeKey:animationCollect(func)
    self:runCsbAction("start", false, function()
        if func ~= nil then
            func()
        end
    end)
end

--默认按钮监听回调
function AliceBonusTreeKey:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceBonusTreeKey