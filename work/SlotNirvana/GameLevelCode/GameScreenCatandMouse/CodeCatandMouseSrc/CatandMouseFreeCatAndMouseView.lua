---
--xcyy
--2018年5月23日
--CatandMouseFreeCatAndMouseView.lua

local CatandMouseFreeCatAndMouseView = class("CatandMouseFreeCatAndMouseView",util_require("Levels.BaseLevelDialog"))


function CatandMouseFreeCatAndMouseView:initUI(kind)

    local path = "CatandMouse_bonusrenwu_0.csb"
    if kind == "MOUSE" then
        path = "CatandMouse_bonusrenwu.csb"
    end
    self:createCsbNode(path)

    self.kind = kind
    self.upPeople = nil
    self.downPeople = nil
    
    self:addSpineToView(kind)
end

function CatandMouseFreeCatAndMouseView:getSpinePosition(col)
    if col == 1 or col == 2 then
        self:findChild("Node_mao_0"):setVisible(true)
        self:findChild("Node_mao_0"):addChild(self.downPeople)
        self:findChild("Node_mao"):setVisible(false)
    elseif col == 3 or col == 4 or col == 5 then
        self:findChild("Node_mao"):setVisible(true)
        self:findChild("Node_mao"):addChild(self.downPeople)
        self:findChild("Node_mao_0"):setVisible(false)
    end
end

function CatandMouseFreeCatAndMouseView:addSpineToView(kind)
    if kind == "MOUSE" then
        self.upPeople = util_spineCreate("CatandMouse_bonusrenwu_laoshu",true,true)
        self.downPeople = util_spineCreate("CatandMouse_Bonus_laoshu",true,true)
        self:findChild("Node_up"):addChild(self.upPeople)
        self:findChild("Node_laoshu"):addChild(self.downPeople)
    else
        self.upPeople = util_spineCreate("CatandMouse_juese_mao",true,true)
        self.downPeople = util_spineCreate("CatandMouse_juese_18",true,true)
        self:findChild("Node_up"):addChild(self.upPeople)
    end
end

--展示屏幕上显示的猫或者老鼠
function CatandMouseFreeCatAndMouseView:showSpineAct(func)
    self:runCsbAction("actionframe",false,function (  )
        self:runCsbAction("idleframe",true)
    end)
    util_spinePlay(self.downPeople,"actionframe1")
    util_spinePlay(self.upPeople,"actionframe4")
    util_spineEndCallFunc(self.upPeople,"actionframe4",function (  )
        util_spinePlay(self.upPeople,"idleframe4",true)
        if func then
            func()
        end
    end)
end

function CatandMouseFreeCatAndMouseView:showChangeWildSpine(func)
    util_spinePlay(self.downPeople,"actionframe2")
    self:runCsbAction("actionframe1",false)
    performWithDelay(self,function (  )
        if func then
            func()
        end
    end,0.7)
end

function CatandMouseFreeCatAndMouseView:showOverSpin( )
    self:runCsbAction("over",false,function (  )
        self:removeFromParent()
    end)
end


return CatandMouseFreeCatAndMouseView