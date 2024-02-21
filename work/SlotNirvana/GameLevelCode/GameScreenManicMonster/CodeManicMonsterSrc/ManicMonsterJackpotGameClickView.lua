---
--xcyy
--2018年5月23日
--ManicMonsterJackpotGameClickView.lua

local ManicMonsterJackpotGameClickView = class("ManicMonsterJackpotGameClickView",util_require("base.BaseView"))

ManicMonsterJackpotGameClickView.m_index = 0
ManicMonsterJackpotGameClickView.m_machine = nil

function ManicMonsterJackpotGameClickView:initUI(data)

    self:createCsbNode("ManicMonster_bonus_Jp_Idle.csb")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

    self.m_falsh = util_createAnimation("ManicMonster_bonus_Jp_Idle_L.csb")
    self:findChild("ManicMonster_bonus_Jp_IdleL"):addChild(self.m_falsh)
    self.m_falsh:setVisible(false)
end


function ManicMonsterJackpotGameClickView:onEnter()
 

end

function ManicMonsterJackpotGameClickView:onExit()
 
end

--默认按钮监听回调
function ManicMonsterJackpotGameClickView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        

        if self.m_machine:isCanTouch( ) then
            self:findChild("click"):setVisible(false)
            
            self.m_machine:setClickData( self.m_index )
            
            print(" 第几个 @@@@ ".. self.m_index)
        end
        
    end

end


return ManicMonsterJackpotGameClickView