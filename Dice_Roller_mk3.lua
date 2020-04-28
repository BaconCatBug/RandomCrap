--Based off: https://steamcommunity.com/sharedfiles/filedetails/?id=726800282
--Link for this mod: https://steamcommunity.com/sharedfiles/filedetails/?id=959360907
lastRolls = {}
scaleBtn = 3
printLastBtn = {
  label = "Last roll", click_function = "printLast", function_owner = self,
  position = { - 2.5, 0.1, - 0.87}, rotation = {0, 0, 0}, height = 50, width = 400,
  font_size = 60, color = {0, 0, 0}, font_color = {1, 1, 1}, scale = {scaleBtn, scaleBtn, scaleBtn}
}
printLast5Btn = {
  label = "Last 5 rolls", click_function = "printLast5", function_owner = self,
  position = {2.5, 0.1, - 0.87}, rotation = {0, 0, 0}, height = 50, width = 400,
  font_size = 60, color = {0, 0, 0}, font_color = {1, 1, 1}, scale = {scaleBtn, scaleBtn, scaleBtn}
}

function printLast()
  printResults(1)
end

function printLast5()
  printResults(5)
end

function printResults(n)
  if #lastRolls == 0 then
    printToAll("NO LAST ROLLS !!!\n", "Yellow")
  else
    printToAll("LAST ROLLS\n")
  end
  for i, result in ipairs(lastRolls) do
    if i <= n then
      printToAll(i.."  "..string.sub(result.msg, 3), result.color)
    end
  end
end

--Initialize Global Variables and pRNG Seed
seedcounter = 0
ver = 'BCB-2020-04-20'
lastHolder = {}
customFace = {4, 6, 8, 10, 12, 20}
diceGuidFaces = {}
sortedKeys = {}
resultsTable = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
local function seedpRNG() -- constructor
  local function private()
    math.randomseed(tonumber(tostring(os.time()):gsub("%.", ""):reverse():sub(1, 7)) + tonumber(tostring(os.clock()):reverse():sub(1, 7)))
    math.random()
    math.random()
    math.random()
    math.random()
  end
  return {
    func = function()
      private()
    end
  }
end
local m = seedpRNG()
m.func()

--Determine the person who put the dice in the box.
function onObjectPickedUp(playerColor, obj)
  lastHolder[obj] = playerColor
end

--Reset the person holding the dice when no dice are held.
function onObjectDestroyed(obj)
  lastHolder[obj] = nil
end

--Reset description on load if empty.
function onLoad(save_state)
  if self.getDescription() == '' then
    setDefaultState()
  end
  self.createButton(printLastBtn)
  self.createButton(printLast5Btn)
end

--Returns description on game save.
function onSave()
  return self.getDescription()
end

--Reset description on drop if empty.
function onDropped(player_color)
  if self.getDescription() == '' then
    setDefaultState()
  end
end

--Sets default description.
function setDefaultState()
  self.setDescription(JSON.encode_pretty({Results = 'no', SmoothDice = 'no', Rows = 'yes', SortNoRows = 'asc', Step = 1.05, Version = ver}))
end

--Creates a table and sorts the dice guids by value.
function sortByVal(t, type)
  local keys = {}
  for key in pairs(t) do
    table.insert(keys, key)
  end
  if type == 'asc' then
    table.sort(keys, function(a, b) return t[a] < t[b] end)
  elseif type == 'desc' then
    table.sort(keys, function(a, b) return t[a] > t[b] end)
  end
  return keys
end

--Checks the item dropped in the bag has a guid.
function hasGuid(t, g)
  for k, v in ipairs(t) do
    if v.guid == g then return true end
  end

  return false
end
--Runs when non-dice is put into bag
function onObjectEnterContainer(container, obj)
  if container == self and obj.tag ~= "Dice" then
    local pos = self.getPosition()
    local f = self.getTransformRight()
    self.takeObject({
      position = {pos.x + 20, pos.y + 50, pos.z + 20},
      smooth = false,
    })
    return
  end
