local shopCoinsActModular=class("shopCoinsActModular",util_require("base.BaseView"))

function shopCoinsActModular:initUI(path)

    local name = "Shop_Res/".. path .. ".csb"

    self:createCsbNode(name)

end


return shopCoinsActModular