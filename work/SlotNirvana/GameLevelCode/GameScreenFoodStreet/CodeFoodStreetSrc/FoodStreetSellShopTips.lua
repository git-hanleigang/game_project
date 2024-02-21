---
--xcyy
--2018年5月23日
--FoodStreetSellShopTips.lua
local SendDataManager = require "network.SendDataManager"
local FoodStreetSellShopTips = class("FoodStreetSellShopTips",util_require("base.BaseView"))


FoodStreetSellShopTips.m_click = false

function FoodStreetSellShopTips:initUI()

    self:createCsbNode("FoodStreet_Tips.csb")

    self:addClick(self:findChild("click"))

    self.m_click = true

    self:runCsbAction("start", false, function()

        self.m_click = false
        self:runCsbAction("idle", true)

    end) 

    self.m_waitNode = cc.Node:create()
    self:addChild(self.m_waitNode)
    performWithDelay(self.m_waitNode,function(  )
                
        if not self.m_click  then
            self:runCsbAction("over", false, function()

                if self.m_func then
                    self.m_func()
                    self.m_func = nil
                end
                
            end) 
            
            self.m_click = true
        end
    end,2)

end


function FoodStreetSellShopTips:setCallFunc(_func)
    self.m_func = _func

end

function FoodStreetSellShopTips:onEnter()
 

end

function FoodStreetSellShopTips:onExit()
 
end

--默认按钮监听回调
function FoodStreetSellShopTips:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_click then
        return 
    end

    self.m_click = true

    self.m_waitNode:stopAllActions()

    gLobalSoundManager:playSound("FoodStreetSounds/sound_FoodStreet_click.mp3")
  

    self:runCsbAction("over", false, function()

        if self.m_func then
            self.m_func()
            self.m_func = nil
        end

        
        
    end) 
end


return FoodStreetSellShopTips