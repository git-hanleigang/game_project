---
--xcyy
--2018年5月23日
--AliceRubyCollectBarDaGuanTail.lua

local AliceRubyCollectBarDaGuanTail = class("AliceRubyCollectBarDaGuanTail",util_require("base.BaseView"))


function AliceRubyCollectBarDaGuanTail:initUI()
    self:createCsbNode("AliceRuby_jindu_daguan.csb")
end

function AliceRubyCollectBarDaGuanTail:setWildPos( data)
    local fixPos = data.fixPos
    for i=1,20 do
        local img = self:findChild("Alice_wild_img_" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end

    for i=1,#fixPos do
        local img = self:findChild("Alice_wild_img_" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end
end

function AliceRubyCollectBarDaGuanTail:onEnter()
 

end


function AliceRubyCollectBarDaGuanTail:onExit()
 
end

--默认按钮监听回调
function AliceRubyCollectBarDaGuanTail:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceRubyCollectBarDaGuanTail