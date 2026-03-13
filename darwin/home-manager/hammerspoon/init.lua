local workspaceItem = hs.menubar.new()

local function notifyFailure(message)
  hs.notify.new({
    title = "AeroSpace",
    informativeText = message,
  }):send()
end

local function setWorkspaceTitle(workspace)
  if workspaceItem == nil then
    return
  end

  if workspace == nil or workspace == "" then
    workspaceItem:setTitle("WS ?")
    return
  end

  workspaceItem:setTitle("WS " .. workspace)
end

local function refreshWorkspaceTitle()
  local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      local message = stdErr
      if message == nil or message == "" then
        message = stdOut
      end
      if message ~= nil and message ~= "" then
        notifyFailure(message)
      end
      setWorkspaceTitle("?")
      return
    end

    local workspace = stdOut:gsub("%s+$", "")
    setWorkspaceTitle(workspace)
  end, function() return true end, {
    "-lc",
    "/opt/homebrew/bin/aerospace list-workspaces --focused | head -n1",
  })

  if task == nil then
    notifyFailure("Failed to query current workspace")
    setWorkspaceTitle("?")
    return
  end

  task:start()
end

local function moveToWorkspace(workspace)
  local command = string.format(
    "/opt/homebrew/bin/aerospace move-node-to-workspace %s --focus-follows-window",
    tostring(workspace)
  )

  local task = hs.task.new("/bin/zsh", function(exitCode, stdOut, stdErr)
    if exitCode ~= 0 then
      local message = stdErr
      if message == nil or message == "" then
        message = stdOut
      end
      if message == nil or message == "" then
        message = "Failed to move window to workspace " .. workspace
      end
      notifyFailure(message)
      refreshWorkspaceTitle()
      return
    end

    setWorkspaceTitle(tostring(workspace))
  end, function() return true end, { "-lc", command })

  if task == nil then
    notifyFailure("Failed to start AeroSpace command")
    return
  end

  task:start()
end

for workspace = 1, 9 do
  hs.hotkey.bind({ "cmd", "alt" }, tostring(workspace), function()
    moveToWorkspace(workspace)
  end)
end

for _, workspace in ipairs({ "A", "B", "C", "D", "E", "F", "G" }) do
  hs.hotkey.bind({ "cmd", "alt" }, workspace:lower(), function()
    moveToWorkspace(workspace)
  end)
end

setWorkspaceTitle("?")
refreshWorkspaceTitle()
