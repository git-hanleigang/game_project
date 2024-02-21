local shopLuckySpinTip=class("shopLuckySpinTip",util_require("base.BaseView"))

function shopLuckySpinTip:initUI(path)
    local name = "shop_title/superspin.csb"
    if path then
        name = path
    end
    if cc.FileUtils:getInstance():isFileExist(name) == true then
        self:createCsbNode(name)
        self:runCsbAction("idle", true, nil, 60)
    end
end


return shopLuckySpinTip