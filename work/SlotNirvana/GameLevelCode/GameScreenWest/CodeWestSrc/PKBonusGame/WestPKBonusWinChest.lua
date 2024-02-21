---
--xcyy
--2018年5月23日
--WestPKBonusWinChest.lua

local WestPKBonusWinChest = class("WestPKBonusWinChest",util_require("base.BaseView"))

WestPKBonusWinChest.m_index = 0
WestPKBonusWinChest.m_machine = nil

function WestPKBonusWinChest:initUI(data)

    self:createCsbNode("West_baoxiang.csb")
    
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_index = data.index
    self.m_machine = data.machine

    self.m_lab = util_createAnimation("West_bonusgame_win_baoxiang_zi.csb")
    self:findChild("Node_ActZi"):addChild(self.m_lab , 1)
    self.m_lab:setVisible(false)

end


function WestPKBonusWinChest:onEnter()
 

end

function WestPKBonusWinChest:onExit()
 
end

--默认按钮监听回调
function WestPKBonusWinChest:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click" then
        
        if self.m_machine:isCanTouch( ) then
            self.m_machine:setClickData( self.m_index )
            self:findChild("click"):setVisible(false)
            print(" WestPKBonusWinChest 第几个 @@@@ ".. self.m_index)
        end
        
    end

end


return WestPKBonusWinChest