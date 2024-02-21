--
local FortuneCatsShopData = util_require("CodeFortuneCatsShopSrc.FortuneCatsShopData")
local FortuneCatsShopCat = class("FortuneCatsShopCat", util_require("base.BaseView"))

function FortuneCatsShopCat:initUI()
    local resourceFilename = "FortuneCats_shop_cat.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("animation0", true)
end

function FortuneCatsShopCat:initMachine(machine)
    self.m_machine = machine
end

function FortuneCatsShopCat:onEnter()
end

function FortuneCatsShopCat:onExit()
end

function FortuneCatsShopCat:changeCatByIndex(_index)
    if _index == 1 then
        self:findChild("Sprite_hong"):setVisible(true)
        self:findChild("Sprite_lv"):setVisible(false)
        self:findChild("Sprite_lan"):setVisible(false)
        self:findChild("Sprite_huang"):setVisible(false)
    elseif _index == 2 then
        self:findChild("Sprite_hong"):setVisible(false)
        self:findChild("Sprite_lv"):setVisible(true)
        self:findChild("Sprite_lan"):setVisible(false)
        self:findChild("Sprite_huang"):setVisible(false)
    elseif _index == 3 then
        self:findChild("Sprite_hong"):setVisible(false)
        self:findChild("Sprite_lv"):setVisible(false)
        self:findChild("Sprite_lan"):setVisible(true)
        self:findChild("Sprite_huang"):setVisible(false)
    else
        self:findChild("Sprite_hong"):setVisible(false)
        self:findChild("Sprite_lv"):setVisible(false)
        self:findChild("Sprite_lan"):setVisible(false)
        self:findChild("Sprite_huang"):setVisible(true)
    end
    local open = FortuneCatsShopData:isPageLockAllOpenIndex(_index)
    if open then
        self:runCsbAction("idle1")
    else
        self:runCsbAction("idle2")
    end
end

function FortuneCatsShopCat:playOpenCatEffect(func)
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_cat_open.mp3")
    self:runCsbAction("animation0",false,function (  )
        if func then
            func()
        end
    end)
end

return FortuneCatsShopCat
