local shopFlashModular=class("shopFlashModular",util_require("base.BaseView"))

function shopFlashModular:initUI(path)

    local name = "Shop_Res/".. path .. ".csb"

    self:createCsbNode(name)

end


return shopFlashModular