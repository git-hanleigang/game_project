--
-- 收集字体
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgypCollectLab = class("MiracleEgypCollectLab", util_require("base.BaseView"))

function MiracleEgypCollectLab:initUI( index )

    self:createCsbNode("MiracleEgypt_tab".. index ..".csb")

end

function MiracleEgypCollectLab:setLabStr( str)
    self:findChild("BitmapFontLabel_1"):setString(str) 
end
function MiracleEgypCollectLab:removeSelf(  )
    self:removeFromParent()
end

return  MiracleEgypCollectLab