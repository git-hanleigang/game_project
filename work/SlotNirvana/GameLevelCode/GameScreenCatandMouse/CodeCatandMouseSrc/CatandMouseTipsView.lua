---
--xcyy
--2018年5月23日
--CatandMouseTipsView.lua

local CatandMouseTipsView = class("CatandMouseTipsView",util_require("Levels.BaseLevelDialog"))


function CatandMouseTipsView:initUI()

    self:createCsbNode("CatandMouse_wenzikuang.csb")

    self:runCsbAction("start",false,function (  )
        self:runCsbAction("idle")
    end) -- 播放时间线
    self:setShowTips(1)
end

function CatandMouseTipsView:setShowTips(index)
    for i=1,3 do
        if i == index then
            self:findChild("CatandMouse_zhujiemian_wenzi_" .. i):setVisible(true)
        else
            self:findChild("CatandMouse_zhujiemian_wenzi_" .. i):setVisible(false)
        end
    end
end


return CatandMouseTipsView