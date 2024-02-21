---
--xcyy
--2018年5月23日
--CharmsViewWinCoinsAction.lua

local CharmsViewWinCoinsAction = class("CharmsViewWinCoinsAction",util_require("base.BaseView"))


function CharmsViewWinCoinsAction:initUI()

    self:createCsbNode("LinkReels/CharmsLink/4in1_Charms_baodian.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


end


function CharmsViewWinCoinsAction:onEnter()
 

end

function CharmsViewWinCoinsAction:onExit()
 
end


return CharmsViewWinCoinsAction