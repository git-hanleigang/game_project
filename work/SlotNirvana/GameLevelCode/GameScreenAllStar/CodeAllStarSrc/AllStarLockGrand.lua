---
--xcyy
--2018年5月23日
--AllStarLockGrand.lua

local AllStarLockGrand = class("AllStarLockGrand",util_require("base.BaseView"))


function AllStarLockGrand:initUI()

    self:createCsbNode("AllStar_Jackpot_unlock.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self:addClick(self:findChild("Image_6")) -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function AllStarLockGrand:onEnter()
 

end

function AllStarLockGrand:showAdd()
    
end
function AllStarLockGrand:onExit()
 
end

--默认按钮监听回调
function AllStarLockGrand:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end


return AllStarLockGrand