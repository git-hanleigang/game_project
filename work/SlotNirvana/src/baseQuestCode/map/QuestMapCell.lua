--quest背景贴图
local QuestMapCell = class("QuestMapCell", util_require("base.BaseView"))
QuestMapCell.m_info = nil
QuestMapCell.m_content = nil
function QuestMapCell:ctor(info)
    self.m_info = info
end

--是否可以显示父类移动坐标 和偏移量
function QuestMapCell:isDisPlayContent(moveX,offX)
    local pos = cc.p(self:getPosition())
    local contentLen = self.m_info[2] 
    if moveX+pos.x+contentLen >= -offX and moveX+pos.x<= display.width+offX then
        return true
    end
    return false
end

--显示贴图 isSync 是否异步加载
function QuestMapCell:showContent(isSync)
    if self.m_content then
        return
    end

    if isSync then
        display.loadImage(self.m_info[1], function()
            if self.createContent then
                self:createContent()
            end
        end)
    else
        self:createContent()
    end
end

function QuestMapCell:createContent()
    self.m_content =  util_createSprite(self.m_info[1])
    self:addChild(self.m_content)
    self.m_content:setAnchorPoint(cc.p(0, 0.5))
end

--隐藏贴图
function QuestMapCell:hideContent()
    -- if self.m_content then
    --     self.m_content:removeFromParent()
    --     self.m_content = nil
    --     self:clearCache()
    -- end
end

--清理图片缓存
function QuestMapCell:clearCache()
    performWithDelay(self,function()
        if self.m_content == nil then
            local fullpath = cc.FileUtils:getInstance():fullPathForFilename(self.m_info[1])
            display.removeImage(fullpath)
        end
    end,0.1)
end

return QuestMapCell
