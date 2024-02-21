---
--xcyy
--2018年5月23日
--CatandMouseGuoChangView.lua

local CatandMouseGuoChangView = class("CatandMouseGuoChangView",util_require("Levels.BaseLevelDialog"))


function CatandMouseGuoChangView:initUI(kind)
    
    self:createCsbNode("CatandMouse_bonus_guochang.csb")
    if kind == nil then
        kind = "CAT"
    end
    self.kind = kind
    self.renWu = nil
    
    self:addSpineToView(kind)

end

function CatandMouseGuoChangView:addSpineToView(kind)
    if kind == "MOUSE" then
        self.renWu = util_spineCreate("CatandMouse_juese_laoshu",true,true)
        self:findChild("Node_laoshu"):addChild(self.renWu)
    elseif kind == "CAT" then
        self.renWu = util_spineCreate("CatandMouse_juese_mao",true,true)
        self:findChild("Node_mao"):addChild(self.renWu)
    end
end

function CatandMouseGuoChangView:showGuochang(func1)
    util_spinePlay(self.renWu,"idleframe1",true)
    if self.kind == "MOUSE" then
        self:runCsbAction("actionframe",false,function (  )
            self:removeFromParent()
            if func1 then
                func1()
            end
        end)
    elseif self.kind == "CAT" then
        self:runCsbAction("actionframe1",false,function (  )
            self:removeFromParent()
            if func1 then
                func1()
            end
        end)
    end
    
end

return CatandMouseGuoChangView