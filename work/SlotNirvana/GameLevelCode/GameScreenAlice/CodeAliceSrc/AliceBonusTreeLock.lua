---
--xcyy
--2018年5月23日
--AliceBonusTreeLock.lua

local AliceBonusTreeLock = class("AliceBonusTreeLock",util_require("base.BaseView"))


function AliceBonusTreeLock:initUI(data)

    self:createCsbNode("Alice_Bonuscup_lock.csb")

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
    local index = 1
    while true do
        local grayLock = self:findChild("lock_gray_"..index)
        local lock = self:findChild("lock_"..index)
        if lock ~= nil then
            if data ~= index then
                lock:setVisible(false)
                grayLock:setVisible(false)
            end
        else
            break
        end
        index = index + 1
    end

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusTreeLock:showCollect()
    self:runCsbAction("idleframe2")
end

function AliceBonusTreeLock:animationCollect(func)
    self:runCsbAction("start", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function AliceBonusTreeLock:onEnter()
 

end

function AliceBonusTreeLock:showAdd()
    
end

function AliceBonusTreeLock:onExit()
 
end

--默认按钮监听回调
function AliceBonusTreeLock:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceBonusTreeLock