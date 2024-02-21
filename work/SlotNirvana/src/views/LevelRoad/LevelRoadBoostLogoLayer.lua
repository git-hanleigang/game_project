--[[
    等级里程碑 商场膨胀界面
]]
local LevelRoadBoostLogoLayer = class("LevelRoadBoostLogoLayer", BaseLayer)

function LevelRoadBoostLogoLayer:initDatas()
    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_Boost_logo_layer.csb")
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    self:setExtendData("LevelRoadBoostLogoLayer")
end

function LevelRoadBoostLogoLayer:onEnter()
    LevelRoadBoostLogoLayer.super.onEnter(self)
    self:setVisible(false)
end

function LevelRoadBoostLogoLayer:playStartAction(_over)
    self.m_over = _over
    self:setVisible(true)
    self:setShowBgOpacity(192)
    self:runCsbAction(
        "start",
        false,
        function()
            self:closeUI()
        end,
        60
    )
end

function LevelRoadBoostLogoLayer:closeUI()
    local callback = function()
        if self.m_over then
            self.m_over()
        end
        -- 发送刷新金币事件
        gLobalNoticManager:postNotification("ShopCarnival")
    end
    LevelRoadBoostLogoLayer.super.closeUI(self, callback)
end

return LevelRoadBoostLogoLayer
