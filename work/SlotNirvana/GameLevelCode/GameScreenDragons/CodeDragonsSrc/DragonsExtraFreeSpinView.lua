---
--xcyy
--2018年5月23日
--DragonsExtraFreeSpinView.lua

local DragonsExtraFreeSpinView = class("DragonsExtraFreeSpinView",util_require("base.BaseView"))


function DragonsExtraFreeSpinView:initUI(data)

    self:createCsbNode("Dragons_freegametankuang.csb")
    local num = data._num

    local lab = self:findChild("BitmapFontLabel_1") -- 获得子节点
    lab:setString(num)
    self:runCsbAction("start") -- 播放时间线

end

function DragonsExtraFreeSpinView:onEnter()

end

function DragonsExtraFreeSpinView:onExit()

end


return DragonsExtraFreeSpinView