--
-- 泰山小信号分数
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local FireDragonScore = class("FireDragonScore", util_require("base.BaseView"))
local actionname = {"show","end","idel"}

function FireDragonScore:initUI(  )
    self:createCsbNode("Socre_FireDragon_shuzi.csb")

    for i=1,4 do
        self:findChild("node_"..i):setVisible(false)
        self:findChild("txt_"..i):setVisible(false)
        self:findChild("txt_"..i.."_0"):setVisible(false)
        -- self:findChild("lab_"..i):setVisible(false)
        
    end
    
end

function FireDragonScore:playShowAction(name,isloop,func )
    self:runCsbAction(name,isloop,func)
end

function FireDragonScore:showOneTxtImg( index )
    for i=1,4 do
        if index == i then
            
            self:findChild("node_"..i):setVisible(true)
            self:findChild("txt_"..i):setVisible(true)
            self:findChild("txt_"..i.."_0"):setVisible(true)
            -- self:findChild("lab_"..i):setVisible(true)
        end
    end
end

function FireDragonScore:setOneTxtScore( index,num )
    for i=1,4 do
        if index == i then
            self:findChild("node_"..i):setVisible(true)
            self:findChild("txt_"..i):setVisible(true)
            self:findChild("txt_"..i):setString(util_formatCoins(num, 20))
            self:findChild("txt_"..i.."_0"):setVisible(true)
            self:findChild("txt_"..i.."_0"):setString(util_formatCoins(num, 20))
        end
    end
end


return  FireDragonScore