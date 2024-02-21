---
--xcyy
--2018年5月23日
--BingoPriatesScatterClickView.lua

local BingoPriatesScatterClickView = class("BingoPriatesScatterClickView",util_require("base.BaseView"))
BingoPriatesScatterClickView.m_machine = nil

BingoPriatesScatterClickView.m_index = nil

function BingoPriatesScatterClickView:initUI()

    self:createCsbNode("Socre_BingoPriates_Scatter_clickNode.csb")

    self.m_machine = nil

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
    
    self:addClick(self:findChild("click"))

end


function BingoPriatesScatterClickView:onEnter()
 

end

function BingoPriatesScatterClickView:initMachine( machine,index)
    self.m_machine = machine
    self.m_index = index
end
function BingoPriatesScatterClickView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesScatterClickView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        self.m_machine:clickScatterCallFunc(self.m_index)
    end

end


return BingoPriatesScatterClickView