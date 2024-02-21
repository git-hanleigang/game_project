---
--xcyy
--2018年5月23日
--MedusaRiseFsTittle.lua

local MedusaRiseFsTittle = class("MedusaRiseFsTittle",util_require("base.BaseView"))
MedusaRiseFsTittle.m_strCurrAnimName = nil

function MedusaRiseFsTittle:initUI()

    self:createCsbNode("MedusaRise_freespin.csb")

    -- 播放时间线
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

function MedusaRiseFsTittle:showNormalAnim()
    if self.m_strCurrAnimName ~= "actionframe1" then
        self.m_strCurrAnimName = "actionframe1"
        self:runCsbAction("actionframe1", true)
    end
end

function MedusaRiseFsTittle:showSpecialAnim()
    if self.m_strCurrAnimName ~= "actionframe2" then
        self.m_strCurrAnimName = "actionframe2"
        self:runCsbAction("actionframe2", true)
    end
end

function MedusaRiseFsTittle:onEnter()
 

end

function MedusaRiseFsTittle:onExit()
 
end

--默认按钮监听回调
function MedusaRiseFsTittle:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return MedusaRiseFsTittle