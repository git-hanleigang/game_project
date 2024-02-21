---
--xcyy
--2018年5月23日
--WestPKBonusClickView.lua

local WestPKBonusClickView = class("WestPKBonusClickView",util_require("base.BaseView"))

WestPKBonusClickView.m_index = 0
WestPKBonusClickView.m_machine = nil

function WestPKBonusClickView:initUI(data)

    self:createCsbNode("West_bonusgame_men.csb")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

end


function WestPKBonusClickView:onEnter()
 

end

function WestPKBonusClickView:onExit()
 
end

--默认按钮监听回调
function WestPKBonusClickView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        if self.m_machine:isCanTouch( ) then
            gLobalSoundManager:playSound("WestSounds/music_West_BonusGame_ClickMen.mp3")

            self.m_machine:setClickData( self.m_index )
            self:findChild("click"):setVisible(false)
            print(" WestPKBonusClickView 第几个 @@@@ ".. self.m_index)
        end
        
    end

end


return WestPKBonusClickView