---
--xcyy
--2018年5月23日
--FivePandeGameTipClickView.lua

local FivePandeGameTipClickView = class("FivePandeGameTipClickView",util_require("base.BaseView"))

FivePandeGameTipClickView.Start = 1
FivePandeGameTipClickView.Idle = 2
FivePandeGameTipClickView.Over = 3

FivePandeGameTipClickView.m_CurrStates = 3

function FivePandeGameTipClickView:initUI()

    self:createCsbNode("FivePande/CollectView_0.csb")

    self:findChild("Panel_1"):setVisible(false)

    self:addClick(self:findChild("Panel_1"))

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


function FivePandeGameTipClickView:onEnter()
 

end

function FivePandeGameTipClickView:onExit()
 
end

function FivePandeGameTipClickView:setOverCallFunc( func )
    self.m_Call = func
end

--默认按钮监听回调
function FivePandeGameTipClickView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Panel_1" then

        self:findChild("Panel_1"):setVisible(false)

        if self.m_CurrStates ~= self.Over then
            self.m_CurrStates = self.Over
            self:runCsbAction("shuomingover",false)
        end
        

    end

end



return FivePandeGameTipClickView