--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-30 17:15:33
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-30 17:15:38
FilePath: /SlotNirvana/src/GameModule/MachineGrandShare/net/MachineGrandShareNet.lua
Description: 关卡中大奖分享 net
--]]
local NetWorkBase = require("network.NetWorkBase")
local HttpFormData = require("GameModule.MachineGrandShare.model.HttpFormData")
local MachineGrandShareConfig = require("GameModule.MachineGrandShare.config.MachineGrandShareConfig")
local MachineGrandShareNet = class("MachineGrandShareNet", NetWorkBase)

-- 上传分享图片
function MachineGrandShareNet:uploadImgToServerReq(_imgData, _filePath, _succcessCB)
    local formData = HttpFormData:create()
    formData:append("file", _imgData, _filePath)

    local xmlRequest = cc.XMLHttpRequest:new()
    xmlRequest.timeout = 30
    xmlRequest.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    xmlRequest:setRequestHeader("Content-Type", self:getContentType(formData:getBoundary()))
    xmlRequest:setRequestHeader("Token", globalData.userRunData.loginUserData.token)
    xmlRequest:setRequestHeader("Timestamp", globalData.userRunData.p_serverTime) 
    xmlRequest:setRequestHeader("Sign", self:getSign())
    xmlRequest:setRequestHeader("Offset", self:getOffsetValue())
    xmlRequest:open("POST", self:getUploadUrl())
    local function httpCallBack()
        local responseCode = xmlRequest.status
        local responseData = xmlRequest.response
        if xmlRequest.readyState == 4 and responseCode == 200 then
            print("cxc---MachineGrandShareNet-success", responseData)
            if _succcessCB then
                _succcessCB()
            end
        else
            print("cxc---MachineGrandShareNet-faild", responseCode, responseCode)
        end
        xmlRequest:unregisterScriptHandler()
    end
    xmlRequest:registerScriptHandler(httpCallBack)
    xmlRequest:send(formData:getSendBody())
end

-- 下载url 分享图片
function MachineGrandShareNet:downloadImgFromServerReq(_url, _cb)
    local xmlRequest = cc.XMLHttpRequest:new()
    xmlRequest.timeout = 30
    xmlRequest:open("GET", _url)
    local function httpCallBack()
        local responseCode = xmlRequest.status
        local responseData = xmlRequest.response
        if xmlRequest.readyState == 4 and responseCode == 200 and responseData then
            local path = MachineGrandShareConfig.IMG_DIRECTORY .. "/" .. xcyy.SlotsUtil:md5(_url)
            cc.FileUtils:getInstance():writeStringToFile(responseData, path)
        else
            print("cxc---MachineGrandShareNet-faild", responseCode, responseCode)
        end
   
        if _cb then
            _cb(xcyy.SlotsUtil:md5(_url))
        end
        xmlRequest:unregisterScriptHandler()
    end
    xmlRequest:registerScriptHandler(httpCallBack)
    xmlRequest:send()
end

-- 获取 请求签名
function MachineGrandShareNet:getSign()
    local token = globalData.userRunData.loginUserData.token
    local saltKey = "xcyyupLTPnuRTEdK"
    local time = globalData.userRunData.p_serverTime
    local str = string.format("%s&%s&%s",token, saltKey, time)
    return xcyy.SlotsUtil:md5(str)
end

-- 获取 contentType
function MachineGrandShareNet:getContentType(_boundary)
    return "multipart/form-data; boundary=" .. _boundary 
end

-- 获取图片上传url
function MachineGrandShareNet:getUploadUrl()
    return DATA_SEND_URL .. RUI_INFO.SLOT_GRAND_SHARE -- 拼接url 地址
end
return MachineGrandShareNet