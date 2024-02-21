local InvitaQiPao = class("InvitaQiPao",BaseView)

function InvitaQiPao:ctor()
    InvitaQiPao.super.ctor(self)
    self:createCsbNode("Activity/Invitermain_MainLayer_qipao.csb")
    self:setExtendData("InvitaQiPao")
    self.config = G_GetMgr(G_REF.Invite):getConfig()
end

function InvitaQiPao:initUI()
    self:initView()
end


function InvitaQiPao:initView()
    self:runCsbAction(
        "idle",
        false,
        function()
        end,
        60
    )
    self.left_item1 = self:findChild("Node_rewards1")
    self.left_item2 = self:findChild("Node_rewards2")
end

function InvitaQiPao:updataView(_data,_type)
    local shop1 = self.left_item1:getChildByName("left_Shop1")
    if shop1 ~= nil and not tolua.isnull(shop1) then
        self.left_item1:removeChildByName("left_Shop1")
    end
    local shop2 = self.left_item2:getChildByName("left_Shop2")
    if shop2 ~= nil and not tolua.isnull(shop2) then
        self.left_item2:removeChildByName("left_Shop2")
    end
    local num = 1
    if _data ~= nil and _data[1] ~= nil then
        local shopItemUI = gLobalItemManager:createRewardNode(_data[1], ITEM_SIZE_TYPE.BATTLE_PASS)
        self.left_item2:addChild(shopItemUI)
        --if _data[1].p_id ~= nil then
            shopItemUI:setScale(0.9)
        --end
        shopItemUI:setName("left_Shop1")
    end
    if _data ~= nil and _data[2] ~= nil then
        num = 2
        local shopItemUI = gLobalItemManager:createRewardNode(_data[2], ITEM_SIZE_TYPE.BATTLE_PASS)
        self.left_item1:addChild(shopItemUI)
        --if _data[2].p_id ~= nil then
            shopItemUI:setScale(0.9)
        --end
        shopItemUI:setName("left_Shop2")
    end
    local qipqo_bg = self:findChild("sp_invitermain_qipao")
    self:setQiPaoSize(qipqo_bg,num)
end

function InvitaQiPao:setQiPaoSize(bg,num)
    if num == 1 then
        bg:setContentSize(130,134)
        self.left_item2:setPositionX(74)
    elseif num == 2 then
        bg:setContentSize(260,134)
    end
end

function InvitaQiPao:playAnima()
    self:runCsbAction(
        "start",
        false,
        function()
            performWithDelay(self, function()
                self:runCsbAction("over",false)
            end, 3)
        end
    )
end

return InvitaQiPao