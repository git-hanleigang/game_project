---
--xcyy
--2018年5月23日
--MermaidBonusStartView.lua

local MermaidBonusStartView = class("MermaidBonusStartView",util_require("base.BaseView"))

MermaidBonusStartView.clickPos = 1

function MermaidBonusStartView:initUI(bonusView)

    self:createCsbNode("Mermaid/BonusGameStart.csb")

    self.clickPos = 1
    self.m_parent = bonusView

    -- self:runCsbAction("actionframe") -- 播放时间线

    self:addClick(self:findChild("click_1")) 
    self:addClick(self:findChild("click_2")) 
    self:addClick(self:findChild("click_3")) 



    self.m_hailuo_1 = util_createAnimation("Mermaid/BonusGameStart_hailuo.csb")
    self:findChild("hailuo1"):addChild(self.m_hailuo_1)
    self.m_hailuo_1:runCsbAction("idle",true)
    self.m_hailuo_2 = util_createAnimation("Mermaid/BonusGameStart_hailuo.csb")
    self:findChild("hailuo2"):addChild(self.m_hailuo_2)
    self.m_hailuo_2:runCsbAction("idle",true)
    self.m_hailuo_3 = util_createAnimation("Mermaid/BonusGameStart_hailuo.csb")
    self:findChild("hailuo3"):addChild(self.m_hailuo_3)
    self.m_hailuo_3:runCsbAction("idle",true)

end


function MermaidBonusStartView:onEnter()
 

end

function MermaidBonusStartView:onExit()
 
end

function MermaidBonusStartView:hideAllClick()
    
    for i=1,3 do
        local click = self:findChild("click_"..i)
        click:setVisible(false)
    end
end


--默认按钮监听回调
function MermaidBonusStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_parent:isTouch() then

        self:hideAllClick()

        gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Click_HaiLuo.mp3")
        
        if name == "click_1" then
            self.clickPos = 1
            self.m_parent:sendData(1)
           
    
        elseif name == "click_2" then
            self.clickPos = 2
            self.m_parent:sendData(2)
            
    
        elseif name == "click_3" then
            self.clickPos = 3
            self.m_parent:sendData(3)
        end

    end

end


return MermaidBonusStartView