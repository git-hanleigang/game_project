--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-09-02 16:45:25
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-09-02 17:10:12
FilePath: /SlotNirvana/src/GameModule/MachineGrandShare/model/HttpFormData.lua
Description: http 表单数据
--]]
local HttpFormData = class("HttpFormData")

function HttpFormData:ctor(_boundaryKey)
    self.m_boundaryKey = "xcyy" .. os.time()
    self._bodyStrList = {}
    self._boundary = "--" .. self.m_boundaryKey

    self.m_sendBodyStr = ""
end

function HttpFormData:append(_key, _value, _filePath)
    if _filePath then
        self:_appendFile(_key, _value, _filePath)
        return
    end
    
    self:_appendText(_key, _value)
end

function HttpFormData:_appendText(_key, _value)
    local tb = {
        self._boundary .. '\r\n',
        'Content-Disposition: form-data; name="' .. _key .. '"\r\n',
        'Content-Type: text/plain',
        '\r\n\r\n',
        _value,
        '\r\n'
    }
    local bodyStr = table.concat(tb)
    table.insert(self._bodyStrList, bodyStr)
end

-- contentType https://www.runoob.com/http/http-content-type.html
function HttpFormData:_appendFile(_key, _fileData, _filePath)
    local fileName = string.match(_filePath, "([%w-_]+)%.")
    local fileEx = string.match(_filePath, "%.(%w+)")
    if not fileEx or not fileName then
        print("cxc-- filepath invaild--" .. _filePath)
        release_print("cxc-- filepath invaild--" ..  _filePath)
        return
    end

    local fileNameWEx = fileName .. '.' .. fileEx
    local contentType = "image/png"
    if fileEx == "jpg" or fileEx == "jpeg" then
        contentType = "image/jpeg"
    end
    local fileData = _fileData
    if not fileData then
        fileData = cc.FileUtils:getInstance():getDataFromFile(_filePath)
    end
    if not fileData or fileData == _filePath then
        print("cxc-- file not exit or content empty--" .. _filePath)
        release_print("cxc-- file not exit or content empty--" .. _filePath)
        return
    end

    local tb = {
        self._boundary .. '\r\n',
        'Content-Disposition: form-data; name="' .. _key .. '"; filename="' .. fileNameWEx .. '"\r\n',
        'Content-Type: ' .. contentType,
        '\r\n\r\n',
        fileData,
        '\r\n'
    }
    local bodyStr = table.concat(tb)
    table.insert(self._bodyStrList, bodyStr) 
end

-- 获取 boundary requestHeader里用
function HttpFormData:getBoundary()
    return self.m_boundaryKey 
end

-- 获取 http send 的body
function HttpFormData:getSendBody()
    local tb = {
        table.concat(self._bodyStrList),
        self._boundary .. "--",
        '\r\n'
    }

    local sendBody = table.concat(tb)
    return sendBody
end

return HttpFormData