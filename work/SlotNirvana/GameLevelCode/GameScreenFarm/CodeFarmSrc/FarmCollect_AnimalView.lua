---
--xcyy
--2018年5月23日
--FarmCollect_AnimalView.lua

local FarmCollect_AnimalView = class("FarmCollect_AnimalView",util_require("base.BaseView"))

FarmCollect_AnimalView.m_niuIndex = 4
FarmCollect_AnimalView.m_zhuIndex = 3
FarmCollect_AnimalView.m_yangIndex = 2
FarmCollect_AnimalView.m_jiIndex = 1

local spinePathList = {"Socre_Farm_6","Socre_Farm_7","Socre_Farm_8","Socre_Farm_9"}

function FarmCollect_AnimalView:initUI(index)

    local csbPath = "Farm_game_duibai_Animal.csb"
    local spinePath = spinePathList[index]

    self:createCsbNode(csbPath)

    self.m_AnimalSpineNode = util_spineCreate(spinePath , true, true)
    self:findChild("actNode"):addChild(self.m_AnimalSpineNode)

    self:findChild("Farm_game_duibai_ji"):setVisible(false)
    self:findChild("Farm_game_duibai_niu"):setVisible(false)
    self:findChild("Farm_game_duibai_yang"):setVisible(false)
    self:findChild("Farm_game_duibai_zhu"):setVisible(false)

    
    if self.m_niuIndex == index then
        self.m_AnimalSpineNode:setPosition(0,0)

        self:findChild("Farm_game_duibai_niu"):setVisible(true)

    elseif self.m_zhuIndex == index then

        self:findChild("Farm_game_duibai_zhu"):setVisible(true)

        self.m_AnimalSpineNode:setPosition(0,0)
    elseif self.m_yangIndex == index then

        self:findChild("Farm_game_duibai_yang"):setVisible(true)

        self.m_AnimalSpineNode:setPosition(0,0)

    elseif self.m_jiIndex == index then

        self:findChild("Farm_game_duibai_ji"):setVisible(true)

        self.m_AnimalSpineNode:setPosition(0,0)
    end
    

    self:addClick(self:findChild("click"))
    
    
    
end

function FarmCollect_AnimalView:setClickCall(func)

        self.m_clickCall = function(  )
            if func then
                func()
            end
        end
end

function FarmCollect_AnimalView:animalSpeak(func )
    util_spinePlay(self.m_AnimalSpineNode, "idleframe2",true)
    -- util_spineEndCallFunc(self.m_AnimalSpineNode, "idleframe2", func)
end

--默认按钮监听回调
function FarmCollect_AnimalView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    print("++++++++++++++")
   if self.m_clickCall then
        self.m_clickCall()
   end 

end

function FarmCollect_AnimalView:onEnter()
 

end


function FarmCollect_AnimalView:onExit()
 
end


return FarmCollect_AnimalView