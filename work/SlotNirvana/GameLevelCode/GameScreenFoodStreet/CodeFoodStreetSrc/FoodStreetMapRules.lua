---
--xcyy
--2018年5月23日
--FoodStreetMapRules.lua

local FoodStreetMapRules = class("FoodStreetMapRules",util_require("base.BaseView"))

FoodStreetMapRules.m_pageIndex = 1

function FoodStreetMapRules:initUI()

    self:createCsbNode("FoodStreet/shuomingtanban.csb")

    self:updatePage( )

end


function FoodStreetMapRules:onEnter()

end

function FoodStreetMapRules:onExit()
 
end

--默认按钮监听回调
function FoodStreetMapRules:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_1" then

        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        self:removeFromParent() 

    elseif name == "you" then

        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")

        self.m_pageIndex = self.m_pageIndex + 1
        if self.m_pageIndex > 3 then
            self.m_pageIndex = 1
        end
        self:updatePage( )

    elseif name == "zuo" then

        gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
        
        self.m_pageIndex = self.m_pageIndex - 1
        if self.m_pageIndex < 1 then
            self.m_pageIndex = 3
        end

        self:updatePage( )
    end
    
end

function FoodStreetMapRules:updatePage( )
    
    local pageName = {"FoodStreet_jiesuanzi_1","FoodStreet_jiesuanzi_2_85","FoodStreet_jiesuanzi_3_86"}

    for i=1,#pageName do
        local node = self:findChild(pageName[i])
        if node then
            node:setVisible(false)

            if i == self.m_pageIndex then
                node:setVisible(true)
            end
            
        end
    end

end


return FoodStreetMapRules