---
--xcyy
--2018年5月23日
--BeerGirlMiniReelsLogoView.lua

local BeerGirlMiniReelsLogoView = class("BeerGirlMiniReelsLogoView",util_require("base.BaseView"))


function BeerGirlMiniReelsLogoView:initUI()

    self:createCsbNode("BeerGirl_logo.csb")

    self:runCsbAction("idle1",true) -- 播放时间线


end


function BeerGirlMiniReelsLogoView:onEnter()
 

end

function BeerGirlMiniReelsLogoView:showAdd()
    
end
function BeerGirlMiniReelsLogoView:onExit()
 
end

--默认按钮监听回调
function BeerGirlMiniReelsLogoView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return BeerGirlMiniReelsLogoView