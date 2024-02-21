local GoldExpressBonusResultItem = class("GoldExpressBonusResultItem", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBonusResultItem:initUI(data)

    local resourceFilename = "GoldExpress_coinswin.csb"--GoldExpress_coinswin
    if data.type == 2 then
        resourceFilename = "GoldExpress_coinswin_0.csb"
    end
    self.m_iLevel = data.levelID

    self:createCsbNode(resourceFilename)
    if data.type == 2 then
        local anim = util_createAnimation("GoldExpress_coinswin_1.csb")
        anim:playAction("actionframe",true)
        self:addChild(anim)
        self:runCsbAction("wenhao", false, function()

        end)
    end

end

function GoldExpressBonusResultItem:showCoins(list)
    local coins = 0
    for i=1,#list do
        if type(list[i]) == "number" then
            coins = coins + list[i]
        end
    end
    self.m_csbOwner["lbs_coins"]:setString(util_formatCoins(coins, 4, false, true, true))
    self:updateLabelSize({label=self.m_csbOwner["lbs_coins"],sx=1,sy=1},262)

    -- self:runCsbAction("unselect", false)
end

function GoldExpressBonusResultItem:showExtra(list)

    local isHave = false
    for i=1,#list do
        if type(list[i]) ~= "number" then
            isHave = true
            break
        end
    end
    if isHave then
        self:runCsbAction("txt"..self.m_iLevel)
        -- local extraGame = util_createView("CodeGoldExpressSrc.GoldExpressBonusExtraGamesChoose")
        -- self:addChild(extraGame)
        -- extraGame:selected(self.m_iLevel)
        -- self:runCsbAction("idleframe", false)
    end
end

function GoldExpressBonusResultItem:showOverExtra(list)
    local isHave = false
    for i=1,#list do
        if type(list[i]) ~= "number" then
            isHave = true
            break
        end
    end
    if not isHave then
        self:runCsbAction("txt"..self.m_iLevel.."hui")
    end
end
function GoldExpressBonusResultItem:onEnter()

end

function GoldExpressBonusResultItem:onExit()

end

function GoldExpressBonusResultItem:setClickFlag(flag)
    self.m_clickFlag = flag
end

return GoldExpressBonusResultItem