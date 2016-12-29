--dofile("anim8.lua")

debug = true
player = {x = 200, y = 710, speed = 230, img = nil, bulletSpeed = 800, hp = 100}
canShoot = true
canShootTimerMax = 1.2
canShootTimer = canShootTimerMax
bulletImg = nil
bullets = {}
enemyImg = nil
enemies = {}
isAlive = true
score = 0
levels = {}
currentLevel = nil
currentLevelIndex = 0
paused = false
stopped = true
terrainShift = 0




function love.load (args)
  -- load images
  player.img = love.graphics.newImage('assets/plane.png')
  bulletImg = love.graphics.newImage('assets/bullet.png')
  enemyImg = love.graphics.newImage('assets/enemy.png')
  terrainTile = love.graphics.newImage('assets/forest.png')
  -- load animation maps
  explosionMap = love.graphics.newImage("assets/explosion.png")
  -- load sounds
  blasterSound = love.audio.newSource("assets/blaster.mp3", "static")
  explosionSound = love.audio.newSource("assets/explosion.wav", "static")
  blasterSound:setVolume(0.5)
  -- animations
  --explosionGrid = anim8.newGrid(64,64, explosionMap:getWidth(),explosionMap:getHeight())
  --explosionFrames = explosionGrid("1-4", 1)
  --explosionAnim = anim8.newAnimation(explosionFrames, 1)
  level1 = {createEnemyTimerMax = 0.8, scoreToWin = 10, name = "Level 1", mapSpeed = 1}
  level2 = {createEnemyTimerMax = 0.6, scoreToWin = 20, name = "Level 2", mapSpeed = 2}
  level3 = {createEnemyTimerMax = 0.4, scoreToWin = 30, name = "Level 3", mapSpeed = 3}
  level4 = {createEnemyTimerMax = 0.2, scoreToWin = 40, name = "Level 4", mapSpeed = 4}
  level5 = {createEnemyTimerMax = 0.1, scoreToWin = 50, name = "Level 5", mapSpeed = 5}
  table.insert(levels, level1)
  table.insert(levels, level2)
  table.insert(levels, level3)
  table.insert(levels, level4)
  table.insert(levels, level5)
end




function love.update (dt)
  -- quit button
  if love.keyboard.isDown('escape') then
    love.event.push('quit')
  end
  if not paused and not stopped then
    -- movement buttons
    if love.keyboard.isDown('left', 'a') then
      if player.x > 0 then
        player.x = player.x - (player.speed * dt)
      end
    elseif love.keyboard.isDown('right', 'd') then
      if player.x < (love.graphics.getWidth() - player.img:getWidth()) then
        player.x = player.x + (player.speed * dt)
      end
    end
    if love.keyboard.isDown('up', 'w') then
      if player.y > 0 then
        player.y = player.y - (player.speed * dt)
      end
    elseif love.keyboard.isDown('down', 's') then
      if player.y < (love.graphics.getHeight() - player.img:getHeight()) then
        player.y = player.y + (player.speed * dt)
      end
    end
    -- fire button
    if love.keyboard.isDown(' ', 'rctrl', 'lctrl', 'ctrl') and canShoot then
      blasterSound:stop()
      blasterSound:play()
      newBullet = {x = player.x + (player.img:getWidth() / 2), y = player.y, img = bulletImg}
      table.insert(bullets, newBullet)
      canShoot = false
      canShootTimer = canShootTimerMax
    end
    -- fire delay calculation
    if table.getn(bullets) > 0 then
      canShootTimer = canShootTimer - (1 * dt)
      if canShootTimer < 0 then
        canShoot = true
      end
    else
      canShoot = true
    end
    -- bullet movement
    for i, bullet in ipairs(bullets) do
      bullet.y = bullet.y - (player.bulletSpeed * dt)
      if bullet.y < 0 then
        table.remove(bullets, i)
      end
    end
    -- enemy calculation
    createEnemyTimer = createEnemyTimer - (1 * dt)
    if createEnemyTimer < 0 then
      createEnemyTimer = currentLevel.createEnemyTimerMax
      -- create an enemy
      randomNumber = math.random(10, love.graphics.getWidth() - enemyImg:getWidth())
      newEnemy = {x = randomNumber, y = -10, img = enemyImg, damage = 20}
      table.insert(enemies, newEnemy)
    end
    -- enemy movement
    for i, enemy in ipairs(enemies) do
      enemy.y = enemy.y + (200 * dt)
      if enemy.y > 850 then
        table.remove(enemies, i)
      end
    end
    -- check collisions
    for i, enemy in ipairs(enemies) do
      for j, bullet in ipairs(bullets) do
        if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), bullet.x, bullet.y, bullet.img:getWidth(), bullet.img:getHeight()) then
          table.remove(bullets, j)
          enemyDestroy(i, dt)
          score = score + 1
        end
      end
      if CheckCollision(enemy.x, enemy.y, enemy.img:getWidth(), enemy.img:getHeight(), player.x, player.y, player.img:getWidth(), player.img:getHeight()) and isAlive then
        player.hp = player.hp - enemy.damage
        if player.hp <= 0 then
          isAlive = false
        end
        enemyDestroy(i, dt)
      end
    end
    -- restart game
    if not isAlive and love.keyboard.isDown('r') then
      bullets = {}
      enemies = {}
      canShootTimer = canShootTimerMax
      createEnemyTimer = currentLevel.createEnemyTimerMax
      player.x = 50
      player.y = 710
      player.hp = 100
      score = 0
      isAlive = true
      currentLevelIndex = 1
      currentLevel = levels[currentLevelIndex]
    end
  end
  -- next level trigger
  if not stopped then
    if currentLevel.scoreToWin <= score then
      currentLevelIndex = currentLevelIndex + 1
      if currentLevelIndex <= table.getn(levels) then
        setLevel(currentLevelIndex)
        paused = true
      end
    end
  end
