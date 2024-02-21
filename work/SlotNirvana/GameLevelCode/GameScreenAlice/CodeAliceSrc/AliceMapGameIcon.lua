---
--xcyy
--2018年5月23日
--AliceMapGameIcon.lua

local AliceMapGameIcon = class("AliceMapGameIcon",util_require("base.BaseView"))


function AliceMapGameIcon:initUI(data)

    self:createCsbNode("Alice_Map_"..data.name..".csb")
    
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
    self.m_effect = util_createView("CodeAliceSrc.AliceMapGameIconEffect")
    self:findChild("Node"):addChild(self.m_effect)
    self.m_effect:setVisible(false)
end


function AliceMapGameIcon:onEnter()
 
end

function AliceMapGameIcon:showTriggerEffect()
    self.m_effect:setVisible(true)
    self.m_effect:showAnim()
end

function AliceMapGameIcon:showCompletedEffect()
    self.m_effect:setVisible(true)
    self.m_effect:showIdle()
end

function AliceMapGameIcon:showLightIdle()
    self.m_effect:setVisible(false)
    self:runCsbAction("idleframe2")
end

function AliceMapGameIcon:showDarkIdle()
    self.m_effect:setVisible(false)
    self:runCsbAction("idleframe1")
end

function AliceMapGameIcon:showClickEffect()
    self:runCsbAction("idle", true)
end

function AliceMapGameIcon:showSelectedEffect()
    self:runCsbAction("actionframe", false, function()
        self:showLightIdle()
    end)
end

function AliceMapGameIcon:onExit()
 
end

--默认按钮监听回调
function AliceMapGameIcon:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceMapGameIcon