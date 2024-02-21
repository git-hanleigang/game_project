local PirateOarsView = class("PirateOarsView", util_require("base.BaseView"))

function PirateOarsView:initUI()
    
    local resourceFilename="Socre_Pirate_chuanduo.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("actionframe", true) -- 播放时间线
end

function PirateOarsView:onExit()
 
end

function PirateOarsView:onEnter()
 
end

return PirateOarsView