end



offset = 0

function love.draw ()
  -- terrain
  tilesCountX = math.floor(love.graphics.getWidth() / terrainTile:getWidth())
  tilesCountY = math.floor(love.graphics.getHeight() / terrainTile:getHeight())
  for j = -1, tilesCountY do
    for i = 0, tilesCountX do
      love.graphics.draw(terrainTile, i * terrainTile:getWidth(), j * terrainTile:getHeight() + terrainShift)
    end
  end
  if not paused and not stopped then
    if terrainShift < terrainTile:getHeight() then
      terrainShift = terrainShift + currentLevel.mapSpeed
    else
      terrainShift = 0
    end
  end
  -- stopped
  if stopped then
    love.graphics.setNewFont(30)
    love.graphics.printf("Welcome to THE GAME!\nPress 'return' to start", 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), 'center')
    love.graphics.setNewFont(15)
  end
  --pause
  if paused then
    love.graphics.print("Paused\n" .. currentLevel.name, love.graphics:getWidth()/2-50, love.graphics:getHeight()/2-50)
  end
  -- player
  if isAlive then
    love.graphics.draw(player.img, player.x, player.y)
  else
    love.graphics.print("Press 'R' to restart", love.graphics:getWidth()/2-50, love.graphics:getHeight()/2-50)
  end
  -- bullets
  for i, bullet in ipairs(bullets) do
    love.graphics.draw(bullet.img, bullet.x, bullet.y)
  end
  -- enemies
  for i, enemy in ipairs(enemies) do
    love.graphics.draw(enemy.img, enemy.x, enemy.y, 0, 0.7)
  end
  --explosionAnim:draw(explosionMap)
  if not stopped then
    -- score
    love.graphics.print("Score: " .. score, 0, 0)
    -- score to win
    love.graphics.print("Score to win: " .. currentLevel.scoreToWin, 0, 15)
    -- current levels
    love.graphics.print(currentLevel.name, love.graphics.getWidth() - 100, 0)
  end
  -- player's hp
  love.graphics.print("Health: " .. player.hp .. "%", 5, love.graphics.getHeight()-20)
end




function CheckCollision(x1,y1,w1,h1, x2,y2,w2,h2)
  return x1 < x2+w2 and
         x2 < x1+w1 and
         y1 < y2+h2 and
         y2 < y1+h1
end


function setLevel (levelIndex)
  currentLevel = levels[levelIndex]
  createEnemyTimer = currentLevel.createEnemyTimerMax
  score = 0
  player.hp = 100
end


function enemyDestroy (enemyIndex, dt)
  explosionSound:stop()
  explosionSound:play()
  --explosionAnim:update(dt)
  table.remove(enemies, enemyIndex)
end


function love.keyreleased(key)
  if key == "return" then
    if stopped then
      stopped = false
      currentLevelIndex = 1
      setLevel(currentLevelIndex)
    elseif paused then
      unPause()
    else
      setPause()
    end
  end
end


function setPause ()
  paused = true
end

function unPause ()
  paused = false
end
