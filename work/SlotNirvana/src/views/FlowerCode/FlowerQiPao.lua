local FlowerQiPao = class("FlowerQiPao", BaseView)
local ITEM_TYPE = {
    SLVER_ITEM = 1,
    GOLD_ITEM = 2
}
function FlowerQiPao:initUI(_type)
    local path = "Activity/csd/EasterSeason_mainUI/Node_reward.csb"
    self._type = _type
    self:createCsbNode(path)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:initView()
end

function FlowerQiPao:initCsbNodes()
    self.node_reward1 = self:findChild("node_reward1")
    self.node_reward2 = self:findChild("node_reward2")
end

function FlowerQiPao:initView()
    local reward1 = self:findChild("node_reward1")
    local reward2 = self:findChild("node_reward2")
    if self._type == ITEM_TYPE.SLVER_ITEM then
        self:updataUI(self.m_data:getSilverBigReward())
    else
        self:updataUI(self.m_data:getGoldBigReward())
    end
    self.status = true
end

function FlowerQiPao:updataUI(shop_items)
    local width,jiange,scal = self:getBgSize(shop_items)
    local bg = self:findChild("sp_qipao")
    bg:setContentSize(cc.size(width,176))
    local pos_X = jiange - width/2 + 40
    for i=1,4 do
        local node = self:findChild("node_reward"..i)
        local str = "shopItemUI_rew"..i
        if node:getChildByName(str) ~= nil and not tolua.isnull(node:getChildByName(str)) then
            node:removeChildByName(str)
        end
        if shop_items[i] then
            local shopItemUI = gLobalItemManager:createRewardNode(shop_items[i], ITEM_SIZE_TYPE.BATTLE_PASS)
            node:addChild(shopItemUI)
            shopItemUI:setName(str)
        end
        node:setScale(scal)
        local pos = pos_X + (i-1)*(80+jiange)*scal
        node:setPositionX(pos)
    end
end

function FlowerQiPao:getBgSize(items)
    local num = #items
    local scal = 1
    if num == 3 then
        scal = 0.8
    elseif num == 4 then
        scal = 0.7
    end
    local jiange = 40*scal
    local width = (num + 1)*jiange + 80*num*scal
    return width,jiange,scal
end

function FlowerQiPao:showAction()
    if self.status then
        self.status = false
        self:runCsbAction(
            "start",
            false,
            function()
                performWithDelay(
                    self,
                    function()
                        self:runCsbAction("end",false,function()
                            self.status = true
                        end)
                    end,
                    1
                )
            end
        )
    end 
end

function FlowerQiPao:showEnd()
    self:runCsbAction("end",false,function()
        self:removeFromParent()
    end)
end

function FlowerQiPao:getStatus()
    return self.status
end

return FlowerQiPao