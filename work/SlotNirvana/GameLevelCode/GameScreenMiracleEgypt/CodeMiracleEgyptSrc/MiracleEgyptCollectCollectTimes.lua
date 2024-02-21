--
-- 收集点击次数的view
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptCollectCollectTimes = class("MiracleEgyptCollectCollectTimes", util_require("base.BaseView"))

function MiracleEgyptCollectCollectTimes:initUI(  )

    self:createCsbNode("MiracleEgypt_tab3.csb")

    

    self.m_CollectBao = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiuCollectBao")
    self:findChild("Bao3"):addChild(self.m_CollectBao)
    self.m_CollectBao:setVisible(false)


end

function MiracleEgyptCollectCollectTimes:showAction(name,func,loop )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction(name,loop,actFunc,20)
end

function MiracleEgyptCollectCollectTimes:setLabStr( str)

    self.m_CollectBao:setVisible(true)
    self.m_CollectBao:showAction()

    self:findChild("BitmapFontLabel_1"):setString(str) 
end

return  MiracleEgyptCollectCollectTimes