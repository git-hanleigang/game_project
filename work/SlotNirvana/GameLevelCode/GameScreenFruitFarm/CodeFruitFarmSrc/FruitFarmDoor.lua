---
--xcyy
--2018年5月23日
--FruitFarmDoor.lua

local FruitFarmDoor = class("FruitFarmDoor",util_require("base.BaseView"))

FruitFarmDoor.LOCK = 1  --封印状态
FruitFarmDoor.UNLOCK = 2 --解封状态
FruitFarmDoor.OPEN = 3 --打开状态

function FruitFarmDoor:initUI(status)

    self:createCsbNode("Socre_FruitFarm_Door.csb")
    self:setIdleStatus(status)
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


function FruitFarmDoor:onEnter()
 

end

function FruitFarmDoor:showAdd()
    
end
function FruitFarmDoor:onExit()
 
end

--默认按钮监听回调
function FruitFarmDoor:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

--亮光
function FruitFarmDoor:playLight()
    if self.m_status == self.LOCK then
        self:runCsbAction("liang")
    end
end

--亮光2
function FruitFarmDoor:playShine()
    if self.m_status == self.LOCK then
        self:runCsbAction("liang2", true)
    end
end

--解封
function FruitFarmDoor:playUnLock( )
    if self.m_status ~= self.LOCK then
        return
    end
    self.m_status = self.UNLOCK
    self:runCsbAction("actionframe")
end

--打开
function FruitFarmDoor:playOpen(isFree)
    if self.m_status ~= self.UNLOCK then
        return false
    end
    self.m_status = self.OPEN
    if isFree then
        self:runCsbAction("open_unlock", false)
    else
        self:runCsbAction("open_lock_base", false)
    end
    return true
end

--关闭
function FruitFarmDoor:playLock(  )
    if self.m_status ~= self.OPEN then
        self:setIdleStatus(self.m_status)
        return
    end
    self.m_status = self.LOCK
    self:runCsbAction("close_lock", false)
end

function FruitFarmDoor:playShan(  )
    if self.m_status ~= self.UNLOCK then
        return
    end
    self:runCsbAction("shan", true)
end

function FruitFarmDoor:isLock(  )
    return self.m_status == self.LOCK
end

function FruitFarmDoor:setIdleStatus(status)
    self.m_status = status
    if self.m_status == self.LOCK then
        self:runCsbAction("idle_lock")
    elseif self.m_status == self.UNLOCK then
        self:runCsbAction("idle_unlock")
    end
end

return FruitFarmDoor