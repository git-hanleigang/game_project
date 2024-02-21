--升级界面

local JackpotPushTip = class("JackpotPushTip", util_require("base.BaseView"))
JackpotPushTip.isOnShow = nil
function JackpotPushTip:initUI()
    self:createCsbNode("JackpotPushTip/JackpotPushTip.csb")
    self.m_lbs_name = self:findChild("lbs_name")
    self.m_lbs_coins = self:findChild("lbs_coins")
    self.m_headImg = self:findChild("headImg")
    self.diKuang = self:findChild("dikuang")
    self.touxiang_kuang = self:findChild("touxiang_kuang")
    self.m_size = self.diKuang:getContentSize()
    self.m_unlockIcon = self:findChild("level")
    self.m_spHead = self:findChild("face_book_head")

    self.m_unlockIcon:setScale(0.4)
end

function JackpotPushTip:setData()
    self.isOnShow = true
    if #globalData.jackpotPushList <= 0 then
        return
    end
    local data = globalData.jackpotPushList[1]
    table.remove(globalData.jackpotPushList, 1)

    self.m_lbs_name:setString(data.p_nickname)
    self.m_lbs_coins:setString(util_getFromatMoneyStr(data.p_winCoins))
    self:updateLabelSize({label = self.m_lbs_coins, sx = 1, sy = 1}, 211)
    if data.p_gameId then
        -- for i = 1, #globalData.slotRunData.p_machineDatas do
        --     if globalData.slotRunData.p_machineDatas[i].p_id == data.p_gameId then
        --         local newPath = globalData.GameConfig:getLevelIconPath(globalData.slotRunData.p_machineDatas[i].p_levelName, LEVEL_ICON_TYPE.UNLOCK)
        --         util_changeTexture(self.m_unlockIcon, newPath)
        --         break
        --     end
        -- end
        local levelInfo = globalData.slotRunData:getLevelInfoById(data.p_gameId)
        if levelInfo then
            local newPath = globalData.GameConfig:getLevelIconPath(levelInfo.p_levelName, LEVEL_ICON_TYPE.UNLOCK)
            util_changeTexture(self.m_unlockIcon, newPath)
        end
    end
    -- 用户头像
    self:initUserHead(data.p_head, data.p_facebookId, data.p_frameId)

    local layer = self:findChild("nameLayer")
    if layer then
        self.m_lbs_name:stopAllActions()
        self.m_lbs_name:setPositionX(0)
        local fntSize = self.m_lbs_name:getContentSize()
        local fntScale = self.m_lbs_name:getScale()
        local clipSize = layer:getContentSize()
        local clipScale = layer:getScale()
        if fntSize.width * fntScale <= clipSize.width * clipScale then
            self.m_lbs_name:setAnchorPoint(0.5, 0.5)
            self.m_lbs_name:setPosition(cc.p(clipSize.width * 0.5, clipSize.height * 0.5))
        else
            util_wordSwing(self.m_lbs_name, 1, layer, 1, 30, 1)
        end
    end

    self:playOpenOrCloseAnim(
        true,
        function()
            performWithDelay(
                self,
                function()
                    self:playOpenOrCloseAnim(
                        false,
                        function()
                            self:setVisible(false)
                            if self.m_clip_node then
                                self.m_clip_node:removeAllChildren()
                            end
                            self.isOnShow = false
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JACKPOT_PUSH)
                        end
                    )
                end,
                5
            )
        end
    )
end

function JackpotPushTip:playOpenOrCloseAnim(flag, callBack)
    local maxSize = self:getMaxSize()
    local bangHeight = globalData.slotRunData.isPortrait and 0 or util_getBangScreenHeight()
    self:runAction(
        cc.Sequence:create(
            cc.MoveBy:create(0.25, cc.p((maxSize.width + bangHeight) * (flag and -1 or 1), 0)),
            cc.CallFunc:create(
                function(sender)
                    if callBack ~= nil then
                        callBack()
                    end
                end
            )
        )
    )
end

function JackpotPushTip:getMaxSize()
    return self.m_size
end

-- 玩家头像
function JackpotPushTip:initUserHead(head, fbId, frameId)
    head = head or 0
    fbId = fbId or ""
    self.m_spHead:removeAllChildren() 
    self.m_spHead:setPosition(self.touxiang_kuang:getPosition())
    -- 背景
    local fbSize = self.touxiang_kuang:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, fbSize)
    self.m_spHead:addChild(nodeAvatar)
end
return JackpotPushTip
