---
--xcyy
--2018年5月23日
--GoldenMammothTip.lua

local GoldenMammothTip = class("GoldenMammothTip",util_require("base.BaseView"))


function GoldenMammothTip:initUI()

    self:createCsbNode("GoldenMammoth_I_rim.csb")

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


function GoldenMammothTip:onEnter()
 

end

function GoldenMammothTip:onExit()
 
end

function GoldenMammothTip:showTip()
    self:setTouchLayer()
    self:runCsbAction("show")
    self.m_hideAction = performWithDelay(self, function()
        self.m_hideAction = nil
        self:hideTip()
    end, 4)
end

function GoldenMammothTip:hideTip()
    self:stopAllActions()
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self, true)
    self:runCsbAction("hide", false, function()
        self:removeFromParent()
    end)
end

function GoldenMammothTip:setTouchLayer()
    local function onTouchBegan_callback(touch, event)
        return true
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        self:hideTip()
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()    
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

--默认按钮监听回调
function GoldenMammothTip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return GoldenMammothTip