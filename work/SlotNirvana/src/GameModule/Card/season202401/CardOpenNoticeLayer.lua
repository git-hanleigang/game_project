--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-19 16:04:42
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-19 16:06:32
FilePath: /SlotNirvana/src/GameModule/Card/season202401/CardOpenNoticeLayer.lua
Description: 202401赛季 集卡开启宣传他那版
--]]
local CardOpenNoticeLayer = class("CardOpenNoticeLayer", BaseLayer)

function CardOpenNoticeLayer:initDatas(_resPath, _albumData, _spinePath)
    CardOpenNoticeLayer.super.initDatas(self)

    self._albumData = _albumData or {}
    self._spinePath = _spinePath
    self._closeCb = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    end
    self:setLandscapeCsbName(_resPath)
    self:setPauseSlotsEnabled(true)
end

function CardOpenNoticeLayer:initCsbNodes()
    self.m_btnClose = self:findChild("Button_close")
    self.m_nodeClose = self:findChild("node_close")

    self.m_btnSeeMore = self:findChild("Button_seemore")
    self.m_nodeSeeMore = self:findChild("node_seemore")

    self.m_nodeCoin= self:findChild("node_coin")
end

function CardOpenNoticeLayer:initView()
    CardOpenNoticeLayer.super.initView(self)

    -- 领取金币
    local lbCoins = self:findChild("lb_coins")
    local coins = 0
    if self._albumData.coins then
        coins = tonumber(self._albumData.coins)
    end
    lbCoins:setString(util_formatCoins(coins, 12))
    util_alignCenter({
        {node = self:findChild("sp_coins")},
        {node = lbCoins}
    })

    -- 按钮文本
    self:setButtonLabelContent("Button_seemore", "ENJOY NOW!")
end

function CardOpenNoticeLayer:initSpineUI()
    CardOpenNoticeLayer.super.initSpineUI(self)
    
    local parent = self:findChild("node_spine")
    if self._spinePath and util_IsFileExist(self._spinePath .. ".skel") then
        local spine = util_spineCreate(self._spinePath, true, true, 1)
        parent:addChild(spine)
        self._spine = spine
        self:spineBindNode()
    end
end

function CardOpenNoticeLayer:spineBindNode()
    util_spinePushBindNode(self._spine, "Button_close", self.m_nodeClose)
    util_spinePushBindNode(self._spine, "node_seemore", self.m_nodeSeeMore)
    util_spinePushBindNode(self._spine, "node_coin", self.m_nodeCoin)
end

function CardOpenNoticeLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")

    if self._spine then
        util_spinePlay(self._spine, "start")
        util_spineEndCallFunc(self._spine, "start", function()
            util_spinePlay(self._spine, "idle", true)
        end)
    end
    CardOpenNoticeLayer.super.playShowAction(self, "start")
end

function CardOpenNoticeLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function CardOpenNoticeLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_close" then
        self:closeUI(self._closeCb)
    elseif name == "Button_seemore" then
        self:closeUI(
            function()
                if CardSysManager:isDownLoadCardRes() then
                    CardSysManager:pushExitCallList(self._closeCb)
                    CardSysManager:enterCardCollectionSys()
                else
                    self._closeCb()
                end
            end
        )
    end
end

return CardOpenNoticeLayer