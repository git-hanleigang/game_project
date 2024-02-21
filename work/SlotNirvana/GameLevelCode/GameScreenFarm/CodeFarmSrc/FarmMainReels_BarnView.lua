---
--xcyy
--2018年5月23日
--FarmMainReels_BarnView.lua

local FarmMainReels_BarnView = class("FarmMainReels_BarnView",util_require("base.BaseView"))


function FarmMainReels_BarnView:initUI()

    self:createCsbNode("Farm_gucang.csb")

    self.m_BarnSpineNode = util_spineCreate("Farm_gucang" , true, true)
    self:findChild("Node_1"):addChild(self.m_BarnSpineNode)
    self.m_BarnSpineNode:setPosition(-80,120)
    util_spinePlay(self.m_BarnSpineNode,"idleframe",true)

    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

end

function FarmMainReels_BarnView:initMachine( machine)
    self.m_machine = machine
end

function FarmMainReels_BarnView:onEnter()
 

end


function FarmMainReels_BarnView:onExit()
 
end

--默认按钮监听回调
function FarmMainReels_BarnView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        if self.m_machine:checkShopShouldClick( ) then
            -- 不允许点击
            return
        end 
        
        gLobalSoundManager:playSound("FarmSounds/music_Farm_click_guCang.mp3")

        self.m_machine:showCollectView( )
    end

end


return FarmMainReels_BarnView