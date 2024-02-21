--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-03 17:15:38
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-03 17:52:08
FilePath: /SlotNirvana/src/GameModule/MachineGrandShare/views/GrandShareImgSprite.lua
Description: 关卡中大奖分享 图片 img
--]]
local GrandShareImgSprite = class("GrandShareImgSprite", cc.Sprite)
local MachineGrandShareConfig = require("GameModule.MachineGrandShare.config.MachineGrandShareConfig")

function GrandShareImgSprite:setUrl(_url, _showSize, _defaultPath, _bImageFull)
    if not _url then
        return
    end

    self._showSize = _showSize
    self._imgName = xcyy.SlotsUtil:md5(_url)
    self.m_bImageFull = _bImageFull
    local bSuccess = self:updateSpTexture()
    if not bSuccess then
        self:updateSpTexture(_defaultPath)
        self:downloadUrlImg(self._imgName)
    end
    self.m_bLoadUrlImgSuccess = bSuccess
end

function GrandShareImgSprite:updateSpTexture(_path)
    local path = _path or MachineGrandShareConfig.IMG_DIRECTORY .. "/" .. self._imgName
    local bSuccess = util_changeTexture(self, path)

    if self._showSize then
        local size = self:getContentSize()
        local scaleW =  self._showSize.width / size.width
        local scaleH = self._showSize.height / size.height
        local scale = size.height > size.width and scaleH or scaleW
        if self.m_bImageFull then
            scale = size.height > size.width and scaleW or scaleH
        end
        self:setScale(scale)
    end

    return bSuccess
end

function GrandShareImgSprite:downloadUrlImg(_imgName)
    gLobalNoticManager:addObserver(self,function(self,data)
        self.m_bLoadUrlImgSuccess = self:updateSpTexture()
        gLobalNoticManager:removeObserver(self, MachineGrandShareConfig.EVENT_NAME.DOWNLOAD_IMG_SUCCESS .. _imgName)
    end, MachineGrandShareConfig.EVENT_NAME.DOWNLOAD_IMG_SUCCESS .. _imgName)
    G_GetMgr(G_REF.MachineGrandShare):downloadImgFromServerReq()
end

function GrandShareImgSprite:checkLoadUrlImgSuccess()
    return self.m_bLoadUrlImgSuccess
end

return GrandShareImgSprite