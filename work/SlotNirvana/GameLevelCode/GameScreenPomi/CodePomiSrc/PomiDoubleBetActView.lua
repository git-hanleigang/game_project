---
--xcyy
--2018年5月23日
--PomiDoubleBetActView.lua

local PomiDoubleBetActView = class("PomiDoubleBetActView",util_require("base.BaseView"))


function PomiDoubleBetActView:initUI(posIndex, multiplePosList)

    self:createCsbNode("Socre_Pomi_DoubleBet_1.csb")

    local vecPos = {}
    local distance = posIndex - 5
    for i = 1, #multiplePosList, 1 do
        local index = nil
        local pos = multiplePosList[i]
        if posIndex - pos >= 4 then
            index = pos - distance + 2
        elseif posIndex - pos <= -4 then
            index = pos - distance - 2
        else
            index = pos - distance
        end
        vecPos[#vecPos + 1] = index
    end
    for i = 1, 9, 1 do
        local sp = self:findChild("sp_"..i)
        if sp ~= nil then
            sp:setVisible(false)
            for j = 1, #vecPos, 1 do
                if vecPos[j] == i then
                    sp:setVisible(true)
                    break
                end
            end
        end
    end

end


function PomiDoubleBetActView:onEnter()
 

end


function PomiDoubleBetActView:onExit()
 
end


return PomiDoubleBetActView