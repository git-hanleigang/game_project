local UserInfoBagItemCell = require("views.UserInfo.view.UserInfoBagItemCell")
local UserInfoBagItemCell_Buck = class("UserInfoBagItemCell_Buck", UserInfoBagItemCell)

function UserInfoBagItemCell_Buck:getCsbName()
    return "Activity/csd/Information_BackBag/Information_reward_buck.csb"
end

function UserInfoBagItemCell_Buck:initView()
    UserInfoBagItemCell_Buck.super.initView(self)
    -- 放在icon上的说明文案
    self.m_lbTxt2 = self:findChild("txt_reward2")
end

-- 没有小红点
function UserInfoBagItemCell_Buck:updateRedPoint()
end

function UserInfoBagItemCell_Buck:updataCell(_data)
    UserInfoBagItemCell_Buck.super.updataCell(self, _data)
    self:updateBucks()
end

function UserInfoBagItemCell_Buck:updateBucks()
    -- local num = self.item_data.num or 0
    local buckNum = G_GetMgr(G_REF.ShopBuck):getBuckNum()
    self.m_lbTxt2:setString(util_cutCoins(buckNum, true, 2))
    self:updateLabelSize({label=self.m_lbTxt2,sx=1,sy=1}, 125)
end

function UserInfoBagItemCell_Buck:clickInfo()
    G_GetMgr(G_REF.ShopBuck):showConfirmInfoLayer()
end

function UserInfoBagItemCell_Buck:onEnter()
    UserInfoBagItemCell_Buck.super.onEnter(self)


    -- 购买代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateBucks()
        end,
        ViewEventType.NOTIFY_PURCHASE_BUCK_SUCCESS
    )    
    -- 花费代币
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.isConsumeBuck then
                self:updateBucks()
            end
        end,
        ViewEventType.NOTIFY_PURCHASE_SUCCESS
    )
end

return UserInfoBagItemCell_Buck