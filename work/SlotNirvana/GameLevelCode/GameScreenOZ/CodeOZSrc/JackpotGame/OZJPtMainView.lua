---
--xcyy
--2018年5月23日
--OZJPtMainView.lua

local OZJPtMainView = class("OZJPtMainView",util_require("base.BaseView"))

OZJPtMainView.m_coinsList = {Major = 0 ,Minor = 0 ,Mini = 0 }
function OZJPtMainView:initUI()

    self:createCsbNode("OZ_rl_lvdiban.csb")

    self.m_coinsList = {Major = 0 ,Minor = 0 ,Mini = 0 }

    self:createDiamonds( )


    local nodeNameType =  {"Major","Minor","Mini"}
    for k,v in pairs(nodeNameType) do
        local coins = 0
        local labname = v .. "_coins" 
        local lab =  self:findChild(labname)
        if lab then
            lab:setString(util_formatCoins(coins,50) )
            self:updateLabelSize({label=lab,sx=1,sy=1},208)
        end
    end

end

function OZJPtMainView:createDiamonds( )

    local nodeType= {"Major","Minor","Mini"}
    local csbType = {"h","z","l"}
    for i=1,3 do
        
        for k=1,3 do
            local name = nodeType[i] .. "_node_" .. k
            local csbname = "OZ_tb_zuan_" .. csbType[i]
            self[name .. "_Diamond"] = util_createView("CodeOZSrc.JackpotGame.OZJPDiamonds",csbname)
            self:findChild(name):addChild(self[name .. "_Diamond"])
            self[name .. "_Diamond"]:setVisible(false)
        end

        
        
    end
end


function OZJPtMainView:onEnter()
 

end

function OZJPtMainView:showAdd()
    
end
function OZJPtMainView:onExit()
 
end

--默认按钮监听回调
function OZJPtMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return OZJPtMainView