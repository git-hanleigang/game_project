local FlowerBox = class("FlowerBox", BaseView)

function FlowerBox:initUI(_isBig)
    local path = "Flower/Activity/csd/node_Reward.csb"
    self._isBig = _isBig
    self:createCsbNode(path)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    if not globalData.slotRunData.isPortrait then
        self:setScale(1.8)
    end
    self:initView()
end

function FlowerBox:initCsbNodes()
end

function FlowerBox:initView()
    self:runCsbAction("idle",true)
    local sp1 = self:findChild("node_rewardlihe")
    local sp2 = self:findChild("node_rewardbaoxiang")
    if self._isBig then
        sp1:setVisible(false)
        sp2:setVisible(true)
    else
        sp1:setVisible(true)
        sp2:setVisible(false)
    end
end

function FlowerBox:playAnima(cb)
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("open",false,function()
                if cb then
                    cb()
                end
                self:removeFromParent()
            end)
        end
    )
end

return FlowerBox