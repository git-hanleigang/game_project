---
--xcyy
--2018年5月23日
--StarryXmasCollectBarDaGuanTail.lua

local StarryXmasCollectBarDaGuanTail = class("StarryXmasCollectBarDaGuanTail",util_require("base.BaseView"))


function StarryXmasCollectBarDaGuanTail:initUI()
    self:createCsbNode("StarryXmas_shoujilan_daguan.csb")
end

function StarryXmasCollectBarDaGuanTail:setWildPos( data)
    self:findChild("m_lb_num_0"):setString(data.triggerTimes)

    local fixPos = data.fixPos
    for i=1,20 do
        local img = self:findChild("wild_img_" .. i - 1) 
        if img then
            img:setVisible(false)
        end
    end

    for i=1,#fixPos do
        local img = self:findChild("wild_img_" .. fixPos[i]) 
        if img then
            img:setVisible(true)
        end
    end
end

function StarryXmasCollectBarDaGuanTail:onEnter()
 

end


function StarryXmasCollectBarDaGuanTail:onExit()
 
end

--默认按钮监听回调
function StarryXmasCollectBarDaGuanTail:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return StarryXmasCollectBarDaGuanTail