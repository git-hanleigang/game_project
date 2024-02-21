---
--xcyy
--2018年5月23日
--PomiViewWinCoinsAction.lua

local PomiViewWinCoinsAction = class("PomiViewWinCoinsAction",util_require("base.BaseView"))


function PomiViewWinCoinsAction:initUI()

    self:createCsbNode("LinkReels/PomiLink/4in1_Pomi_baodian.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


end


function PomiViewWinCoinsAction:onEnter()
 

end

function PomiViewWinCoinsAction:onExit()
 
end


return PomiViewWinCoinsAction