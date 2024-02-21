---
--xcyy
--2018年5月23日
--ClassicCashMulpleView.lua

local ClassicCashMulpleView = class("ClassicCashMulpleView",util_require("base.BaseView"))


function ClassicCashMulpleView:initUI()

    self:createCsbNode("ClassicCash_mulple.csb")


end


function ClassicCashMulpleView:onEnter()
 

end

function ClassicCashMulpleView:showOneImg( index)
    local nameList = {"10x","15x","20x","25x","30x"} 
    for k,v in pairs(nameList) do
        local name = v
        local node =  self:findChild(name)
        if node then
            node:setVisible(false)        
        end
    end

    for k,v in pairs(nameList) do
        local name = v
        local node =  self:findChild(name)
        if node then
            if k == index then
                node:setVisible(true)
                break
            end
            
        end
    end


end


function ClassicCashMulpleView:onExit()
 
end


return ClassicCashMulpleView