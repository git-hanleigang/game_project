---
--xcyy
--2018年5月23日
--BeerHauseCupView.lua

local BeerHauseCupView = class("BeerHauseCupView",util_require("base.BaseView"))

BeerHauseCupView.m_canTouch = false

function BeerHauseCupView:initUI()

    self:createCsbNode("Socre_BeerHause_BonusGameItem.csb")

    self.m_canTouch = false

    -- self:runCsbAction("actionframe") -- 播放时间线
     -- 获得子节点
    
     self:addViewClick( )
end

function BeerHauseCupView:addViewClick( )
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听
end

function BeerHauseCupView:setClickStates( state)
    self.m_canTouch = state
end 

function BeerHauseCupView:initItem(game,index,func)
    self.m_game=game
    self.m_index=index
    self.m_func=func
    self:setClickStates( true)
    self.isShowItem = false
end

function BeerHauseCupView:onEnter()
 

end

function BeerHauseCupView:onExit()
 
end

--默认按钮监听回调
function BeerHauseCupView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self.m_game:isTouch() then
        return
    end

    if self.m_game.isClickNow then
        return 
    end 
    
    if self.m_canTouch == true then
        self.m_canTouch = false
        sender:setVisible(false)
    else
        sender:setVisible(false)
        return 
    end


    if name == "click" then

        gLobalSoundManager:playSound("BeerHauseSounds/BeerHause_click_cup.mp3")

        if self.m_func then
            self.m_func(self.m_index)
        end
        
    end

end


return BeerHauseCupView