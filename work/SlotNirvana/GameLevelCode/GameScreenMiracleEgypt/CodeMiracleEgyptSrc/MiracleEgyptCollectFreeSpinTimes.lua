--
-- 收集FreeSpin次数的view
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptCollectFreeSpinTimes = class("MiracleEgyptCollectFreeSpinTimes", util_require("base.BaseView"))

function MiracleEgyptCollectFreeSpinTimes:initUI(  )

    self:createCsbNode("MiracleEgypt_tab4.csb")

    self.m_CollectBao = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiuCollectBao")
    self:findChild("Bao4"):addChild(self.m_CollectBao)
    self.m_CollectBao:setVisible(false)

end

function MiracleEgyptCollectFreeSpinTimes:showAction(name,func,loop )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction(name,loop,actFunc,20)
end

function MiracleEgyptCollectFreeSpinTimes:setLabStr( str)
    self.m_CollectBao:setVisible(true)
    self.m_CollectBao:showAction()
    
    self:findChild("BitmapFontLabel_1"):setString(str) 
end

return  MiracleEgyptCollectFreeSpinTimes