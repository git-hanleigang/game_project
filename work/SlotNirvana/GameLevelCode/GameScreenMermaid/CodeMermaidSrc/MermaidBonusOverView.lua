---
--xcyy
--2018年5月23日
--MermaidBonusOverView.lua

local MermaidBonusOverView = class("MermaidBonusOverView",util_require("base.BaseView"))


function MermaidBonusOverView:initUI()

    self.m_click = false

    self:createCsbNode("Mermaid/BonusGameOver.csb")

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


function MermaidBonusOverView:onEnter()
 

end


function MermaidBonusOverView:initViewData(coins,callBackFun)

    local node1=self:findChild("m_lb_coins")

    self:runCsbAction("start")

    self.m_callFun = callBackFun
    node1:setString(coins)

    self:updateLabelSize({label=node1,sx=0.54,sy=0.54},1184)
    
end

function MermaidBonusOverView:onExit()
 
end


function MermaidBonusOverView:clickFunc(sender)
    local name = sender:getName()

    if name == "Button_1" then

        if self.m_click == true then
            return 
        end
        self.m_click = true
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:runCsbAction("over",false,function(  )
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)


    end
end

return MermaidBonusOverView