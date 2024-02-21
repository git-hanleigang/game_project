---
--xcyy
--2018年5月23日
--HallowinRespinBtn.lua

local HallowinRespinBtn = class("HallowinRespinBtn",util_require("base.BaseView"))


function HallowinRespinBtn:initUI()
    
    self:createCsbNode("Socre_Hallowin_BonusClick.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self.m_clickFlag = true
end

function HallowinRespinBtn:onEnter()

end

function HallowinRespinBtn:onExit()
 
end

function HallowinRespinBtn:setClickCallBack(func)
    self.m_cliclCall = func
end

--默认按钮监听回调
function HallowinRespinBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFlag ~= true then
        return
    end
    if self.m_cliclCall ~= nil then
        self.m_clickFlag = self.m_cliclCall()
    else
        self.m_clickFlag = false
    end
    

end


return HallowinRespinBtn