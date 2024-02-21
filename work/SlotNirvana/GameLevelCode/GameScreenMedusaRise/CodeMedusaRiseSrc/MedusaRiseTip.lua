---
--xcyy
--2018年5月23日
--MedusaRiseTip.lua

local MedusaRiseTip = class("MedusaRiseTip",util_require("base.BaseView"))
MedusaRiseTip.m_animIndex = nil

function MedusaRiseTip:initUI()

    self:createCsbNode("MedusaRise_fs_tishi.csb")

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
    
    self:changeUI()
end

function MedusaRiseTip:showTipIdle()
    -- self:runCsbAction("idleframe"..self.m_animIndex, true)
    -- self.m_actionSchedule = schedule(self, function()
    --     self:changeTipAnim()
    -- end, 10)
end

function MedusaRiseTip:changeTipAnim()
    -- self:runCsbAction("actionframe"..self.m_animIndex, false, function()
    --     self.m_animIndex = self.m_animIndex + 1
    --     if self.m_animIndex > 2 then
    --         self.m_animIndex = 1
    --     end
    --     self:runCsbAction("idleframe"..self.m_animIndex, true)
    -- end)
end

function MedusaRiseTip:changeUI(index)
    if index == nil then
        self:runCsbAction("idleframe1", true)
    elseif index == 0 then
        self:runCsbAction("idleframe2", true)
    else
        self:runCsbAction("idleframe3", true)
    end
    -- if index == nil then
    --     self.m_nodeFs:setVisible(true)
    --     self.m_fsMore:setVisible(false)
    --     self.m_multip2:setVisible(true)
    --     self.m_multip3:setVisible(false)
    --     self.m_multip5:setVisible(false)
    -- else
    --     self.m_nodeFs:setVisible(false)
    --     self.m_fsMore:setVisible(true)
    --     if index == 0 then
    --         self.m_multip2:setVisible(false)
    --         self.m_multip3:setVisible(true)
    --         self.m_multip5:setVisible(false)
    --     else
    --         self.m_multip2:setVisible(false)
    --         self.m_multip3:setVisible(false)
    --         self.m_multip5:setVisible(true)
    --     end
    -- end
end

function MedusaRiseTip:onEnter()

end

function MedusaRiseTip:onExit()
 
end

return MedusaRiseTip