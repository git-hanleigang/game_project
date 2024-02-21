---
--xcyy
--2018年5月23日
--MermaidFreeSpinStartView.lua

local MermaidFreeSpinStartView = class("MermaidFreeSpinStartView",util_require("base.BaseView"))

MermaidFreeSpinStartView.m_isCallTouch = false
function MermaidFreeSpinStartView:initUI()

    self:createCsbNode("Mermaid/FreeSpinStart.csb")


    self.m_isCallTouch = false

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self.m_isCallTouch = true
    end) -- 播放时间线

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function MermaidFreeSpinStartView:onEnter()
 

end

function MermaidFreeSpinStartView:initCallFunc( func )

    self.m_CallFunc = function(  )
        if func then
            func()
        end
    end
    
end
function MermaidFreeSpinStartView:onExit()
 
end

--默认按钮监听回调
function MermaidFreeSpinStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_isCallTouch == true then
        self.m_isCallTouch = false

        if name ==  "click" then
        
            self:findChild("click"):setVisible(false)
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
            self:runCsbAction("over",false,function(  )
                
                if self.m_CallFunc then
                    self.m_CallFunc()
                end

                self:removeFromParent()
            end)
        end

    end

    

end


return MermaidFreeSpinStartView