end
--Runs when an object is dropped in bag.
function onCollisionEnter(collision_info)
  playerColor = lastHolder[collision_info.collision_object]
  if collision_info.collision_object.getGUID() == nil then return end
  diceGuidFaces = {}
  sortedKeys = {}

  --Save number of faces on dice
  for k, v in ipairs(getAllObjects()) do
    if v.tag == 'Dice' then
      objType = tostring(v)
      faces = tonumber(string.match(objType, 'Die_(%d+).*'))
      if faces == nil then
        faces = tonumber(customFace[v.getCustomObject().type + 1])
      end
      diceGuidFaces[v.getGUID()] = faces
      table.insert(sortedKeys, v.getGUID())
    end
  end

  --[[Benchmarking code
if resetclock ~= 1 then
clockstart = os.clock()
resetclock = 1
end--]]

--Creates a timer to take the dice out and position them.
Wait.time(|| takeDiceOut(), 0.3)
end

--Function to take the dice out of the bag and position them.
function takeDiceOut(tab)
local data = JSON.decode(self.getDescription())
if data == nil then
  setDefaultState()
  data = JSON.decode(self.getDescription())
  printToAll('Warning - invalid description. Restored default configuration.', {0.8, 0.5, 0})
end

if data.Step < 1 then
  setDefaultState()
  data = JSON.decode(self.getDescription())
  printToAll('Warning - "step" can\'t be lower than 1. Restored default configuration.', {0.8, 0.5, 0})
end

diceGuids = {}
for k, v in pairs(self.getObjects()) do
  faces = diceGuidFaces[v.guid]
  if v.name == "BCB-D3" then
    faces = 3
  end
  r = math.random(faces)
  seedcounter = seedcounter + math.random(10)
  if seedcounter > 99 then
    math.randomseed(tonumber(tostring(os.time()):reverse():sub(1, 7)) + tonumber(tostring(os.clock()):reverse():sub(1, 7)))
    seedcounter = 0
  end

  diceGuids[v.guid] = r
end

local objs = self.getObjects()
local position = self.getPosition()
rotation = self.getRotation()
sortedKeys = sortByVal(diceGuids, data.SortNoRows)
Rows = {}
n = 1
for _, key in pairs(sortedKeys) do
  if diceGuids[key] == math.floor(diceGuids[key]) then
    resultsTable[diceGuids[key]] = resultsTable[diceGuids[key]] + 1
  end

  if hasGuid(objs, key) then
    if Rows[diceGuids[key]] == nil then
      Rows[diceGuids[key]] = 0
    end
    Rows[diceGuids[key]] = Rows[diceGuids[key]] + 1
    params = {}
    params.guid = key
    local d12Xoffset = 0
    local d12Zoffset = 0
    if diceGuids[key] > 6 then
      d12Xoffset = -24
      d12Zoffset = 6
    end
    if data.Rows == 'no' then
      params.position = { position.x + (-1) * math.sin((90 + rotation.y) * 0.0174532) * (n + 0.5) * data.Step,
        position.y + 1,
      position.z + (-1) * math.cos((90 + rotation.y) * 0.0174532) * (n + 0.5) * data.Step}
    else
      params.position = {
        position.x + d12Xoffset + (Rows[diceGuids[key]] * math.cos((180 + self.getRotation().y) * 0.0174532)) * data.Step - (diceGuids[key] * math.sin((180 + self.getRotation().y) * 0.0174532)) * data.Step,
        position.y + 2,
      position.z + (Rows[diceGuids[key]] * math.sin((self.getRotation().y) * 0.0174532)) * data.Step + ((diceGuids[key] - d12Zoffset) * math.cos((0 + self.getRotation().y) * 0.0174532)) * data.Step}
    end

    --params.rotation = {rotation.x, rotation.y, rotation.z}
    params.callback = 'setValueCallback'
    params.params = {diceGuids[key]}
    params.smooth = false
    if data.SmoothDice == 'yes' then params.smooth = true end
    self.takeObject(params)
    n = n + 1
  end
end

printresultsTable()
--[[Benchmarking code
	clockend = os.clock()
	resetclock=0
	print('Runtime: ' .. clockend-clockstart .. ' seconds.')--]]
end

--Function to count resultsTable for printing.
function sum(t)
local sum = 0
for k, v in pairs(t) do
  sum = sum + v
