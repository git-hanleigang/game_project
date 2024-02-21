local GoldExpressBonusGameItem = class("GoldExpressBonusGameItem", util_require("base.BaseView"))
-- 构造函数
GoldExpressBonusGameItem.m_bSelected = nil
function GoldExpressBonusGameItem:initUI(data)
    self.m_type = data.type
    self.m_iLevel = data.levelID
    local resourceFilename = "Bonus_GoldExpress_"..self.m_type..".csb"
    self:createCsbNode(resourceFilename)
    self.m_clickFlag = false
    self:addClick(self:findChild("click"))
end

function GoldExpressBonusGameItem:idle()
    self:runCsbAction("actionframe", true)
end

function GoldExpressBonusGameItem:click(coin, callback, func)
    -- gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_bonusgame_choose.mp3")
    self.m_bSelected = true
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setString("")
        local extraGame = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesChoose")
        self.m_csbOwner["Node_2"]:addChild(extraGame)
        extraGame:animation(self.m_iLevel)
    end
    self:runCsbAction("click", false, function()
        -- self:runCsbAction("idleframe1", true)
        if callback ~= nil then
            callback()
        end
    end)
end

function GoldExpressBonusGameItem:unclick(coin)
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setString("")
        local extraGame = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesChoose")
        extraGame:unselected(self.m_iLevel)
        self.m_csbOwner["Node_2"]:addChild(extraGame)
    end
    self:runCsbAction("unselect", false)
end

function GoldExpressBonusGameItem:showSelected(coin)
    self.m_bSelected = true
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setString("")
        local extraGame = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesChoose")
        self.m_csbOwner["Node_2"]:addChild(extraGame)
        extraGame:selected(self.m_iLevel)
    end
    self:runCsbAction("idleframe1", false)
end

function GoldExpressBonusGameItem:unselected(coin)
    self.m_csbOwner["font_shu"]:setString(util_formatCoins(coin, 3, false, true, true))
    if coin == 0 then
        self.m_csbOwner["font_shu"]:setVisible(false)
        local extraGame = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesChoose")
        extraGame:unselected(self.m_iLevel)
        self.m_csbOwner["Node_2"]:addChild(extraGame)
    end
    self:runCsbAction("unselect", false)
end

function GoldExpressBonusGameItem:canNotClick()
    self:runCsbAction("Dark", false)
end

function GoldExpressBonusGameItem:setClickFunc(func)
    self.m_clickFunc = func
end

--默认按钮监听回调
function GoldExpressBonusGameItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_clickFunc ~= nil then
        self.m_clickFunc()
    end
end

function GoldExpressBonusGameItem:getIsSelected()
    return self.m_bSelected
end

function GoldExpressBonusGameItem:onEnter()

end

function GoldExpressBonusGameItem:onExit()

end

function GoldExpressBonusGameItem:setClickFlag(flag)
    self.m_clickFlag = flag
end

return GoldExpressBonusGameItem