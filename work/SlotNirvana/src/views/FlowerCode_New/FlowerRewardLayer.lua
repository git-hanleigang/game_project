-- 奖励
local FlowerRewardLayer = class("FlowerRewardLayer", BaseLayer)
-- itemList道具名字,clickFunc点击回调,flyCoins=飞金币数量,skipRotate = 横竖屏适配
function FlowerRewardLayer:initDatas(itemList, clickFunc, flyCoins, skipRotate,isBig)
    self.m_func = clickFunc
    self.m_flyCoins = flyCoins
    self.isBig = isBig

    self:setLandscapeCsbName("Flower/Activity/csd/EasterSeason_Reward_2.csb")
    self:setPortraitCsbName("Flower/Activity/csd/EasterSeason_Reward_2_shu.csb")

    self:setExtendData("FlowerRewardLayer")
end

function FlowerRewardLayer:initView(itemList)
    local rew1 = self:findChild("txt_desc")
    local rew2 = self:findChild("txt_desc2")
    local rew3 = self:findChild("txt_desc3")
    if self.isBig == 3 then
        rew2:setVisible(false)
        rew1:setVisible(false)
        rew3:setVisible(true)
    else
        rew2:setVisible(self.isBig)
        rew1:setVisible(not self.isBig)
        rew3:setVisible(false)
    end
    local node_list = self:findChild("node_list")
    if node_list then
        local node = gLobalItemManager:createRewardListView(itemList)
        node_list:addChild(node)
        local cellList = node:getCellList()
        local coinsNode = node:findCell("Coins")
        local coinsNodeList = node:findCellList("Coins")
    end
    self:runCsbAction("idle", true)
end

function FlowerRewardLayer:onKeyBack()
    self:closeUI()
end

function FlowerRewardLayer:onClickMask()
    self:closeUI()
end

function FlowerRewardLayer:clickFunc(sender)
    local btnName = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:closeUI(btnName)
end

function FlowerRewardLayer:closeUI(btnName)
    if self.close then
        return
    end
    self.close = true
    self:checkFlyCoins(
        function()
            self:commonHide(
                self:findChild("root"),
                function()
                    if self.m_func then
                        self.m_func(btnName)
                        self.m_func = nil
                    end
                    self:removeFromParent()
                end
            )
        end
    )
end
--飞金币
function FlowerRewardLayer:checkFlyCoins(func)
    if not self.m_flyCoins or self.m_flyCoins == 0 then
        func()
        return
    end
    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_flyCoins, func)
end
return FlowerRewardLayer
