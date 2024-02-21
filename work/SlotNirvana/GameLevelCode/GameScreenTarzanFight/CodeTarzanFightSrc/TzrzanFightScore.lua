--
-- 泰山小信号分数
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local TzrzanFightScore = class("TzrzanFightScore", util_require("base.BaseView"))
local actionname = {"show","end","idel"}

function TzrzanFightScore:initUI(  )
    self:createCsbNode("Socre_TarzanFight_shuzi.csb")

    for i=1,4 do
        self:findChild("node_"..i):setVisible(false)
        self:findChild("txt_"..i):setVisible(false)
        self:findChild("txt_"..i.."_0"):setVisible(false)
        self:findChild("lab_"..i):setVisible(false)
        
    end
    
end

function TzrzanFightScore:playShowAction(name,isloop,func )
    self:runCsbAction(name,isloop,func)
end

function TzrzanFightScore:showOneTxtImg( index )
    for i=1,4 do
        if index == i then
            
            self:findChild("node_"..i):setVisible(true)
            self:findChild("txt_"..i):setVisible(true)
            self:findChild("txt_"..i.."_0"):setVisible(true)
            self:findChild("lab_"..i):setVisible(true)
        end
    end
end


function TzrzanFightScore:setOneTxtScore( index,num )
    for i=1,4 do
        if index == i then
            self:findChild("node_"..i):setVisible(true)
            self:findChild("txt_"..i):setVisible(true)
            self:findChild("txt_"..i):setString(num)
            self:findChild("txt_"..i.."_0"):setVisible(true)
            self:findChild("txt_"..i.."_0"):setString(num)
        end
    end
end


return  TzrzanFightScore