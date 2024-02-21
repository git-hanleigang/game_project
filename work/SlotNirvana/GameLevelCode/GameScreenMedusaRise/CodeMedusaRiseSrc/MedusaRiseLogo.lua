---
--xcyy
--2018年5月23日
--MedusaRiseLogo.lua

local MedusaRiseLogo = class("MedusaRiseLogo",util_require("base.BaseView"))


function MedusaRiseLogo:initUI()

    self:createCsbNode("MedusaRise_logo.csb")

    self:runCsbAction("idleframe", true) -- 播放时间线
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


function MedusaRiseLogo:onEnter()
 

end

function MedusaRiseLogo:showAdd()
    
end
function MedusaRiseLogo:onExit()
 
end

--默认按钮监听回调
function MedusaRiseLogo:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return MedusaRiseLogo