end

return sum
end

--Prints resultsTable.
function printresultsTable()
local data = JSON.decode(self.getDescription())
local description = {'Ones.', 'Twos.', 'Threes.', 'Fours.', 'Fives.', 'Sixes.', 'Sevens.', 'Eights.', 'Nines.', 'Tens.', 'Elevens.', 'Twelves.', 'Thirteens.', 'Fourteens.', 'Fifteens.', 'Sixteens.', 'Seventeens', 'Eighteens.', 'Nineteens.', 'Twenties.'}
local msg = ''
local color = {1, 1, 1}
for dieFace, numRolled in ipairs(resultsTable) do
  if numRolled > 0 then
    msg = msg .. numRolled .. ' ' .. description[dieFace] .. ' '
  end
end

local time = '[' .. os.date("%H") .. ':' .. os.date("%M") .. ':' .. os.date("%S") .. ' UTC] '
if playerColor == nil then
  msg = '*******************************************************\n' .. time .. '~UNKNOWN PLAYER~ rolls:\n' .. msg .. '*******************************************************'
else
  msg = '*******************************************************\n' .. time .. Player[playerColor].steam_name .. ' rolls:\n' .. msg .. '*******************************************************'
  color = stringColorToRGB(playerColor)
end
local rolltorecord = {msg = msg, color = color}
if sum(resultsTable) > 0 then
  if #lastRolls >= 5 then
    table.remove(lastRolls, 1)
  end
  table.insert(lastRolls, #lastRolls + 1, rolltorecord)
end

if sum(resultsTable) > 0 and data.Results == 'yes' then
  printToAll(msg, color)
end

for k, v in ipairs(resultsTable) do
  resultsTable[k] = 0
end
end

--Sets the value of the physical dice object and reorients them if needed.
function setValueCallback(obj, tab)
function insidef()
  obj.setValue(tab[1])
  if obj.tag == 'Dice' then
    objType = tostring(obj)
    callFaces = tonumber(string.match(objType, 'Die_(%d+).*'))
    if callFaces == nil then callFaces = tonumber(customFace[obj.getCustomObject().type + 1]) end
    diceGuidFaces[obj.getGUID()] = callFaces
  end

  local waitFramesDelay = 35

  RotValues_4 = {180, 0, 180, 180}
  RotValues_6 = {180, 180, 180, 180, 180, 180}
  RotValues_8 = {180, 180, 0, 0, 0, 0, 180, 180}
  RotValues_10 = {180, 0, 180, 0, 180, 0, 180, 0, 180, 0}
  RotValues_12 = {180, 180, 180, 0, 0, 180, 0, 0, 180, 0, 287.93, 216}
  RotValues_20 = {239.65, 120, 0, 0, 120, 0, 120, 120, 120, 0, 180, 301.86, 300, 300, 300, 180, 60, 180, 300, 180}
  waitFrames(waitFramesDelay)
  local rot = self.getRotation()
  local r = obj.getRotation()
  local v = obj.getValue()

  if callFaces == 4 then
    obj.setRotation({r.x, rot.y + RotValues_4[v], r.z})
  end

  if callFaces == 6 then
    obj.setRotation({r.x, rot.y + RotValues_6[v], r.z})
  end

  if callFaces == 8 then
    obj.setRotation({r.x, rot.y + RotValues_8[v], r.z})
  end

  if callFaces == 10 then
    obj.setRotation({r.x, rot.y + RotValues_10[v], r.z})
  end

  if callFaces == 12 then
    obj.setRotation({r.x, rot.y + RotValues_12[v], r.z})
  end

  if callFaces == 20 then
    obj.setRotation({r.x, rot.y + RotValues_20[v], r.z})
  end

  return 1
end

startLuaCoroutine(self, 'insidef')
end

--Coroutine to wait to allow for custom dice positional data to be altered.
function waitFrames(frames)
while frames > 0 do
  coroutine.yield(0)
  frames = frames - 1
end
end


--Function to print table contents.
--[[
function printTable(tempTable)
	for k, v in pairs(tempTable) do
		print('key = ' .. k)
		print('value =' .. v)
	end
end
--]]