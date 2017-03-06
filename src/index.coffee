###*
# Tween.js - Licensed under the MIT license
# https://github.com/tweenjs/tween.js
# ----------------------------------------------
#
# See https://github.com/tweenjs/tween.js/graphs/contributors for the full list of contributors.
# Thank you all, you're awesome!
###
import now from 'es-now'

TWEEN = TWEEN or do ->
  _tweens = []
  {
    getAll: ->
      _tweens
    removeAll: ->
      _tweens = []
      return
    add: (tween) ->
      _tweens.push tween
      return
    remove: (tween) ->
      i = _tweens.indexOf(tween)
      if i != -1
        _tweens.splice i, 1
      return
    update: (time, preserve) ->
      if _tweens.length == 0
        return false
      i = 0
      time = if time != undefined then time else TWEEN.now()
      while i < _tweens.length
        if _tweens[i].update(time) or preserve
          i++
        else
          _tweens.splice i, 1
      true

  }

TWEEN.now = now

TWEEN.Tween              = (object) ->
  _object                = object
  _valuesStart           = {}
  _valuesEnd             = {}
  _valuesStartRepeat     = {}
  _duration              = 1000
  _repeat                = 0
  _repeatDelayTime       = undefined
  _yoyo                  = false
  _isPlaying             = false
  _reversed              = false
  _delayTime             = 0
  _startTime             = null
  _easingFunction        = TWEEN.Easing.Linear.None
  _interpolationFunction = TWEEN.Interpolation.Linear
  _chainedTweens         = []
  _onStartCallback       = null
  _onStartCallbackFired  = false
  _onUpdateCallback      = null
  _onCompleteCallback    = null
  _onStopCallback        = null

  @to = (properties, duration) ->
    _valuesEnd = properties
    if duration != undefined
      _duration = duration
    this

  @start = (time) ->
    TWEEN.add this
    _isPlaying = true
    _onStartCallbackFired = false
    _startTime = if time != undefined then time else TWEEN.now()
    _startTime += _delayTime
    for property of _valuesEnd
      # Check if an Array was provided as property value
      if _valuesEnd[property] instanceof Array
        if _valuesEnd[property].length == 0
          continue
        # Create a local copy of the Array with the start value at the front
        _valuesEnd[property] = [ _object[property] ].concat(_valuesEnd[property])
      # If `to()` specifies a property that doesn't exist in the source object,
      # we should not set that property in the object
      if _object[property] == undefined
        continue
      # Save the starting value.
      _valuesStart[property] = _object[property]
      if _valuesStart[property] instanceof Array == false
        _valuesStart[property] *= 1.0
        # Ensures we're using numbers, not strings
      _valuesStartRepeat[property] = _valuesStart[property] or 0
    this

  @stop = ->
    if !_isPlaying
      return this
    TWEEN.remove this
    _isPlaying = false
    if _onStopCallback != null
      _onStopCallback.call _object, _object
    @stopChainedTweens()
    this

  @end = ->
    @update _startTime + _duration
    this

  @stopChainedTweens = ->
    i = 0
    numChainedTweens = _chainedTweens.length
    while i < numChainedTweens
      _chainedTweens[i].stop()
      i++
    return

  @delay = (amount) ->
    _delayTime = amount
    this

  @repeat = (times) ->
    _repeat = times
    this

  @repeatDelay = (amount) ->
    _repeatDelayTime = amount
    this

  @yoyo = (yoyo) ->
    _yoyo = yoyo
    this

  @easing = (easing) ->
    _easingFunction = easing
    this

  @interpolation = (interpolation) ->
    _interpolationFunction = interpolation
    this

  @chain = ->
    _chainedTweens = arguments
    this

  @onStart = (callback) ->
    _onStartCallback = callback
    this

  @onUpdate = (callback) ->
    _onUpdateCallback = callback
    this

  @onComplete = (callback) ->
    _onCompleteCallback = callback
    this

  @onStop = (callback) ->
    _onStopCallback = callback
    this

  @update = (time) ->
    property = undefined
    elapsed  = undefined
    value    = undefined
    if time < _startTime
      return true
    if _onStartCallbackFired == false
      if _onStartCallback != null
        _onStartCallback.call _object, _object
      _onStartCallbackFired = true
    elapsed = (time - _startTime) / _duration
    elapsed = if elapsed > 1 then 1 else elapsed
    value = _easingFunction(elapsed)
    for property of _valuesEnd
      `property = property`
      # Don't update properties that do not exist in the source object
      if _valuesStart[property] == undefined
        i++
        continue
      start = _valuesStart[property] or 0
      end = _valuesEnd[property]
      if end instanceof Array
        _object[property] = _interpolationFunction(end, value)
      else
        # Parses relative end values with start as base (e.g.: +10, -3)
        if typeof end == 'string'
          if end.charAt(0) == '+' or end.charAt(0) == '-'
            end = start + parseFloat(end)
          else
            end = parseFloat(end)
        # Protect against non numeric properties.
        if typeof end == 'number'
          _object[property] = start + (end - start) * value
    if _onUpdateCallback != null
      _onUpdateCallback.call _object, value
    if elapsed == 1
      if _repeat > 0
        if isFinite(_repeat)
          _repeat--
        # Reassign starting values, restart by making startTime = now
        for property of _valuesStartRepeat
          `property = property`
          if typeof _valuesEnd[property] == 'string'
            _valuesStartRepeat[property] = _valuesStartRepeat[property] + parseFloat(_valuesEnd[property])
          if _yoyo
            tmp                          = _valuesStartRepeat[property]
            _valuesStartRepeat[property] = _valuesEnd[property]
            _valuesEnd[property]         = tmp
          _valuesStart[property]         = _valuesStartRepeat[property]
        if _yoyo
          _reversed = !_reversed
        if _repeatDelayTime != undefined
          _startTime = time + _repeatDelayTime
        else
          _startTime = time + _delayTime
        return true
      else
        if _onCompleteCallback != null
          _onCompleteCallback.call _object, _object
        i = 0
        numChainedTweens = _chainedTweens.length
        while i < numChainedTweens
          # Make the chained tweens start exactly at the time they should,
          # even if the `update()` method was called way past the duration of the tween
          _chainedTweens[i].start _startTime + _duration
          i++
        return false
    true

  return

TWEEN.Easing =
  Linear: None: (k) ->
    k
  Quadratic:
    In: (k) ->
      k * k
    Out: (k) ->
      k * (2 - k)
    InOut: (k) ->
      if (k *= 2) < 1
        return 0.5 * k * k
      -0.5 * (--k * (k - 2) - 1)
  Cubic:
    In: (k) ->
      k * k * k
    Out: (k) ->
      --k * k * k + 1
    InOut: (k) ->
      if (k *= 2) < 1
        return 0.5 * k * k * k
      0.5 * ((k -= 2) * k * k + 2)
  Quartic:
    In: (k) ->
      k * k * k * k
    Out: (k) ->
      1 - (--k * k * k * k)
    InOut: (k) ->
      if (k *= 2) < 1
        return 0.5 * k * k * k * k
      -0.5 * ((k -= 2) * k * k * k - 2)
  Quintic:
    In: (k) ->
      k * k * k * k * k
    Out: (k) ->
      --k * k * k * k * k + 1
    InOut: (k) ->
      if (k *= 2) < 1
        return 0.5 * k * k * k * k * k
      0.5 * ((k -= 2) * k * k * k * k + 2)
  Sinusoidal:
    In: (k) ->
      1 - Math.cos(k * Math.PI / 2)
    Out: (k) ->
      Math.sin k * Math.PI / 2
    InOut: (k) ->
      0.5 * (1 - Math.cos(Math.PI * k))
  Exponential:
    In: (k) ->
      if k == 0 then 0 else 1024 ** (k - 1)
    Out: (k) ->
      if k == 1 then 1 else 1 - 2 ** (-10 * k)
    InOut: (k) ->
      if k == 0
        return 0
      if k == 1
        return 1
      if (k *= 2) < 1
        return 0.5 * 1024 ** (k - 1)
      0.5 * (-2 ** (-10 * (k - 1)) + 2)
  Circular:
    In: (k) ->
      1 - Math.sqrt(1 - (k * k))
    Out: (k) ->
      Math.sqrt 1 - (--k * k)
    InOut: (k) ->
      if (k *= 2) < 1
        return -0.5 * (Math.sqrt(1 - (k * k)) - 1)
      0.5 * (Math.sqrt(1 - ((k -= 2) * k)) + 1)
  Elastic:
    In: (k) ->
      if k == 0
        return 0
      if k == 1
        return 1
      -2 ** (10 * (k - 1)) * Math.sin((k - 1.1) * 5 * Math.PI)
    Out: (k) ->
      if k == 0
        return 0
      if k == 1
        return 1
      2 ** (-10 * k) * Math.sin((k - 0.1) * 5 * Math.PI) + 1
    InOut: (k) ->
      if k == 0
        return 0
      if k == 1
        return 1
      k *= 2
      if k < 1
        return -0.5 * 2 ** (10 * (k - 1)) * Math.sin((k - 1.1) * 5 * Math.PI)
      0.5 * 2 ** (-10 * (k - 1)) * Math.sin((k - 1.1) * 5 * Math.PI) + 1
  Back:
    In: (k) ->
      s = 1.70158
      k * k * ((s + 1) * k - s)
    Out: (k) ->
      s = 1.70158
      --k * k * ((s + 1) * k + s) + 1
    InOut: (k) ->
      s = 1.70158 * 1.525
      if (k *= 2) < 1
        return 0.5 * k * k * ((s + 1) * k - s)
      0.5 * ((k -= 2) * k * ((s + 1) * k + s) + 2)
  Bounce:
    In: (k) ->
      1 - TWEEN.Easing.Bounce.Out(1 - k)
    Out: (k) ->
      if k < 1 / 2.75
        7.5625 * k * k
      else if k < 2 / 2.75
        7.5625 * (k -= 1.5 / 2.75) * k + 0.75
      else if k < 2.5 / 2.75
        7.5625 * (k -= 2.25 / 2.75) * k + 0.9375
      else
        7.5625 * (k -= 2.625 / 2.75) * k + 0.984375
    InOut: (k) ->
      if k < 0.5
        return TWEEN.Easing.Bounce.In(k * 2) * 0.5
      TWEEN.Easing.Bounce.Out(k * 2 - 1) * 0.5 + 0.5

TWEEN.Interpolation =
  Linear: (v, k) ->
    m = v.length - 1
    f = m * k
    i = Math.floor(f)
    fn = TWEEN.Interpolation.Utils.Linear
    if k < 0
      return fn(v[0], v[1], f)
    if k > 1
      return fn(v[m], v[m - 1], m - f)
    fn v[i], v[if i + 1 > m then m else i + 1], f - i
  Bezier: (v, k) ->
    b = 0
    n = v.length - 1
    pw = Math.pow
    bn = TWEEN.Interpolation.Utils.Bernstein
    i = 0
    while i <= n
      b += pw(1 - k, n - i) * pw(k, i) * v[i] * bn(n, i)
      i++
    b
  CatmullRom: (v, k) ->
    m = v.length - 1
    f = m * k
    i = Math.floor(f)
    fn = TWEEN.Interpolation.Utils.CatmullRom
    if v[0] == v[m]
      if k < 0
        i = Math.floor(f = m * (1 + k))
      fn v[(i - 1 + m) % m], v[i], v[(i + 1) % m], v[(i + 2) % m], f - i
    else
      if k < 0
        return v[0] - (fn(v[0], v[0], v[1], v[1], -f) - (v[0]))
      if k > 1
        return v[m] - (fn(v[m], v[m], v[m - 1], v[m - 1], f - m) - (v[m]))
      fn v[if i then i - 1 else 0], v[i], v[if m < i + 1 then m else i + 1], v[if m < i + 2 then m else i + 2], f - i

  Utils:
    Linear: (p0, p1, t) ->
      (p1 - p0) * t + p0
    Bernstein: (n, i) ->
      fc = TWEEN.Interpolation.Utils.Factorial
      fc(n) / fc(i) / fc(n - i)
    Factorial: do ->
      a = [ 1 ]
      (n) ->
        s = 1
        if a[n]
          return a[n]
        i = n
        while i > 1
          s *= i
          i--
        a[n] = s
        s
    CatmullRom: (p0, p1, p2, p3, t) ->
      v0 = (p2 - p0) * 0.5
      v1 = (p3 - p1) * 0.5
      t2 = t * t
      t3 = t * t2
      (2 * p1 - (2 * p2) + v0 + v1) * t3 + (-3 * p1 + 3 * p2 - (2 * v0) - v1) * t2 + v0 * t + p1

export default TWEEN
