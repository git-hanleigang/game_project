---
--xcyy
--2018年5月23日
--MermaidRsBarView.lua

local MermaidRsBarView = class("MermaidRsBarView",util_require("base.BaseView"))


function MermaidRsBarView:initUI()

    self:createCsbNode("Mermaid_respin_counter.csb")

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


function MermaidRsBarView:onEnter()
 

end

function MermaidRsBarView:updataRespinTimes(curCount,isfirst)
    
    self:findChild("huang1"):setVisible(false)
    self:findChild("huang2"):setVisible(false)
    self:findChild("huang3"):setVisible(false)
    if curCount == 1 then
        self:findChild("huang1"):setVisible(true)

    elseif curCount == 2 then
        self:findChild("huang2"):setVisible(true)
    elseif curCount == 3 then
        if not isfirst then
            gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_RsBar_rest.mp3")
        end
        
        self:findChild("huang3"):setVisible(true)
    end

end
function MermaidRsBarView:onExit()
 
end




return MermaidRsBarView