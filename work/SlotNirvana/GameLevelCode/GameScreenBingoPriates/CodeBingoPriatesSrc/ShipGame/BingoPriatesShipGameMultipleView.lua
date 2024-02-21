---
--xcyy
--2018年5月23日
--BingoPriatesShipGameMultipleView.lua

local BingoPriatesShipGameMultipleView = class("BingoPriatesShipGameMultipleView",util_require("base.BaseView"))

BingoPriatesShipGameMultipleView.m_MultipleNUm = 0
function BingoPriatesShipGameMultipleView:initUI()

    self:createCsbNode("BingoPriates_shipGame_hudiej.csb")

    self.m_MultipleNUm = 0
    self:initMultipleNode()
end


function BingoPriatesShipGameMultipleView:initMultipleNode( )
        
    for i=1,8 do
        
        local MultipleNode = util_createAnimation("BingoPriates_shipGame_hudiej_x" .. i .. ".csb")
        self:findChild("x" .. i):addChild(MultipleNode)
        MultipleNode:runCsbAction("idle1")
        self["MultipleNode" .. i] = MultipleNode
    end
end


function BingoPriatesShipGameMultipleView:onEnter()
 

end

function BingoPriatesShipGameMultipleView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesShipGameMultipleView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function BingoPriatesShipGameMultipleView:updateMultipleUI( multiple )
    
    for i=1,8 do
        local MultipleNode = self["MultipleNode" .. i]
        if MultipleNode then
            if i == multiple then

                if self.m_MultipleNUm ~= multiple then
                    self.m_MultipleNUm = multiple
                    gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_ShipGame_updateMultiple.mp3")
                    MultipleNode:runCsbAction("actionframe")
                end
               
            elseif i < multiple then
                MultipleNode:runCsbAction("idle2")
            elseif i > multiple then
                MultipleNode:runCsbAction("idle1")
            end
        end
    end

end

return BingoPriatesShipGameMultipleView