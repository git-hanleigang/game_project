--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-08-09 17:34:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-08-09 17:36:55
FilePath: /SlotNirvana/src/GameModule/Card/views/NormalCardOpenNoticeLayer.lua
Description: 集卡开启宣传他那版
--]]
local NormalCardOpenNoticeLayer = class("NormalCardOpenNoticeLayer", BaseLayer)

function NormalCardOpenNoticeLayer:initDatas(_resPath, _albumData, _spinePath)
    NormalCardOpenNoticeLayer.super.initDatas(self)

    self._albumData = _albumData or {}
    self._spinePath = _spinePath
    self._closeCb = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    end
    self:setLandscapeCsbName(_resPath)
    self:setPauseSlotsEnabled(true)
end

function NormalCardOpenNoticeLayer:initView()
    NormalCardOpenNoticeLayer.super.initView(self)

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

function NormalCardOpenNoticeLayer:initSpineUI()
    NormalCardOpenNoticeLayer.super.initSpineUI(self)
    
    local parent = self:findChild("node_spine")
    if self._spinePath and util_IsFileExist(self._spinePath .. ".skel") then
        local spine = util_spineCreate(self._spinePath, true, true, 1)
        parent:addChild(spine)
        util_spinePlay(spine, "idle", true)
    end
end

function NormalCardOpenNoticeLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function NormalCardOpenNoticeLayer:clickFunc(sender)
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

return NormalCardOpenNoticeLayer