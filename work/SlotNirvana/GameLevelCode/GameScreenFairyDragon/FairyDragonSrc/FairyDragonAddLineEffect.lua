local FairyDragonAddLineEffect = class("FairyDragonAddLineEffect", util_require("base.BaseView"))

function FairyDragonAddLineEffect:initUI()
    self:createCsbNode("FairyDragon_shuzi_jiantou.csb")
    -- self:runCsbAction("actionframe1") -- 播放时间线
end

function FairyDragonAddLineEffect:onEnter()
end

function FairyDragonAddLineEffect:onExit()
end

return FairyDragonAddLineEffect
