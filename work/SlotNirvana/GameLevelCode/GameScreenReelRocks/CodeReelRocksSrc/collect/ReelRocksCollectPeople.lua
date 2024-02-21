---
--xcyy
--2018年5月23日
--ReelRocksCollectPeople.lua

local ReelRocksCollectPeople = class("ReelRocksCollectPeople",util_require("base.BaseView"))


function ReelRocksCollectPeople:initUI()

    self:createCsbNode("ReelRocks_jindutiao_kuanggong.csb")

end

function ReelRocksCollectPeople:showCollect( )
    
end

function ReelRocksCollectPeople:onEnter()
 

end


function ReelRocksCollectPeople:onExit()
 
end

--默认按钮监听回调
function ReelRocksCollectPeople:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_1" then
        gLobalNoticManager:postNotification("SHOW_BONUS_Tip")
    end
end


return ReelRocksCollectPeople