---
--xcyy
--2018年5月23日
--WestPKBonusWinView.lua

local WestPKBonusWinView = class("WestPKBonusWinView",util_require("base.BaseView"))

WestPKBonusWinView.m_machine = nil
function WestPKBonusWinView:initUI(machine)

    self.m_machine = machine
    self:createCsbNode("West/BonusGamewin.csb")

    self:initChest()


end

function WestPKBonusWinView:initChest( )
    
    for i=1,3 do
        local data = {}
        data.index = i - 1
        data.machine = self.m_machine

        local chest = util_createView("CodeWestSrc.PKBonusGame.WestPKBonusWinChest",data)    

        local nodeName = "baoxiang" .. i
        self:findChild(nodeName):addChild(chest)
        self["chest_" .. i] = chest
        chest:runCsbAction("idleframe_1",true)
      
    end

end

function WestPKBonusWinView:restAllChest( )
    
    for i=1,3 do

        local chest = self["chest_" .. i]
        chest:runCsbAction("idleframe_1",true)
        chest:findChild("click"):setVisible(true)
        chest.m_lab:setVisible(false)
      
    end

end

function WestPKBonusWinView:onEnter()
 

end

function WestPKBonusWinView:showBeginAct(func)
    
    if func then
        func()
    end


end


function WestPKBonusWinView:onExit()
 
end

--默认按钮监听回调
function WestPKBonusWinView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return WestPKBonusWinView