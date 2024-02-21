local URLImageManager = require("views.URLImageManager")
local LottoPartyHeadManager = class("LottoPartyHeadManager")

-- ctor
function LottoPartyHeadManager:ctor()
    self.m_headInfoList = {}
end

-- get Instance --
function LottoPartyHeadManager:getInstance()
    if not self._instance then
        self._instance = LottoPartyHeadManager.new()
    end
    return self._instance
end

function LottoPartyHeadManager:addPlayerHeadInfo(_url)
    local bDownload = self:isHaveDownloadByUrl(_url)
    if not bDownload then
        table.insert(self.m_headInfoList, {url = _url})
    end
end

--判断这个图片是否在下载列表
function LottoPartyHeadManager:isHaveDownloadByUrl(_url)
    for k, v in ipairs(self.m_headInfoList) do
        if v.url == _url then
            return true
        end
    end
    return false
end
--切换房间 删除所有正在下载的
function LottoPartyHeadManager:removeAllHeadInfo()
    local m_headInfoList = self.m_headInfoList
    while #m_headInfoList > 0 do
        local downloadInfo = m_headInfoList[1]
        URLImageManager.getInstance():removeDownloadInfo(downloadInfo.url)
        table.remove(m_headInfoList,1)
    end
end

function LottoPartyHeadManager:setAvatar(headNode, _fbid, _headName, _data, _isMe, _size)
    local fbid = _fbid
    local headName = _headName
    local frameId
    if _isMe then
        frameId = globalData.userRunData.avatarFrameId
    else
        frameId = _data.frame
    end
    local headSize = _size and _size or headNode:getContentSize()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize)
    headNode:addChild(nodeAvatar)
    if _size then
        nodeAvatar:setPosition( 0, 0 )
    else
        nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )
    end
    
end


function LottoPartyHeadManager:release( )
    self.m_headInfoList = {}
end
-- Global Var --
GD.LottoPartyHeadManager = LottoPartyHeadManager:getInstance()
