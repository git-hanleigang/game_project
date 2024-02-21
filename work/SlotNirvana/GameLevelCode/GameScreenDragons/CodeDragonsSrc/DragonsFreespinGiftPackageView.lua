---
--xcyy
--2018年5月23日
--DragonsFreespinGiftPackageView.lua

local DragonsFreespinGiftPackageView = class("DragonsFreespinGiftPackageView",util_require("base.BaseView"))

DragonsFreespinGiftPackageView.m_freespinCurrtTimes = 0


function DragonsFreespinGiftPackageView:initUI(data)
    self:createCsbNode("Dragons_qiandai.csb")
    local num = data.num
    self:findChild("BitmapFontLabel_1"):setString(num)
    self:runCsbAction("start",false,function(  )
        -- self:runCsbAction("actionframe",false)
    end)
end


function DragonsFreespinGiftPackageView:onEnter()

end

function DragonsFreespinGiftPackageView:onExit()
end


-- 更新并显示FreeSpin次数
function DragonsFreespinGiftPackageView:updateFreespinCount(curtimes)
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    self:runCsbAction("actionframe2",false,function()
    end)
end

-- 更新并显示FreeSpin次数
function DragonsFreespinGiftPackageView:showFreespinCount(curtimes)
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
    self:runCsbAction("actionframe",false,function()
    end)
end

function DragonsFreespinGiftPackageView:changeFreespinCount(curtimes)
    self:findChild("BitmapFontLabel_1"):setString(curtimes)
end

return DragonsFreespinGiftPackageView