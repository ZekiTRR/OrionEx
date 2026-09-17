
local httpService = game:GetService("HttpService")
local client = WebsocketClient.new('ws://127.0.0.1:1818')
local futures = {}

client.DataReceived:Connect(function(payload)
  local object = httpService:JSONDecode(payload)
  if object.future and object.id then
    local future = futures[object.future]
    if future then
      future(object.id)
    end
  end
end)

local _futurei = 0
getgenv().BrowserView = {
  new = function(contents)
    local positionFrame = Instance.new("TextLabel")
    positionFrame.BackgroundTransparency = 1
    positionFrame.Size = UDim2.new(0, 100, 0, 100)
    positionFrame.TextSize = 0
    positionFrame.TextTransparency = 1
    positionFrame.Text = contents

    local coro = coroutine.running()
    local myfuture = _futurei
    _futurei = _futurei + 1
    futures[myfuture] = function(id)
      futures[myfuture] = nil
      coroutine.resume(coro, id)
    end

    client:Send(httpService:JSONEncode({
      op = 'create',
      future = myfuture,
      location = {positionFrame.AbsolutePosition.X, positionFrame.AbsolutePosition.Y},
      size = {positionFrame.AbsoluteSize.X, positionFrame.AbsoluteSize.Y},
      contents = contents
    }))

    local viewid = coroutine.yield()
    local function modify()
      client:Send(httpService:JSONEncode({
        id = viewid,
        op = 'modify',
        location = {positionFrame.AbsolutePosition.X, positionFrame.AbsolutePosition.Y},
        size = {positionFrame.AbsoluteSize.X, positionFrame.AbsoluteSize.Y},
        contents = positionFrame.Text
      }))
    end

    positionFrame:GetPropertyChangedSignal('Position'):Connect(modify)
    positionFrame:GetPropertyChangedSignal('Size'):Connect(modify)
    positionFrame:GetPropertyChangedSignal('Text'):Connect(modify)
    positionFrame.Destroying:Connect(function()
      client:Send(httpService:JSONEncode({
        id = viewid,
        op = 'destroy'
      }))
    end)

    return positionFrame
  end
}

client:Connect()