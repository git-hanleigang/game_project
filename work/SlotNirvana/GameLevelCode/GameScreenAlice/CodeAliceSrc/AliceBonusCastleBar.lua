---
--xcyy
--2018年5月23日
--AliceBonusCastleBar.lua

local AliceBonusCastleBar = class("AliceBonusCastleBar",util_require("base.BaseView"))
AliceBonusCastleBar.m_collectNum = nil

function AliceBonusCastleBar:initUI()

    self:createCsbNode("Alice_BonusJp_point.csb")

    self:runCsbAction("idleframe") -- 播放时间线
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
    self.m_collectNum = 0

    util_setCascadeOpacityEnabledRescursion(self,true)
end

function AliceBonusCastleBar:showSelected()
    self.m_collectNum = self.m_collectNum + 1
    self:runCsbAction("idleframe"..self.m_collectNum)
end

function AliceBonusCastleBar:showResult(func)
    self.m_collectNum = self.m_collectNum + 1
    self:runCsbAction("idle"..self.m_collectNum, false, function()
        if self.m_collectNum == 2 then
            self:runCsbAction("actionframe", false, function()
                
            end)
            if func ~= nil then
                func()
            end
        else
            if func ~= nil then
                func()
            end
        end
    end)
end

function AliceBonusCastleBar:getCollectNum( )
    return self.m_collectNum
end

function AliceBonusCastleBar:onEnter()
 

end

function AliceBonusCastleBar:showAdd()
    
end
function AliceBonusCastleBar:onExit()
 
end

--默认按钮监听回调
function AliceBonusCastleBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceBonusCastleBar