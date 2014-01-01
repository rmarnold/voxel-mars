module.exports = ->
  self.addEventListener 'message', (e) ->
    switch e.data.cmd
      when 'generateChunk'
        info = e.data.chunkInfo
        
        info.heightMap = new Uint8ClampedArray info.heightMap

        msg = 
          event: 'chunkGenerated'
          chunk: 
            voxels: generateChunk(info).buffer
            position: info.positionRaw
        
        self.postMessage msg, [msg.chunk.voxels]

  log = (msg) ->
    self.postMessage
      event: 'log'
      msg: msg

  getChunkIndex = (x, y, z, size) ->
    xIndex = Math.abs((size + x % size) % size)
    yIndex = Math.abs((size + y % size) % size)
    zIndex = Math.abs((size + z % size) % size)

    xIndex + (yIndex * size) + (zIndex * size * size)

  generateChunk = (info) ->
    {heightMap, position, size, heightScale, heightOffset} = info

    chunk = null
    anyHeight = no

    if position.y > -1
      chunk = new Int8Array(size * size * size)
    
      startY = position.y * size

      for z in [0...size]
        for x in [0...size]
          imgIdx = (size * z + x) << 2
          data = heightMap[imgIdx]
          height = getHeightFromColor data, heightScale, heightOffset
          endY = startY + size

          if endY > height >= startY
            anyHeight = yes

            # 3 layers of voxels under the surface
            for offset in [0..2]
              y = height - offset
              if y < startY
                break
              chunk[getChunkIndex(x, y, z, size)] = 1

    if anyHeight
      chunk
    else
      new Int8Array()