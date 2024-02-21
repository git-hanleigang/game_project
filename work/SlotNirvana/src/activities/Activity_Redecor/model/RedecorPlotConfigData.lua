--[[
    剧情配置类
    剧情所有对话  【讲话人和听话人[//0不显示人物，其余对应csb序号] 位置[//L R]】
        讲话人a-讲话人位置-听话人b|文字id1-文字id2-...
        讲话人b-讲话人位置-听话人a|文字id1-文字id2-...
        讲话人a-讲话人位置-听话人b|文字id1-文字id2-...
        ...
        ...
    触发类型 [//1完成节点 2完成章节 3引导]`
    能否跳过 [//1可跳过2不可]    
]]
local RedecorPlotConfigData = class("RedecorPlotConfigData")
function RedecorPlotConfigData:parseData(_netData)
    self.p_plotId = tonumber(_netData[2])
    self.p_content = _netData[3]
    self.p_skip = tonumber(_netData[4])
    self.p_triggerType = tonumber(_netData[5])
    self.p_triggerDetail = tonumber(_netData[6])

    self:splitContent()
end

function RedecorPlotConfigData:getPlotId()
    return self.p_plotId
end
function RedecorPlotConfigData:getNodeId()
    return self.p_nodeId
end
function RedecorPlotConfigData:getContent()
    return self.p_content
end

function RedecorPlotConfigData:getSkip()
    return self.p_skip
end
function RedecorPlotConfigData:getTriggerType()
    return self.p_triggerType
end
function RedecorPlotConfigData:getTriggerDetail()
    return self.p_triggerDetail
end

function RedecorPlotConfigData:isShowSkip()
    if self.p_skip == 1 then
        return true
    elseif self.p_skip == 2 then
    end
    return false
end

function RedecorPlotConfigData:splitContent()
    -- self.m_dialogCount = 0
    self.m_dialogs = {}
    local dialogList = string.split(self.p_content, "&")
    if dialogList and #dialogList > 0 then
        for i = 1, #dialogList do
            local dl = string.split(dialogList[i], "|")
            if dl and #dl == 2 then
                local _dialog = {}
                local roles = string.split(dl[1], "-")
                _dialog.wordIds = string.split(dl[2], "-")
                -- self.m_dialogCount = self.m_dialogCount + #_dialog.wordIds
                if roles and #roles == 3 then
                    _dialog.speakerId = tonumber(roles[1])
                    _dialog.speakerPos = roles[2]
                    _dialog.listenerId = tonumber(roles[3])
                else
                    assert(false, string.format("!!!ERROR[MAQUN]: %s content is error form, roles is not 3", self.p_plotId))
                end
                table.insert(self.m_dialogs, _dialog)
            else
                assert(false, string.format("!!!ERROR[MAQUN]: %s content is error form, dialog is not 2", self.p_plotId))
            end
        end
    end
end

function RedecorPlotConfigData:getDialogs()
    return self.m_dialogs
end

return RedecorPlotConfigData
