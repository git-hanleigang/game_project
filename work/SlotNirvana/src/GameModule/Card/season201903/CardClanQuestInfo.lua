local BaseView = util_require("base.BaseView")
local CardClanQuestInfo = class("CardClanQuestInfo", BaseView)
function CardClanQuestInfo:initUI(clanIndex, index)
    local isAutoScale      =  true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale        =  false
    end
    self:createCsbNode( self:getCsbName() , isAutoScale )
    local root = self:findChild("root")
    if root then
        self:commonShow(root)
    else
        local maskUI = util_newMaskLayer()
        self:addChild(maskUI,-1)
        maskUI:setOpacity(192)
    end
end

-- 子类重写
function CardClanQuestInfo:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanQuestRes, "season201903")
end

function CardClanQuestInfo:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_x" then
        self:closeUI()
    end
end

function CardClanQuestInfo:closeUI()
    if self.m_closed then
        return 
    end
    self.m_closed = true
    local root = self:findChild("root")
    if root then
        self:commonHide(root,function()
            self:removeFromParent()
        end)
    else
        self:removeFromParent()
    end
end

return CardClanQuestInfo