--[[
Author: cxc
Date: 2021-01-11 19:50:02
LastEditTime: 2021-02-23 14:17:08
LastEditors: Please set LastEditors
Description: 常规促销 小游戏收集的金币 面板
FilePath: /SlotNirvana/src/views/sale/LuckyCollectCoinLayer.lua
--]]
local LuckyCollectCoinLayer = class("LuckyCollectCoinLayer", util_require("base.BaseView"))
local LuckyChooseConfig = util_require("views.sale.LuckyChooseConfig")

function LuckyCollectCoinLayer:initUI(_rewardInfo)
    _rewardInfo = _rewardInfo or {coins = 0, hit = true}

    local isAutoScale = true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale = false
    end
    local csbName = "Sale/CollectLayer.csb"
    self:createCsbNode(csbName, isAutoScale)

    self.m_btnCollect = self:findChild("btn_collect")
    self.m_bCollected = false

    -- 金币信息
    self.m_rewardCoinNum = _rewardInfo.coins
    local lbCoins = self:findChild("lb_jinbi")
    lbCoins:setString(util_formatCoins(self.m_rewardCoinNum, 20))
    local posX = lbCoins:getPositionX()
    local size = lbCoins:getContentSize()
    local nodePosX = -(posX + size.width) * 0.5
    local nodeCoins = self:findChild("node_coins")
    nodeCoins:move(cc.p(nodePosX, 0))

    self:commonShow(
        self:findChild("root"),
        function()
            performWithDelay(
                self,
                function()
                    if tolua.isnull(self) then
                        return
                    end
                    self:collectCoins()
                end,
                5
            )
            self:runCsbAction("sp_light")
        end
    )
end

function LuckyCollectCoinLayer:onKeyBack()
    self:collectCoins()
end

function LuckyCollectCoinLayer:onClickMask()
    self:collectCoins()
end

-- 统一点击回调
function LuckyCollectCoinLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_collect" then
        self:collectCoins()
    end
end

-- 收集金币
function LuckyCollectCoinLayer:collectCoins()
    if self.m_bCollected then
        return
    end
    self.m_bCollected = true
    local callFunc = function()
        self:closeUI()
    end

    local senderSize = self.m_btnCollect:getContentSize()
    local startPos = self.m_btnCollect:convertToWorldSpace(cc.p(senderSize.width / 2, senderSize.height / 2))
    gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self.m_rewardCoinNum, callFunc)
end

function LuckyCollectCoinLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    self:commonHide(
        self:findChild("root"),
        function()
            gLobalNoticManager:postNotification(LuckyChooseConfig.EVENT_NAME.NOTIFY_COLLECT_CLOSE_UI)
            self:removeFromParent()
        end
    )
end

return LuckyCollectCoinLayer
