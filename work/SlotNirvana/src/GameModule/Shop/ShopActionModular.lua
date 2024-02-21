local ShopActionModular=class("ShopActionModular",util_require("base.BaseView"))


function ShopActionModular:initUI(csbpath)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end
    if util_IsFileExist(csbpath) then
        self:createCsbNode(csbpath,isAutoScale)
    end
end

function ShopActionModular:onEnter()

end

function ShopActionModular:onExit()
  
end


function ShopActionModular:getLefttxt()
    local lab_left_time = self:findChild("lab_left_time")
    local time_left = self:findChild("time_left")

    return lab_left_time,time_left
end

return ShopActionModular