---
--xcyy
--2018年5月23日
--MermaidBonusQiPaoBtn.lua

local MermaidBonusQiPaoBtn = class("MermaidBonusQiPaoBtn",util_require("base.BaseView"))


function MermaidBonusQiPaoBtn:initUI(parent)

    self.m_parent = parent

    self:createCsbNode("Mermaid_Jibiqipao.csb")

    self:runCsbAction("idleframe",true)

    -- self:runCsbAction("actionframe") -- 播放时间线
    self:addClick(self:findChild("click_pao")) -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function MermaidBonusQiPaoBtn:onEnter()
 

end

function MermaidBonusQiPaoBtn:showAdd()
    
end
function MermaidBonusQiPaoBtn:onExit()
 
end

--默认按钮监听回调
function MermaidBonusQiPaoBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name ==  "click_pao" then

        self.m_parent:clickOnePao( self ) 

    end

end


return MermaidBonusQiPaoBtn